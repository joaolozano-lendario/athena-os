#!/usr/bin/env bash
# PreToolUse hook: Validate content against contracts before Write
# Called by Claude Code BEFORE a worker writes a file.
# Modes:
#   inject → Return additionalContext with dependency info (never blocks)
#   strict → Run validator → exit 0 (pass) or exit 2 (block with corrective feedback)
# If not a consumer or no contracts → exit 0 (noop).

set +e  # Never crash the worker

INPUT=$(cat)

# Only act on Write tool
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null)
[[ "$TOOL_NAME" != "Write" ]] && exit 0

# Extract file_path and content to temp files for reliable passing
_TMPINPUT=$(mktemp "${TEMP:-/tmp}/hook-input-XXXXXX.json" 2>/dev/null || mktemp)
echo "$INPUT" > "$_TMPINPUT"
trap "rm -f '$_TMPINPUT'" EXIT

FILE_PATH=$(python3 -c "import sys,json; d=json.load(open(sys.argv[1])); print(d.get('tool_input',{}).get('file_path',''))" "$_TMPINPUT" 2>/dev/null)
[[ -z "$FILE_PATH" ]] && exit 0

RUNTIME="${FORMICA_RUNTIME_DIR:-}"
TASK_ID="${FORMICA_TASK_ID:-}"
MODE="${FORMICA_COHERENCE_MODE:-off}"
[[ -z "$RUNTIME" || "$MODE" == "off" ]] && exit 0

# Load coherence map
COHERENCE_MAP="$RUNTIME/coherence-map.json"
[[ ! -f "$COHERENCE_MAP" ]] && exit 0

# Find consumer entry for current task
CONSUMER_INFO=$(python3 -c "
import json, sys
with open('$COHERENCE_MAP') as f:
    cmap = json.load(f)
contracts = cmap.get('contracts', [])
for c in contracts:
    if c.get('consumer') == '$TASK_ID':
        print(json.dumps(c))
        sys.exit(0)
print('')
" 2>/dev/null)

[[ -z "$CONSUMER_INFO" ]] && exit 0

# Get producer task ID and validator type
_TMPCONSUMER=$(mktemp "${TEMP:-/tmp}/hook-consumer-XXXXXX.json" 2>/dev/null || mktemp)
echo "$CONSUMER_INFO" > "$_TMPCONSUMER"
trap "rm -f '$_TMPINPUT' '$_TMPCONSUMER'" EXIT

PRODUCER=$(python3 -c "import sys,json; print(json.load(open(sys.argv[1])).get('producer',''))" "$_TMPCONSUMER" 2>/dev/null)
VALIDATOR_TYPE=$(python3 -c "import sys,json; print(json.load(open(sys.argv[1])).get('validator','generic'))" "$_TMPCONSUMER" 2>/dev/null)

# Load producer's contract
CONTRACT_FILE="$RUNTIME/contracts/${PRODUCER}.contract.json"
if [[ ! -f "$CONTRACT_FILE" ]]; then
  exit 0
fi

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$MODE" == "inject" ]]; then
  # Inject mode: return additionalContext with contract summary
  SUMMARY=$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    c = json.load(f)
exports = c.get('exports', {})
parts = []
for key, val in exports.items():
    if isinstance(val, list):
        parts.append(f'{key}: {len(val)} items')
    else:
        parts.append(f'{key}: {val}')
print('; '.join(parts))
" "$CONTRACT_FILE" 2>/dev/null)
  python3 -c "
import json
result = {'additionalContext': 'Reference from producer ($PRODUCER): $SUMMARY'}
print(json.dumps(result))
" 2>/dev/null
  exit 0
fi

# Strict mode: run validator
VALIDATOR="$HOOK_DIR/validators/validate-${VALIDATOR_TYPE}.sh"
[[ ! -f "$VALIDATOR" ]] && VALIDATOR="$HOOK_DIR/validators/validate-generic.sh"

# Build validator input: { contract, content, file_path }
_TMPVALIDATOR=$(mktemp "${TEMP:-/tmp}/hook-validator-XXXXXX.json" 2>/dev/null || mktemp)
trap "rm -f '$_TMPINPUT' '$_TMPCONSUMER' '$_TMPVALIDATOR'" EXIT

python3 -c "
import json, sys
with open(sys.argv[1]) as cf:
    contract = json.load(cf)
with open(sys.argv[2]) as inf:
    inp = json.load(inf)
content = inp.get('tool_input', {}).get('content', '')
data = {
    'contract': contract,
    'content': content,
    'file_path': '$FILE_PATH'
}
with open(sys.argv[3], 'w') as out:
    json.dump(data, out)
" "$CONTRACT_FILE" "$_TMPINPUT" "$_TMPVALIDATOR" 2>/dev/null

cat "$_TMPVALIDATOR" | bash "$VALIDATOR"
exit $?
