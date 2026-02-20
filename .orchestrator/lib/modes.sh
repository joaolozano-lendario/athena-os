#!/usr/bin/env bash
# modes.sh — Orchestration mode profiles for FORMICA v2.0
# Modes: economic, quality, speed, guided
# Each mode sets global orchestration parameters.

[[ -n "${_MODES_SH_LOADED:-}" ]] && return 0
_MODES_SH_LOADED=1

# ============================================================================
# MODE DEFINITIONS
# ============================================================================

# Apply orchestration mode by name
# Sets global variables: MAX_PARALLEL, DEFAULT_MODEL, QA_MODEL, QA_THRESHOLD,
# MAX_RETRIES, ADVISORY_ENABLED, TASK_BUDGET
apply_orchestration_mode() {
  local mode="${1:-quality}"

  case "$mode" in
    economic)
      MAX_PARALLEL=$(config_read "modes.economic.max_parallel" "1")
      DEFAULT_MODEL="haiku"
      QA_MODEL="haiku"
      QA_THRESHOLD=$(config_read "modes.economic.qa_threshold" "70")
      MAX_RETRIES=$(config_read "modes.economic.max_retries" "1")
      ADVISORY_ENABLED=false
      BUDGET_FACTOR=$(config_read "modes.economic.budget_factor" "0.70")
      ;;
    quality)
      MAX_PARALLEL=$(config_read "modes.quality.max_parallel" "2")
      DEFAULT_MODEL="haiku"
      QA_MODEL="haiku"
      QA_THRESHOLD=$(config_read "modes.quality.qa_threshold" "85")
      MAX_RETRIES=$(config_read "modes.quality.max_retries" "3")
      ADVISORY_ENABLED=true
      BUDGET_FACTOR=$(config_read "modes.quality.budget_factor" "1.50")
      ;;
    speed)
      MAX_PARALLEL=$(config_read "modes.speed.max_parallel" "4")
      DEFAULT_MODEL="haiku"
      QA_MODEL="haiku"
      QA_THRESHOLD=$(config_read "modes.speed.qa_threshold" "75")
      MAX_RETRIES=$(config_read "modes.speed.max_retries" "2")
      ADVISORY_ENABLED=false
      BUDGET_FACTOR=$(config_read "modes.speed.budget_factor" "1.00")
      ;;
    guided)
      MAX_PARALLEL=$(config_read "modes.guided.max_parallel" "2")
      DEFAULT_MODEL="haiku"
      QA_MODEL="haiku"
      QA_THRESHOLD=$(config_read "modes.guided.qa_threshold" "80")
      MAX_RETRIES=$(config_read "modes.guided.max_retries" "3")
      ADVISORY_ENABLED=true
      BUDGET_FACTOR=$(config_read "modes.guided.budget_factor" "1.20")
      ;;
    *)
      log_warn "Unknown mode '$mode' — defaulting to quality"
      apply_orchestration_mode "quality"
      return
      ;;
  esac

  # Apply budget factor to TASK_BUDGET
  if [[ -n "${BUDGET_FACTOR:-}" ]]; then
    TASK_BUDGET=$(awk -v b="${TASK_BUDGET:-0.50}" -v f="$BUDGET_FACTOR" 'BEGIN { printf "%.2f", b * f }')
  fi

  log_info "Mode applied: $mode (parallel=$MAX_PARALLEL, model=$DEFAULT_MODEL, qa=$QA_THRESHOLD, retries=$MAX_RETRIES, advisory=$ADVISORY_ENABLED)"
}

# Get human-readable mode description for wizard display
get_mode_description() {
  local mode="${1:-quality}"

  case "$mode" in
    economic)  echo "Economic — Minimize cost. Single worker, haiku only, 1 retry, no advisory." ;;
    quality)   echo "Quality — Balance quality and cost. Advisory enabled, 3 retries, threshold 85." ;;
    speed)     echo "Speed — Maximize throughput. 4 parallel workers, 2 retries, threshold 75." ;;
    guided)    echo "Guided — Human-in-the-loop. Pauses after each wave for review." ;;
    *)         echo "Unknown mode: $mode" ;;
  esac
}

# List all available modes (for wizard display)
list_modes() {
  echo "economic quality speed guided"
}
