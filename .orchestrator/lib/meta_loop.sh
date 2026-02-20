#!/usr/bin/env bash
# meta_loop.sh — Meta-loop orchestration with quorum sensing
# Biomimetic patterns: Quorum Sensing (Pattern 3), Trophallaxis demand (Pattern 2)
# Cycle: forge → execute → learn → re-forge (max 2 auto cycles)

[[ -n "${_META_LOOP_SH_LOADED:-}" ]] && return 0
_META_LOOP_SH_LOADED=1

# ============================================================================
# QUORUM SENSING (Pattern 3) — Multi-source meta-loop decision
# ============================================================================

# Compute composite quorum signal from 4 sources
# Returns: pipe-delimited "composite|qa|advisory|colony|structural|disagreement"
compute_quorum_signal() {
  local runtime_dir="${1:-$RUNTIME_DIR}"

  # Source 1: QA scores (weight 0.40)
  local qa_signal=0.5
  local qa_scores
  qa_scores=$(state_read '[.tasks | to_entries[] | select(.value.score != null) | .value.score] | if length > 0 then (add / length / 100) else 0.5 end' 2>/dev/null || echo "0.5")
  qa_signal=$(echo "$qa_scores" | tr -d '\r')

  # Source 2: Advisory coherence (weight 0.25)
  local advisory_signal=0.7  # Default: assume healthy
  local advisory_file="${TELEMETRY_DIR:-$runtime_dir/telemetry}/advisory_reviews.jsonl"
  if [[ -f "$advisory_file" ]]; then
    local last_coherence
    last_coherence=$(tail -1 "$advisory_file" 2>/dev/null | jq -r '.review.coherence_score // 7' 2>/dev/null | tr -d '\r')
    advisory_signal=$(awk -v c="$last_coherence" 'BEGIN { printf "%.2f", c / 10 }')
  fi

  # Source 3: Colony sentiment (weight 0.15) — warning ratio from colony signals
  local colony_signal=0.7  # Default: neutral-positive
  if [[ -f "$runtime_dir/colony_signals.jsonl" ]]; then
    local total_signals warning_signals
    total_signals=$(jq -s 'length' "$runtime_dir/colony_signals.jsonl" 2>/dev/null || echo "0")
    warning_signals=$(jq -s '[.[] | select(.type == "warning" or .type == "risk")] | length' "$runtime_dir/colony_signals.jsonl" 2>/dev/null || echo "0")
    if [[ "$total_signals" -gt 0 ]]; then
      colony_signal=$(awk -v t="$total_signals" -v w="$warning_signals" 'BEGIN { printf "%.2f", 1 - (w / t) }')
    fi
  fi

  # Source 4: Structural health (weight 0.20) — failure + retry ratio
  local structural_signal=0.8
  local total_tasks completed_tasks failed_tasks
  total_tasks=$(state_read '.counters.total' 2>/dev/null || echo "1")
  completed_tasks=$(state_read '.counters.completed' 2>/dev/null || echo "0")
  failed_tasks=$(state_read '.counters.failed' 2>/dev/null || echo "0")
  [[ "$total_tasks" -eq 0 ]] && total_tasks=1
  structural_signal=$(awk -v c="$completed_tasks" -v f="$failed_tasks" -v t="$total_tasks" \
    'BEGIN { r = (c - f * 0.5) / t; if (r < 0) r = 0; if (r > 1) r = 1; printf "%.2f", r }')

  # Adjust weights based on advisory availability
  local w_qa w_adv w_col w_str
  if [[ "$ADVISORY_ENABLED" == "true" ]]; then
    w_qa=$(config_read "quorum.weight_qa" "0.40")
    w_adv=$(config_read "quorum.weight_advisory" "0.25")
    w_col=$(config_read "quorum.weight_colony" "0.15")
    w_str=$(config_read "quorum.weight_structural" "0.20")
  else
    w_qa=$(config_read "quorum.weight_qa_noadv" "0.50")
    w_adv=0.00
    w_col=$(config_read "quorum.weight_colony_noadv" "0.20")
    w_str=$(config_read "quorum.weight_structural_noadv" "0.30")
  fi

  # Compute weighted composite
  local composite
  composite=$(awk -v q="$qa_signal" -v a="$advisory_signal" -v c="$colony_signal" -v s="$structural_signal" \
    -v wq="$w_qa" -v wa="$w_adv" -v wc="$w_col" -v ws="$w_str" \
    'BEGIN { printf "%.4f", q*wq + a*wa + c*wc + s*ws }')

  # Apply sigmoid sharpening: 1/(1+e^(-k*(x-m)))
  local _sig_k=$(config_read "quorum.sigmoid_steepness" "12")
  local _sig_m=$(config_read "quorum.sigmoid_midpoint" "0.75")
  local sigmoid
  sigmoid=$(awk -v x="$composite" -v k="$_sig_k" -v m="$_sig_m" 'BEGIN { printf "%.4f", 1 / (1 + exp(-k * (x - m))) }')

  # Compute disagreement: max deviation between any two sources
  local disagreement
  disagreement=$(awk -v q="$qa_signal" -v a="$advisory_signal" -v c="$colony_signal" -v s="$structural_signal" \
    'BEGIN {
      max=0; vals[1]=q; vals[2]=a; vals[3]=c; vals[4]=s
      for(i=1;i<=4;i++) for(j=i+1;j<=4;j++) {
        d=vals[i]-vals[j]; if(d<0)d=-d; if(d>max)max=d
      }
      printf "%.2f", max
    }')

  echo "$sigmoid|$qa_signal|$advisory_signal|$colony_signal|$structural_signal|$disagreement"
}

# Interpret quorum signal and decide action
# Returns: DONE|TARGETED_RETRY|RE_EXECUTE|RE_FORGE|ESCALATE
quorum_decide() {
  local quorum_line="$1"
  local cycle="${2:-0}"
  local max_cycles="${3:-2}"
  local budget_pct="${4:-100}"

  local sigmoid qa_sig adv_sig col_sig str_sig disagreement
  IFS='|' read -r sigmoid qa_sig adv_sig col_sig str_sig disagreement <<< "$quorum_line"

  # Override conditions
  if command -v awk &>/dev/null; then
    local _dis_thresh=$(config_read "quorum.disagreement_threshold" "0.40")
    if (( $(awk -v d="$disagreement" -v t="$_dis_thresh" 'BEGIN { print (d > t) }') )); then
      log_info "Quorum: ESCALATE — disagreement=$disagreement > $_dis_thresh"
      echo "ESCALATE"
      return
    fi
  fi

  local _bud_esc=$(config_read "quorum.budget_escalate_pct" "20")
  if [[ "$budget_pct" -lt "$_bud_esc" ]]; then
    log_info "Quorum: ESCALATE — budget=$budget_pct% < ${_bud_esc}%"
    echo "ESCALATE"
    return
  fi

  # Cycle >= max: ESCALATE
  if [[ "$cycle" -ge "$max_cycles" ]]; then
    log_info "Quorum: ESCALATE — cycle=$cycle >= max=$max_cycles"
    echo "ESCALATE"
    return
  fi

  # Sigmoid-based decision
  if command -v awk &>/dev/null; then
    local _q_done=$(config_read "quorum.done_threshold" "0.90")
    local _q_retry=$(config_read "quorum.retry_threshold" "0.70")
    local _q_reexec=$(config_read "quorum.reexecute_threshold" "0.40")
    if (( $(awk -v s="$sigmoid" -v t="$_q_done" 'BEGIN { print (s >= t) }') )); then
      log_info "Quorum: DONE — sigmoid=$sigmoid >= $_q_done"
      echo "DONE"
    elif (( $(awk -v s="$sigmoid" -v t="$_q_retry" 'BEGIN { print (s >= t) }') )); then
      log_info "Quorum: TARGETED_RETRY — sigmoid=$sigmoid >= $_q_retry"
      echo "TARGETED_RETRY"
    elif (( $(awk -v s="$sigmoid" -v t="$_q_reexec" 'BEGIN { print (s >= t) }') )); then
      log_info "Quorum: RE_EXECUTE — sigmoid=$sigmoid >= $_q_reexec"
      echo "RE_EXECUTE"
    else
      log_info "Quorum: RE_FORGE — sigmoid=$sigmoid < 0.40"
      echo "RE_FORGE"
    fi
  else
    # Fallback: use qa_signal as simple proxy
    local qa_pct
    qa_pct=$(awk -v q="$qa_sig" 'BEGIN { printf "%d", q * 100 }')
    if [[ $qa_pct -ge 85 ]]; then echo "DONE"
    elif [[ $qa_pct -ge 70 ]]; then echo "TARGETED_RETRY"
    elif [[ $qa_pct -ge 50 ]]; then echo "RE_EXECUTE"
    else echo "RE_FORGE"
    fi
  fi
}

# ============================================================================
# META-LOOP CYCLE MANAGEMENT
# ============================================================================

# Run meta-loop: execute blueprint, evaluate, decide next action
# Wraps run_blueprint with iterative improvement
run_meta_loop() {
  local max_cycles="${1:-2}"

  # S2.4: Wall-clock timeout — read from manifest, fallback 3600s (1h)
  local max_wall_clock
  local _wc_default=$(config_read "orchestration.wall_clock_timeout_s" "3600")
  max_wall_clock=$(yq -r ".meta_loop.max_wall_clock_seconds // $_wc_default" "$MANIFEST" 2>/dev/null | tr -d '\r')
  [[ ! "$max_wall_clock" =~ ^[0-9]+$ ]] && max_wall_clock=$_wc_default
  local start_time
  start_time=$(date +%s)

  local cycle=0

  while [[ $cycle -lt $max_cycles ]]; do
    # S2.4: Check wall-clock before each cycle
    local elapsed=$(( $(date +%s) - start_time ))
    if [[ $elapsed -gt $max_wall_clock ]]; then
      log_error "Meta-loop: wall-clock timeout (${elapsed}s > ${max_wall_clock}s) — ESCALATE"
      log_event "{\"ts\":\"$(now_iso)\",\"event\":\"meta_loop_timeout\",\"cycle\":$cycle,\"elapsed\":$elapsed,\"max\":$max_wall_clock}"
      generate_execution_report 2>/dev/null || true
      return 1
    fi

    log_info "=== META-LOOP CYCLE $((cycle + 1))/$max_cycles (elapsed: ${elapsed}s/${max_wall_clock}s) ==="

    # Execute blueprint
    run_blueprint

    # Generate report
    generate_report

    # Detect demand signals
    detect_demand_signals

    # Compute quorum
    local quorum_line
    quorum_line=$(compute_quorum_signal)
    log_info "Quorum signal: $quorum_line"

    # Budget percentage
    local used_usd limit_usd budget_pct
    used_usd=$(state_read '.budget.used_usd' 2>/dev/null || echo "0")
    limit_usd=$(state_read '.budget.limit_usd' 2>/dev/null || echo "50")
    budget_pct=$(awk -v u="$used_usd" -v l="$limit_usd" 'BEGIN { if (l>0) printf "%d", (1 - u/l) * 100; else print 100 }')

    # Decide
    local verdict
    verdict=$(quorum_decide "$quorum_line" "$cycle" "$max_cycles" "$budget_pct")

    log_event "{\"ts\":\"$(now_iso)\",\"event\":\"meta_loop_verdict\",\"cycle\":$cycle,\"verdict\":\"$verdict\",\"quorum\":\"$quorum_line\"}"

    case "$verdict" in
      DONE)
        log_info "Meta-loop: DONE — blueprint quality sufficient"
        return 0
        ;;
      TARGETED_RETRY)
        log_info "Meta-loop: TARGETED_RETRY — re-executing failed tasks only"
        targeted_retry
        ((cycle++)) || true
        ;;
      RE_EXECUTE)
        log_info "Meta-loop: RE_EXECUTE — re-executing all tasks with adjustments"
        re_execute
        ((cycle++)) || true
        ;;
      RE_FORGE)
        log_info "Meta-loop: RE_FORGE — spawning forger for new blueprint YAML"
        # RE_FORGE is complex — for now, escalate
        log_warn "RE_FORGE not yet implemented — escalating to operator"
        return 1
        ;;
      ESCALATE)
        log_warn "Meta-loop: ESCALATE — operator intervention required"
        return 1
        ;;
    esac
  done

  log_info "Meta-loop: max cycles reached ($max_cycles)"
  return 0
}

# Re-execute only failed tasks
targeted_retry() {
  local failed_tasks
  failed_tasks=$(state_read '[.tasks | to_entries[] | select(.value.status == "rejected" or .value.status == "exhausted") | .key] | .[]' 2>/dev/null || echo "")

  if [[ -z "$failed_tasks" ]]; then
    log_info "No failed tasks to retry"
    return 0
  fi

  for tid in $failed_tasks; do
    log_info "Targeted retry: resetting $tid to pending"
    task_set_status "$tid" "pending"
    task_set_field "$tid" "attempts" "0"
  done

  set_blueprint_status "running"
}

# Re-execute all tasks with fresh state
re_execute() {
  local all_tasks
  all_tasks=$(state_read '.tasks | keys[]' 2>/dev/null || echo "")

  for tid in $all_tasks; do
    local status
    status=$(task_get "$tid" "status")
    # Only reset non-completed tasks
    if [[ "$status" != "completed" ]]; then
      task_set_status "$tid" "pending"
      task_set_field "$tid" "attempts" "0"
    fi
  done

  set_blueprint_status "running"
}

# ============================================================================
# DEMAND SIGNAL DETECTION (Trophallaxis Pattern 2)
# ============================================================================

# Analyze colony signals for repeated warnings → demand signals
detect_demand_signals() {
  local signals_file="$RUNTIME_DIR/colony_signals.jsonl"
  local demand_file="$RUNTIME_DIR/demand_signals.json"

  [[ ! -f "$signals_file" ]] && return 0

  # Count warnings with similar keywords (simplified: group by type=warning)
  local warning_count
  warning_count=$(jq -s '[.[] | select(.type == "warning")] | length' "$signals_file" 2>/dev/null || echo "0")

  local _demand_thresh=$(config_read "quorum.demand_signal_threshold" "3")
  local _demand_min=$(config_read "quorum.demand_group_min" "2")
  if [[ "$warning_count" -ge "$_demand_thresh" ]]; then
    jq -s '[.[] | select(.type == "warning")] |
      group_by(.signal | split(" ") | .[0:3] | join(" ")) |
      map({signal: .[0].signal, count: length}) |
      sort_by(-.count) |
      [.[] | select(.count >= '"$_demand_min"')]' "$signals_file" 2>/dev/null > "$demand_file" || true

    local demand_count
    demand_count=$(jq 'length' "$demand_file" 2>/dev/null || echo "0")
    if [[ "$demand_count" -gt 0 ]]; then
      log_info "Demand signals detected: $demand_count patterns from colony warnings"
    fi
  fi
}
