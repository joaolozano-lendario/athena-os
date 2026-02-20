#!/usr/bin/env bash
# Extract keyword/term contract from content
# Input: $1 = file path
# Output: JSON contract to stdout

FILE_PATH="$1"
[[ ! -f "$FILE_PATH" ]] && exit 1

FILE_CONTENT=$(cat "$FILE_PATH")

_EXTRACT_CONTENT="$FILE_CONTENT" _EXTRACT_PATH="$FILE_PATH" python3 -c "
import re, json, sys, os
from collections import Counter

content = os.environ['_EXTRACT_CONTENT']
file_path = os.environ['_EXTRACT_PATH']

# Extract words (3+ chars, alphabetic)
words = re.findall(r'\b[a-zA-Z]{3,}\b', content.lower())
freq = Counter(words)

# Significant terms: appear 2+ times, not common stopwords
stopwords = {'the','and','for','are','but','not','you','all','can','had','her','was','one','our','out',
             'has','its','let','may','who','how','did','get','him','his','she','too','use','from','with',
             'that','this','have','will','each','make','like','long','look','many','some','than','them',
             'then','what','when','been','come','could','into','just','more','most','much','only','over',
             'such','take','very','also','back','been','body','class','here','html','css','div','span'}
keywords = sorted([w for w, c in freq.items() if c >= 2 and w not in stopwords])
phrases = sorted(set(re.findall(r'\b[A-Z][a-z]+ [A-Z][a-z]+\b', content)))

contract = {
    'source': file_path,
    'type': 'keyword-set',
    'exports': {
        'keywords': keywords[:50],
        'phrases': phrases[:20]
    }
}
json.dump(contract, sys.stdout, indent=2)
" 2>/dev/null
