#!/usr/bin/env bash
# Sprint Gate v3.8 — Verification tests for E1 Critical Fixes
# Tests: CAS stress, budget atomicity, QA coherence, model routing
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCH_DIR="$(dirname "$SCRIPT_DIR")"

# Minimal test harness
PASSED=0
FAILED=0
TOTAL=0

pass() { ((PASSED++)); ((TOTAL++)); echo "  PASS: $1"; }
fail() { ((FAILED++)); ((TOTAL++)); echo "  FAIL: $1 — $2"; }

# ============================================================================
# Setup: Source libraries with minimal scaffolding
# ============================================================================
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

export STATE_FILE="$TEST_DIR/state.json"
export RUNTIME_DIR="$TEST_DIR/runtime"
export EVENTS_FILE="$TEST_DIR/events.jsonl"
export COST_FILE="$TEST_DIR/costs.jsonl"
export ORCHESTRATOR_DIR="$ORCH_DIR"
export MANIFEST="$TEST_DIR/manifest.yaml"
export LOCKS_DIR="$TEST_DIR/locks"
export MEMORY_DIR="$TEST_DIR/memory"
export DEFAULT_MODEL="haiku"

mkdir -p "$RUNTIME_DIR" "$LOCKS_DIR" "$MEMORY_DIR"
touch "$EVENTS_FILE" "$COST_FILE"

# Stub functions that tests don't need
log_info()  { :; }
log_warn()  { :; }
log_error() { :; }
log_debug() { :; }
log_event() { :; }
die() { echo "DIE: $*" >&2; return 1; }
now_iso()   { date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "2026-02-19T00:00:00Z"; }
append_jsonl() { echo "$2" >> "$1"; }
get_model_hint() { echo ""; return 1; }

# Source config first (v4.0: all libs depend on config_read)
export CONFIG_FILE="$ORCH_DIR/formiga.config.yaml"
source "$ORCH_DIR/lib/config.sh" 2>/dev/null || true

# Source only the libs we need
source "$ORCH_DIR/lib/state.sh" 2>/dev/null || true
source "$ORCH_DIR/lib/cost.sh" 2>/dev/null || true
source "$ORCH_DIR/lib/qa.sh" 2>/dev/null || true
source "$ORCH_DIR/lib/routing.sh" 2>/dev/null || true

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  SPRINT GATE v3.8 — E1 Critical Fixes Verification       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# T1: CAS STRESS TEST — 4 writers × 100 increments = version 400
# ============================================================================
echo "── T1: CAS Stress Test (4×100 writers) ──"

# Create initial state
echo '{"_version":0,"counter":0,"tasks":{},"counters":{"running":0,"completed":0,"failed":0,"total":0},"budget":{"limit_usd":50,"used_usd":0,"estimated_remaining":50}}' > "$STATE_FILE"

# Launch 4 writers, each doing 100 increments
for w in 1 2 3 4; do
  (
    for i in $(seq 1 100); do
      state_write '.counter += 1' 2>/dev/null || true
    done
  ) &
done
wait

FINAL_VERSION=$(jq -r '._version' "$STATE_FILE" 2>/dev/null)
FINAL_COUNTER=$(jq -r '.counter' "$STATE_FILE" 2>/dev/null)

if [[ "$FINAL_VERSION" == "400" ]]; then
  pass "Version counter: $FINAL_VERSION (expected 400)"
else
  fail "Version counter: $FINAL_VERSION" "expected 400"
fi

if [[ "$FINAL_COUNTER" == "400" ]]; then
  pass "Counter value: $FINAL_COUNTER (expected 400)"
else
  fail "Counter value: $FINAL_COUNTER" "expected 400"
fi

# ============================================================================
# T2: BUDGET RESERVE ATOMICITY — 4 parallel reserves on limited budget
# ============================================================================
echo ""
echo "── T2: Budget Reserve Atomicity ──"

# Reset state with $1.00 budget
echo '{"_version":0,"tasks":{},"counters":{"running":0,"completed":0,"failed":0,"total":0},"budget":{"limit_usd":1.00,"used_usd":0,"estimated_remaining":1.00}}' > "$STATE_FILE"

# 4 tasks each trying to reserve $0.30 (only 3 should succeed)
RESERVE_RESULTS="$TEST_DIR/reserves.log"
: > "$RESERVE_RESULTS"

for t in task-A task-B task-C task-D; do
  (
    if budget_reserve "0.30" "$t" 2>/dev/null; then
      echo "RESERVED:$t" >> "$RESERVE_RESULTS"
    else
      echo "INSUFFICIENT:$t" >> "$RESERVE_RESULTS"
    fi
  ) &
done
wait

RESERVED_COUNT=$(grep -c "^RESERVED:" "$RESERVE_RESULTS" 2>/dev/null || echo "0")
INSUFFICIENT_COUNT=$(grep -c "^INSUFFICIENT:" "$RESERVE_RESULTS" 2>/dev/null || echo "0")
FINAL_USED=$(jq -r '.budget.used_usd' "$STATE_FILE" 2>/dev/null)

if [[ "$RESERVED_COUNT" == "3" ]]; then
  pass "Reserved count: $RESERVED_COUNT (expected 3 of 4)"
else
  fail "Reserved count: $RESERVED_COUNT" "expected exactly 3"
fi

if [[ "$INSUFFICIENT_COUNT" == "1" ]]; then
  pass "Insufficient count: $INSUFFICIENT_COUNT (expected 1)"
else
  fail "Insufficient count: $INSUFFICIENT_COUNT" "expected 1"
fi

# Budget used should be ~0.90 (3 × 0.30) — allow FP precision tolerance
USED_CENTS=$(awk -v u="$FINAL_USED" 'BEGIN { printf "%d", u * 100 + 0.5 }')
if [[ "$USED_CENTS" -ge 89 && "$USED_CENTS" -le 91 ]]; then
  pass "Budget used: \$$FINAL_USED ≈ \$0.90 (${USED_CENTS} cents)"
else
  fail "Budget used: \$$FINAL_USED" "expected ~\$0.90 (got ${USED_CENTS} cents)"
fi

# Budget should not exceed limit
LIMIT=$(jq -r '.budget.limit_usd' "$STATE_FILE" 2>/dev/null)
if (( $(echo "$FINAL_USED <= $LIMIT" | bc -l 2>/dev/null || echo 1) )); then
  pass "Budget not exceeded: \$$FINAL_USED <= \$$LIMIT"
else
  fail "Budget exceeded" "\$$FINAL_USED > \$$LIMIT"
fi

# ============================================================================
# T3: BUDGET RECONCILE — estimated vs actual adjustment
# ============================================================================
echo ""
echo "── T3: Budget Reconcile ──"

# Reserve $0.30 for task-X, then reconcile with actual $0.15
echo '{"_version":0,"tasks":{},"counters":{"running":0,"completed":0,"failed":0,"total":0},"budget":{"limit_usd":1.00,"used_usd":0,"estimated_remaining":1.00}}' > "$STATE_FILE"

budget_reserve "0.30" "task-X" 2>/dev/null
USED_AFTER_RESERVE=$(jq -r '.budget.used_usd' "$STATE_FILE")

budget_reconcile "task-X" "0.15" 2>/dev/null
USED_AFTER_RECONCILE=$(jq -r '.budget.used_usd' "$STATE_FILE")
REMAINING=$(jq -r '.budget.estimated_remaining' "$STATE_FILE")
HAS_RESERVATION=$(jq -r '.budget.reservations["task-X"] // "none"' "$STATE_FILE")

RECONCILED_CENTS=$(awk -v u="$USED_AFTER_RECONCILE" 'BEGIN { printf "%d", u * 100 }')
if [[ "$RECONCILED_CENTS" == "15" ]]; then
  pass "Reconciled budget: \$$USED_AFTER_RECONCILE (expected \$0.15)"
else
  fail "Reconciled budget: \$$USED_AFTER_RECONCILE" "expected \$0.15"
fi

if [[ "$HAS_RESERVATION" == "none" || "$HAS_RESERVATION" == "null" ]]; then
  pass "Reservation cleaned up after reconcile"
else
  fail "Reservation still exists" "value=$HAS_RESERVATION"
fi

# ============================================================================
# T4: QA COHERENCE — detect score/text mismatches
# ============================================================================
echo ""
echo "── T4: QA Coherence Validation ──"

# Case 1: Moderate-high score (80-84) + rejection text → INCOHERENT
# v4.2: scores >= 85 skip rejection check (analytical language exemption)
R1=$(validate_qa_coherence 82 "This is unacceptable and must be rejected. The output does not meet criteria." "PASS")
if [[ "$R1" == "INCOHERENT" ]]; then
  pass "Moderate score (82) + rejection text → INCOHERENT"
else
  fail "Moderate score + rejection text" "got $R1, expected INCOHERENT"
fi

# Case 2: Low score + praise text → INCOHERENT
R2=$(validate_qa_coherence 45 "Excellent work! This is a flawless implementation that passes all criteria." "REJECT")
if [[ "$R2" == "INCOHERENT" ]]; then
  pass "Low score + praise text → INCOHERENT"
else
  fail "Low score + praise text" "got $R2, expected INCOHERENT"
fi

# Case 3: High score + positive text → COHERENT
R3=$(validate_qa_coherence 90 "Good implementation that meets the requirements. Minor suggestions for improvement." "PASS")
if [[ "$R3" == "COHERENT" ]]; then
  pass "High score + positive text → COHERENT"
else
  fail "High score + positive text" "got $R3, expected COHERENT"
fi

# Case 4: Low score + negative text → COHERENT
R4=$(validate_qa_coherence 50 "The output is wrong and needs significant rework. Multiple issues found." "REJECT")
if [[ "$R4" == "COHERENT" ]]; then
  pass "Low score + negative text → COHERENT"
else
  fail "Low score + negative text" "got $R4, expected COHERENT"
fi

# ============================================================================
# T5: MODEL ROUTING — budget guard before override
# ============================================================================
echo ""
echo "── T5: Model Routing — Budget Guard Priority ──"

# Low budget → always haiku, even with per-task override
# v4.2: budget_guard_pct changed from 30 to 15; use 10% for test
M1=$(select_model "implementer" 0 10 "sonnet" 0)
if [[ "$M1" == "haiku" ]]; then
  pass "Budget<15% overrides per-task sonnet → haiku"
else
  fail "Budget<15% + override=sonnet" "got $M1, expected haiku"
fi

# Low budget but gateway (blocking_factor≥3) → keeps sonnet
M2=$(select_model "architect" 0 10 "sonnet" 3)
if [[ "$M2" == "sonnet" ]]; then
  pass "Budget<15% + gateway(blocks=3) → sonnet (protected)"
else
  fail "Budget<15% + gateway" "got $M2, expected sonnet"
fi

# Normal budget + per-task override → respects override
M3=$(select_model "implementer" 0 80 "opus" 0)
if [[ "$M3" == "opus" ]]; then
  pass "Budget OK + override=opus → opus"
else
  fail "Budget OK + override=opus" "got $M3, expected opus"
fi

# Unknown model override → fallback to default
M4=$(select_model "implementer" 0 80 "gpt-4" 0)
if [[ "$M4" == "$DEFAULT_MODEL" ]]; then
  pass "Unknown model override → default ($DEFAULT_MODEL)"
else
  fail "Unknown model override" "got $M4, expected $DEFAULT_MODEL"
fi

# Retry escalation
M5=$(select_model "implementer" 1 80 "" 0)
if [[ "$M5" == "sonnet" ]]; then
  pass "Retry=1 + default=haiku → sonnet (escalation)"
else
  fail "Retry escalation" "got $M5, expected sonnet"
fi

# ============================================================================
# T6: state_write_and_read — atomic write + extract
# ============================================================================
echo ""
echo "── T6: state_write_and_read Atomicity ──"

echo '{"_version":0,"tasks":{},"counters":{"running":0,"completed":0,"failed":0,"total":0},"budget":{"limit_usd":5,"used_usd":0,"estimated_remaining":5}}' > "$STATE_FILE"

RESULT=$(state_write_and_read '.budget.used_usd += 1.50 | .budget.estimated_remaining = (.budget.limit_usd - .budget.used_usd)' '.budget.estimated_remaining')
if [[ "$RESULT" == "3.5" ]]; then
  pass "state_write_and_read: returned 3.5 (5 - 1.5)"
else
  fail "state_write_and_read" "got '$RESULT', expected '3.5'"
fi

VERSION_AFTER=$(jq -r '._version' "$STATE_FILE")
if [[ "$VERSION_AFTER" == "1" ]]; then
  pass "Version incremented to 1 after write_and_read"
else
  fail "Version after write_and_read" "got $VERSION_AFTER, expected 1"
fi

# ============================================================================
# T7: get_ready_tasks — atomic single-query
# ============================================================================
echo ""
echo "── T7: get_ready_tasks Atomic Query ──"

cat > "$STATE_FILE" <<'EOF'
{
  "_version": 5,
  "tasks": {
    "T-1": {"status":"completed","depends_on":[]},
    "T-2": {"status":"pending","depends_on":["T-1"]},
    "T-3": {"status":"pending","depends_on":["T-1","T-2"]},
    "T-4": {"status":"running","depends_on":[]},
    "T-5": {"status":"pending","depends_on":[]}
  },
  "counters":{"running":1,"completed":1,"failed":0,"total":5}
}
EOF

READY=$(get_ready_tasks 2>/dev/null | sort | tr '\n' ' ' | xargs)
# T-2 ready (dep T-1 completed), T-5 ready (no deps)
# T-3 NOT ready (T-2 not completed), T-4 running
if [[ "$READY" == "T-2 T-5" ]]; then
  pass "get_ready_tasks: T-2 T-5 (correct)"
else
  fail "get_ready_tasks" "got '$READY', expected 'T-2 T-5'"
fi

# ============================================================================
# RESULTS
# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "  SPRINT GATE v3.8 RESULTS: $PASSED/$TOTAL passed, $FAILED failed"
echo "════════════════════════════════════════════════════════════"

if [[ $FAILED -eq 0 ]]; then
  echo "  STATUS: ✓ GATE PASSED"
  exit 0
else
  echo "  STATUS: ✗ GATE FAILED"
  exit 1
fi
