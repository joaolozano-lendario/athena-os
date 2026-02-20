#!/usr/bin/env bash
# Validate JS content against HTML contract (DOM queries must match)
# Input: stdin JSON { contract: {...}, content: "...", file_path: "..." }
# Output: exit 0 (valid) | exit 2 + stderr (invalid)

INPUT=$(cat)

_TMPJSON=$(mktemp "${TEMP:-/tmp}/validate-XXXXXX.json" 2>/dev/null || mktemp)
echo "$INPUT" > "$_TMPJSON"
trap "rm -f '$_TMPJSON'" EXIT

python3 -c "
import json, re, sys

with open(sys.argv[1], 'r') as f:
    data = json.load(f)

contract = data.get('contract', {})
content = data.get('content', '')

html_classes = set(contract.get('exports', {}).get('classes', []))
html_ids = set(contract.get('exports', {}).get('ids', []))

if not html_classes and not html_ids:
    sys.exit(0)

# Extract DOM queries from JS
qs_matches = re.findall(r'querySelector(?:All)?\s*\(\s*[\"\'](.*?)[\"\']', content)
gid_matches = re.findall(r'getElementById\s*\(\s*[\"\'](.*?)[\"\']', content)
gcn_matches = re.findall(r'getElementsByClassName\s*\(\s*[\"\'](.*?)[\"\']', content)

orphan_selectors = []
for sel in qs_matches:
    for c in re.findall(r'\.([a-zA-Z][a-zA-Z0-9_-]*)', sel):
        if c not in html_classes:
            orphan_selectors.append(f'.{c}')
    for i in re.findall(r'#([a-zA-Z][a-zA-Z0-9_-]*)', sel):
        if i not in html_ids:
            orphan_selectors.append(f'#{i}')

for i in gid_matches:
    if i not in html_ids:
        orphan_selectors.append(f'#{i}')

for c in gcn_matches:
    if c not in html_classes:
        orphan_selectors.append(f'.{c}')

orphan_selectors = sorted(set(orphan_selectors))

if orphan_selectors:
    print(f'BLOCKED: {len(orphan_selectors)} JS DOM queries reference non-existent HTML elements.', file=sys.stderr)
    print(f'', file=sys.stderr)
    print(f'Orphan queries:', file=sys.stderr)
    for o in orphan_selectors:
        print(f'  {o}', file=sys.stderr)
    print(f'', file=sys.stderr)
    print(f'Fix your JS to query ONLY elements present in the HTML.', file=sys.stderr)
    sys.exit(2)

sys.exit(0)
" "$_TMPJSON"

exit $?
