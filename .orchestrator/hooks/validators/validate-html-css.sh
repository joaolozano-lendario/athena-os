#!/usr/bin/env bash
# Validate CSS content against HTML contract
# Input: stdin JSON { contract: {...}, content: "...", file_path: "..." }
# Output: exit 0 (valid) | exit 2 + stderr (invalid)

# Read all stdin into variable
INPUT=$(cat)

# Use a temp file for reliable JSON passing to python
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

# CSS class selectors from content (strip pseudo-classes)
content_clean = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
css_classes = set(
    re.sub(r':.*$', '', m)
    for m in re.findall(r'\.([a-zA-Z][a-zA-Z0-9_-]*)', content_clean)
)

# Filter out known CSS pseudo/framework patterns
skip = {'root','before','after','hover','focus','active','visited','first-child','last-child',
        'nth-child','not','placeholder','selection','webkit','moz','ms','where','is','has'}
css_classes = {c for c in css_classes if c.lower() not in skip and not c.startswith(('webkit','moz','ms'))}

orphans = sorted(css_classes - html_classes)

if orphans:
    print(f'BLOCKED: {len(orphans)} CSS selectors have no matching HTML class.', file=sys.stderr)
    print(f'', file=sys.stderr)
    print(f'Orphan selectors:', file=sys.stderr)
    for o in orphans:
        print(f'  .{o}', file=sys.stderr)
    print(f'', file=sys.stderr)
    print(f'Available HTML classes ({len(html_classes)}):', file=sys.stderr)
    for c in sorted(html_classes):
        print(f'  .{c}', file=sys.stderr)
    print(f'', file=sys.stderr)
    print(f'Fix your CSS to use ONLY classes present in the HTML.', file=sys.stderr)
    sys.exit(2)

sys.exit(0)
" "$_TMPJSON"

exit $?
