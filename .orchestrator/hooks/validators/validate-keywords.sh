#!/usr/bin/env bash
# Validate content against keyword contract (required terms must be present)
# Input: stdin JSON { contract: {...}, content: "...", file_path: "..." }
# Output: exit 0 (valid) | exit 2 + stderr (invalid)

INPUT=$(cat)

_TMPJSON=$(mktemp "${TEMP:-/tmp}/validate-XXXXXX.json" 2>/dev/null || mktemp)
echo "$INPUT" > "$_TMPJSON"
trap "rm -f '$_TMPJSON'" EXIT

python3 -c "
import json, sys

with open(sys.argv[1], 'r') as f:
    data = json.load(f)

contract = data.get('contract', {})
content = data.get('content', '').lower()

keywords = contract.get('exports', {}).get('keywords', [])
if not keywords:
    sys.exit(0)

missing = [kw for kw in keywords if kw.lower() not in content]

if len(missing) > len(keywords) * 0.3:
    print(f'BLOCKED: {len(missing)}/{len(keywords)} required keywords missing from content.', file=sys.stderr)
    print(f'', file=sys.stderr)
    print(f'Missing keywords:', file=sys.stderr)
    for m in missing[:20]:
        print(f'  - {m}', file=sys.stderr)
    print(f'', file=sys.stderr)
    print(f'Ensure content includes the key terms from the source document.', file=sys.stderr)
    sys.exit(2)

sys.exit(0)
" "$_TMPJSON"

exit $?
