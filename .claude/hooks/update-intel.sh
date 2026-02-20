#!/bin/bash
# ATHENA OS 3.0 - Codebase Intelligence Updater
# Called by PostToolUse hook after Edit|Write operations
#
# Usage: update-intel.sh <file_path>

FILE_PATH="$1"
PLANNING_DIR="${PLANNING_DIR:-.planning}"
INTEL_DIR="$PLANNING_DIR/intel"
LOG_FILE="$INTEL_DIR/updates.log"

# Ensure intel directory exists
mkdir -p "$INTEL_DIR"

# Skip if no file path provided
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Skip if file is in .planning or .claude (meta files)
if [[ "$FILE_PATH" == *".planning"* || "$FILE_PATH" == *".claude"* ]]; then
    exit 0
fi

# Log the update
TIMESTAMP=$(date -Iseconds 2>/dev/null || date)
echo "$TIMESTAMP | UPDATED | $FILE_PATH" >> "$LOG_FILE"

# Get file extension
EXT="${FILE_PATH##*.}"

# Track file types
case "$EXT" in
    ts|tsx|js|jsx)
        echo "$TIMESTAMP | TYPE | javascript/typescript | $FILE_PATH" >> "$LOG_FILE"
        ;;
    py)
        echo "$TIMESTAMP | TYPE | python | $FILE_PATH" >> "$LOG_FILE"
        ;;
    md)
        echo "$TIMESTAMP | TYPE | markdown | $FILE_PATH" >> "$LOG_FILE"
        ;;
    yaml|yml)
        echo "$TIMESTAMP | TYPE | yaml | $FILE_PATH" >> "$LOG_FILE"
        ;;
    json)
        echo "$TIMESTAMP | TYPE | json | $FILE_PATH" >> "$LOG_FILE"
        ;;
esac

# Future enhancements:
# - Parse file for exports/imports
# - Update index.json
# - Detect naming conventions
# - Build dependency graph

exit 0
