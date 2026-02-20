#!/usr/bin/env bash
# Stop gate: verify worker produced output before considering task complete
# Called by orchestrate.sh after worker exits

output_file="$1"
task_id="$2"

if [[ ! -f "$output_file" ]]; then
  echo "[STOP-GATE] FAIL: Worker for $task_id produced no output file at $output_file" >&2
  exit 1
fi

if [[ ! -s "$output_file" ]]; then
  echo "[STOP-GATE] FAIL: Worker for $task_id produced empty output at $output_file" >&2
  exit 1
fi

echo "[STOP-GATE] PASS: Output exists ($(wc -c < "$output_file") bytes)" >&2
exit 0
