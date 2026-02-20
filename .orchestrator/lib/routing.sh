#!/usr/bin/env bash
# routing.sh — Model selection, allometry scaling, negative pheromone
# Biomimetic patterns: Allometry (Pattern 4), Negative Pheromone (Pattern 1)

[[ -n "${_ROUTING_SH_LOADED:-}" ]] && return 0
_ROUTING_SH_LOADED=1

# ============================================================================
# ALLOMETRY — Scale-dependent configuration
# ============================================================================

# Colony size thresholds (from config, fallback to v3.9 defaults)
ALLOMETRY_SMALL=$(config_read "allometry.small_threshold" "8")
ALLOMETRY_MEDIUM=$(config_read "allometry.medium_threshold" "25")

# Exported allometry variables (set by apply_allometry)
CONTEXT_TOKEN_BUDGET=$(config_read "allometry.token_budget_base" "60000")
ADVISORY_ENABLED=false
SIGNAL_INJECTION_MAX=3

# Apply allometry based on task count
# Sets global variables: MAX_PARALLEL, MAX_RETRIES, ADVISORY_ENABLED, etc.
apply_allometry() {
  local task_count="$1"

  local colony_class
  if [[ $task_count -le $ALLOMETRY_SMALL ]]; then
    colony_class="small"
    MAX_PARALLEL=${MAX_PARALLEL:-2}
    MAX_RETRIES=${MAX_RETRIES:-2}
    ADVISORY_ENABLED=false
    SIGNAL_INJECTION_MAX=$(config_read "allometry.signal_injection_max_small" "2")
    CONTEXT_TOKEN_BUDGET=$(_allometry_token_budget "$task_count")
  elif [[ $task_count -le $ALLOMETRY_MEDIUM ]]; then
    colony_class="medium"
    MAX_PARALLEL=${MAX_PARALLEL:-3}
    MAX_RETRIES=${MAX_RETRIES:-3}
    ADVISORY_ENABLED=true
    SIGNAL_INJECTION_MAX=$(config_read "allometry.signal_injection_max_medium" "4")
    CONTEXT_TOKEN_BUDGET=$(_allometry_token_budget "$task_count")
  else
    colony_class="large"
    MAX_PARALLEL=${MAX_PARALLEL:-4}
    MAX_RETRIES=${MAX_RETRIES:-3}
    ADVISORY_ENABLED=true
    SIGNAL_INJECTION_MAX=$(config_read "allometry.signal_injection_max_large" "6")
    CONTEXT_TOKEN_BUDGET=$(_allometry_token_budget "$task_count")
  fi

  log_info "Allometry: $colony_class colony ($task_count tasks) — parallel=$MAX_PARALLEL, advisory=$ADVISORY_ENABLED, budget=${CONTEXT_TOKEN_BUDGET}tok"
}

# Power-law token budget: tokens = base * (8/n)^0.75, floor 3000
_allometry_token_budget() {
  local n="$1"
  local base=$(config_read "allometry.token_budget_base" "60000")
  local exponent=$(config_read "allometry.token_budget_exponent" "0.75")
  local floor=$(config_read "allometry.token_budget_floor" "3000")

  if [[ $n -le 1 ]]; then
    echo "$base"
    return
  fi

  # Power law: base * (8/n)^exponent
  if command -v bc &>/dev/null; then
    local result
    result=$(echo "scale=0; $base * e($exponent * l(8 / $n)) / 1" | bc -l 2>/dev/null)
    if [[ -n "$result" && "$result" -gt "$floor" ]] 2>/dev/null; then
      echo "$result"
    else
      echo "$floor"
    fi
  else
    awk -v base="$base" -v n="$n" -v expon="$exponent" -v fl="$floor" 'BEGIN {
      r = base * (8/n)^expon
      if (r < fl) r = fl
      printf "%d", r
    }'
  fi
}

# Between-wave adaptation: adjust params based on execution performance
adapt_allometry() {
  local failure_rate="${1:-0}"   # 0.0-1.0
  local retry_rate="${2:-0}"    # 0.0-1.0

  local fail_thresh=$(config_read "routing.failure_rate_threshold" "0.30")
  local retry_thresh=$(config_read "routing.retry_rate_threshold" "0.50")

  # Reduce parallelism if failure rate > threshold
  if command -v bc &>/dev/null; then
    if (( $(echo "$failure_rate > $fail_thresh" | bc -l) )); then
      local new_parallel=$((MAX_PARALLEL > 1 ? MAX_PARALLEL - 1 : 1))
      log_info "Allometry adapt: failure_rate=$failure_rate > $fail_thresh — reducing parallelism $MAX_PARALLEL → $new_parallel"
      MAX_PARALLEL=$new_parallel
    fi

    # Upgrade default model if retry rate > threshold
    if (( $(echo "$retry_rate > $retry_thresh" | bc -l) )); then
      if [[ "$DEFAULT_MODEL" == "haiku" ]]; then
        log_info "Allometry adapt: retry_rate=$retry_rate > 0.50 — upgrading default model haiku → sonnet"
        DEFAULT_MODEL="sonnet"
      fi
    fi
  else
    # Fallback: integer comparison (multiply by 100)
    local fr_int=$(awk -v r="$failure_rate" 'BEGIN { printf "%d", r * 100 }')
    local rr_int=$(awk -v r="$retry_rate" 'BEGIN { printf "%d", r * 100 }')
    local ft_int=$(awk -v r="$fail_thresh" 'BEGIN { printf "%d", r * 100 }')
    local rt_int=$(awk -v r="$retry_thresh" 'BEGIN { printf "%d", r * 100 }')
    if [[ $fr_int -gt $ft_int ]]; then
      MAX_PARALLEL=$((MAX_PARALLEL > 1 ? MAX_PARALLEL - 1 : 1))
      log_info "Allometry adapt: reducing parallelism to $MAX_PARALLEL"
    fi
    if [[ $rr_int -gt $rt_int && "$DEFAULT_MODEL" == "haiku" ]]; then
      DEFAULT_MODEL="sonnet"
      log_info "Allometry adapt: upgrading default model to sonnet"
    fi
  fi
}

# ============================================================================
# MODEL SELECTION
# ============================================================================

# Select model for a task based on type, retry count, and budget
# Args: task_type, retry_count, budget_remaining_pct
# Returns: model name (haiku|sonnet|opus)
select_model() {
  local task_type="${1:-implementer}"
  local retry_count="${2:-0}"
  local budget_remaining_pct="${3:-100}"
  local task_model="${4:-}"  # Per-task override from manifest
  local blocking_factor="${5:-0}"  # C5: gateway task protection

  # S1.6: Budget guard FIRST — CANNOT be bypassed by per-task override
  # C5: gateway tasks with blocking_factor≥threshold are exempt
  local _bg_pct=$(config_read "routing.budget_guard_pct" "30")
  local _gw_bf=$(config_read "routing.gateway_blocking_factor" "3")
  if [[ $budget_remaining_pct -lt $_bg_pct ]]; then
    if [[ $blocking_factor -ge $_gw_bf ]]; then
      log_info "[$task_type] Budget low ($budget_remaining_pct%) but gateway (blocks=$blocking_factor) — keeping sonnet"
    else
      echo "haiku"
      return
    fi
  fi

  # Per-task override (now budget-safe — budget guard already passed)
  if [[ -n "$task_model" && "$task_model" != "null" ]]; then
    case "$task_model" in
      haiku|sonnet|opus) echo "$task_model" ;;
      *) log_warn "Unknown model override: $task_model — using default"; echo "${DEFAULT_MODEL:-haiku}" ;;
    esac
    return
  fi

  # Check epigenetic model hints (cross-blueprint learning) — after budget guard
  local hint
  hint=$(get_model_hint "$task_type" 2>/dev/null) || hint=""
  if [[ -n "$hint" && "$hint" != "null" ]]; then
    echo "$hint"
    return
  fi

  # Friction-based upgrade: if this worker type has >=2 friction events, upgrade model
  local friction_file="${RUNTIME_DIR:-}/friction_events.jsonl"
  if [[ -f "$friction_file" && -s "$friction_file" ]]; then
    local friction_count
    friction_count=$(jq -r "select(.worker_type == \"$task_type\")" "$friction_file" 2>/dev/null | wc -l)
    local _fric_thresh=$(config_read "routing.friction_upgrade_threshold" "2")
    if [[ "$friction_count" -ge "$_fric_thresh" ]]; then
      log_info "[$task_type] $friction_count friction events — upgrading model"
      echo "sonnet"
      return
    fi
  fi

  # MMAS-inspired model selection: use pheromone evidence if available
  if type get_pheromone &>/dev/null 2>&1; then
    local haiku_score sonnet_score
    haiku_score=$(get_pheromone "$task_type" "haiku" 2>/dev/null || echo 0)
    sonnet_score=$(get_pheromone "$task_type" "sonnet" 2>/dev/null || echo 0)

    # If both have data, use evidence-based routing
    if [[ "$haiku_score" != "0" && "$sonnet_score" != "0" ]]; then
      local use_sonnet
      local _p_min=$(config_read "routing.pheromone_prob_min" "0.10")
      local _p_max=$(config_read "routing.pheromone_prob_max" "0.90")
      local _p_thresh=$(config_read "routing.pheromone_sonnet_threshold" "0.60")
      use_sonnet=$(awk -v h="$haiku_score" -v s="$sonnet_score" -v pmin="$_p_min" -v pmax="$_p_max" -v pt="$_p_thresh" 'BEGIN {
        p = s / (h + s);
        if (p < pmin) p = pmin;
        if (p > pmax) p = pmax;
        print (p >= pt) ? 1 : 0
      }')
      if [[ "$use_sonnet" == "1" ]]; then
        log_info "[$task_type] Pheromone routing → sonnet (h=$haiku_score, s=$sonnet_score)"
        echo "sonnet"
        return
      fi
    fi
  fi

  # Upgrade on retry 1+ (escalate early — haiku retries waste budget)
  if [[ $retry_count -ge 1 ]]; then
    case "$DEFAULT_MODEL" in
      haiku)  echo "sonnet" ;;
      sonnet) echo "sonnet" ;;  # Don't auto-upgrade to opus (cost)
      *)      echo "$DEFAULT_MODEL" ;;
    esac
    return
  fi

  # Default model selection
  echo "$DEFAULT_MODEL"
}

# ============================================================================
# NEGATIVE PHEROMONE — Active repulsion via blacklist
# ============================================================================

# Read blacklist entries and return constraints
# Args: blueprint_runtime_dir
# Returns: pipe-separated constraints (severity|type|pattern|id)
apply_negative_pheromone() {
  local runtime_dir="${1:-}"
  local global_blacklist="$ORCHESTRATOR_DIR/global_blacklist.jsonl"
  local blueprint_blacklist="${runtime_dir}/blacklist.jsonl"

  local constraints_hard=""
  local constraints_soft=""

  # Process blacklist files
  for bl_file in "$global_blacklist" "$blueprint_blacklist"; do
    [[ ! -f "$bl_file" ]] && continue

    while IFS= read -r line; do
      [[ -z "$line" || "$line" == "#"* ]] && continue

      local severity pattern bl_type bl_id ttl_days source
      severity=$(echo "$line" | jq -r '.severity // 0' 2>/dev/null | tr -d '\r')
      pattern=$(echo "$line" | jq -r '.pattern // ""' 2>/dev/null | tr -d '\r')
      bl_type=$(echo "$line" | jq -r '.type // "unknown"' 2>/dev/null | tr -d '\r')
      bl_id=$(echo "$line" | jq -r '.id // "anon"' 2>/dev/null | tr -d '\r')
      ttl_days=$(echo "$line" | jq -r ".ttl_days // $(config_read "routing.blacklist_ttl_days" "90")" 2>/dev/null | tr -d '\r')
      source=$(echo "$line" | jq -r '.source // ""' 2>/dev/null | tr -d '\r')

      # Check TTL expiry
      local created_at
      created_at=$(echo "$line" | jq -r '.created_at // ""' 2>/dev/null | tr -d '\r')
      if [[ -n "$created_at" ]] && _is_blacklist_expired "$created_at" "$ttl_days"; then
        log_debug "Negative pheromone: skipping expired entry $bl_id (created $created_at, ttl $ttl_days days)"
        continue
      fi

      [[ -z "$pattern" ]] && continue

      # Severity 4-5: mechanical/hard constraints (auto-reject)
      # Severity 1-3: cognitive/soft constraints (injected as warnings)
      local _hard_sev=$(config_read "routing.pheromone_hard_severity" "4")
      if [[ $severity -ge $_hard_sev ]]; then
        constraints_hard="${constraints_hard}${severity}|${bl_type}|${pattern}|${bl_id}\n"
      else
        constraints_soft="${constraints_soft}${severity}|${bl_type}|${pattern}|${bl_id}\n"
      fi
    done < "$bl_file"
  done

  # Output hard constraints to stdout (for mechanical blocking)
  if [[ -n "$constraints_hard" ]]; then
    echo -e "$constraints_hard" | grep -v '^$'
  fi

  # Output soft constraints to fd 3 if open (for context injection)
  if [[ -n "$constraints_soft" ]]; then
    echo -e "$constraints_soft" | grep -v '^$' >&3 2>/dev/null || true
  fi
}

# Check if a blacklist entry has expired
_is_blacklist_expired() {
  local created_at="$1"
  local ttl_days="$2"

  # Portable date comparison
  local now_epoch created_epoch expiry_epoch
  if command -v date &>/dev/null; then
    now_epoch=$(date +%s 2>/dev/null || echo "0")
    # Try GNU date first, then fallback
    created_epoch=$(date -d "$created_at" +%s 2>/dev/null || echo "0")
    if [[ "$created_epoch" == "0" && "$PLATFORM" == "windows" ]]; then
      # On Windows/MSYS, try parsing ISO date manually
      local date_part="${created_at%%T*}"
      created_epoch=$(date -d "$date_part" +%s 2>/dev/null || echo "0")
    fi

    if [[ "$created_epoch" != "0" && "$now_epoch" != "0" ]]; then
      expiry_epoch=$((created_epoch + ttl_days * 86400))
      [[ $now_epoch -gt $expiry_epoch ]] && return 0
    fi
  fi

  return 1
}

# Check output against hard blacklist constraints
# Returns 0 if clean, 1 if blacklist violation found
check_blacklist_violations() {
  local output_file="$1"
  local runtime_dir="$2"

  [[ ! -f "$output_file" ]] && return 0

  local violations=""
  local hard_constraints
  hard_constraints=$(apply_negative_pheromone "$runtime_dir" 3>/dev/null)

  while IFS='|' read -r severity bl_type pattern bl_id; do
    [[ -z "$pattern" ]] && continue
    if grep -qE "$pattern" "$output_file" 2>/dev/null; then
      violations="${violations}BLACKLIST_VIOLATION: id=$bl_id type=$bl_type pattern=$pattern severity=$severity\n"
      log_warn "Negative pheromone: blacklist violation in output — $bl_id ($pattern)"
    fi
  done <<< "$hard_constraints"

  if [[ -n "$violations" ]]; then
    log_event "{\"ts\":\"$(now_iso)\",\"event\":\"blacklist_violation\",\"file\":\"$output_file\",\"violations\":\"$(echo -e "$violations" | head -3 | tr '\n' '; ')\"}"
    return 1
  fi

  return 0
}
