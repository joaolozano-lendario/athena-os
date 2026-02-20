#!/usr/bin/env bash
# Extract HTML interface contract: classes, IDs, data-attributes
# Input: $1 = file path (HTML file already written)
# Output: JSON contract to stdout

FILE_PATH="$1"
[[ ! -f "$FILE_PATH" ]] && exit 1

# Read content via bash (handles MSYS paths that python can't resolve on Windows)
FILE_CONTENT=$(cat "$FILE_PATH")

_EXTRACT_CONTENT="$FILE_CONTENT" _EXTRACT_PATH="$FILE_PATH" python3 -c "
import re, json, sys, os

content = os.environ['_EXTRACT_CONTENT']
file_path = os.environ['_EXTRACT_PATH']

classes = sorted(set(
    cls for match in re.findall(r'class=\"([^\"]+)\"', content)
    for cls in match.split()
    if cls
))
ids = sorted(set(re.findall(r'id=\"([^\"]+)\"', content)))
data_attrs = sorted(set(re.findall(r'(data-[a-z][a-z0-9-]*)=', content)))

contract = {
    'source': file_path,
    'type': 'html-interface',
    'exports': {
        'classes': classes,
        'ids': ids,
        'data_attributes': data_attrs
    }
}
json.dump(contract, sys.stdout, indent=2)
" 2>/dev/null
