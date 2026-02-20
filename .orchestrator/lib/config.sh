#!/usr/bin/env bash
# config.sh — Centralized configuration reader for FORMICA v4.0
# Reads from formiga.config.yaml with hardcoded fallback defaults
# S3.1: Externalize all magic numbers into formiga.config.yaml

[[ -n "${_CONFIG_SH_LOADED:-}" ]] && return 0
_CONFIG_SH_LOADED=1

# Dependencies: utils.sh (for ORCHESTRATOR_DIR, log_warn)

CONFIG_FILE="${ORCHESTRATOR_DIR}/formiga.config.yaml"

# Read a config value by dot-path key with fallback default
# Usage: config_read "section.key" "default_value"
# Example: config_read "orchestration.task_timeout_s" "600"
config_read() {
  local key="$1"
  local default="${2:-}"

  # Fast path: no config file → return default immediately
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "$default"
    return
  fi

  local val
  val=$(yq -r ".${key} // \"\"" "$CONFIG_FILE" 2>/dev/null | tr -d '\r')

  if [[ -n "$val" && "$val" != "null" ]]; then
    echo "$val"
  else
    echo "$default"
  fi
}

# Validate config values on startup (called once from orchestrate.sh)
# Warns on out-of-range values, never crashes
validate_config() {
  [[ ! -f "$CONFIG_FILE" ]] && return 0

  local warnings=0

  # Helper: check numeric range
  _check_range() {
    local key="$1" min="$2" max="$3"
    local val
    val=$(config_read "$key" "")
    [[ -z "$val" ]] && return 0
    if awk -v v="$val" -v mn="$min" -v mx="$max" 'BEGIN { exit !(v < mn || v > mx) }'; then
      log_warn "Config validation: $key=$val is outside expected range [$min, $max]"
      ((warnings++)) || true
    fi
  }

  # Orchestration
  _check_range "orchestration.task_timeout_s" 30 7200
  _check_range "orchestration.cas_max_retries" 1 50
  _check_range "orchestration.kill_timeout_s" 1 30
  _check_range "orchestration.wall_clock_timeout_s" 60 86400

  # Allometry
  _check_range "allometry.small_threshold" 1 100
  _check_range "allometry.medium_threshold" 2 500
  _check_range "allometry.token_budget_base" 1000 500000
  _check_range "allometry.token_budget_floor" 500 100000

  # Routing
  _check_range "routing.budget_guard_pct" 5 90
  _check_range "routing.pheromone_sonnet_threshold" 0.01 1.0

  # Pheromone
  _check_range "pheromone.evaporation_rate" 0.01 1.0
  _check_range "pheromone.signal_ttl_waves" 1 20
  _check_range "pheromone.friction_ttl_waves" 1 20

  # Quorum
  _check_range "quorum.done_threshold" 0.50 1.0
  _check_range "quorum.retry_threshold" 0.30 1.0
  _check_range "quorum.disagreement_threshold" 0.10 1.0

  # Immune
  _check_range "immune.promotion_threshold" 1 20
  _check_range "immune.min_file_bytes" 1 1000
  _check_range "immune.max_file_bytes" 1000 10000000

  # QA
  _check_range "qa.pass_threshold_default" 50 100
  _check_range "qa.rework_floor" 20 90

  if [[ $warnings -gt 0 ]]; then
    log_warn "Config validation: $warnings warning(s) — values will be used as-is"
  fi

  unset -f _check_range
}
