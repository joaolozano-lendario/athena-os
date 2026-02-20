#!/usr/bin/env bash
# cost.sh — Cost tracking and budget enforcement

[[ -n "${_COST_SH_LOADED:-}" ]] && return 0
_COST_SH_LOADED=1

# Atomic budget reservation — check+deduct in one state_write.
# Returns 0 if reserved, 1 if insufficient.
# Args: estimated_cost task_id
budget_reserve() {
  local est="$1"
  local tid="$2"

  [[ -z "$est" ]] && die "budget_reserve: estimated_cost required"
  [[ -z "$tid" ]] && die "budget_reserve: task_id required"

  local result
  result=$(state_write_and_read '
    if (.budget.reservations // {} | has("'"$tid"'")) then .
    elif (.budget.limit_usd - .budget.used_usd) >= '"$est"' then
      .budget.used_usd += '"$est"' |
      .budget.estimated_remaining = (.budget.limit_usd - .budget.used_usd) |
      .budget.reservations = ((.budget.reservations // {}) + {"'"$tid"'": '"$est"'})
    else . end' \
    'if .budget.reservations["'"$tid"'"] then "RESERVED" else "INSUFFICIENT" end')

  if [[ "$result" == "RESERVED" ]]; then
    log_info "Budget reserved: \$${est} for $tid"
    return 0
  else
    log_warn "Budget insufficient for $tid: need \$$est"
    return 1
  fi
}

# Reconcile estimated reservation with actual cost.
# Adjusts budget: removes reservation, applies real cost.
# Args: task_id actual_cost
budget_reconcile() {
  local tid="$1"
  local actual="$2"

  [[ -z "$tid" ]] && die "budget_reconcile: task_id required"
  [[ -z "$actual" ]] && die "budget_reconcile: actual_cost required"

  state_write '
    .budget.used_usd = (.budget.used_usd - (.budget.reservations["'"$tid"'"] // 0) + '"$actual"') |
    .budget.estimated_remaining = (.budget.limit_usd - .budget.used_usd) |
    del(.budget.reservations["'"$tid"'"])
  '
  log_info "Budget reconciled for $tid: actual=\$${actual}"
}

# Record cost to JSONL and reconcile budget reservation
record_cost() {
  local task_id="$1"
  local attempt="$2"
  local cost_usd="$3"
  local model="$4"
  local input_tokens="$5"
  local output_tokens="$6"
  local worker_type="${7:-unknown}"

  local ts=$(now_iso)

  # Append to COST_FILE (locked)
  append_jsonl "$COST_FILE" "{\"ts\":\"$ts\",\"task_id\":\"$task_id\",\"attempt\":$attempt,\"cost_usd\":$cost_usd,\"model\":\"$model\",\"input_tokens\":$input_tokens,\"output_tokens\":$output_tokens,\"worker\":\"$worker_type\"}"

  # Reconcile reservation with actual cost (or just add if no reservation)
  local has_reservation
  has_reservation=$(state_read '.budget.reservations["'"$task_id"'"] // "none"')
  if [[ "$has_reservation" != "none" && "$has_reservation" != "null" ]]; then
    budget_reconcile "$task_id" "$cost_usd"
  else
    # No reservation (e.g., advisory, QA, meta-report) — direct add
    state_write ".budget.used_usd += $cost_usd | .budget.estimated_remaining = (.budget.limit_usd - .budget.used_usd)"
  fi

  log_event "{\"ts\":\"$ts\",\"event\":\"cost_recorded\",\"task_id\":\"$task_id\",\"attempt\":$attempt,\"cost_usd\":$cost_usd,\"model\":\"$model\"}"
  log_info "Cost recorded: \$${cost_usd} ($model, ${input_tokens}in/${output_tokens}out)"
}

# Extract cost from claude JSON response
extract_cost_from_response() {
  local response_file="$1"
  local model="${2:-sonnet}"

  if [[ ! -f "$response_file" ]]; then
    echo "0"
    return
  fi

  # Try direct cost field (claude CLI format)
  local cost
  cost=$(jq -r '.total_cost_usd // .cost_usd // empty' "$response_file" 2>/dev/null | tr -d '\r')

  if [[ -z "$cost" || "$cost" == "null" ]]; then
    # Fallback: estimate from tokens (including cache tokens for accurate cost)
    local input_t output_t cache_create cache_read
    input_t=$(jq -r '.usage.input_tokens // 0' "$response_file" 2>/dev/null | tr -d '\r')
    output_t=$(jq -r '.usage.output_tokens // 0' "$response_file" 2>/dev/null | tr -d '\r')
    cache_create=$(jq -r '.usage.cache_creation_input_tokens // 0' "$response_file" 2>/dev/null | tr -d '\r')
    cache_read=$(jq -r '.usage.cache_read_input_tokens // 0' "$response_file" 2>/dev/null | tr -d '\r')
    # Include cache tokens in total input for estimation
    local total_input
    total_input=$(( ${input_t:-0} + ${cache_create:-0} + ${cache_read:-0} ))
    cost=$(estimate_cost_by_model "$model" "$total_input" "${output_t:-0}")
  fi

  echo "${cost:-0}"
}

# Extract real token counts from claude CLI response (handles all token types)
# Returns: input_tokens output_tokens (space-separated)
extract_tokens_from_response() {
  local response_file="$1"

  if [[ ! -f "$response_file" ]]; then
    echo "0 0"
    return
  fi

  local input_t output_t cache_create cache_read
  input_t=$(jq -r '.usage.input_tokens // 0' "$response_file" 2>/dev/null | tr -d '\r')
  output_t=$(jq -r '.usage.output_tokens // 0' "$response_file" 2>/dev/null | tr -d '\r')
  cache_create=$(jq -r '.usage.cache_creation_input_tokens // 0' "$response_file" 2>/dev/null | tr -d '\r')
  cache_read=$(jq -r '.usage.cache_read_input_tokens // 0' "$response_file" 2>/dev/null | tr -d '\r')

  local total_input=$(( ${input_t:-0} + ${cache_create:-0} + ${cache_read:-0} ))
  echo "$total_input ${output_t:-0}"
}

# Estimate cost by model and token counts
estimate_cost_by_model() {
  local model="$1"
  local input_tokens="${2:-0}"
  local output_tokens="${3:-0}"

  local input_rate output_rate

  case "$model" in
    sonnet|claude-sonnet*)
      input_rate=3
      output_rate=15
      ;;
    haiku|claude-haiku*)
      input_rate=0.80
      output_rate=4
      ;;
    opus|claude-opus*)
      input_rate=15
      output_rate=75
      ;;
    *)
      # Default to sonnet rates
      input_rate=3
      output_rate=15
      ;;
  esac

  # Use bc for floating point calculation if available
  if command -v bc &>/dev/null; then
    echo "scale=6; ($input_tokens * $input_rate + $output_tokens * $output_rate) / 1000000" | bc
  else
    # Fallback to awk
    awk -v it="$input_tokens" -v ot="$output_tokens" -v ir="$input_rate" -v or="$output_rate" \
      'BEGIN { printf "%.6f", (it * ir + ot * or) / 1000000 }'
  fi
}

# Check if budget has enough remaining (read-only, no reservation).
# Used by pre-spawn barriers where reservation isn't needed.
# Args: estimated_cost
budget_has_remaining() {
  local estimated_cost="$1"

  local remaining
  remaining=$(state_read '.budget.estimated_remaining // (.budget.limit_usd - .budget.used_usd)')
  remaining=${remaining:-0}

  if command -v bc &>/dev/null; then
    if (( $(echo "$remaining < $estimated_cost" | bc -l) )); then
      return 1
    fi
  else
    local remaining_cents=$(awk -v r="$remaining" 'BEGIN { print int(r * 1000) }')
    local needed_cents=$(awk -v e="$estimated_cost" 'BEGIN { print int(e * 1000) }')
    if (( remaining_cents < needed_cents )); then
      return 1
    fi
  fi
  return 0
}
