#!/usr/bin/env bash
# meta_report.sh — F3 SYNTHESIZE for FORMICA v3.0
# Generates 3-layer diagnostics + handoff for P6 + immune/pattern staging

[[ -n "${_META_REPORT_SH_LOADED:-}" ]] && return 0
_META_REPORT_SH_LOADED=1

# ============================================================================
# MAIN META-REPORT GENERATOR
# ============================================================================

generate_meta_report() {
  local report_file="${REPORTS_DIR:-$RUNTIME_DIR/reports}/execution-report.md"
  local diagnostic_file="${REPORTS_DIR:-$RUNTIME_DIR/reports}/diagnostic.md"
  local json_file="${REPORTS_DIR:-$RUNTIME_DIR/reports}/diagnostic.json"
  local handoff_file="${REPORTS_DIR:-$RUNTIME_DIR/reports}/handoff.yaml"

  # Create reports directory if not exists
  mkdir -p "${REPORTS_DIR:-$RUNTIME_DIR/reports}" 2>/dev/null || true

  # Generate diagnostic.json (L1+L2+L3)
  generate_diagnostic_json "$json_file" || echo "(diagnostic.json generation error)"

  # Generate handoff.yaml for P6
  generate_handoff_yaml "$handoff_file" || echo "(handoff.yaml generation error)"

  # Promote immune patterns (conservative)
  promote_immune_patterns || echo "(immune promotion error)"

  # Stage pattern candidates for P6 review
  stage_pattern_candidates || echo "(pattern staging error)"

  # Generate human-readable diagnostic (legacy, optional)
  {
    echo "# Diagnostic Report: $BLUEPRINT_ID"
    echo ""
    echo "Generated: $(now_iso)"
    echo ""

    # Layer 1: Blueprint diagnostics (zero API cost)
    _meta_layer1_diagnostics || echo "(Layer 1 diagnostic error)"

    # Layer 2: Friction analysis (zero API cost)
    _meta_layer2_friction || echo "(Layer 2 friction error)"

    # Layer 3: System evolution (haiku call)
    _meta_layer3_evolution "$json_file" || echo "(Layer 3 evolution error)"

  } > "$diagnostic_file" 2>/dev/null || true

  log_info "Meta-report generated: $diagnostic_file, $json_file, $handoff_file"
}

# ============================================================================
# DIAGNOSTIC.JSON (for P6) — 3 Layers
# ============================================================================

generate_diagnostic_json() {
  local output_file="${1:-${REPORTS_DIR:-$RUNTIME_DIR/reports}/diagnostic.json}"

  local telemetry_dir="${TELEMETRY_DIR:-$RUNTIME_DIR}"
  local state_file="${STATE_FILE:-$RUNTIME_DIR/state.json}"

  # Layer 1: Score distribution + cost breakdown (deterministic)
  local l1_scores l1_cost
  l1_scores=$(_diagnostic_l1_scores "$state_file" 2>/dev/null || echo '{}')
  l1_cost=$(_diagnostic_l1_cost "$telemetry_dir" 2>/dev/null || echo '{}')

  # Layer 2: Friction analysis + systemic issues (deterministic)
  local l2_friction
  l2_friction=$(_diagnostic_l2_friction "$telemetry_dir" 2>/dev/null || echo '{}')

  # Layer 3: System evolution assessment (1 haiku call, ~$0.02)
  local l3_evolution
  l3_evolution=$(_diagnostic_l3_evolution "$state_file" "$telemetry_dir" 2>/dev/null || echo '{}')

  # Combine all layers
  jq -n \
    --argjson l1_scores "$l1_scores" \
    --argjson l1_cost "$l1_cost" \
    --argjson l2_friction "$l2_friction" \
    --argjson l3_evolution "$l3_evolution" \
    '{
      layer1: {
        scores: $l1_scores,
        cost: $l1_cost
      },
      layer2: $l2_friction,
      layer3: $l3_evolution,
      generated_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
    }' > "$output_file" 2>/dev/null || echo '{}' > "$output_file"

  log_info "Diagnostic JSON generated: $output_file"
}

_diagnostic_l1_scores() {
  local state_file="$1"
  [[ ! -f "$state_file" ]] && echo '{}' && return

  local task_ids
  task_ids=$(jq -r '.tasks | keys[]' "$state_file" 2>/dev/null | tr -d '\r')

  local bucket_0_59=0 bucket_60_69=0 bucket_70_79=0 bucket_80_89=0 bucket_90_100=0
  for tid in $task_ids; do
    [[ -z "$tid" ]] && continue
    local score
    score=$(jq -r ".tasks[\"$tid\"].score // empty" "$state_file" 2>/dev/null | tr -d '\r')
    [[ "$score" == "null" || -z "$score" ]] && continue
    [[ ! "$score" =~ ^[0-9]+$ ]] && continue
    if [[ $score -ge 90 ]]; then ((bucket_90_100++)) || true
    elif [[ $score -ge 80 ]]; then ((bucket_80_89++)) || true
    elif [[ $score -ge 70 ]]; then ((bucket_70_79++)) || true
    elif [[ $score -ge 60 ]]; then ((bucket_60_69++)) || true
    else ((bucket_0_59++)) || true
    fi
  done

  jq -n \
    --argjson b0 "$bucket_0_59" \
    --argjson b1 "$bucket_60_69" \
    --argjson b2 "$bucket_70_79" \
    --argjson b3 "$bucket_80_89" \
    --argjson b4 "$bucket_90_100" \
    '{
      "0-59": $b0,
      "60-69": $b1,
      "70-79": $b2,
      "80-89": $b3,
      "90-100": $b4
    }'
}

_diagnostic_l1_cost() {
  local telemetry_dir="$1"
  local cost_file="$telemetry_dir/cost.jsonl"
  [[ ! -f "$cost_file" ]] && echo '{}' && return

  jq -s 'group_by(.model) | map({model: .[0].model, tasks: length, cost_usd: (map(.cost_usd) | add)}) | map({(.model): {tasks: .tasks, cost_usd: .cost_usd}}) | add // {}' \
    "$cost_file" 2>/dev/null || echo '{}'
}

_diagnostic_l2_friction() {
  local telemetry_dir="$1"
  local friction_file="$telemetry_dir/friction_events.jsonl"
  [[ ! -f "$friction_file" || ! -s "$friction_file" ]] && echo '{}' && return

  # Get summary using friction.sh if available
  if type get_friction_summary &>/dev/null; then
    get_friction_summary 2>/dev/null || echo '{}'
  else
    # Fallback: basic analysis
    jq -s '{
      total: length,
      causes: (group_by(.cause) | map({(..[0].cause): length}) | add // {}),
      worker_types: (group_by(.worker_type) | map({(..[0].worker_type): length}) | add // {})
    }' "$friction_file" 2>/dev/null || echo '{}'
  fi
}

_diagnostic_l3_evolution() {
  local state_file="$1"
  local telemetry_dir="$2"
  local schema_file="$ORCHESTRATOR_DIR/schemas/meta-report.json"

  [[ ! -f "$schema_file" ]] && echo '{}' && return
  [[ ! -f "$state_file" ]] && echo '{}' && return

  # Build context
  local context=""
  context+="Blueprint: ${BLUEPRINT_ID:-unknown}\n"
  local _completed _total _failed _used _limit
  _completed=$(jq -r '.counters.completed // 0' "$state_file" 2>/dev/null | tr -d '\r')
  _total=$(jq -r '.counters.total // 0' "$state_file" 2>/dev/null | tr -d '\r')
  _failed=$(jq -r '.counters.failed // 0' "$state_file" 2>/dev/null | tr -d '\r')
  _used=$(jq -r '.budget.used_usd // 0' "$state_file" 2>/dev/null | tr -d '\r')
  _limit=$(jq -r '.budget.limit_usd // 0' "$state_file" 2>/dev/null | tr -d '\r')
  context+="Tasks: ${_completed}/${_total} completed\n"
  context+="Failed: ${_failed}\n"
  context+="Cost: \$${_used}/\$${_limit}\n"

  # Add rejection details (FIX 2) — pass factual failure info to L3 agent
  local rejection_details=""
  local rejected_tasks
  rejected_tasks=$(jq -r '.tasks | to_entries[] | select(.value.status == "rejected") | .key' "$state_file" 2>/dev/null | tr -d '\r')
  for tid in $rejected_tasks; do
    [[ -z "$tid" ]] && continue
    local reason feedback
    reason=$(jq -r ".tasks[\"$tid\"].rejection_reason // \"unknown\"" "$state_file" 2>/dev/null | tr -d '\r')
    feedback=$(jq -r ".tasks[\"$tid\"].last_feedback // \"none\"" "$state_file" 2>/dev/null | tr -d '\r')
    rejection_details+="Task $tid: reason=$reason, feedback=$feedback\n"
  done
  [[ -n "$rejection_details" ]] && context+="Rejection Details:\n${rejection_details}"

  # Add friction summary if available
  if [[ -f "$telemetry_dir/friction_events.jsonl" ]] && type get_friction_summary &>/dev/null; then
    local friction_json
    friction_json=$(get_friction_summary 2>/dev/null)
    context+="Friction: $(echo "$friction_json" | jq -c '.' 2>/dev/null)\n"
  fi

  # Add score distribution
  local scores_summary
  scores_summary=$(jq -r '.tasks | to_entries | map({key: .key, score: (.value.score // 0), status: .value.status}) | sort_by(-.score)' "$state_file" 2>/dev/null | tr -d '\r')
  context+="Scores: $(echo "$scores_summary" | jq -c '.' 2>/dev/null)\n"

  # Single haiku call
  local response_file="/tmp/meta-report-l3-${BASHPID:-$$}-${RANDOM}.json"
  local l3_prompt
  l3_prompt=$(printf "Analyze this blueprint execution and assess system health:\n\n%b\n\nProvide your assessment as structured JSON." "$context")

  echo "$l3_prompt" | \
    env -u CLAUDECODE claude -p \
      --model "haiku" \
      --max-budget-usd 0.05 \
      --tools "" \
      --setting-sources "" \
      --output-format json \
      --json-schema "$(cat "$schema_file")" \
      --no-session-persistence \
      --dangerously-skip-permissions \
      2>/dev/null | tr -d '\r' > "$response_file" || true

  # Extract structured output
  local l3_output
  l3_output=$(jq '.structured_output // {}' "$response_file" 2>/dev/null || echo '{}')

  # Record cost
  if [[ -f "$response_file" ]]; then
    local l3_cost
    l3_cost=$(jq -r '.total_cost_usd // 0' "$response_file" 2>/dev/null | tr -d '\r' || echo "0")
    if [[ "$l3_cost" != "0" && -n "$l3_cost" ]]; then
      local l3_tokens
      l3_tokens=$(extract_tokens_from_response "$response_file" 2>/dev/null || echo "0 0")
      local l3_input l3_output_tokens
      l3_input=$(echo "$l3_tokens" | cut -d' ' -f1)
      l3_output_tokens=$(echo "$l3_tokens" | cut -d' ' -f2)
      record_cost "meta-report-l3" 1 "$l3_cost" "haiku" "${l3_input:-0}" "${l3_output_tokens:-0}" "meta-report" 2>/dev/null || true
    fi
  fi

  rm -f "$response_file"
  echo "$l3_output"
}

# ============================================================================
# HANDOFF.YAML (for P6) — per §15.2
# ============================================================================

generate_handoff_yaml() {
  local output_file="${1:-${REPORTS_DIR:-$RUNTIME_DIR/reports}/handoff.yaml}"
  local state_file="${STATE_FILE:-$RUNTIME_DIR/state.json}"
  local telemetry_dir="${TELEMETRY_DIR:-$RUNTIME_DIR}"
  local manifest="${MANIFEST:-$RUNTIME_DIR/manifest.yaml}"

  [[ ! -f "$state_file" ]] && log_warn "State file not found, handoff incomplete" && return 1

  # Extract data from state and telemetry
  local bp_id bp_title started_at completed_at target
  bp_id="${BLUEPRINT_ID:-unknown}"

  # Read blueprint_title from manifest (FIX 1a) — fail explicitly if missing
  local manifest_title
  if [[ ! -f "$manifest" ]]; then
    log_warn "Manifest file not found at $manifest, using default blueprint title"
    bp_title="Untitled"
  else
    manifest_title=$(yq -r '.blueprint.name // ""' "$manifest" 2>/dev/null | tr -d '\r')
    if [[ -z "$manifest_title" ]]; then
      log_warn "blueprint.name not found in manifest, using default title"
      bp_title="Untitled"
    else
      bp_title="$manifest_title"
    fi
  fi

  started_at=$(jq -r '.started_at // "unknown"' "$state_file" 2>/dev/null | tr -d '\r')
  completed_at=$(now_iso)

  # Read target_project from manifest (FIX 1b) — fail explicitly if missing
  local manifest_target
  if [[ ! -f "$manifest" ]]; then
    log_warn "Manifest file not found at $manifest, using default target"
    target="unknown"
  else
    manifest_target=$(yq -r '.blueprint.project_dir // ""' "$manifest" 2>/dev/null | tr -d '\r')
    if [[ -z "$manifest_target" ]]; then
      log_warn "blueprint.project_dir not found in manifest, using default target"
      target="unknown"
    else
      target="$manifest_target"
    fi
  fi

  # Calculate duration
  local duration_s=0
  if [[ "$started_at" != "unknown" ]]; then
    local start_epoch end_epoch
    start_epoch=$(date -d "$started_at" +%s 2>/dev/null || echo 0)
    end_epoch=$(date +%s)
    duration_s=$((end_epoch - start_epoch))
  fi

  # Results
  local total completed failed first_pass_rate total_cost cost_estimate cost_vs_estimate
  total=$(jq -r '.counters.total // 0' "$state_file" 2>/dev/null | tr -d '\r')
  completed=$(jq -r '.counters.completed // 0' "$state_file" 2>/dev/null | tr -d '\r')
  failed=$(jq -r '.counters.failed // 0' "$state_file" 2>/dev/null | tr -d '\r')

  # Calculate first_pass_rate (FIX 1d) — verify .attempts field exists, fallback to retry log analysis
  local completed_first_try
  completed_first_try=$(jq -r '[.tasks | to_entries[] | select(.value.status == "completed" and (.value.attempts // 1) == 1)] | length' "$state_file" 2>/dev/null | tr -d '\r')

  # Verify .attempts field is actually populated; if all tasks show attempts==1, likely unfilled
  local sample_attempts
  sample_attempts=$(jq -r '[.tasks | to_entries[] | .value.attempts] | map(select(. != null)) | length' "$state_file" 2>/dev/null | tr -d '\r')

  if [[ "$sample_attempts" == "0" ]]; then
    # .attempts not populated; fallback: count retries from events or assume first_pass_rate from completed tasks
    log_warn "Task .attempts field not populated in state.json; deriving first_pass_rate from retry events"
    local retry_count
    retry_count=$(jq -r '[.tasks | to_entries[] | select(.value.retries // 0 > 0)] | length' "$state_file" 2>/dev/null | tr -d '\r')
    completed_first_try=$((completed - (retry_count > 0 ? retry_count : 0)))
    [[ $completed_first_try -lt 0 ]] && completed_first_try=0
  fi

  if [[ "$completed" -gt 0 ]]; then
    first_pass_rate=$(awk -v cft="$completed_first_try" -v tc="$completed" 'BEGIN { printf "%.2f", cft / tc }')
  else
    first_pass_rate="0"
  fi

  total_cost=$(jq -r '.budget.used_usd // 0' "$state_file" 2>/dev/null | tr -d '\r')
  cost_estimate=$(jq -r '.budget.limit_usd // 0' "$state_file" 2>/dev/null | tr -d '\r')

  if [[ "$cost_estimate" != "0" && -n "$cost_estimate" ]]; then
    cost_vs_estimate=$(awk -v tc="$total_cost" -v ce="$cost_estimate" 'BEGIN { printf "%.2f", tc / ce }')
  else
    cost_vs_estimate="0"
  fi

  # Status
  local status="COMPLETE"
  [[ "$failed" -gt 0 ]] && status="PARTIAL"

  # Waves (FIX 1c) — count from logs
  local wave_count=0 advisory_runs=0
  if [[ -f "$telemetry_dir/logs/orchestrator.log" ]]; then
    wave_count=$(grep -c 'Wave [0-9]' "$telemetry_dir/logs/orchestrator.log" 2>/dev/null || echo "0")
  fi
  if [[ -f "$telemetry_dir/events.jsonl" ]]; then
    advisory_runs=$(jq -r 'select(.event == "advisory_complete")' "$telemetry_dir/events.jsonl" 2>/dev/null | wc -l | tr -d ' ')
  fi

  # Friction
  local friction_total=0 friction_causes friction_top_worker friction_trend
  if [[ -f "$telemetry_dir/friction_events.jsonl" ]]; then
    friction_total=$(wc -l < "$telemetry_dir/friction_events.jsonl" 2>/dev/null | tr -d ' ')
    friction_causes=$(jq -s 'group_by(.cause) | map({cause: .[0].cause, count: length}) | sort_by(-.count) | .[0:3]' "$telemetry_dir/friction_events.jsonl" 2>/dev/null || echo '[]')
    friction_top_worker=$(jq -s 'group_by(.worker_type) | map({worker: .[0].worker_type, count: length}) | sort_by(-.count) | .[0].worker // "none"' "$telemetry_dir/friction_events.jsonl" 2>/dev/null | tr -d '\r')
    friction_trend="stable"
  else
    friction_causes="[]"
    friction_top_worker="none"
    friction_trend="none"
  fi

  # Cost analysis (FIX 1e, 1f) — by task type and worker
  local cost_by_type cost_by_worker
  if [[ -f "$telemetry_dir/cost.jsonl" ]]; then
    # Aggregate by call_type (categorize as qa, advisory, meta_report, workers)
    cost_by_type=$(jq -s '
      group_by(
        if .task_id | startswith("qa-") then "qa"
        elif .task_id | startswith("advisory-") then "advisory"
        elif .task_id | startswith("meta-report") then "meta_report"
        else "workers"
        end
      ) |
      map({
        (.[0] | if .task_id | startswith("qa-") then "qa" elif .task_id | startswith("advisory-") then "advisory" elif .task_id | startswith("meta-report") then "meta_report" else "workers" end): (map(.cost_usd) | add)
      }) |
      add // {}
    ' "$telemetry_dir/cost.jsonl" 2>/dev/null || echo '{}')

    # Aggregate by worker type — direct grouping from cost.jsonl if worker field present, else unknown
    cost_by_worker=$(jq -s 'group_by(.worker // "unknown") | map({(.[0].worker // "unknown"): (map(.cost_usd) | add)}) | add // {}' "$telemetry_dir/cost.jsonl" 2>/dev/null || echo '{}')
  else
    cost_by_type="{}"
    cost_by_worker="{}"
  fi

  # Pattern candidates (from friction analysis)
  local pattern_candidates
  pattern_candidates=$(_extract_pattern_candidates "$telemetry_dir" 2>/dev/null || echo '[]')

  # Epigenetic updates (from markers file)
  local epigenetic_updates
  epigenetic_updates=$(_extract_epigenetic_updates 2>/dev/null || echo '[]')

  # Recommendations (basic heuristics)
  local recommendations_immediate recommendations_strategic
  recommendations_immediate=$(_generate_immediate_recommendations "$state_file" "$telemetry_dir" 2>/dev/null || echo '[]')
  recommendations_strategic=$(_generate_strategic_recommendations "$state_file" "$telemetry_dir" 2>/dev/null || echo '[]')

  # Write YAML
  cat > "$output_file" <<EOF
# F3→P6 Handoff: ${bp_title}
blueprint_id: "${bp_id}"
blueprint_title: "${bp_title}"
executed_at: "${started_at}"
duration_s: ${duration_s}
target_project: "${target}"

results:
  status: "${status}"
  tasks:
    total: ${total}
    passed: ${completed}
    failed: ${failed}
  first_pass_rate: ${first_pass_rate}
  total_cost_usd: ${total_cost}
  cost_vs_estimate: ${cost_vs_estimate}

waves:
  total: ${wave_count}
  advisory_runs: ${advisory_runs}

friction:
  total_events: ${friction_total}
  top_causes: $(echo "$friction_causes" | yq -P '.' 2>/dev/null || echo "$friction_causes")
  most_affected_worker: "${friction_top_worker}"
  trend: "${friction_trend}"

cost_analysis:
  by_type: $(echo "$cost_by_type" | yq -P '.' 2>/dev/null || echo "$cost_by_type")
  by_worker: $(echo "$cost_by_worker" | yq -P '.' 2>/dev/null || echo "$cost_by_worker")

pattern_candidates: $(echo "$pattern_candidates" | yq -P '.' 2>/dev/null || echo "$pattern_candidates")

epigenetic_updates: $(echo "$epigenetic_updates" | yq -P '.' 2>/dev/null || echo "$epigenetic_updates")

recommendations:
  immediate: $(echo "$recommendations_immediate" | yq -P '.' 2>/dev/null || echo "$recommendations_immediate")
  strategic: $(echo "$recommendations_strategic" | yq -P '.' 2>/dev/null || echo "$recommendations_strategic")
EOF

  log_info "Handoff YAML generated: $output_file"
}

_extract_pattern_candidates() {
  local telemetry_dir="$1"
  local friction_file="$telemetry_dir/friction_events.jsonl"
  [[ ! -f "$friction_file" ]] && echo '[]' && return

  # Find recurring friction patterns (3+ occurrences)
  jq -s '
    group_by(.cause) |
    map(select(length >= 3) | {
      pattern: ("Recurring \(.[0].cause) in \(.[0].worker_type) tasks"),
      confidence: (length / 10 | if . > 1 then 1 else . end),
      evidence_count: length,
      action: "review"
    })
  ' "$friction_file" 2>/dev/null || echo '[]'
}

_extract_epigenetic_updates() {
  local markers_file="${MEMORY_DIR:-.orchestrator/memory}/epigenetic-markers.yaml"
  [[ ! -f "$markers_file" ]] && echo '[]' && return

  # Extract recent changes (this is simplified - real implementation would track changes)
  echo '[]'
}

_generate_immediate_recommendations() {
  local state_file="$1"
  local telemetry_dir="$2"

  local recommendations='[]'

  # Check for failed tasks
  local failed_count
  failed_count=$(jq -r '.counters.failed // 0' "$state_file" 2>/dev/null | tr -d '\r')
  if [[ "$failed_count" -gt 0 ]]; then
    recommendations=$(echo "$recommendations" | jq '. + ["Review failed tasks for manual completion"]')
  fi

  # Check for high friction
  if [[ -f "$telemetry_dir/friction_events.jsonl" ]]; then
    local friction_count
    friction_count=$(wc -l < "$telemetry_dir/friction_events.jsonl" 2>/dev/null | tr -d ' ')
    if [[ "$friction_count" -gt 5 ]]; then
      recommendations=$(echo "$recommendations" | jq '. + ["Investigate high friction count"]')
    fi
  fi

  echo "$recommendations"
}

_generate_strategic_recommendations() {
  local state_file="$1"
  local telemetry_dir="$2"

  local recommendations='[]'

  # Check cost overrun
  local total_cost cost_estimate
  total_cost=$(jq -r '.budget.used_usd // 0' "$state_file" 2>/dev/null | tr -d '\r')
  cost_estimate=$(jq -r '.budget.limit_usd // 0' "$state_file" 2>/dev/null | tr -d '\r')

  if [[ "$cost_estimate" != "0" && -n "$cost_estimate" ]]; then
    local cost_ratio
    cost_ratio=$(awk -v tc="$total_cost" -v ce="$cost_estimate" 'BEGIN { print (tc / ce > 1.2) ? 1 : 0 }')
    if [[ "$cost_ratio" == "1" ]]; then
      recommendations=$(echo "$recommendations" | jq '. + ["Review cost estimation model"]')
    fi
  fi

  echo "$recommendations"
}

# ============================================================================
# IMMUNE PROMOTION (conservative)
# ============================================================================

promote_immune_patterns() {
  local telemetry_dir="${TELEMETRY_DIR:-$RUNTIME_DIR}"
  local immune_file="$telemetry_dir/immune.jsonl"
  local memory_dir="${MEMORY_DIR:-.orchestrator/memory}"
  local immune_memory="$memory_dir/immune-memory.jsonl"

  [[ ! -f "$immune_file" || ! -s "$immune_file" ]] && return 0

  mkdir -p "$memory_dir" 2>/dev/null || true

  # Find patterns appearing 3+ times
  local patterns
  patterns=$(jq -s 'group_by(.pattern) | map(select(length >= 3) | {pattern: .[0].pattern, count: length, evidence: map(.task_id)})' "$immune_file" 2>/dev/null)

  # Write as "flag" entries (conservative, not auto_reject)
  echo "$patterns" | jq -c '.[] | {
    pattern: .pattern,
    status: "flag",
    evidence_count: .count,
    evidence_tasks: .evidence,
    promoted_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
    blueprint_id: env.BLUEPRINT_ID
  }' >> "$immune_memory" 2>/dev/null || true

  local promoted_count
  promoted_count=$(echo "$patterns" | jq 'length' 2>/dev/null || echo "0")

  if [[ "$promoted_count" -gt 0 ]]; then
    log_info "Immune: promoted $promoted_count patterns to 'flag' status"
  fi
}

# ============================================================================
# PATTERN STAGING
# ============================================================================

stage_pattern_candidates() {
  local telemetry_dir="${TELEMETRY_DIR:-$RUNTIME_DIR}"
  local memory_dir="${MEMORY_DIR:-.orchestrator/memory}"
  local staging_file="$memory_dir/pattern-candidates.yaml"
  local friction_file="$telemetry_dir/friction_events.jsonl"
  local events_file="$telemetry_dir/events.jsonl"

  mkdir -p "$memory_dir" 2>/dev/null || true

  local candidates='[]'

  # 1. Recurring friction causes (3+ times)
  if [[ -f "$friction_file" && -s "$friction_file" ]]; then
    local friction_patterns
    friction_patterns=$(jq -s '
      group_by(.cause) |
      map(select(length >= 3) | {
        pattern: ("Recurring \(.[0].cause) in \(.[0].worker_type) tasks"),
        type: "friction",
        confidence: (length / 10 | if . > 1 then 1 else . end),
        evidence_count: length,
        evidence: map(.task_id),
        recommendation: "Review \(.[0].worker_type) worker DNA or constraints"
      })
    ' "$friction_file" 2>/dev/null || echo '[]')

    candidates=$(jq -n --argjson c "$candidates" --argjson f "$friction_patterns" '$c + $f')
  fi

  # 2. Successful model escalations (patterns that work)
  if [[ -f "$events_file" ]]; then
    local escalation_patterns
    escalation_patterns=$(jq -s '
      [.[] | select(.event == "model_escalation")] |
      group_by(.worker_type) |
      map(select(length >= 2) | {
        pattern: ("Model escalation frequently needed for \(.[0].worker_type) tasks"),
        type: "escalation",
        confidence: (length / 5 | if . > 1 then 1 else . end),
        evidence_count: length,
        evidence: map(.task_id),
        recommendation: "Consider higher default model for \(.[0].worker_type)"
      })
    ' "$events_file" 2>/dev/null || echo '[]')

    candidates=$(jq -n --argjson c "$candidates" --argjson e "$escalation_patterns" '$c + $e')
  fi

  # Write to staging file
  if [[ $(echo "$candidates" | jq 'length' 2>/dev/null) -gt 0 ]]; then
    cat > "$staging_file" <<EOF
# Pattern Candidates for P6 Review
# Generated: $(now_iso)
# Blueprint: ${BLUEPRINT_ID:-unknown}

candidates:
$(echo "$candidates" | yq -P '.' 2>/dev/null || echo "$candidates")
EOF

    local candidate_count
    candidate_count=$(echo "$candidates" | jq 'length' 2>/dev/null || echo "0")
    log_info "Pattern staging: $candidate_count candidates identified"
  fi
}

# ============================================================================
# LAYER 1: BLUEPRINT DIAGNOSTICS (deterministic)
# ============================================================================

_meta_layer1_diagnostics() {
  echo "## Layer 1: Blueprint Diagnostics"
  echo ""

  # Score distribution
  echo "### Score Distribution"
  echo ""
  local task_ids
  task_ids=$(jq -r '.tasks | keys[]' "$STATE_FILE" 2>/dev/null | tr -d '\r')

  local bucket_0_59=0 bucket_60_69=0 bucket_70_79=0 bucket_80_89=0 bucket_90_100=0
  for tid in $task_ids; do
    [[ -z "$tid" ]] && continue
    local score
    score=$(jq -r ".tasks[\"$tid\"].score // empty" "$STATE_FILE" 2>/dev/null | tr -d '\r')
    [[ "$score" == "null" || -z "$score" ]] && continue
    [[ ! "$score" =~ ^[0-9]+$ ]] && continue
    if [[ $score -ge 90 ]]; then ((bucket_90_100++)) || true
    elif [[ $score -ge 80 ]]; then ((bucket_80_89++)) || true
    elif [[ $score -ge 70 ]]; then ((bucket_70_79++)) || true
    elif [[ $score -ge 60 ]]; then ((bucket_60_69++)) || true
    else ((bucket_0_59++)) || true
    fi
  done

  echo "| Range | Count |"
  echo "|-------|-------|"
  echo "| 90-100 (excellent) | $bucket_90_100 |"
  echo "| 80-89 (good) | $bucket_80_89 |"
  echo "| 70-79 (acceptable) | $bucket_70_79 |"
  echo "| 60-69 (needs work) | $bucket_60_69 |"
  echo "| 0-59 (failed) | $bucket_0_59 |"
  echo ""

  # Cost breakdown by model
  echo "### Cost by Model"
  echo ""
  local telemetry_dir="${TELEMETRY_DIR:-$RUNTIME_DIR}"
  if [[ -f "$telemetry_dir/cost.jsonl" ]]; then
    echo "| Model | Tasks | Total Cost |"
    echo "|-------|-------|------------|"
    jq -s 'group_by(.model) | .[] | {model: .[0].model, count: length, cost: (map(.cost_usd) | add)}' \
      "$telemetry_dir/cost.jsonl" 2>/dev/null | jq -r '"| \(.model) | \(.count) | $\(.cost | tostring) |"' 2>/dev/null
    echo ""
  else
    echo "No cost data available."
    echo ""
  fi

  # Timing analysis
  echo "### Timing"
  echo ""
  local started
  started=$(jq -r '.started_at // "unknown"' "$STATE_FILE" 2>/dev/null | tr -d '\r')
  echo "- Blueprint started: $started"
  echo "- Report generated: $(now_iso)"
  echo ""
}

# ============================================================================
# LAYER 2: FRICTION ANALYSIS (deterministic)
# ============================================================================

_meta_layer2_friction() {
  echo "## Layer 2: Friction Analysis"
  echo ""

  local telemetry_dir="${TELEMETRY_DIR:-$RUNTIME_DIR}"
  local friction_file="$telemetry_dir/friction_events.jsonl"
  if [[ ! -f "$friction_file" || ! -s "$friction_file" ]]; then
    echo "No friction events recorded. Clean blueprint execution."
    echo ""
    return
  fi

  # Use friction.sh summary if available
  if type get_friction_summary &>/dev/null; then
    local summary
    summary=$(get_friction_summary)

    echo "### Friction Summary"
    echo ""
    echo "Total friction events: $(echo "$summary" | jq '.total' 2>/dev/null)"
    echo ""

    echo "### Causes Ranked by Frequency"
    echo ""
    echo "| Cause | Count | % of Total |"
    echo "|-------|-------|------------|"
    local total
    total=$(echo "$summary" | jq '.total' 2>/dev/null || echo "1")
    echo "$summary" | jq -r --argjson t "$total" \
      '.causes | to_entries | sort_by(-.value) | .[] | "| \(.key) | \(.value) | \(.value * 100 / $t | round)% |"' \
      2>/dev/null
    echo ""

    echo "### Worker Type Analysis"
    echo ""
    echo "| Worker Type | Friction Count |"
    echo "|-------------|----------------|"
    echo "$summary" | jq -r '.worker_types | to_entries | sort_by(-.value) | .[] | "| \(.key) | \(.value) |"' 2>/dev/null
    echo ""
  fi

  # Budget incidents
  echo "### Budget Incidents"
  echo ""
  local budget_events
  budget_events=$(jq -s '[.[] | select(.cause == "budget_exhaustion")]' "$friction_file" 2>/dev/null)
  local budget_count
  budget_count=$(echo "$budget_events" | jq 'length' 2>/dev/null || echo "0")
  if [[ "$budget_count" -gt 0 ]]; then
    echo "**$budget_count budget-related friction events detected.**"
    echo ""
    echo "$budget_events" | jq -r '.[] | "- Task \(.task_id): score \(.score), attempt \(.attempt)"' 2>/dev/null
  else
    echo "No budget incidents. All tasks completed within budget."
  fi
  echo ""
}

# ============================================================================
# LAYER 3: SYSTEM EVOLUTION (single haiku call)
# ============================================================================

_meta_layer3_evolution() {
  local json_output="$1"

  echo "## Layer 3: System Evolution Assessment"
  echo ""

  # Build context for haiku (direct jq reads — no die on error)
  local diagnostics_context=""
  diagnostics_context+="Blueprint: ${BLUEPRINT_ID:-unknown}\n"
  local _completed _total _failed _used _limit
  _completed=$(jq -r '.counters.completed // 0' "$STATE_FILE" 2>/dev/null | tr -d '\r')
  _total=$(jq -r '.counters.total // 0' "$STATE_FILE" 2>/dev/null | tr -d '\r')
  _failed=$(jq -r '.counters.failed // 0' "$STATE_FILE" 2>/dev/null | tr -d '\r')
  _used=$(jq -r '.budget.used_usd // 0' "$STATE_FILE" 2>/dev/null | tr -d '\r')
  _limit=$(jq -r '.budget.limit_usd // 0' "$STATE_FILE" 2>/dev/null | tr -d '\r')
  diagnostics_context+="Tasks: ${_completed}/${_total} completed\n"
  diagnostics_context+="Failed: ${_failed}\n"
  diagnostics_context+="Cost: \$${_used}/\$${_limit}\n"

  # Add rejection details (FIX 2 — for human markdown output)
  local rejection_details=""
  local rejected_tasks
  rejected_tasks=$(jq -r '.tasks | to_entries[] | select(.value.status == "rejected") | .key' "$STATE_FILE" 2>/dev/null | tr -d '\r')
  for tid in $rejected_tasks; do
    [[ -z "$tid" ]] && continue
    local reason feedback
    reason=$(jq -r ".tasks[\"$tid\"].rejection_reason // \"unknown\"" "$STATE_FILE" 2>/dev/null | tr -d '\r')
    feedback=$(jq -r ".tasks[\"$tid\"].last_feedback // \"none\"" "$STATE_FILE" 2>/dev/null | tr -d '\r')
    rejection_details+="Task $tid: reason=$reason, feedback=$feedback\n"
  done
  [[ -n "$rejection_details" ]] && diagnostics_context+="Rejection Details:\n${rejection_details}"

  # Add friction summary if available
  local telemetry_dir="${TELEMETRY_DIR:-$RUNTIME_DIR}"
  if [[ -f "$telemetry_dir/friction_events.jsonl" ]] && type get_friction_summary &>/dev/null; then
    local friction_json
    friction_json=$(get_friction_summary 2>/dev/null)
    diagnostics_context+="Friction: $(echo "$friction_json" | jq -c '.' 2>/dev/null)\n"
  fi

  # Add score distribution
  local scores_summary
  scores_summary=$(jq -r '.tasks | to_entries | map({key: .key, score: (.value.score // 0), status: .value.status}) | sort_by(-.score)' "$STATE_FILE" 2>/dev/null | tr -d '\r')
  diagnostics_context+="Scores: $(echo "$scores_summary" | jq -c '.' 2>/dev/null)\n"

  local schema_file="$ORCHESTRATOR_DIR/schemas/meta-report.json"
  if [[ ! -f "$schema_file" ]]; then
    echo "Schema file not found. Skipping Layer 3."
    echo ""
    return
  fi

  # Single haiku call for evolution assessment
  local response_file="/tmp/meta-report-l3-${BASHPID:-$$}-${RANDOM}.json"

  local l3_prompt
  l3_prompt=$(printf "Analyze this blueprint data and assess system health:\n\n%b\n\nProvide your assessment as structured JSON." "$diagnostics_context")

  echo "$l3_prompt" | \
    env -u CLAUDECODE claude -p \
      --model "haiku" \
      --max-budget-usd 0.05 \
      --tools "" \
      --setting-sources "" \
      --output-format json \
      --json-schema "$(cat "$schema_file")" \
      --no-session-persistence \
      --dangerously-skip-permissions \
      2>/dev/null | tr -d '\r' > "$response_file" || true

  # Extract structured output
  local l3_output
  l3_output=$(jq '.structured_output // empty' "$response_file" 2>/dev/null)

  if [[ -n "$l3_output" && "$l3_output" != "null" ]]; then
    # Save machine-readable JSON
    echo "$l3_output" > "$json_output"

    # Render to markdown
    local trend health
    trend=$(echo "$l3_output" | jq -r '.trend_assessment // "unknown"' | tr -d '\r')
    health=$(echo "$l3_output" | jq -r '.system_health // "unknown"' | tr -d '\r')

    echo "**Trend:** $trend | **Health:** $health"
    echo ""

    # Systemic issues
    local issue_count
    issue_count=$(echo "$l3_output" | jq '.systemic_issues | length' 2>/dev/null || echo "0")
    if [[ "$issue_count" -gt 0 ]]; then
      echo "### Systemic Issues"
      echo ""
      echo "$l3_output" | jq -r '.systemic_issues[] | "- **\(.pattern)** [\(.severity)]: \(.evidence) → \(.recommendation)"' 2>/dev/null
      echo ""
    fi

    # Recommendations
    echo "### Recommendations"
    echo ""
    echo "**Immediate:**"
    echo "$l3_output" | jq -r '.recommendations.immediate[]? | "- \(.)"' 2>/dev/null
    echo ""
    echo "**Strategic:**"
    echo "$l3_output" | jq -r '.recommendations.strategic[]? | "- \(.)"' 2>/dev/null
    echo ""

    # Pattern updates
    local pattern_count
    pattern_count=$(echo "$l3_output" | jq '.pattern_updates | length' 2>/dev/null || echo "0")
    if [[ "$pattern_count" -gt 0 ]]; then
      echo "### Pattern Updates"
      echo ""
      echo "$l3_output" | jq -r '.pattern_updates[] | "- [\(.action)] \(.pattern_id): \(.rationale) (confidence: \(.confidence))"' 2>/dev/null
      echo ""
    fi

    # Record cost with real token counts
    local l3_cost
    l3_cost=$(jq -r '.total_cost_usd // 0' "$response_file" 2>/dev/null | tr -d '\r' || echo "0")
    if [[ "$l3_cost" != "0" && -n "$l3_cost" ]]; then
      local l3_tokens
      l3_tokens=$(extract_tokens_from_response "$response_file" 2>/dev/null || echo "0 0")
      local l3_input l3_output_tokens
      l3_input=$(echo "$l3_tokens" | cut -d' ' -f1)
      l3_output_tokens=$(echo "$l3_tokens" | cut -d' ' -f2)
      record_cost "meta-report-l3" 1 "$l3_cost" "haiku" "${l3_input:-0}" "${l3_output_tokens:-0}" "meta-report" 2>/dev/null || true
    fi
  else
    echo "Layer 3 assessment unavailable (haiku call failed or returned no structured output)."
    echo "This is non-critical — Layers 1 and 2 provide sufficient diagnostics."
    echo ""
    echo "{}" > "$json_output"
  fi

  rm -f "$response_file"
}
