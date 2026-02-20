#!/usr/bin/env bash
# wizard.sh — Pre-execution plan display for FORMICA v3.0
# Single-screen plan with cost estimate, wave map, validation, and mode display.
# Fully deterministic (zero API calls).

[[ -n "${_WIZARD_SH_LOADED:-}" ]] && return 0
_WIZARD_SH_LOADED=1

# ============================================================================
# WIZARD DISPLAY
# ============================================================================

# Run the pre-execution wizard
# Shows plan, validates, estimates cost, and optionally waits for confirmation
# Args: manifest interactive [--auto-approve] [--dry-run]
run_wizard() {
  local manifest="$1"
  local interactive="${2:-false}"
  local auto_approve=false
  local dry_run=false

  # Parse flags
  shift 2 || true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --auto-approve) auto_approve=true; shift ;;
      --dry-run)      dry_run=true; shift ;;
      *)              shift ;;
    esac
  done

  local blueprint_name
  blueprint_name=$(yq -r '.blueprint.name // .blueprint.id' "$manifest" 2>/dev/null | tr -d '\r')
  local blueprint_id
  blueprint_id=$(yq -r '.blueprint.id' "$manifest" 2>/dev/null | tr -d '\r')
  local project_dir
  project_dir=$(yq -r '.blueprint.project_dir // "."' "$manifest" 2>/dev/null | tr -d '\r')
  local mode
  mode=$(yq -r '.config.mode // "quality"' "$manifest" 2>/dev/null | tr -d '\r')

  # Task count and validation
  local task_count
  task_count=$(yq -r '.tasks | length' "$manifest")
  local worker_names
  worker_names=$(yq -r '.workers | keys | .[]' "$manifest" 2>/dev/null || echo "")

  # Version
  local version="3.9"

  # Banner
  echo "" >&2
  echo "╔════════════════════════════════════════════════════════════╗" >&2
  echo "║  FORMICA v${version} — Autonomous Orchestration Engine         ║" >&2
  echo "╠════════════════════════════════════════════════════════════╣" >&2
  printf "║  Blueprint: %-44s ║\n" "$blueprint_name" >&2
  printf "║  Project:   %-44s ║\n" "$project_dir" >&2
  printf "║  Mode:      %-44s ║\n" "$mode" >&2
  echo "╚════════════════════════════════════════════════════════════╝" >&2
  echo "" >&2

  # Validation
  echo "┌─ Validation ────────────────────────────────────────────┐" >&2
  printf "│  Tasks: %-3s  │  DAG: %-5s  │  Workers: %-5s         │\n" \
    "$task_count" "valid" "$(echo "$worker_names" | wc -w | tr -d ' ')" >&2
  echo "└─────────────────────────────────────────────────────────┘" >&2
  echo "" >&2

  # Worker distribution
  echo "┌─ Worker Distribution ───────────────────────────────────┐" >&2
  for wname in $worker_names; do
    local wcount
    wcount=$(yq -r "[.tasks[] | select(.worker == \"$wname\")] | length" "$manifest" 2>/dev/null || echo "0")
    printf "│  %-15s %s tasks %*s│\n" "$wname" "$wcount" $((40 - ${#wname} - ${#wcount})) "" >&2
  done
  echo "└─────────────────────────────────────────────────────────┘" >&2
  echo "" >&2

  # Wave map
  _wizard_wave_map "$manifest"

  # Cost estimate
  _wizard_cost_estimate "$manifest" "$task_count"

  # Warnings
  _wizard_warnings "$manifest" "$task_count"

  # Mode description
  if type get_mode_description &>/dev/null; then
    echo "" >&2
    echo "Mode: $(get_mode_description "$mode")" >&2
  fi

  echo "" >&2

  # Dry-run flag: display wizard then exit
  if [[ "$dry_run" == "true" ]]; then
    log_info "Wizard dry-run complete (--dry-run flag)"
    return 0
  fi

  # Interactive mode: wait for confirmation (unless auto-approve)
  if [[ "$interactive" == "true" && "$auto_approve" != "true" && -t 0 ]]; then
    echo "Press ENTER to start or Ctrl+C to abort..." >&2
    read -r
  fi
}

# ============================================================================
# WAVE MAP
# ============================================================================

_wizard_wave_map() {
  local manifest="$1"

  echo "┌─ Execution Waves ───────────────────────────────────────┐" >&2

  # Build temp state for wave computation
  local tmp_state="/tmp/wizard-dag-${BASHPID:-$$}-${RANDOM}.json"
  build_tasks_json "$manifest" "$tmp_state"

  # Inject file conflict deps (same as validate_manifest)
  local tmp_registry="/tmp/wizard-registry-${BASHPID:-$$}-${RANDOM}.json"
  if type build_file_registry &>/dev/null; then
    build_file_registry "$manifest" "$tmp_registry" 2>/dev/null
    local conflicts
    conflicts=$(detect_file_conflicts "$tmp_registry" 2>/dev/null || echo "[]")
    local conflict_count
    conflict_count=$(echo "$conflicts" | jq 'length' 2>/dev/null || echo "0")
    if [[ "$conflict_count" -gt 0 ]]; then
      while IFS= read -r conflict; do
        local task_a task_b
        task_a=$(echo "$conflict" | jq -r '.task_a' | tr -d '\r')
        task_b=$(echo "$conflict" | jq -r '.task_b' | tr -d '\r')
        jq --arg a "$task_a" --arg b "$task_b" \
          '.tasks[$b].depends_on = (.tasks[$b].depends_on // [] | . + [$a])' \
          "$tmp_state" > "${tmp_state}.tmp" && mv "${tmp_state}.tmp" "$tmp_state"
      done < <(echo "$conflicts" | jq -c '.[]' 2>/dev/null | tr -d '\r')
    fi
    rm -f "$tmp_registry"
  fi

  local wave_num=0
  while IFS= read -r wave; do
    [[ -z "$wave" ]] && continue
    ((wave_num++)) || true
    local task_count_w
    task_count_w=$(echo "$wave" | wc -w)
    # Format: "W1 [4 tasks]: T-1.1 T-1.2 T-1.3 T-1.4"
    printf "│  W%d [%-2s tasks]: %-38s│\n" "$wave_num" "$task_count_w" "$wave" >&2
  done < <(get_execution_waves "$tmp_state" 2>/dev/null)

  rm -f "$tmp_state"
  echo "└─────────────────────────────────────────────────────────┘" >&2
}

# ============================================================================
# COST ESTIMATE
# ============================================================================

_wizard_cost_estimate() {
  local manifest="$1"
  local task_count="$2"

  local max_retries
  max_retries=$(yq -r '.config.max_retries // 3' "$manifest" 2>/dev/null | tr -d '\r')
  local max_budget
  max_budget=$(yq -r '.config.max_budget_usd // 50' "$manifest" 2>/dev/null | tr -d '\r')
  local project_dir
  project_dir=$(yq -r '.blueprint.project_dir // "."' "$manifest" 2>/dev/null | tr -d '\r')

  # Use budget.sh token-aware estimates if available
  local best expected worst
  if type estimate_blueprint_cost &>/dev/null; then
    local estimates
    estimates=$(estimate_blueprint_cost "$manifest" "$project_dir" 2>/dev/null) || estimates=""
    if [[ -n "$estimates" && "$estimates" != "0.0000 0.0000 0.0000" ]]; then
      read best expected worst <<< "$estimates"
    fi
  fi

  # Fallback: simple calculation if budget.sh unavailable or returned empty
  if [[ -z "${best:-}" || "$best" == "0.0000" ]]; then
    local default_model
    default_model=$(yq -r '.config.default_model // "sonnet"' "$manifest" 2>/dev/null | tr -d '\r')
    local simple_rate
    case "$default_model" in
      haiku*)  simple_rate="0.10" ;;
      sonnet*) simple_rate="0.50" ;;
      opus*)   simple_rate="2.00" ;;
      *)       simple_rate="0.50" ;;
    esac
    log_warn "budget.sh estimate unavailable — using simple fallback (\$${simple_rate}/task)" 2>/dev/null || true
    best=$(awk -v r="$simple_rate" -v n="$task_count" 'BEGIN { printf "%.2f", n * r }')
    expected=$(awk -v b="$best" 'BEGIN { printf "%.2f", b * 1.3 }')
    worst=$(awk -v b="$best" -v r="$max_retries" 'BEGIN { printf "%.2f", b * r }')
  fi

  echo "" >&2
  echo "┌─ Cost Estimate ─────────────────────────────────────────┐" >&2
  printf "│  Best case:     \$%-8s (all pass first try)          │\n" "$best" >&2
  printf "│  Expected:      \$%-8s (30%% retry overhead)          │\n" "$expected" >&2
  printf "│  Worst case:    \$%-8s (max retries on all tasks)    │\n" "$worst" >&2
  printf "│  Budget limit:  \$%-8s                               │\n" "$max_budget" >&2
  echo "└─────────────────────────────────────────────────────────┘" >&2
}

# ============================================================================
# WARNINGS
# ============================================================================

_wizard_warnings() {
  local manifest="$1"
  local task_count="$2"

  local warnings=()

  # Tasks without explicit QA criteria
  local no_criteria=0
  for i in $(seq 0 $((task_count - 1))); do
    local criteria_count
    criteria_count=$(yq -r ".tasks[$i].qa.criteria // [] | length" "$manifest" 2>/dev/null || echo "0")
    [[ "$criteria_count" -eq 0 ]] && ((no_criteria++)) || true
  done
  [[ $no_criteria -gt 0 ]] && warnings+=("$no_criteria task(s) have no explicit QA criteria (auto-gen will be used)")

  # Budget risk
  local max_budget
  max_budget=$(yq -r '.config.max_budget_usd // 50' "$manifest" 2>/dev/null | tr -d '\r')
  local expected_cost
  expected_cost=$(awk -v mb="$max_budget" 'BEGIN { printf "%.2f", mb * 0.3 }')
  local budget_risk_pct
  budget_risk_pct=$(awk -v ec="$expected_cost" -v mb="$max_budget" 'BEGIN { printf "%.0f", (ec / mb) * 100 }')
  if [[ "$budget_risk_pct" -ge 80 ]]; then
    warnings+=("Budget tight: expected cost (~\$$expected_cost) is ${budget_risk_pct}% of limit")
  fi

  # Check epigenetic markers for worker type issues (new v3.0)
  local markers_file="${MEMORY_DIR:-.orchestrator/memory}/epigenetic-markers.yaml"
  if [[ -f "$markers_file" ]]; then
    local bad_workers
    bad_workers=$(yq -r '.budget_adjustments // {} | to_entries[] | select(.value > 1.5) | .key' "$markers_file" 2>/dev/null | tr -d '\r')
    for wtype in $bad_workers; do
      local mult
      mult=$(yq -r ".budget_adjustments.\"$wtype\"" "$markers_file" 2>/dev/null | tr -d '\r')
      warnings+=("Worker type '$wtype' has poor epigenetic history (${mult}x budget multiplier)")
    done
  fi

  # File conflicts detected in manifest (new v3.0)
  local tmp_registry="/tmp/wizard-conflicts-${BASHPID:-$$}-${RANDOM}.json"
  if type build_file_registry &>/dev/null; then
    build_file_registry "$manifest" "$tmp_registry" 2>/dev/null
    local conflicts
    conflicts=$(detect_file_conflicts "$tmp_registry" 2>/dev/null || echo "[]")
    local conflict_count
    conflict_count=$(echo "$conflicts" | jq 'length' 2>/dev/null || echo "0")
    if [[ "$conflict_count" -gt 0 ]]; then
      warnings+=("File conflicts detected: $conflict_count tasks will have implicit dependencies")
    fi
    rm -f "$tmp_registry"
  fi

  if [[ ${#warnings[@]} -gt 0 ]]; then
    echo "" >&2
    echo "┌─ Warnings ───────────────────────────────────────────────┐" >&2
    for w in "${warnings[@]}"; do
      printf "│  ⚠ %-53s│\n" "$w" >&2
    done
    echo "└─────────────────────────────────────────────────────────┘" >&2
  fi
}
