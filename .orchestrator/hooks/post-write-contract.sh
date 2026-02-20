#!/usr/bin/env bash
# PostToolUse hook: Extract interface contract after Write
# Called by Claude Code after a worker writes a file.
# Reads coherence-map.json to determine if this task is a producer.
# If yes → delegates to type-specific extractor → saves contract JSON.
# If no → exit 0 (noop).

set +e  # Never crash the worker

INPUT=$(cat)

# Only act on Write tool
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
[[ "$TOOL_NAME" != "Write" ]] && exit 0

FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)
[[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]] && exit 0

# Need runtime dir and task ID
RUNTIME="${FORMICA_RUNTIME_DIR:-}"
TASK_ID="${FORMICA_TASK_ID:-}"
[[ -z "$RUNTIME" ]] && exit 0

# Load coherence map
COHERENCE_MAP="$RUNTIME/coherence-map.json"
[[ ! -f "$COHERENCE_MAP" ]] && exit 0

# Check if current task is a producer
EXTRACTOR_TYPE=$(python3 -c "
import json, sys
with open('$COHERENCE_MAP') as f:
    cmap = json.load(f)
contracts = cmap.get('contracts', [])
for c in contracts:
    if c.get('producer') == '$TASK_ID':
        vtype = c.get('validator', 'generic')
        type_map = {
            'html-css-classes': 'html',
            'html-js-queries': 'html',
            'keyword-presence': 'keywords',
        }
        etype = c.get('extractor', type_map.get(vtype, 'generic'))
        print(etype)
        sys.exit(0)
print('')
" 2>/dev/null)

[[ -z "$EXTRACTOR_TYPE" ]] && exit 0

# Determine extractor script
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTRACTOR="$HOOK_DIR/extractors/extract-${EXTRACTOR_TYPE}.sh"
[[ ! -f "$EXTRACTOR" ]] && EXTRACTOR="$HOOK_DIR/extractors/extract-generic.sh"

# Run extractor → save contract
CONTRACT_DIR="$RUNTIME/contracts"
mkdir -p "$CONTRACT_DIR"
CONTRACT_FILE="$CONTRACT_DIR/${TASK_ID}.contract.json"

CONTRACT=$(bash "$EXTRACTOR" "$FILE_PATH" 2>/dev/null)
if [[ -n "$CONTRACT" ]]; then
  # Add metadata (source_task, timestamp)
  _TMPC=$(mktemp "${TEMP:-/tmp}/contract-XXXXXX.json" 2>/dev/null || mktemp)
  echo "$CONTRACT" > "$_TMPC"
  python3 -c "
import json, sys
from datetime import datetime
with open(sys.argv[1]) as f:
    c = json.load(f)
c['source_task'] = '$TASK_ID'
c['timestamp'] = datetime.now().isoformat()
with open(sys.argv[2], 'w') as out:
    json.dump(c, out, indent=2)
" "$_TMPC" "$CONTRACT_FILE" 2>/dev/null
  rm -f "$_TMPC"
fi

exit 0
