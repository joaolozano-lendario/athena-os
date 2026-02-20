#!/usr/bin/env python3
"""Stage 3: Parser accuracy test against existing test-lp files"""
import re
import os
import json

SKIP_SELECTORS = {
    'root', 'before', 'after', 'hover', 'focus', 'active', 'visited',
    'first-child', 'last-child', 'nth-child', 'not', 'js-enabled',
    'webkit', 'moz', 'ms'
}

def extract_html_classes(html_path):
    with open(html_path, encoding='utf-8') as f:
        content = f.read()
    classes = set()
    for match in re.finditer(r'class="([^"]*)"', content):
        for cls in match.group(1).split():
            if cls:
                classes.add(cls)
    return classes

def extract_css_selectors(css_path):
    with open(css_path, encoding='utf-8') as f:
        content = f.read()
    # Remove comments
    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
    selectors = set()
    for match in re.finditer(r'\.([a-zA-Z][a-zA-Z0-9_-]*)', content):
        sel = match.group(1)
        # Skip pseudo-classes and vendor prefixes
        skip = False
        for s in SKIP_SELECTORS:
            if sel == s or sel.startswith(s):
                skip = True
                break
        if not skip:
            selectors.add(sel)
    return selectors

# Known ground truth from manual grep
EXPECTED = {
    'blind': {'css_orphans': {'font-mono'}, 'html_orphans': set()},
    'contract': {'css_orphans': set(), 'html_orphans': set()},  # .json was false positive (in comment)
    'sequential': {'css_orphans': set(), 'html_orphans': set()},
}

print("=" * 60)
print("STAGE 3: PARSER ACCURACY TEST")
print("=" * 60)

all_pass = True
results = {}

for arm in ['blind', 'contract', 'sequential']:
    html_path = f'test-lp/{arm}/index.html'
    css_path = f'test-lp/{arm}/styles.css'

    html_classes = extract_html_classes(html_path)
    css_selectors = extract_css_selectors(css_path)

    css_orphans = css_selectors - html_classes
    html_orphans = html_classes - css_selectors

    total_unique = len(html_classes | css_selectors)
    matched = len(html_classes & css_selectors)
    score = (matched / total_unique * 100) if total_unique > 0 else 0

    expected_css = EXPECTED[arm]['css_orphans']
    expected_html = EXPECTED[arm]['html_orphans']

    css_match = css_orphans == expected_css
    html_match = html_orphans == expected_html

    status = "PASS" if (css_match and html_match) else "FAIL"
    if status == "FAIL":
        all_pass = False

    results[arm] = {
        'html_classes': len(html_classes),
        'css_selectors': len(css_selectors),
        'css_orphans': css_orphans,
        'html_orphans': html_orphans,
        'score': score,
        'status': status
    }

    print(f"\n--- {arm.upper()} ---")
    print(f"  HTML classes:    {len(html_classes)}")
    print(f"  CSS selectors:   {len(css_selectors)}")
    print(f"  CSS orphans:     {css_orphans or 'none'}")
    print(f"  HTML orphans:    {html_orphans or 'none'}")
    print(f"  Score:           {score:.1f}%")
    print(f"  Expected CSS:    {expected_css or 'none'}")
    print(f"  Expected HTML:   {expected_html or 'none'}")
    print(f"  Parser match:    {status}")
    if not css_match:
        print(f"    CSS diff: got {css_orphans}, expected {expected_css}")
    if not html_match:
        print(f"    HTML diff: got {html_orphans}, expected {expected_html}")

print(f"\n{'=' * 60}")
print(f"STAGE 3 VERDICT: {'PASS' if all_pass else 'FAIL'}")
if all_pass:
    print("Parser matches manual grep results on all 3 arms.")
else:
    print("Parser has discrepancies vs manual grep. Needs refinement.")
print(f"{'=' * 60}")
