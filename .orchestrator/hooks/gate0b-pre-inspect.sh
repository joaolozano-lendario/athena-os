#!/usr/bin/env bash
# Gate 0B — PreToolUse inspector
# Logs ALL environment variables and stdin to understand what data is available
env | sort > /tmp/gate0b-env.log
echo "---STDIN---" >> /tmp/gate0b-env.log
cat >> /tmp/gate0b-env.log
# Allow the write
exit 0
