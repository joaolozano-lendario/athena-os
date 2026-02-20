#!/usr/bin/env bash
# budget.sh — Budget Intelligence Module
# Provides token-aware cost estimation for FORMICA task budgets.
# Replaces flat $0.50 per-task approach with calculated estimates.

[[ -n "${_BUDGET_SH_LOADED:-}" ]] && return 0
_BUDGET_SH_LOADED=1

# CLI overhead: system prompt + tool definitions (tokens)
CLI_OVERHEAD=$(config_read "token_estimation.cli_overhead_tokens" "20000")

# ============================================================================
# get_model_pricing(model_name)
# Returns input_price output_price per 1M tokens as space-separated values.
# Usage: read input_price output_price <<< "$(get_model_pricing sonnet)"
# ============================================================================
get_model_pricing() {
  local model="${1:-sonnet}"

  case "$model" in
    haiku|claude-haiku*)
      echo "$(config_read "pricing.haiku_input_per_1m" "0.80") $(config_read "pricing.haiku_output_per_1m" "4.00")"
      ;;
    sonnet|claude-sonnet*)
      echo "$(config_read "pricing.sonnet_input_per_1m" "3.00") $(config_read "pricing.sonnet_output_per_1m" "15.00")"
      ;;
    opus|claude-opus*)
      echo "$(config_read "pricing.opus_input_per_1m" "15.00") $(config_read "pricing.opus_output_per_1m" "75.00")"
      ;;
    *)
      echo "$(config_read "pricing.sonnet_input_per_1m" "3.00") $(config_read "pricing.sonnet_output_per_1m" "15.00")"
      ;;
  esac
}

# ============================================================================
# estimate_task_tokens(manifest_path, task_index, project_dir)
# Sums token count of all context_files for the task.
# ============================================================================
estimate_task_tokens() {
  local manifest_path="$1"
  local task_index="$2"
  local project_dir="${3:-}"

  local total=0

  # Extract context_files for this task
  local context_files
  context_files=$(jq -r ".tasks[$task_index].context_files // [] | .[]" "$manifest_path" 2>/dev/null | tr -d '\r') || true

  # Get worker type for tool-use multiplier
  local worker_type
  worker_type=$(jq -r ".tasks[$task_index].worker // \"\"" "$manifest_path" 2>/dev/null | tr -d '\r') || true

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    # Resolve relative paths against project_dir
    local resolved="$file"
    if [[ -n "$project_dir" && ! "$file" = /* ]]; then
      resolved="${project_dir}/${file}"
    fi

    if [[ -f "$resolved" ]]; then
      # Char-based estimation (aligned with context.sh:_chars_per_token)
      local byte_count cpt file_tokens
      byte_count=$(wc -c < "$resolved" 2>/dev/null || echo 0)
      cpt=$(_estimate_chars_per_token "$resolved")
      file_tokens=$(awk -v b="$byte_count" -v c="$cpt" 'BEGIN { printf "%d", int(b / c) }')
      total=$((total + file_tokens))
    else
      total=$((total + $(config_read "token_estimation.future_file_token_estimate" "500")))
    fi
  done <<< "$context_files"

  # Add CLI overhead
  total=$((total + CLI_OVERHEAD))

  # Apply tool-use amplification multiplier
  local multiplier
  multiplier=$(_get_tool_use_multiplier "$worker_type")
  total=$(awk -v t="$total" -v m="$multiplier" 'BEGIN { printf "%d", int(t * m) }')

  log_debug "estimate_task_tokens: task[$task_index] = ${total} tokens (multiplier=${multiplier})" 2>/dev/null || true
  echo "$total"
}

# Chars-per-token ratio by file extension (mirrors context.sh:_chars_per_token)
_estimate_chars_per_token() {
  local filepath="${1:-}"
  local _mixed=$(config_read "token_estimation.mixed_chars_per_token" "4")
  [[ -z "$filepath" ]] && { echo "$_mixed"; return; }
  local _code=$(config_read "token_estimation.code_chars_per_token" "2")
  local _prose=$(config_read "token_estimation.prose_chars_per_token" "5")
  local _cfg=$(config_read "token_estimation.config_chars_per_token" "3")
  case "${filepath##*.}" in
    sh|py|js|ts|jsx|tsx|rb|go|rs|c|cpp|h|java|json) echo "$_code" ;;
    md|txt|rst|adoc) echo "$_prose" ;;
    yaml|yml|toml|ini|cfg) echo "$_cfg" ;;
    *) echo "$_mixed" ;;
  esac
}

# Tool-use amplification multiplier by worker type (from config)
_get_tool_use_multiplier() {
  local worker_type="${1:-}"
  local multiplier
  if [[ -n "$worker_type" ]]; then
    multiplier=$(config_read "budget.tool_use_multipliers.$worker_type" "")
  fi
  if [[ -z "$multiplier" || "$multiplier" == "null" ]]; then
    multiplier=$(config_read "budget.tool_use_multipliers.default" "1.0")
  fi
  # Backward compat: if config section doesn't exist, factor=1.0
  [[ -z "$multiplier" || "$multiplier" == "null" ]] && multiplier="1.0"
  echo "$multiplier"
}

# ============================================================================
# estimate_worker_turns(worker_type)
# Returns estimated number of API turns by worker type.
# ============================================================================
estimate_worker_turns() {
  local worker_type="${1:-}"

  case "$worker_type" in
    analyst)    echo 3 ;;
    architect)  echo 4 ;;
    implementer) echo 6 ;;
    writer)     echo 3 ;;
    qa)         echo 2 ;;
    advisor)    echo 2 ;;
    forger)     echo 2 ;;
    *)          echo 4 ;;
  esac
}

# ============================================================================
# estimate_task_cost(manifest_path, task_index, project_dir)
# Calculates estimated cost for a single task.
# ============================================================================
estimate_task_cost() {
  local manifest_path="$1"
  local task_index="$2"
  local project_dir="${3:-}"

  # Get task tokens
  local tokens
  tokens=$(estimate_task_tokens "$manifest_path" "$task_index" "$project_dir")

  # Get model from manifest or fall back to DEFAULT_MODEL
  local model
  model=$(jq -r ".tasks[$task_index].model // \"\"" "$manifest_path" 2>/dev/null | tr -d '\r') || true
  if [[ -z "$model" || "$model" == "null" ]]; then
    model="${DEFAULT_MODEL:-sonnet}"
  fi

  # Get worker type for turns estimate
  local worker_type
  worker_type=$(jq -r ".tasks[$task_index].worker // \"\"" "$manifest_path" 2>/dev/null | tr -d '\r') || true

  local turns
  turns=$(estimate_worker_turns "$worker_type")

  # Get pricing
  local input_price output_price
  read input_price output_price <<< "$(get_model_pricing "$model")"

  # Output tokens vary by worker type (empirical from 59 context packs)
  local output_tokens
  case "$worker_type" in
    analyst)      output_tokens=5000 ;;
    architect)    output_tokens=4000 ;;
    implementer)  output_tokens=8000 ;;
    writer)       output_tokens=5000 ;;
    qa)           output_tokens=1000 ;;
    *)            output_tokens=4000 ;;
  esac

  # Calculate cost using awk (no bc dependency):
  # Turn 1: full input price
  # Turns 2+: input_price * 0.15 (90% cache hit)
  # input_cost = tokens * input_price / 1M + tokens * (turns-1) * input_price * 0.15 / 1M
  # output_cost = output_tokens * turns * output_price / 1M
  local total_cost
  total_cost=$(awk \
    -v tok="$tokens" \
    -v ip="$input_price" \
    -v op="$output_price" \
    -v turns="$turns" \
    -v out_tok="$output_tokens" \
    -v chf="$(config_read "pricing.cache_hit_factor" "0.15")" \
    'BEGIN {
      input_cost = (tok * ip / 1000000) + (tok * (turns - 1) * ip * chf / 1000000)
      output_cost = out_tok * turns * op / 1000000
      total = input_cost + output_cost
      printf "%.4f", total
    }')

  log_debug "estimate_task_cost: task[$task_index] model=$model turns=$turns tokens=$tokens cost=\$${total_cost}" 2>/dev/null || true
  echo "$total_cost"
}

# ============================================================================
# calculate_safety_budget(estimated_cost, manifest_task_budget)
# Returns safety budget with 3x multiplier and floor.
# ============================================================================
calculate_safety_budget() {
  local estimated_cost="${1:-0}"
  local manifest_task_budget="${2:-0}"

  local safety
  local _sm=$(config_read "token_estimation.safety_budget_multiplier" "3.0")
  local _sf=$(config_read "token_estimation.safety_budget_floor" "0.15")
  safety=$(awk \
    -v est="$estimated_cost" \
    -v manifest="$manifest_task_budget" \
    -v sm="$_sm" -v sf="$_sf" \
    'BEGIN {
      safety = est * sm
      if (safety < sf) safety = sf
      if (manifest != "" && manifest != "null" && manifest + 0 > safety) safety = manifest + 0
      printf "%.2f", safety
    }')

  echo "$safety"
}

# ============================================================================
# estimate_blueprint_cost(manifest_path, project_dir)
# Iterates all tasks, sums costs, adds QA and advisory overhead.
# Echoes: best_case expected worst_case
# ============================================================================
estimate_blueprint_cost() {
  local manifest_path="$1"
  local project_dir="${2:-}"

  if [[ ! -f "$manifest_path" ]]; then
    log_debug "estimate_blueprint_cost: manifest not found: $manifest_path" 2>/dev/null || true
    echo "0.00 0.00 0.00"
    return
  fi

  # Get task count
  local task_count
  task_count=$(jq '.tasks | length' "$manifest_path" 2>/dev/null || echo 0)

  # Get max_retries from manifest
  local max_retries
  max_retries=$(jq -r '.settings.max_retries // 3' "$manifest_path" 2>/dev/null | tr -d '\r') || true
  max_retries="${max_retries:-3}"

  # Get wave count estimate (for advisory overhead)
  local wave_count
  wave_count=$(jq -r '.settings.waves // 1' "$manifest_path" 2>/dev/null | tr -d '\r') || true
  if [[ -z "$wave_count" || "$wave_count" == "null" ]]; then
    # Estimate waves from task count
    local _tpw=$(config_read "pricing.tasks_per_wave_estimate" "5")
    wave_count=$(awk -v n="$task_count" -v pw="$_tpw" 'BEGIN { print (n > 0) ? int((n / pw) + 1) : 1 }')
  fi

  # Sum task costs
  local total_task_cost=0
  local i=0
  while [[ $i -lt $task_count ]]; do
    local task_cost
    task_cost=$(estimate_task_cost "$manifest_path" "$i" "$project_dir")
    total_task_cost=$(awk -v acc="$total_task_cost" -v tc="$task_cost" 'BEGIN { printf "%.4f", acc + tc }')
    i=$((i + 1))
  done

  # QA overhead: 30% of total task cost
  # Advisory overhead: wave_count * $0.03
  local best_case expected worst_case
  best_case=$(awk \
    -v base="$total_task_cost" \
    -v waves="$wave_count" \
    -v qaf="$(config_read "pricing.qa_overhead_fraction" "0.30")" \
    -v apc="$(config_read "pricing.advisory_cost_per_wave" "0.03")" \
    'BEGIN {
      qa_overhead = base * qaf
      advisory_overhead = waves * apc
      printf "%.4f", base + qa_overhead + advisory_overhead
    }')

  expected=$(awk -v best="$best_case" -v ecm="$(config_read "pricing.expected_cost_multiplier" "1.30")" 'BEGIN { printf "%.4f", best * ecm }')

  worst_case=$(awk \
    -v best="$best_case" \
    -v retries="$max_retries" \
    'BEGIN { printf "%.4f", best * retries }')

  log_debug "estimate_blueprint_cost: tasks=$task_count waves=$wave_count best=\$${best_case} expected=\$${expected} worst=\$${worst_case}" 2>/dev/null || true
  echo "$best_case $expected $worst_case"
}

# ============================================================================
# log_estimation_accuracy(task_id, estimated_cost, actual_cost)
# Logs estimated vs actual cost for calibration feedback.
# ============================================================================
log_estimation_accuracy() {
  local task_id="$1"
  local estimated="$2"
  local actual="$3"

  local accuracy
  accuracy=$(awk -v est="$estimated" -v act="$actual" 'BEGIN {
    if (act == 0) { printf "100"; exit }
    ratio = (est > act) ? act / est : est / act
    printf "%.0f", ratio * 100
  }')

  local delta
  delta=$(awk -v est="$estimated" -v act="$actual" 'BEGIN { printf "%.4f", act - est }')

  log_info "Estimation accuracy: task=$task_id estimated=\$${estimated} actual=\$${actual} accuracy=${accuracy}% delta=\$${delta}"
  log_event "{\"ts\":\"$(now_iso)\",\"event\":\"estimation_accuracy\",\"task_id\":\"$task_id\",\"estimated\":$estimated,\"actual\":$actual,\"accuracy\":$accuracy,\"delta\":$delta}" 2>/dev/null || true
}
