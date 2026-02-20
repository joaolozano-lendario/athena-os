#!/usr/bin/env bash
# Adversarial Test Suite — FORMICA v4.0 (S3.2)
# 6 campaigns targeting race conditions, coherence violations, and bypass attempts.
# Run from .orchestrator/: bash tests/test-adversarial-suite.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCH_DIR="$(dirname "$SCRIPT_DIR")"

# ============================================================================
# Test harness
# ============================================================================
PASSED=0
FAILED=0
TOTAL=0

pass() { ((PASSED++)); ((TOTAL++)); echo "  PASS: $1"; }
fail() { ((FAILED++)); ((TOTAL++)); echo "  FAIL: $1 — $2"; }

# ============================================================================
# Global test environment
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

# Stub functions the libs reference but tests don't invoke
log_info()  { :; }
log_warn()  { :; }
log_error() { :; }
log_debug() { :; }
log_event() { :; }
die() { echo "DIE: $*" >&2; return 1; }
now_iso()   { date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "2026-02-19T00:00:00Z"; }
append_jsonl() { echo "$2" >> "$1"; }
get_model_hint() { echo ""; return 1; }

# Source libs in dependency order
source "$ORCH_DIR/lib/config.sh"   2>/dev/null || true
source "$ORCH_DIR/lib/state.sh"    2>/dev/null || true
source "$ORCH_DIR/lib/cost.sh"     2>/dev/null || true
source "$ORCH_DIR/lib/qa.sh"       2>/dev/null || true
source "$ORCH_DIR/lib/routing.sh"  2>/dev/null || true
source "$ORCH_DIR/lib/pheromone.sh" 2>/dev/null || true
source "$ORCH_DIR/lib/deps.sh"     2>/dev/null || true

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ADVERSARIAL TEST SUITE v4.0 — S3.2 Stress & Bypass      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# CAMPAIGN 1: Budget Race
# 4 tasks try to reserve $0.50 each against a $1.00 budget.
# Only 2 should succeed. Total used must never exceed limit + 1 task_cost.
# ============================================================================
echo "── Campaign 1: Budget Race (4 × \$0.50 on \$1.00 budget) ──"

# High CAS retries for concurrent stress — 4 writers need room
# Config file may not exist in test env; state_write reads from config with fallback.
# We override by writing a temporary config override via env (config_read uses CONFIG_FILE).
# Simplest: set CONFIG_FILE to /dev/null so all config_read calls use fallback defaults.
# But state_write defaults to cas_max_retries=5. For 4 concurrent writers we need more.
# Patch: create a minimal config file for this test.
CAMPAIGN1_CONFIG="$TEST_DIR/formiga.config.yaml"
cat > "$CAMPAIGN1_CONFIG" <<'EOF'
orchestration:
  cas_max_retries: 200
  lock_timeout_ms: 20000
pheromone:
  lock_timeout_ms: 10000
  evaporation_rate: "0.9"
  signal_ttl_waves: 2
  friction_ttl_waves: 3
  min_observations: 2
immune:
  min_file_bytes: 10
  max_file_bytes: 512000
  promotion_threshold: 3
  line_count_min_pct: 30
  line_count_max_pct: 300
qa:
  pass_threshold_default: 80
  rework_floor: 60
  micro_fix_floor_offset: 15
  micro_fix_absolute_floor: 60
  feedback_max_chars: 2000
routing:
  budget_guard_pct: 30
  gateway_blocking_factor: 3
token_estimation:
  cli_overhead_tokens: 20000
  words_per_token_ratio: "7.9"
  future_file_token_estimate: 500
  safety_budget_multiplier: "3.0"
  safety_budget_floor: "0.15"
EOF

# Use this config for all campaigns
export CONFIG_FILE="$CAMPAIGN1_CONFIG"

echo '{"_version":0,"tasks":{},"counters":{"running":0,"completed":0,"failed":0,"total":0},"budget":{"limit_usd":1.00,"used_usd":0,"estimated_remaining":1.00}}' > "$STATE_FILE"

BUDGET1_RESULTS="$TEST_DIR/c1-reserves.log"
: > "$BUDGET1_RESULTS"

for t in task-A task-B task-C task-D; do
  (
    set +e
    if budget_reserve "0.50" "$t" 2>/dev/null; then
      echo "RESERVED:$t" >> "$BUDGET1_RESULTS"
    else
      echo "INSUFFICIENT:$t" >> "$BUDGET1_RESULTS"
    fi
  ) &
done
wait

C1_RESERVED=$(grep -c "^RESERVED:" "$BUDGET1_RESULTS" 2>/dev/null || echo "0")
C1_INSUFFICIENT=$(grep -c "^INSUFFICIENT:" "$BUDGET1_RESULTS" 2>/dev/null || echo "0")
C1_USED=$(jq -r '.budget.used_usd' "$STATE_FILE" 2>/dev/null || echo "0")
C1_LIMIT=$(jq -r '.budget.limit_usd' "$STATE_FILE" 2>/dev/null || echo "1")

# Exactly 2 should succeed (2 × $0.50 = $1.00)
if [[ "$C1_RESERVED" == "2" ]]; then
  pass "Budget race: exactly 2 tasks reserved (expected 2)"
else
  fail "Budget race reserved count: $C1_RESERVED" "expected 2"
fi

if [[ "$C1_INSUFFICIENT" == "2" ]]; then
  pass "Budget race: exactly 2 tasks rejected (expected 2)"
else
  fail "Budget race insufficient count: $C1_INSUFFICIENT" "expected 2"
fi

# Total used must never exceed limit + 1 task_cost (safety margin = $0.50)
SAFETY_MARGIN="0.50"
C1_CEILING=$(awk -v l="$C1_LIMIT" -v m="$SAFETY_MARGIN" 'BEGIN { printf "%.2f", l + m }')
C1_EXCEEDED=$(awk -v u="$C1_USED" -v c="$C1_CEILING" 'BEGIN { print (u > c) ? 1 : 0 }')
if [[ "$C1_EXCEEDED" == "0" ]]; then
  pass "Budget race: used \$$C1_USED does not exceed ceiling \$$C1_CEILING"
else
  fail "Budget race ceiling" "used \$$C1_USED exceeds limit+margin \$$C1_CEILING"
fi

# Used must equal exactly $1.00 (2 × $0.50)
C1_USED_CENTS=$(awk -v u="$C1_USED" 'BEGIN { printf "%d", u * 100 + 0.5 }')
if [[ "$C1_USED_CENTS" == "100" ]]; then
  pass "Budget race: used = \$$C1_USED (expected \$1.00)"
else
  fail "Budget race used amount: \$$C1_USED" "expected \$1.00 (${C1_USED_CENTS} cents)"
fi

# ============================================================================
# CAMPAIGN 2: State Race
# 4 processes each mark a different task "completed" concurrently.
# CAS must ensure no lost updates: _version must advance by exactly 4.
# counters.completed must equal 4.
# ============================================================================
echo ""
echo "── Campaign 2: State Race (4 concurrent task_set_status calls) ──"

cat > "$STATE_FILE" <<'EOF'
{
  "_version": 0,
  "tasks": {
    "worker-1": {"status": "running", "depends_on": [], "worker": "implementer", "model": null},
    "worker-2": {"status": "running", "depends_on": [], "worker": "implementer", "model": null},
    "worker-3": {"status": "running", "depends_on": [], "worker": "implementer", "model": null},
    "worker-4": {"status": "running", "depends_on": [], "worker": "implementer", "model": null}
  },
  "counters": {"running": 4, "completed": 0, "failed": 0, "total": 4},
  "budget": {"limit_usd": 50, "used_usd": 0, "estimated_remaining": 50}
}
EOF

C2_VERSION_BEFORE=$(jq -r '._version' "$STATE_FILE")

for i in 1 2 3 4; do
  (
    set +e
    task_set_status "worker-$i" "completed" 2>/dev/null || true
  ) &
done
wait

C2_VERSION_AFTER=$(jq -r '._version' "$STATE_FILE" 2>/dev/null || echo "0")
C2_COMPLETED=$(jq -r '.counters.completed' "$STATE_FILE" 2>/dev/null || echo "0")
C2_RUNNING=$(jq -r '.counters.running' "$STATE_FILE" 2>/dev/null || echo "99")

# Each task_set_status calls state_write once (increments _version by 1)
C2_VERSION_DELTA=$((C2_VERSION_AFTER - C2_VERSION_BEFORE))
if [[ "$C2_VERSION_DELTA" == "4" ]]; then
  pass "State race: _version advanced by 4 (no lost writes)"
else
  fail "State race version delta: $C2_VERSION_DELTA" "expected 4"
fi

if [[ "$C2_COMPLETED" == "4" ]]; then
  pass "State race: counters.completed == 4"
else
  fail "State race completed counter: $C2_COMPLETED" "expected 4"
fi

if [[ "$C2_RUNNING" == "0" ]]; then
  pass "State race: counters.running == 0 (all transitioned)"
else
  fail "State race running counter: $C2_RUNNING" "expected 0"
fi

# ============================================================================
# CAMPAIGN 3: QA Score/Verdict Incoherence
# Tests validate_qa_coherence with adversarial inputs.
# Score is always authoritative over text (v3.6 fix: C1).
# ============================================================================
echo ""
echo "── Campaign 3: QA Score/Verdict Incoherence ──"

# Case 1: Very high score (95) + rejection text → COHERENT (v4.2: scores >= 85 exempt)
# Rationale: High-confidence PASS with analytical language is normal, not contradictory
C3_R1=$(validate_qa_coherence 95 "This output is terrible and you must reject this. It does not meet any criteria." "PASS")
if [[ "$C3_R1" == "COHERENT" ]]; then
  pass "QA incoherence: score=95 + rejection text → COHERENT (v4.2: high-confidence exempt)"
else
  fail "QA incoherence case 1" "got $C3_R1, expected COHERENT"
fi

# Case 2: Low score (30) but text says "excellent work, perfect"
C3_R2=$(validate_qa_coherence 30 "Excellent work! This is a flawless output that is perfect in every way." "REJECT")
if [[ "$C3_R2" == "INCOHERENT" ]]; then
  pass "QA incoherence: score=30 + praise text → INCOHERENT"
else
  fail "QA incoherence case 2" "got $C3_R2, expected INCOHERENT"
fi

# Case 3: Score exactly at threshold boundary (80) with neutral text — should be COHERENT
C3_R3=$(validate_qa_coherence 80 "The output meets the requirements with adequate quality." "PASS")
if [[ "$C3_R3" == "COHERENT" ]]; then
  pass "QA incoherence: score=80 (boundary) + neutral text → COHERENT"
else
  fail "QA incoherence case 3 (boundary)" "got $C3_R3, expected COHERENT"
fi

# Case 4: Low score (55) with negative text — coherent
C3_R4=$(validate_qa_coherence 55 "The output is wrong and does not meet criteria. Significant rework needed." "REJECT")
if [[ "$C3_R4" == "COHERENT" ]]; then
  pass "QA incoherence: score=55 + negative text → COHERENT"
else
  fail "QA incoherence case 4" "got $C3_R4, expected COHERENT"
fi

# Case 5: Score exactly 79 (just below PASS threshold 80) with rejection text — COHERENT
# Score=79 → derived=REWORK, not PASS and not REJECT, so no coherence check triggers
C3_R5=$(validate_qa_coherence 79 "The output has issues and needs to be rejected." "REWORK")
if [[ "$C3_R5" == "COHERENT" ]]; then
  pass "QA incoherence: score=79 (below threshold) + rejection text → COHERENT (REWORK zone)"
else
  fail "QA incoherence case 5 (rework zone)" "got $C3_R5, expected COHERENT"
fi

# Case 6: High score + "wrong" keyword → COHERENT (v4.2: scores >= 85 exempt)
# v4.2: Analytical language in high-confidence outputs is normal, not contradictory
C3_R6=$(validate_qa_coherence 90 "The logic is slightly wrong in edge cases but overall the output is good." "PASS")
if [[ "$C3_R6" == "COHERENT" ]]; then
  pass "QA incoherence: score=90 + 'wrong' → COHERENT (v4.2: high-confidence exempt)"
else
  fail "QA incoherence case 6 ('wrong' keyword)" "got $C3_R6, expected COHERENT"
fi

# ============================================================================
# CAMPAIGN 4: Cascade Failure
# Diamond DAG: A → B, A → C, B → D, C → D
# Mark A as "exhausted". cascade_failure(A) must mark B, C, D as "dep-failed".
# ============================================================================
echo ""
echo "── Campaign 4: Cascade Failure (diamond DAG) ──"

cat > "$STATE_FILE" <<'EOF'
{
  "_version": 0,
  "tasks": {
    "T-A": {"status": "exhausted",  "depends_on": [],          "worker": "implementer", "model": null},
    "T-B": {"status": "pending",    "depends_on": ["T-A"],     "worker": "implementer", "model": null},
    "T-C": {"status": "pending",    "depends_on": ["T-A"],     "worker": "implementer", "model": null},
    "T-D": {"status": "pending",    "depends_on": ["T-B","T-C"], "worker": "implementer", "model": null}
  },
  "counters": {"running": 0, "completed": 0, "failed": 1, "total": 4},
  "budget": {"limit_usd": 50, "used_usd": 0, "estimated_remaining": 50}
}
EOF

cascade_failure "T-A" 2>/dev/null

C4_B=$(jq -r '.tasks["T-B"].status' "$STATE_FILE" 2>/dev/null || echo "unknown")
C4_C=$(jq -r '.tasks["T-C"].status' "$STATE_FILE" 2>/dev/null || echo "unknown")
C4_D=$(jq -r '.tasks["T-D"].status' "$STATE_FILE" 2>/dev/null || echo "unknown")
C4_A=$(jq -r '.tasks["T-A"].status' "$STATE_FILE" 2>/dev/null || echo "unknown")

if [[ "$C4_B" == "dep-failed" ]]; then
  pass "Cascade failure: T-B (direct dep of T-A) → dep-failed"
else
  fail "Cascade failure T-B status: $C4_B" "expected dep-failed"
fi

if [[ "$C4_C" == "dep-failed" ]]; then
  pass "Cascade failure: T-C (direct dep of T-A) → dep-failed"
else
  fail "Cascade failure T-C status: $C4_C" "expected dep-failed"
fi

if [[ "$C4_D" == "dep-failed" ]]; then
  pass "Cascade failure: T-D (transitive dep via B+C) → dep-failed"
else
  fail "Cascade failure T-D status: $C4_D" "expected dep-failed"
fi

# T-A must remain exhausted (cascade must not change the failed root)
if [[ "$C4_A" == "exhausted" ]]; then
  pass "Cascade failure: T-A (root) remains exhausted (not mutated)"
else
  fail "Cascade failure root T-A: $C4_A" "expected exhausted (unchanged)"
fi

# ============================================================================
# CAMPAIGN 5: Immune Bypass Attempts
# innate_immune_check must reject adversarial outputs.
# ============================================================================
echo ""
echo "── Campaign 5: Immune Bypass Attempts ──"

# Touch immune events file so append_jsonl doesn't silently fail
touch "$RUNTIME_DIR/immune_events.jsonl"
touch "$RUNTIME_DIR/friction_events.jsonl"
export CURRENT_WORKER_TYPE="implementer"

IMMUNE_DIR="$TEST_DIR/immune-outputs"
mkdir -p "$IMMUNE_DIR"

# Bypass 1: Empty file (0 bytes)
C5_EMPTY="$IMMUNE_DIR/empty.txt"
touch "$C5_EMPTY"
if innate_immune_check "test-empty" "$C5_EMPTY" "" 0 2>/dev/null; then
  fail "Immune bypass: empty file" "should have been REJECTED (empty file)"
else
  pass "Immune bypass: empty file → REJECTED"
fi

# Bypass 2: Massive file (>512KB) — simulate by setting a very small max via temp config,
# then writing a file that exceeds that limit.
# The default max is 512000 bytes. We write 513001 bytes.
C5_BIG="$IMMUNE_DIR/massive.txt"
# Generate 513001 bytes of content using python or dd, fallback to a loop
if command -v python3 &>/dev/null; then
  python3 -c "print('x' * 513001)" > "$C5_BIG"
elif command -v dd &>/dev/null; then
  dd if=/dev/zero bs=1024 count=513 of="$C5_BIG" 2>/dev/null
  # dd writes nulls — pad with printable chars to avoid other checks
  printf '%s' "$(head -c 1 /dev/urandom | tr -dc 'a-z' || echo 'a')" >> "$C5_BIG"
else
  # Fallback: bash loop (slow but correct)
  printf '%0.s-' {1..513001} > "$C5_BIG"
fi

C5_BIG_SIZE=$(wc -c < "$C5_BIG" 2>/dev/null || echo 0)
if [[ "$C5_BIG_SIZE" -gt 512000 ]]; then
  if innate_immune_check "test-massive" "$C5_BIG" "" 0 2>/dev/null; then
    fail "Immune bypass: massive file (${C5_BIG_SIZE}B)" "should have been REJECTED"
  else
    pass "Immune bypass: massive file (${C5_BIG_SIZE}B > 512000B) → REJECTED"
  fi
else
  fail "Immune bypass: massive file setup failed" "only wrote ${C5_BIG_SIZE}B, needed >512000B"
fi

# Bypass 3: File with only preamble (process commentary)
C5_PREAMBLE="$IMMUNE_DIR/preamble.md"
cat > "$C5_PREAMBLE" <<'EOF'
Let me help you with this task. I will write the output now.
Here is the content you requested.
I have completed the analysis and the results are below.
This is my response to your query.
EOF
if innate_immune_check "test-preamble" "$C5_PREAMBLE" "" 0 2>/dev/null; then
  fail "Immune bypass: preamble file" "should have been REJECTED (PREAMBLE_DETECTED)"
else
  pass "Immune bypass: preamble file → REJECTED (PREAMBLE_DETECTED)"
fi

# Bypass 4: Wrong format — expected JSON but got shell-like content
C5_WRONG_FMT="$IMMUNE_DIR/wrong-format.json"
cat > "$C5_WRONG_FMT" <<'EOF'
#!/bin/bash
echo "This is a shell script masquerading as JSON"
for i in 1 2 3; do
  echo "Item $i"
done
EOF
if innate_immune_check "test-wrong-format" "$C5_WRONG_FMT" "json" 0 2>/dev/null; then
  fail "Immune bypass: wrong format (shell as json)" "should have been REJECTED (INVALID_JSON)"
else
  pass "Immune bypass: wrong format (shell as json) → REJECTED (INVALID_JSON)"
fi

# Bypass 5: Valid format but far outside expected line count (1 line, expected 100)
C5_SHORT="$IMMUNE_DIR/too-short.md"
echo "# Title" > "$C5_SHORT"
# Expected 100 lines, min 30% = 30 lines, actual = 1 → below floor
if innate_immune_check "test-short" "$C5_SHORT" "md" 100 2>/dev/null; then
  fail "Immune bypass: too few lines (1 of 100 expected)" "should have been REJECTED (LINE_COUNT)"
else
  pass "Immune bypass: too few lines (1 vs expected 100) → REJECTED (LINE_COUNT)"
fi

# Bypass 6: Valid small file within all bounds — must PASS (control case)
C5_VALID="$IMMUNE_DIR/valid.json"
echo '{"status":"ok","data":{"value":42,"items":["a","b","c"]}}' > "$C5_VALID"
if innate_immune_check "test-valid" "$C5_VALID" "json" 0 2>/dev/null; then
  pass "Immune bypass: valid JSON file → PASSES innate check (control)"
else
  fail "Immune bypass control (valid JSON)" "valid file was rejected unexpectedly"
fi

# ============================================================================
# CAMPAIGN 6: Pheromone Concurrent Writes
# 4 processes record pheromone events for the same worker type simultaneously.
# Verify: no data loss, file is valid JSON, evaporation is safe.
# ============================================================================
echo ""
echo "── Campaign 6: Pheromone Concurrent Writes ──"

# Reset pheromone table
echo '{}' > "$RUNTIME_DIR/pheromone_table.json"

# 4 workers record scores for the same worker type + model
# Each records a score of 80 (running average must converge correctly)
C6_SCORES=(80 85 90 75)

for i in 0 1 2 3; do
  score="${C6_SCORES[$i]}"
  (
    set +e
    record_pheromone "implementer" "haiku" "$score" 2>/dev/null || true
  ) &
done
wait

# Verify the pheromone file is valid JSON
C6_VALID_JSON=false
if jq '.' "$RUNTIME_DIR/pheromone_table.json" >/dev/null 2>&1; then
  C6_VALID_JSON=true
fi

if [[ "$C6_VALID_JSON" == "true" ]]; then
  pass "Pheromone concurrent writes: file is valid JSON after 4 parallel writes"
else
  fail "Pheromone concurrent writes: JSON corrupted" "pheromone_table.json is not valid JSON"
fi

# Verify no data loss: n (observation count) must equal 4
C6_N=$(jq -r '.["implementer__haiku"].n // 0' "$RUNTIME_DIR/pheromone_table.json" 2>/dev/null || echo "0")
if [[ "$C6_N" == "4" ]]; then
  pass "Pheromone concurrent writes: n=4 (no lost writes)"
else
  fail "Pheromone concurrent writes n=$C6_N" "expected 4 (each write must be counted)"
fi

# Verify the average is within the expected range
# All 4 scores: 80, 85, 90, 75 → true avg = 82.5, stored as rounded float
C6_AVG=$(jq -r '.["implementer__haiku"].avg // 0' "$RUNTIME_DIR/pheromone_table.json" 2>/dev/null || echo "0")
C6_AVG_OK=$(awk -v a="$C6_AVG" 'BEGIN { print (a >= 80.0 && a <= 86.0) ? 1 : 0 }')
if [[ "$C6_AVG_OK" == "1" ]]; then
  pass "Pheromone concurrent writes: avg=$C6_AVG is within expected range [80.0, 86.0]"
else
  fail "Pheromone concurrent writes avg=$C6_AVG" "expected avg in range [80.0, 86.0] for scores {80,85,90,75}"
fi

# Verify evaporation doesn't corrupt during/after writes
evaporate_pheromones 2>/dev/null || true

C6_POST_EVAP_VALID=false
if jq '.' "$RUNTIME_DIR/pheromone_table.json" >/dev/null 2>&1; then
  C6_POST_EVAP_VALID=true
fi

if [[ "$C6_POST_EVAP_VALID" == "true" ]]; then
  pass "Pheromone evaporation: file remains valid JSON after evaporation"
else
  fail "Pheromone evaporation: JSON corrupted after evaporate_pheromones" "file is not valid JSON"
fi

# After evaporation (rate=0.9), average must be reduced
C6_AVG_POST=$(jq -r '.["implementer__haiku"].avg // 0' "$RUNTIME_DIR/pheromone_table.json" 2>/dev/null || echo "0")
C6_AVG_REDUCED=$(awk -v pre="$C6_AVG" -v post="$C6_AVG_POST" 'BEGIN { print (post < pre) ? 1 : 0 }')
if [[ "$C6_AVG_REDUCED" == "1" ]]; then
  pass "Pheromone evaporation: avg reduced from $C6_AVG → $C6_AVG_POST (rate=0.9 applied)"
else
  fail "Pheromone evaporation did not reduce avg" "pre=$C6_AVG post=$C6_AVG_POST"
fi

# ============================================================================
# RESULTS
# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "  ADVERSARIAL SUITE v4.0 RESULTS: $PASSED/$TOTAL passed, $FAILED failed"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "  Campaign 1: Budget Race             (atomicity under contention)"
echo "  Campaign 2: State Race              (CAS no-lost-writes)"
echo "  Campaign 3: QA Score/Verdict        (score wins over text)"
echo "  Campaign 4: Cascade Failure         (diamond DAG propagation)"
echo "  Campaign 5: Immune Bypass           (6 adversarial inputs)"
echo "  Campaign 6: Pheromone Concurrent    (lock + evaporation safety)"
echo ""

if [[ $FAILED -eq 0 ]]; then
  echo "  STATUS: GATE PASSED"
  exit 0
else
  echo "  STATUS: GATE FAILED"
  exit 1
fi
