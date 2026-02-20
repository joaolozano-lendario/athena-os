#!/usr/bin/env bash
# test-config-defaults.sh — Backward compatibility test for formiga.config.yaml
#
# Verifies that removing formiga.config.yaml produces identical defaults to v3.9.
# Every key in formiga.config.yaml is tested against its expected hardcoded default.
#
# Usage (from .orchestrator directory):
#   bash tests/test-config-defaults.sh
#
# Exit code: 0 = all PASS, 1 = one or more FAIL

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve ORCHESTRATOR_DIR to the parent of this tests/ directory
# so the script works regardless of cwd.
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCHESTRATOR_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export ORCHESTRATOR_DIR

# Source order matters: config.sh must load before utils.sh because
# utils.sh calls config_read inside append_jsonl.
# shellcheck source=/dev/null
source "${ORCHESTRATOR_DIR}/lib/config.sh"
# shellcheck source=/dev/null
source "${ORCHESTRATOR_DIR}/lib/utils.sh"

# ---------------------------------------------------------------------------
# Setup: rename config file so config_read always falls back to defaults
# ---------------------------------------------------------------------------
CONFIG_PATH="${ORCHESTRATOR_DIR}/formiga.config.yaml"
CONFIG_BACKUP="${ORCHESTRATOR_DIR}/formiga.config.yaml.bak_test_$$"

_restore_config() {
  if [[ -f "$CONFIG_BACKUP" ]]; then
    mv "$CONFIG_BACKUP" "$CONFIG_PATH" 2>/dev/null || true
  fi
}
trap _restore_config EXIT INT TERM

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "[ERROR] formiga.config.yaml not found at: $CONFIG_PATH"
  echo "        This test requires the file to exist so it can be temporarily hidden."
  exit 1
fi

mv "$CONFIG_PATH" "$CONFIG_BACKUP"

# ---------------------------------------------------------------------------
# Test harness
# ---------------------------------------------------------------------------
PASS=0
FAIL=0
FAILURES=()

assert_default() {
  local key="$1"
  local expected="$2"
  local actual
  actual=$(config_read "$key" "$expected")

  if [[ "$actual" == "$expected" ]]; then
    PASS=$(( PASS + 1 ))
  else
    FAIL=$(( FAIL + 1 ))
    FAILURES+=("  FAIL  $key  expected='$expected'  got='$actual'")
  fi
}

# ---------------------------------------------------------------------------
# All keys from formiga.config.yaml with their v3.9 default values
# ---------------------------------------------------------------------------

# orchestration
assert_default "orchestration.task_timeout_s"             "600"
assert_default "orchestration.lock_timeout_ms"            "20000"
assert_default "orchestration.cas_max_retries"            "5"
assert_default "orchestration.kill_timeout_s"             "2"
assert_default "orchestration.stagger_sleep_s"            "2"
assert_default "orchestration.poll_interval_s"            "2"
assert_default "orchestration.wall_clock_timeout_s"       "3600"
assert_default "orchestration.jsonl_lock_retries"         "20"
assert_default "orchestration.lock_stale_age_s"           "60"
assert_default "orchestration.retry_backoff_multiplier_s" "3"
assert_default "orchestration.default_task_budget_usd"    "0.50"
assert_default "orchestration.default_max_budget_usd"     "50"

# allometry
assert_default "allometry.small_threshold"            "8"
assert_default "allometry.medium_threshold"           "25"
assert_default "allometry.token_budget_base"          "60000"
assert_default "allometry.token_budget_exponent"      "0.75"
assert_default "allometry.token_budget_floor"         "3000"
assert_default "allometry.signal_injection_max_small" "2"
assert_default "allometry.signal_injection_max_medium" "4"
assert_default "allometry.signal_injection_max_large" "6"

# routing
assert_default "routing.budget_guard_pct"              "30"
assert_default "routing.gateway_blocking_factor"       "3"
assert_default "routing.pheromone_sonnet_threshold"    "0.60"
assert_default "routing.pheromone_prob_min"            "0.10"
assert_default "routing.pheromone_prob_max"            "0.90"
assert_default "routing.pheromone_hard_severity"       "4"
assert_default "routing.blacklist_ttl_days"            "90"
assert_default "routing.friction_upgrade_threshold"    "2"
assert_default "routing.gateway_budget_multiplier"     "1.5"
assert_default "routing.budget_kill_detection_pct"     "0.90"
assert_default "routing.budget_kill_scale_factor"      "1.5"
assert_default "routing.micro_fix_budget_fraction"     "0.30"

# pheromone
assert_default "pheromone.evaporation_rate"   "0.90"
assert_default "pheromone.signal_ttl_waves"   "2"
assert_default "pheromone.friction_ttl_waves" "3"
assert_default "pheromone.lock_timeout_ms"    "5000"
assert_default "pheromone.min_observations"   "2"

# quorum
assert_default "quorum.done_threshold"          "0.90"
assert_default "quorum.retry_threshold"         "0.70"
assert_default "quorum.reexecute_threshold"     "0.40"
assert_default "quorum.disagreement_threshold"  "0.40"
assert_default "quorum.budget_escalate_pct"     "20"
assert_default "quorum.sigmoid_steepness"       "12"
assert_default "quorum.sigmoid_midpoint"        "0.75"
assert_default "quorum.weight_qa"               "0.40"
assert_default "quorum.weight_advisory"         "0.25"
assert_default "quorum.weight_colony"           "0.15"
assert_default "quorum.weight_structural"       "0.20"
assert_default "quorum.weight_qa_noadv"         "0.50"
assert_default "quorum.weight_colony_noadv"     "0.20"
assert_default "quorum.weight_structural_noadv" "0.30"
assert_default "quorum.demand_signal_threshold" "3"
assert_default "quorum.demand_group_min"        "2"

# immune
assert_default "immune.promotion_threshold"    "3"
assert_default "immune.min_file_bytes"         "10"
assert_default "immune.max_file_bytes"         "512000"
assert_default "immune.line_count_min_pct"     "30"
assert_default "immune.line_count_max_pct"     "300"
assert_default "immune.qa_crash_fallback_score" "70"
assert_default "immune.inferred_lines_short"   "50"
assert_default "immune.inferred_lines_long"    "200"

# token_estimation
assert_default "token_estimation.code_chars_per_token"       "2.0"
assert_default "token_estimation.prose_chars_per_token"      "5.0"
assert_default "token_estimation.config_chars_per_token"     "3.0"
assert_default "token_estimation.mixed_chars_per_token"      "4.0"
assert_default "token_estimation.truncation_safety_margin"   "500"
assert_default "token_estimation.truncation_min_remaining"   "200"
assert_default "token_estimation.truncation_char_multiplier" "4"
assert_default "token_estimation.cli_overhead_tokens"        "20000"
assert_default "token_estimation.words_per_token_ratio"      "7.9"
assert_default "token_estimation.future_file_token_estimate" "500"
assert_default "token_estimation.safety_budget_multiplier"   "3.0"
assert_default "token_estimation.safety_budget_floor"        "0.15"

# advisory
assert_default "advisory.max_budget_usd"               "0.30"
assert_default "advisory.coherence_pause"              "5"
assert_default "advisory.coherence_cancel"             "3"
assert_default "advisory.min_wave"                     "2"
assert_default "advisory.pass_rate_floor"              "50"
assert_default "advisory.adjustment_threshold"         "7"
assert_default "advisory.qa_threshold_step"            "5"
assert_default "advisory.qa_threshold_cap"             "95"
assert_default "advisory.context_recent_qa_count"      "5"
assert_default "advisory.context_recent_friction_count" "10"
assert_default "advisory.context_output_preview_lines" "30"

# qa
assert_default "qa.default_budget_usd"        "0.20"
assert_default "qa.budget_fraction"           "0.50"
assert_default "qa.min_budget_usd"            "0.15"
assert_default "qa.micro_fix_floor_offset"    "15"
assert_default "qa.micro_fix_absolute_floor"  "60"
assert_default "qa.rework_floor"              "60"
assert_default "qa.pass_threshold_default"    "80"
assert_default "qa.rework_threshold_default"  "60"
assert_default "qa.feedback_max_chars"        "2000"

# meta_supervisor
assert_default "meta_supervisor.critical_pass_rate_pct"      "30"
assert_default "meta_supervisor.critical_min_samples"        "6"
assert_default "meta_supervisor.critical_cost_velocity"      "1.5"
assert_default "meta_supervisor.repeated_friction_threshold" "3"
assert_default "meta_supervisor.budget_conserve_pct"         "20"

# friction
assert_default "friction.trend_min_events"           "10"
assert_default "friction.trend_window_size"           "5"
assert_default "friction.trend_delta_threshold"       "0.05"
assert_default "friction.consecutive_cause_threshold" "3"
assert_default "friction.consecutive_scan_window"     "15"
assert_default "friction.max_worker_patterns"         "5"

# epigenetics
assert_default "epigenetics.multiplier_min"               "0.50"
assert_default "epigenetics.multiplier_max"               "3.00"
assert_default "epigenetics.min_blueprints_for_evidence"  "2"
assert_default "epigenetics.budget_exhaustion_min_count"  "2"
assert_default "epigenetics.budget_multiplier_step"       "0.20"
assert_default "epigenetics.pattern_prune_threshold"      "0.30"
assert_default "epigenetics.pattern_decay_rate"           "0.95"
assert_default "epigenetics.max_patterns_inject"          "5"

# colony
assert_default "colony.signal_intensity_floor" "0.40"
assert_default "colony.convention_max_lines"   "15"
assert_default "colony.genius_kit_max_lines"   "50"

# pricing
assert_default "pricing.haiku_input_per_1m"         "0.80"
assert_default "pricing.haiku_output_per_1m"         "4.00"
assert_default "pricing.sonnet_input_per_1m"         "3.00"
assert_default "pricing.sonnet_output_per_1m"        "15.00"
assert_default "pricing.opus_input_per_1m"           "15.00"
assert_default "pricing.opus_output_per_1m"          "75.00"
assert_default "pricing.cache_hit_factor"            "0.15"
assert_default "pricing.qa_overhead_fraction"        "0.30"
assert_default "pricing.advisory_cost_per_wave"      "0.03"
assert_default "pricing.expected_cost_multiplier"    "1.30"
assert_default "pricing.tasks_per_wave_estimate"     "5"

# modes (three-level nested keys)
assert_default "modes.economic.max_parallel" "1"
assert_default "modes.economic.qa_threshold" "70"
assert_default "modes.economic.max_retries"  "1"
assert_default "modes.economic.budget_factor" "0.70"

assert_default "modes.quality.max_parallel" "2"
assert_default "modes.quality.qa_threshold" "85"
assert_default "modes.quality.max_retries"  "3"
assert_default "modes.quality.budget_factor" "1.50"

assert_default "modes.speed.max_parallel" "4"
assert_default "modes.speed.qa_threshold" "75"
assert_default "modes.speed.max_retries"  "2"
assert_default "modes.speed.budget_factor" "1.00"

assert_default "modes.guided.max_parallel" "2"
assert_default "modes.guided.qa_threshold" "80"
assert_default "modes.guided.max_retries"  "3"
assert_default "modes.guided.budget_factor" "1.20"

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
TOTAL=$(( PASS + FAIL ))

echo ""
echo "============================================================"
echo "  Config Defaults Backward Compatibility Test"
echo "  formiga.config.yaml → v3.9 defaults"
echo "============================================================"
echo "  Total keys tested : $TOTAL"
echo "  PASS              : $PASS"
echo "  FAIL              : $FAIL"
echo "============================================================"

if [[ ${#FAILURES[@]} -gt 0 ]]; then
  echo ""
  echo "Failures:"
  for f in "${FAILURES[@]}"; do
    echo "$f"
  done
  echo ""
fi

if [[ $FAIL -eq 0 ]]; then
  echo "  Result: PASS — all defaults match v3.9 behavior"
  echo "============================================================"
  echo ""
  exit 0
else
  echo "  Result: FAIL — $FAIL key(s) returned unexpected values"
  echo "============================================================"
  echo ""
  exit 1
fi
