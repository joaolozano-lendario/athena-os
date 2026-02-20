#!/usr/bin/env bash
# advisory.sh — Strategic coherence advisory between execution waves
# Spawns advisor worker, processes recommendations, adjusts blueprint

[[ -n "${_ADVISORY_SH_LOADED:-}" ]] && return 0
_ADVISORY_SH_LOADED=1

# Run advisory review between waves
# Assembles context, spawns advisor, parses structured output
run_advisory() {
  local blueprint_id="$1"
  local wave_num="$2"
  local advisory_model="${3:-sonnet}"

  if [[ "$ADVISORY_ENABLED" != "true" ]]; then
    log_debug "Advisory disabled (small colony) — skipping"
    return 0
  fi

  log_info "Running advisory review after wave $wave_num"

  local advisory_dir="$RUNTIME_DIR/advisory"
  mkdir -p "$advisory_dir"

  # Assemble advisory context
  local context_file="$advisory_dir/wave-${wave_num}-context.md"
  _assemble_advisory_context "$wave_num" "$context_file"

  # Build advisor identity
  local advisor_identity
  advisor_identity="$(cat "$ORCHESTRATOR_DIR/workers/_base.md")"$'\n\n'"$(cat "$ORCHESTRATOR_DIR/workers/advisor.md")"

  # Spawn advisor
  local response_file="$advisory_dir/wave-${wave_num}-response.json"
  local advisor_log="$advisory_dir/wave-${wave_num}.log"

  cat "$context_file" | \
    env -u CLAUDECODE claude -p \
      --append-system-prompt "$advisor_identity" \
      --model "$advisory_model" \
      --max-budget-usd "$(config_read "advisory.max_budget_usd" "0.30")" \
      --tools "Read,Grep,Glob" \
      --setting-sources "" \
      --output-format json \
      --json-schema "$(cat "$ORCHESTRATOR_DIR/schemas/advisory-review.json")" \
      --no-session-persistence \
      --dangerously-skip-permissions \
      2>"$advisor_log" | tr -d '\r' > "$response_file" || true

  # Extract cost with real token counts
  local cost
  cost=$(extract_cost_from_response "$response_file" "$advisory_model")
  local adv_tokens
  adv_tokens=$(extract_tokens_from_response "$response_file" 2>/dev/null || echo "0 0")
  local adv_input adv_output
  adv_input=$(echo "$adv_tokens" | cut -d' ' -f1)
  adv_output=$(echo "$adv_tokens" | cut -d' ' -f2)
  record_cost "advisory-wave-$wave_num" "1" "${cost:-0}" "$advisory_model" "${adv_input:-0}" "${adv_output:-0}" "advisory"

  # Parse structured output
  local coherence quality_trend
  coherence=$(jq -r '.structured_output.coherence_score // 7' "$response_file" 2>/dev/null | tr -d '\r')
  quality_trend=$(jq -r '.structured_output.quality_trend // "stable"' "$response_file" 2>/dev/null | tr -d '\r')

  # Log to advisory reviews
  local review_entry
  review_entry=$(jq -c '.structured_output // {}' "$response_file" 2>/dev/null | tr -d '\r')
  append_jsonl "${TELEMETRY_DIR:-$RUNTIME_DIR}/advisory_reviews.jsonl" "{\"ts\":\"$(now_iso)\",\"wave\":$wave_num,\"review\":$review_entry}"

  log_info "Advisory: coherence=$coherence, trend=$quality_trend"
  log_event "{\"ts\":\"$(now_iso)\",\"event\":\"advisory_complete\",\"wave\":$wave_num,\"coherence\":$coherence,\"trend\":\"$quality_trend\"}"

  return 0
}

# Process advisory recommendations and apply adjustments
apply_advisory() {
  local wave_num="$1"

  local response_file="$RUNTIME_DIR/advisory/wave-${wave_num}-response.json"
  [[ ! -f "$response_file" ]] && return 0

  local coherence
  coherence=$(jq -r '.structured_output.coherence_score // 7' "$response_file" 2>/dev/null | tr -d '\r')

  # S2.2 + S3.1: Thresholds from manifest → config → hardcoded defaults
  local _cfg_pause=$(config_read "advisory.coherence_pause" "5")
  local _cfg_cancel=$(config_read "advisory.coherence_cancel" "3")
  local _cfg_minw=$(config_read "advisory.min_wave" "2")
  local _cfg_floor=$(config_read "advisory.pass_rate_floor" "50")
  local coherence_pause coherence_cancel min_wave pass_rate_floor
  coherence_pause=$(yq -r ".advisory.coherence_pause // $_cfg_pause" "$MANIFEST" 2>/dev/null | tr -d '\r')
  coherence_cancel=$(yq -r ".advisory.coherence_cancel // $_cfg_cancel" "$MANIFEST" 2>/dev/null | tr -d '\r')
  min_wave=$(yq -r ".advisory.min_wave // $_cfg_minw" "$MANIFEST" 2>/dev/null | tr -d '\r')
  pass_rate_floor=$(yq -r ".advisory.pass_rate_floor // $_cfg_floor" "$MANIFEST" 2>/dev/null | tr -d '\r')
  # Ensure numeric defaults
  [[ ! "$coherence_pause" =~ ^[0-9]+$ ]] && coherence_pause=$_cfg_pause
  [[ ! "$coherence_cancel" =~ ^[0-9]+$ ]] && coherence_cancel=$_cfg_cancel
  [[ ! "$min_wave" =~ ^[0-9]+$ ]] && min_wave=$_cfg_minw
  [[ ! "$pass_rate_floor" =~ ^[0-9]+$ ]] && pass_rate_floor=$_cfg_floor

  # S2.2: CANCEL check — coherence < cancel_threshold for 3 consecutive waves
  if [[ "$coherence" -lt "$coherence_cancel" && "$wave_num" -ge 3 ]]; then
    local cancel_count=1
    local i
    for i in 1 2; do
      local prev_file="$RUNTIME_DIR/advisory/wave-$((wave_num - i))-response.json"
      local prev_coh
      prev_coh=$(jq -r '.structured_output.coherence_score // 7' "$prev_file" 2>/dev/null | tr -d '\r')
      [[ "${prev_coh:-7}" -lt "$coherence_cancel" ]] && ((cancel_count++)) || true
    done
    if [[ $cancel_count -ge 3 ]]; then
      log_error "Advisory: coherence=$coherence < $coherence_cancel for 3 consecutive waves — CANCELLING"
      log_event "{\"ts\":\"$(now_iso)\",\"event\":\"advisory_cancel\",\"wave\":$wave_num,\"coherence\":$coherence,\"consecutive\":3}"
      # Generate partial report before cancelling
      generate_execution_report 2>/dev/null || true
      set_blueprint_status "cancelled"
      return 2
    fi
  fi

  # Coherence < pause threshold: proportional signal with guards (C2)
  if [[ "$coherence" -lt "$coherence_pause" ]]; then
    local should_pause=false
    if [[ "$wave_num" -ge "$min_wave" ]]; then
      local _c2_completed _c2_failed _c2_total _c2_pass_rate
      _c2_completed=$(state_read '.counters.completed' 2>/dev/null || echo "0")
      _c2_failed=$(state_read '.counters.failed' 2>/dev/null || echo "0")
      _c2_total=$((_c2_completed + _c2_failed)); [[ $_c2_total -eq 0 ]] && _c2_total=1
      _c2_pass_rate=$((_c2_completed * 100 / _c2_total))
      if [[ $_c2_pass_rate -le "$pass_rate_floor" ]]; then
        local _c2_prev
        _c2_prev=$(jq -r '.structured_output.coherence_score // 7' \
          "$RUNTIME_DIR/advisory/wave-$((wave_num - 1))-response.json" 2>/dev/null | tr -d '\r')
        [[ "${_c2_prev:-7}" -lt "$coherence_pause" ]] && should_pause=true
      fi
    fi
    if $should_pause; then
      log_warn "Advisory: coherence=$coherence (2nd consecutive < $coherence_pause, pass_rate≤${pass_rate_floor}%) — PAUSING"
      log_event "{\"ts\":\"$(now_iso)\",\"event\":\"advisory_pause\",\"wave\":$wave_num,\"coherence\":$coherence}"
      # Generate partial report before pausing
      generate_execution_report 2>/dev/null || true
      set_blueprint_status "paused"
      return 1
    else
      log_info "Advisory: coherence=$coherence < $coherence_pause — guards prevent pause (wave=$wave_num)"
    fi
  fi

  # Coherence < adjustment threshold: apply adjustments
  local _adj_thresh=$(config_read "advisory.adjustment_threshold" "7")
  if [[ "$coherence" -lt "$_adj_thresh" ]]; then
    log_info "Advisory: coherence=$coherence < $_adj_thresh — applying adjustments"

    local upgrade_model
    upgrade_model=$(jq -r '.structured_output.adjustments.upgrade_model // false' "$response_file" 2>/dev/null | tr -d '\r')
    if [[ "$upgrade_model" == "true" && "$DEFAULT_MODEL" == "haiku" ]]; then
      local prev_model="$DEFAULT_MODEL"
      DEFAULT_MODEL="sonnet"
      log_info "Advisory adjustment: upgraded default model to sonnet"
      _log_decision "advisory_model_upgrade" "$BLUEPRINT_ID" "{\"coherence\":$coherence,\"wave\":$wave_num}" "sonnet" "Advisory coherence < 7 triggered model upgrade" "$prev_model" 2>/dev/null || true
    fi

    local increase_qa
    increase_qa=$(jq -r '.structured_output.adjustments.increase_qa_threshold // false' "$response_file" 2>/dev/null | tr -d '\r')
    if [[ "$increase_qa" == "true" ]]; then
      local prev_threshold="$QA_THRESHOLD"
      local _qa_step=$(config_read "advisory.qa_threshold_step" "5")
      local _qa_cap=$(config_read "advisory.qa_threshold_cap" "95")
      QA_THRESHOLD=$((QA_THRESHOLD + _qa_step))
      [[ $QA_THRESHOLD -gt $_qa_cap ]] && QA_THRESHOLD=$_qa_cap
      log_info "Advisory adjustment: increased QA threshold to $QA_THRESHOLD"
      _log_decision "advisory_qa_threshold" "$BLUEPRINT_ID" "{\"coherence\":$coherence,\"wave\":$wave_num}" "$QA_THRESHOLD" "Advisory coherence < 7 increased QA threshold +5" "$prev_threshold" 2>/dev/null || true
    fi
  fi

  return 0
}

# Internal: Assemble context for advisory review
_assemble_advisory_context() {
  local wave_num="$1"
  local output_file="$2"

  {
    echo "# ADVISORY REVIEW REQUEST"
    echo ""
    echo "## Blueprint State"
    echo ""
    echo "Blueprint: $BLUEPRINT_ID"
    echo "Wave just completed: $wave_num"
    echo ""

    # Blueprint progress
    local completed failed total
    completed=$(state_read '.counters.completed' 2>/dev/null || echo "0")
    failed=$(state_read '.counters.failed' 2>/dev/null || echo "0")
    total=$(state_read '.counters.total' 2>/dev/null || echo "0")
    echo "Progress: $completed/$total completed, $failed failed"
    echo ""

    # Recent task results (last 5)
    echo "## Recent Task Results"
    echo ""
    state_read '.tasks | to_entries | sort_by(.value.completed_at // .value.started_at // "") | reverse | .[:5][] | "\(.key): status=\(.value.status), score=\(.value.score // "n/a"), attempts=\(.value.attempts)"' 2>/dev/null || echo "(no task data)"
    echo ""

    # Recent QA feedback
    echo "## Recent QA Feedback"
    echo ""
    if [[ -f "$EVENTS_FILE" ]]; then
      local _qa_ctx=$(config_read "advisory.context_recent_qa_count" "5")
      grep '"qa_verdict"' "$EVENTS_FILE" | tail -"$_qa_ctx" | while IFS= read -r line; do
        local tid score verdict
        tid=$(echo "$line" | jq -r '.task_id' 2>/dev/null | tr -d '\r')
        score=$(echo "$line" | jq -r '.score' 2>/dev/null | tr -d '\r')
        verdict=$(echo "$line" | jq -r '.verdict' 2>/dev/null | tr -d '\r')
        echo "- $tid: $verdict (score $score)"
      done
    fi
    echo ""

    # Demand signals (from colony/trophallaxis)
    if [[ -f "$RUNTIME_DIR/demand_signals.json" ]]; then
      echo "## Demand Signals (Colony)"
      echo ""
      jq -r '.[] | "- \(.signal) (count: \(.count))"' "$RUNTIME_DIR/demand_signals.json" 2>/dev/null || true
      echo ""
    fi

    # Completed task outputs (summaries)
    echo "## Completed Task Outputs (summaries)"
    echo ""
    local completed_tids
    completed_tids=$(state_read '[.tasks | to_entries[] | select(.value.status == "completed") | .key] | .[]' 2>/dev/null) || true
    for tid in $completed_tids; do
      local out_path
      out_path=$(task_get "$tid" "output" 2>/dev/null) || continue
      [[ -z "$out_path" || "$out_path" == "null" ]] && continue
      [[ -n "$PROJECT_DIR" && ! -f "$out_path" ]] && out_path="$PROJECT_DIR/$out_path"
      [[ -f "$out_path" ]] || continue
      echo "### $tid"
      local _preview_lines=$(config_read "advisory.context_output_preview_lines" "30")
      head -"$_preview_lines" "$out_path" 2>/dev/null
      echo "..."
      echo ""
    done

    # Friction events
    echo "## Recent Friction Events"
    echo ""
    if [[ -f "$RUNTIME_DIR/friction_events.jsonl" ]]; then
      local _fric_ctx=$(config_read "advisory.context_recent_friction_count" "10")
      tail -"$_fric_ctx" "$RUNTIME_DIR/friction_events.jsonl" 2>/dev/null
    else
      echo "(none)"
    fi
    echo ""

    echo "## Your Task"
    echo ""
    echo "Assess cross-task coherence, identify emerging risks, and recommend adjustments."
    echo "Return your assessment as structured JSON per the advisory-review schema."
  } > "$output_file"
}
