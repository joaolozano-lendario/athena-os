#!/usr/bin/env bash
# consciousness.sh — Situational awareness map for FORMICA workers
# Part of FORMICA SAPIENS v4.2
# Provides: generate_consciousness_map, update_consciousness_map

[[ -n "${_CONSCIOUSNESS_SH_LOADED:-}" ]] && return 0
_CONSCIOUSNESS_SH_LOADED=1

# ============================================================================
# generate_consciousness_map(task_id, runtime_dir)
# Generates markdown consciousness map with HARD CAP of ~225 words.
# Output: runtime/{bp}/consciousness-map.md
# ============================================================================
generate_consciousness_map() {
  local task_id="$1"
  local runtime_dir="${2:-$RUNTIME_DIR}"

  [[ -z "$runtime_dir" ]] && return 0

  local map_file="$runtime_dir/consciousness-map.md"
  local state_file="$runtime_dir/state.json"
  [[ ! -f "$state_file" ]] && return 0

  # Read blueprint metadata
  local bp_name bp_id
  bp_name=$(jq -r '.blueprint_id // "unknown"' "$state_file" 2>/dev/null | tr -d '\r')
  bp_id="$bp_name"

  # Task position
  local total_tasks completed_tasks
  total_tasks=$(jq -r '.counters.total // 0' "$state_file" 2>/dev/null | tr -d '\r')
  completed_tasks=$(jq -r '.counters.completed // 0' "$state_file" 2>/dev/null | tr -d '\r')

  # Budget info
  local budget_total budget_used budget_remaining
  budget_total=$(jq -r '.budget.total_usd // 0' "$state_file" 2>/dev/null | tr -d '\r')
  budget_used=$(jq -r '.budget.used_usd // 0' "$state_file" 2>/dev/null | tr -d '\r')
  budget_remaining=$(awk -v t="$budget_total" -v u="$budget_used" 'BEGIN { printf "%.2f", t - u }')

  # Model info
  local current_model
  current_model=$(jq -r ".tasks[\"$task_id\"].model // \"sonnet\"" "$state_file" 2>/dev/null | tr -d '\r')

  # DAG context: upstream and downstream
  local upstream_info=""
  local deps
  deps=$(jq -r ".tasks[\"$task_id\"].depends_on // [] | .[]" "$state_file" 2>/dev/null | tr -d '\r')
  while IFS= read -r dep; do
    [[ -z "$dep" ]] && continue
    local dep_status dep_score
    dep_status=$(jq -r ".tasks[\"$dep\"].status // \"pending\"" "$state_file" 2>/dev/null | tr -d '\r')
    dep_score=$(jq -r ".tasks[\"$dep\"].score // \"?\"" "$state_file" 2>/dev/null | tr -d '\r')
    upstream_info+="$dep [$dep_status $dep_score] → "
  done <<< "$deps"
  [[ -z "$upstream_info" ]] && upstream_info="(no upstream) → "

  local downstream_info=""
  local downstream
  downstream=$(jq -r "[.tasks | to_entries[] | select(.value.depends_on // [] | index(\"$task_id\")) | .key] | .[]" "$state_file" 2>/dev/null | tr -d '\r')
  while IFS= read -r ds; do
    [[ -z "$ds" ]] && continue
    downstream_info+=" → $ds [pending]"
  done <<< "$downstream"
  [[ -z "$downstream_info" ]] && downstream_info=" → (no downstream)"

  # Decision log (last 3)
  local decision_log=""
  if type get_recent_decisions &>/dev/null; then
    decision_log=$(get_recent_decisions 3 2>/dev/null)
  fi

  # Stability
  local stability="STABLE"
  if type detect_instability &>/dev/null; then
    stability=$(detect_instability 5 2>/dev/null || echo "STABLE")
  fi

  # Colony intelligence (last 2 signals by intensity)
  local colony_info=""
  local signals_file="$runtime_dir/colony_signals.jsonl"
  if [[ -f "$signals_file" && -s "$signals_file" ]]; then
    colony_info=$(jq -s '[.[] | select(.intensity >= 0.4)] | sort_by(-.intensity) | .[:2] | .[] | "- [\(.type)] \(.signal)"' "$signals_file" 2>/dev/null | tr -d '"' | tr -d '\r')
  fi

  # Build map
  {
    echo "## SITUATIONAL AWARENESS"
    echo ""
    echo "**Blueprint:** $bp_id"
    echo "**Your Position:** Task $((completed_tasks + 1))/$total_tasks"
    echo "**Model:** $current_model | Budget: \$$budget_remaining/\$$budget_total"
    echo ""
    echo "**DAG Context:**"
    echo "${upstream_info}**YOU [$task_id]**${downstream_info}"
    echo ""

    # Colony intelligence (truncate first if over budget)
    if [[ -n "$colony_info" ]]; then
      echo "**Colony Intelligence:**"
      echo "$colony_info"
      echo ""
    fi

    # Decision log (truncate second if over budget)
    if [[ -n "$decision_log" ]]; then
      echo "**Decision Log (last 3):**"
      echo "$decision_log"
      echo ""
    fi

    echo "**Stability:** $stability"
  } > "$map_file"

  # Hard cap: truncate if > 225 words
  local word_count
  word_count=$(wc -w < "$map_file" 2>/dev/null || echo 0)
  if [[ $word_count -gt 225 ]]; then
    # Truncate colony intelligence and decision log sections
    local truncated
    truncated=$(awk '
      /^\*\*Colony Intelligence/ { skip=1 }
      /^\*\*Decision Log/ { skip=1 }
      /^\*\*Stability/ { skip=0 }
      !skip { print }
    ' "$map_file")
    echo "$truncated" > "$map_file"
    echo "**Stability:** $stability" >> "$map_file"
  fi
}

# ============================================================================
# update_consciousness_map(task_id, verdict, score, runtime_dir)
# Re-generates map after task completion. Lightweight wrapper.
# ============================================================================
update_consciousness_map() {
  local task_id="$1"
  local verdict="${2:-}"
  local score="${3:-}"
  local runtime_dir="${4:-$RUNTIME_DIR}"

  # Simply re-generate with updated state
  generate_consciousness_map "$task_id" "$runtime_dir" 2>/dev/null || true
}
