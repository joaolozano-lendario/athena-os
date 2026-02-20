#!/usr/bin/env bash
# Test hook - logs when Write tool is used
echo "[HOOK-TEST] $(date +%H:%M:%S) Write detected: $CLAUDE_FILE_PATH" >> /tmp/formica-hook-test.log
