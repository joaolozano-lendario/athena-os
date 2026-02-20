#!/usr/bin/env bash
# Extract CSS interface contract: class selectors, ID selectors, variables
# Input: $1 = file path (CSS file already written)
# Output: JSON contract to stdout

FILE_PATH="$1"
[[ ! -f "$FILE_PATH" ]] && exit 1

FILE_CONTENT=$(cat "$FILE_PATH")

_EXTRACT_CONTENT="$FILE_CONTENT" _EXTRACT_PATH="$FILE_PATH" python3 -c "
import re, json, sys, os

content = os.environ['_EXTRACT_CONTENT']
file_path = os.environ['_EXTRACT_PATH']

# Remove comments
content_clean = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)

# Class selectors (strip pseudo-classes)
classes = sorted(set(
    re.sub(r':.*$', '', m)
    for m in re.findall(r'\.([a-zA-Z][a-zA-Z0-9_-]*)', content_clean)
))
# ID selectors
ids = sorted(set(re.findall(r'#([a-zA-Z][a-zA-Z0-9_-]*)', content_clean)))
# CSS custom properties
variables = sorted(set(re.findall(r'(--[a-zA-Z][a-zA-Z0-9_-]*)', content_clean)))

contract = {
    'source': file_path,
    'type': 'css-selectors',
    'exports': {
        'selectors': classes,
        'ids': ids,
        'variables': variables
    }
}
json.dump(contract, sys.stdout, indent=2)
" 2>/dev/null
