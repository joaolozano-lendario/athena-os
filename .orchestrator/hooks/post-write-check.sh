#!/usr/bin/env bash
# Post-write check: validate output format
# Called after worker completes and output is captured

output_file="$1"
expected_format="${2:-any}"  # yaml, json, markdown, any

case "$expected_format" in
  yaml)
    yq '.' "$output_file" > /dev/null 2>&1 || { echo "[FORMAT-CHECK] FAIL: Invalid YAML" >&2; exit 1; }
    ;;
  json)
    jq '.' "$output_file" > /dev/null 2>&1 || { echo "[FORMAT-CHECK] FAIL: Invalid JSON" >&2; exit 1; }
    ;;
  markdown)
    # Basic check: file starts with # or ---
    head -1 "$output_file" | grep -qE '^(#|---)' || { echo "[FORMAT-CHECK] WARN: May not be valid Markdown" >&2; }
    ;;
  any)
    # No format validation
    ;;
esac

echo "[FORMAT-CHECK] PASS: $expected_format format OK" >&2
exit 0
