#!/bin/bash
# ATHENA OS 3.0 - Ralph Loop Stop Handler
# This hook implements the dual-gate completion check
#
# Called by Claude Code's Stop hook when execution tries to exit
# Returns 0 to allow exit, 1 to block exit and continue iteration

PLANNING_DIR="${PLANNING_DIR:-.planning}"
CURRENT_OUTPUT="$PLANNING_DIR/current-output.txt"
CURRENT_DONE="$PLANNING_DIR/current-task-done.txt"

# Initialize indicator count
INDICATORS=0

# Check for completion indicators in output
if [ -f "$CURRENT_OUTPUT" ]; then
    # Pattern matching for completion signals
    grep -qi "tests pass" "$CURRENT_OUTPUT" && ((INDICATORS++))
    grep -qi "testes passando" "$CURRENT_OUTPUT" && ((INDICATORS++))
    grep -qi "implementation complete" "$CURRENT_OUTPUT" && ((INDICATORS++))
    grep -qi "implementação completa" "$CURRENT_OUTPUT" && ((INDICATORS++))
    grep -qi "no errors" "$CURRENT_OUTPUT" && ((INDICATORS++))
    grep -qi "sem erros" "$CURRENT_OUTPUT" && ((INDICATORS++))
    grep -qi "successfully" "$CURRENT_OUTPUT" && ((INDICATORS++))
    grep -qi "build succeeded" "$CURRENT_OUTPUT" && ((INDICATORS++))
    grep -qi "all criteria met" "$CURRENT_OUTPUT" && ((INDICATORS++))
fi

# Check for explicit EXIT_SIGNAL
EXIT_SIGNAL=0
if [ -f "$CURRENT_OUTPUT" ]; then
    EXIT_SIGNAL=$(grep -c "EXIT_SIGNAL: true" "$CURRENT_OUTPUT" 2>/dev/null || echo "0")
fi

# Check task-specific done flag
TASK_DONE="false"
if [ -f "$CURRENT_DONE" ]; then
    TASK_DONE=$(cat "$CURRENT_DONE" 2>/dev/null || echo "false")
fi

# Log the check
echo "[$(date -Iseconds)] ATHENA Stop Handler Check:"
echo "  - Completion Indicators: $INDICATORS"
echo "  - EXIT_SIGNAL present: $EXIT_SIGNAL"
echo "  - Task marked done: $TASK_DONE"

# Dual-gate check
# EXIT requires: indicators >= 2 AND EXIT_SIGNAL present
if [[ "$INDICATORS" -ge 2 && "$EXIT_SIGNAL" -ge 1 ]]; then
    echo "  → RESULT: EXIT ALLOWED (dual-gate passed)"
    exit 0  # Allow exit
elif [[ "$TASK_DONE" == "true" && "$EXIT_SIGNAL" -ge 1 ]]; then
    echo "  → RESULT: EXIT ALLOWED (task done + signal)"
    exit 0  # Allow exit
else
    echo "  → RESULT: CONTINUE ITERATION (gate not passed)"
    exit 1  # Block exit, continue iteration
fi
