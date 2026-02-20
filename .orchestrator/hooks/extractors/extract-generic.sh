#!/usr/bin/env bash
# Generic contract extractor: saves content summary as reference
# Input: $1 = file path
# Output: JSON contract to stdout

FILE_PATH="$1"
[[ ! -f "$FILE_PATH" ]] && exit 1

FILE_CONTENT=$(cat "$FILE_PATH")
FILE_SIZE=$(wc -c < "$FILE_PATH" | tr -d ' ')

_EXTRACT_CONTENT="$FILE_CONTENT" _EXTRACT_PATH="$FILE_PATH" _EXTRACT_SIZE="$FILE_SIZE" python3 -c "
import json, sys, os

content = os.environ['_EXTRACT_CONTENT']
file_path = os.environ['_EXTRACT_PATH']
size = int(os.environ.get('_EXTRACT_SIZE', '0'))

contract = {
    'source': file_path,
    'type': 'generic',
    'exports': {
        'size_bytes': size,
        'line_count': content.count('\n') + 1,
        'preview': content[:500]
    }
}
json.dump(contract, sys.stdout, indent=2)
" 2>/dev/null
