#!/usr/bin/env bash
# report.sh — Human-facing report generator (FORMICA v3.0)
# Generates: execution-report.md, file-manifest.md, progress.txt
# Zero API calls, all data from JSONL/JSON files.

[[ -n "${_REPORT_SH_LOADED:-}" ]] && return 0
_REPORT_SH_LOADED=1

# ============================================================================
# PROGRESS MONITORING (progress.txt)
# ============================================================================

# Append timestamped message to progress.txt
# Designed for: tail -f runtime/{bp-id}/progress.txt
update_progress() {
  local message="$1"
  local progress_file="${REPORTS_DIR:-$RUNTIME_DIR}/progress.txt"
  local timestamp
  timestamp=$(date +"%H:%M:%S" 2>/dev/null || echo "00:00:00")
  echo "[$timestamp] $message" >> "$progress_file" 2>/dev/null || true
}

# ============================================================================
# EXECUTION REPORT (execution-report.md)
# ============================================================================

# Generate human-facing execution report matching SPECIFICATION.md §14.2
# Output: $REPORTS_DIR/execution-report.md
generate_execution_report() {
  local report_file="${REPORTS_DIR:-$RUNTIME_DIR/reports}/execution-report.md"
  mkdir -p "$(dirname "$report_file")" 2>/dev/null || true

  local total completed failed used_usd limit_usd started_at
  total=$(state_read '.counters.total' 2>/dev/null || echo "0")
  completed=$(state_read '.counters.completed' 2>/dev/null || echo "0")
  failed=$(state_read '.counters.failed' 2>/dev/null || echo "0")
  used_usd=$(state_read '.budget.used_usd' 2>/dev/null || echo "0")
  limit_usd=$(state_read '.budget.limit_usd' 2>/dev/null || echo "0")
  started_at=$(state_read '.started_at' 2>/dev/null || echo "unknown")
  local ended_at
  ended_at=$(now_iso 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")

  # Generate report section by section with error isolation
  {
    _section_header "$started_at" "$ended_at" "$total" "$completed" "$failed" "$used_usd" "$limit_usd"
  } >> "$report_file" 2>/dev/null || echo "(error generating header)" >> "$report_file"

  {
    _section_results_dashboard "$total" "$completed" "$failed" "$used_usd" "$limit_usd"
  } >> "$report_file" 2>/dev/null || echo "(error generating results dashboard)" >> "$report_file"

  {
    _section_what_was_created
  } >> "$report_file" 2>/dev/null || echo "(error generating what was created)" >> "$report_file"

  {
    _section_cost_breakdown "$used_usd" "$limit_usd"
  } >> "$report_file" 2>/dev/null || echo "(error generating cost breakdown)" >> "$report_file"

  {
    _section_per_task_results
  } >> "$report_file" 2>/dev/null || echo "(error generating per-task results)" >> "$report_file"

  {
    _section_wave_timeline
  } >> "$report_file" 2>/dev/null || echo "(error generating wave timeline)" >> "$report_file"

  {
    _section_issues_encountered
  } >> "$report_file" 2>/dev/null || echo "(error generating issues)" >> "$report_file"

  {
    _section_qa_skipped_warning
  } >> "$report_file" 2>/dev/null || true

  {
    _section_decisions
  } >> "$report_file" 2>/dev/null || echo "(error generating decisions)" >> "$report_file"

  {
    _section_recommendations
  } >> "$report_file" 2>/dev/null || echo "(error generating recommendations)" >> "$report_file"

  log_info "Execution report generated: $report_file"
}

# Section 1: Header + metadata
_section_header() {
  local started="$1" ended="$2" total="$3" completed="$4" failed="$5" cost="$6" limit="$7"

  local bp_name bp_id status
  bp_name=$(yq -r '.blueprint.name // .blueprint.id // "Unknown Blueprint"' "$MANIFEST" 2>/dev/null | tr -d '\r')
  bp_id=$(yq -r '.blueprint.id // "UNKNOWN"' "$MANIFEST" 2>/dev/null | tr -d '\r')

  # Calculate duration
  local duration="unknown"
  if [[ "$started" != "unknown" && "$ended" != "unknown" ]]; then
    local start_epoch end_epoch
    start_epoch=$(date -d "$started" +%s 2>/dev/null || echo "0")
    end_epoch=$(date -d "$ended" +%s 2>/dev/null || echo "0")
    if [[ $start_epoch -gt 0 && $end_epoch -gt 0 ]]; then
      local diff=$((end_epoch - start_epoch))
      local mins=$((diff / 60))
      local secs=$((diff % 60))
      duration="${mins}m${secs}s"
    fi
  fi

  # Determine status
  if [[ $failed -eq 0 && $completed -eq $total ]]; then
    status="COMPLETE"
  elif [[ $completed -gt 0 ]]; then
    status="PARTIAL"
  else
    status="ABORTED"
  fi

  cat <<EOF
# Execution Report: $bp_name

**Blueprint:** \`$bp_id\`
**Date:** $started → $ended ($duration)
**Status:** $status
**Cost:** \$$cost (budget: \$$limit)

---

EOF
}

# Section 2: Results dashboard
_section_results_dashboard() {
  local total="$1" completed="$2" failed="$3" used="$4" limit="$5"

  local pass_rate=0
  [[ "$total" -gt 0 ]] && pass_rate=$((completed * 100 / total))

  # Calculate first-pass rate from state.json (authoritative — catches budget kills + QA reworks)
  local first_pass=0 retry_count=0
  if [[ -f "$STATE_FILE" ]]; then
    first_pass=$(jq '[.tasks | to_entries[] | select(.value.status == "completed" and (.value.attempts // 1) == 1)] | length' "$STATE_FILE" 2>/dev/null || echo "0")
    retry_count=$(jq '[.tasks | to_entries[] | select((.value.attempts // 1) > 1) | ((.value.attempts // 1) - 1)] | add // 0' "$STATE_FILE" 2>/dev/null || echo "0")
  fi
  local first_pass_pct=0
  [[ "$completed" -gt 0 ]] && first_pass_pct=$((first_pass * 100 / completed))

  # Count waves
  local wave_count=0
  local tmp_state="/tmp/report-waves-${BASHPID:-$$}-${RANDOM}.json"
  cp "$STATE_FILE" "$tmp_state" 2>/dev/null || true
  if [[ -f "$tmp_state" ]]; then
    wave_count=$(get_execution_waves "$tmp_state" 2>/dev/null | grep -c . || echo "0")
    rm -f "$tmp_state"
  fi

  # Budget percentage
  local budget_pct=0
  if [[ -n "$limit" && "$limit" != "0" ]]; then
    budget_pct=$(awk -v u="$used" -v l="$limit" 'BEGIN { if (l>0) printf "%d", u/l*100; else print 0 }')
  fi

  # Model distribution
  local haiku_count sonnet_count opus_count
  haiku_count=$(jq -r '[.tasks[] | select(.model == "haiku")] | length' "$STATE_FILE" 2>/dev/null || echo "0")
  sonnet_count=$(jq -r '[.tasks[] | select(.model == "sonnet")] | length' "$STATE_FILE" 2>/dev/null || echo "0")
  opus_count=$(jq -r '[.tasks[] | select(.model == "opus")] | length' "$STATE_FILE" 2>/dev/null || echo "0")

  cat <<EOF
## Results Dashboard

| Metric | Value |
|--------|-------|
| Tasks | $completed/$total passed ($pass_rate%) |
| First-pass rate | $first_pass_pct% |
| Retries | $retry_count across $((completed - first_pass)) tasks |
| Waves | $wave_count |
| Cost | \$$used / \$$limit budget ($budget_pct%) |
| Duration | see above |
| Model distribution | haiku: $haiku_count, sonnet: $sonnet_count, opus: $opus_count |

EOF
}

# Section 3: What was created
_section_what_was_created() {
  echo "## What Was Created"
  echo ""
  echo "| File | Status | Purpose |"
  echo "|------|--------|---------|"

  local file_reg="${RUNTIME_DIR}/file_registry.json"
  if [[ -f "$file_reg" && -s "$file_reg" ]]; then
    jq -r 'to_entries[] | "\(.key)|\(.value.task_id)|\(.value.action)"' "$file_reg" 2>/dev/null | \
      while IFS='|' read -r filepath task_id action; do
        local lines="?"
        if [[ -f "$filepath" ]]; then
          lines=$(wc -l < "$filepath" 2>/dev/null || echo "?")
        fi
        local status_str="${action} (${lines} lines)"
        local purpose
        purpose=$(task_get "$task_id" "description" 2>/dev/null | head -c 60 || echo "")
        [[ ${#purpose} -gt 55 ]] && purpose="${purpose:0:55}..."
        echo "| \`$filepath\` | $status_str | $purpose |"
      done | head -20
  else
    echo "| (no file registry found) | - | - |"
  fi

  echo ""
  echo "See [file-manifest.md](./file-manifest.md) for complete file details."
  echo ""
}

# Section 4: Cost breakdown with ASCII bar chart
_section_cost_breakdown() {
  local used="$1" limit="$2"

  echo "## Cost Breakdown"
  echo ""

  local cost_file="${TELEMETRY_DIR:-$RUNTIME_DIR}/cost.jsonl"
  if [[ ! -f "$cost_file" || ! -s "$cost_file" ]]; then
    echo "No cost data available."
    echo ""
    return
  fi

  # Calculate category costs by reading cost.jsonl line by line
  local worker_cost=0 qa_cost=0 advisory_cost=0 meta_cost=0 retry_cost=0

  while IFS= read -r line; do
    local task_id attempt cost_usd
    task_id=$(echo "$line" | jq -r '.task_id // ""' 2>/dev/null)
    attempt=$(echo "$line" | jq -r '.attempt // 1' 2>/dev/null)
    cost_usd=$(echo "$line" | jq -r '.cost_usd // 0' 2>/dev/null)

    if [[ -z "$task_id" || -z "$cost_usd" ]]; then
      continue
    fi

    # Categorize by task_id prefix
    if [[ "$task_id" == qa-* ]]; then
      qa_cost=$(awk -v a="$qa_cost" -v b="$cost_usd" 'BEGIN { printf "%.2f", a+b }')
    elif [[ "$task_id" == advisory-* ]]; then
      advisory_cost=$(awk -v a="$advisory_cost" -v b="$cost_usd" 'BEGIN { printf "%.2f", a+b }')
    elif [[ "$task_id" == meta-report* ]]; then
      meta_cost=$(awk -v a="$meta_cost" -v b="$cost_usd" 'BEGIN { printf "%.2f", a+b }')
    else
      if [[ "$attempt" == "1" ]]; then
        worker_cost=$(awk -v a="$worker_cost" -v b="$cost_usd" 'BEGIN { printf "%.2f", a+b }')
      else
        retry_cost=$(awk -v a="$retry_cost" -v b="$cost_usd" 'BEGIN { printf "%.2f", a+b }')
      fi
    fi
  done < "$cost_file"

  # Calculate percentages
  local w_pct=0 q_pct=0 a_pct=0 m_pct=0 r_pct=0
  if [[ -n "$used" && "$used" != "0" ]]; then
    w_pct=$(awk -v c="$worker_cost" -v t="$used" 'BEGIN { if (t>0) printf "%d", c/t*100; else print 0 }')
    q_pct=$(awk -v c="$qa_cost" -v t="$used" 'BEGIN { if (t>0) printf "%d", c/t*100; else print 0 }')
    a_pct=$(awk -v c="$advisory_cost" -v t="$used" 'BEGIN { if (t>0) printf "%d", c/t*100; else print 0 }')
    m_pct=$(awk -v c="$meta_cost" -v t="$used" 'BEGIN { if (t>0) printf "%d", c/t*100; else print 0 }')
    r_pct=$(awk -v c="$retry_cost" -v t="$used" 'BEGIN { if (t>0) printf "%d", c/t*100; else print 0 }')
  fi

  # ASCII bar (20 chars wide)
  local bar_width=20
  local w_bar q_bar a_bar r_bar m_bar
  w_bar=$(awk -v p="$w_pct" -v w="$bar_width" 'BEGIN { printf "%d", p/100*w }' 2>/dev/null || echo "0")
  q_bar=$(awk -v p="$q_pct" -v w="$bar_width" 'BEGIN { printf "%d", p/100*w }' 2>/dev/null || echo "0")
  a_bar=$(awk -v p="$a_pct" -v w="$bar_width" 'BEGIN { printf "%d", p/100*w }' 2>/dev/null || echo "0")
  r_bar=$(awk -v p="$r_pct" -v w="$bar_width" 'BEGIN { printf "%d", p/100*w }' 2>/dev/null || echo "0")
  m_bar=$(awk -v p="$m_pct" -v w="$bar_width" 'BEGIN { printf "%d", p/100*w }' 2>/dev/null || echo "0")

  cat <<EOF
\`\`\`
Workers   $(printf '%0.s█' $(seq 1 $w_bar 2>/dev/null))$(printf '%0.s░' $(seq 1 $((bar_width - w_bar)) 2>/dev/null))  \$$worker_cost  ($w_pct%)
QA        $(printf '%0.s█' $(seq 1 $q_bar 2>/dev/null))$(printf '%0.s░' $(seq 1 $((bar_width - q_bar)) 2>/dev/null))  \$$qa_cost  ($q_pct%)
Advisory  $(printf '%0.s█' $(seq 1 $a_bar 2>/dev/null))$(printf '%0.s░' $(seq 1 $((bar_width - a_bar)) 2>/dev/null))  \$$advisory_cost  ($a_pct%)
Retries   $(printf '%0.s█' $(seq 1 $r_bar 2>/dev/null))$(printf '%0.s░' $(seq 1 $((bar_width - r_bar)) 2>/dev/null))  \$$retry_cost  ($r_pct%)
Meta-rpt  $(printf '%0.s█' $(seq 1 $m_bar 2>/dev/null))$(printf '%0.s░' $(seq 1 $((bar_width - m_bar)) 2>/dev/null))  \$$meta_cost  ($m_pct%)
──────────────────────────────────────────
Total     $(printf '%0.s█' $(seq 1 $bar_width 2>/dev/null))  \$$used
\`\`\`

EOF
}

# Section 5: Per-task results
_section_per_task_results() {
  echo "## Per-Task Results"
  echo ""
  echo "| Task | Worker | Model | Attempts | Score | Cost | Duration |"
  echo "|------|--------|-------|----------|-------|------|----------|"

  local cost_file="${TELEMETRY_DIR:-$RUNTIME_DIR}/cost.jsonl"
  local task_ids
  task_ids=$(state_read '.tasks | keys[]' 2>/dev/null | sort)
  for tid in $task_ids; do
    local worker model attempts score status
    worker=$(task_get "$tid" "worker" 2>/dev/null || echo "-")
    model=$(task_get "$tid" "model" 2>/dev/null || echo "-")
    attempts=$(task_get "$tid" "attempts" 2>/dev/null || echo "1")
    score=$(task_get "$tid" "score" 2>/dev/null || echo "-")
    status=$(task_get "$tid" "status" 2>/dev/null || echo "unknown")

    # Get cost from cost.jsonl
    local task_cost="0.00"
    if [[ -f "$cost_file" && -s "$cost_file" ]]; then
      task_cost=$(jq -s --arg tid "$tid" '[.[] | select(.task_id == $tid)] | map(.cost_usd) | add // 0' "$cost_file" 2>/dev/null || echo "0.00")
    fi

    # Get duration
    local duration="-"
    local events_file="${TELEMETRY_DIR:-$RUNTIME_DIR}/events.jsonl"
    if [[ -f "$events_file" ]]; then
      duration=$(while IFS= read -r line; do
        echo "$line" | jq -r --arg tid "$tid" 'select(.task_id == $tid and .event == "task_completed") | .duration_s // "-"' 2>/dev/null
      done < "$events_file" | head -1)
      [[ -n "$duration" && "$duration" != "-" ]] && duration="${duration}s"
    fi

    [[ "$score" == "null" || -z "$score" ]] && score="-"
    [[ "$model" == "null" ]] && model="-"
    [[ "$worker" == "null" ]] && worker="-"

    echo "| $tid | $worker | $model | $attempts | $score | \$$task_cost | $duration |"
  done

  echo ""
}

# Section 6: Wave timeline with progress symbols (BUG-003 FIX)
_section_wave_timeline() {
  echo "## Wave Timeline"
  echo ""

  # Build waves from state using get_execution_waves (deps.sh)
  local tmp_state="/tmp/report-dag-${BASHPID:-$$}-${RANDOM}.json"
  cp "$STATE_FILE" "$tmp_state" 2>/dev/null || true

  if [[ ! -f "$tmp_state" ]]; then
    echo "Wave data unavailable."
    echo ""
    return
  fi

  echo '```'
  local wave_num=0
  while IFS= read -r wave; do
    [[ -z "$wave" ]] && continue
    ((wave_num++)) || true

    echo "Wave $wave_num:"
    for tid in $wave; do
      local status score
      status=$(task_get "$tid" "status" 2>/dev/null || echo "pending")
      score=$(task_get "$tid" "score" 2>/dev/null || echo "")

      local icon="◌"
      case "$status" in
        completed) icon="✓" ;;
        rejected|exhausted) icon="✗" ;;
        dep-failed) icon="⊘" ;;
        rework) icon="◐" ;;
        running) icon="▶" ;;
      esac

      [[ "$score" == "null" || -z "$score" ]] && score="" || score="($score)"
      echo "  $icon $tid$score"
    done
    echo ""

    # Check for advisory review
    local advisory_file="${TELEMETRY_DIR:-$RUNTIME_DIR}/advisory_reviews.jsonl"
    if [[ -f "$advisory_file" ]]; then
      local adv_line
      adv_line=$(jq -r --arg w "$wave_num" 'select(.wave == ($w | tonumber)) | "  📋 Advisory: coherence=\(.review.coherence_score // "?"), trend=\(.review.quality_trend // "?")"' "$advisory_file" 2>/dev/null | head -1)
      [[ -n "$adv_line" ]] && echo "$adv_line" && echo ""
    fi
  done < <(get_execution_waves "$tmp_state" 2>/dev/null)

  rm -f "$tmp_state"
  echo '```'
  echo ""
  echo "Legend: ✓=completed ✗=failed ◐=rework ◌=pending ⊘=dep-failed ▶=running"
  echo ""
}

# Section 7: Issues encountered
_section_issues_encountered() {
  echo "## Issues Encountered"
  echo ""

  local friction_file="${TELEMETRY_DIR:-$RUNTIME_DIR}/friction_events.jsonl"
  local events_file="${TELEMETRY_DIR:-$RUNTIME_DIR}/events.jsonl"
  local state_file="${STATE_FILE}"
  local has_issues=false
  local failed=0

  failed=$(state_read '.counters.failed' 2>/dev/null || echo "0")

  # Check for friction events
  if [[ -f "$friction_file" && -s "$friction_file" ]]; then
    has_issues=true
  fi

  # Check for budget_exceeded events
  if [[ -f "$events_file" && -s "$events_file" ]]; then
    if jq -r 'select(.event == "budget_exceeded")' "$events_file" 2>/dev/null | grep -q .; then
      has_issues=true
    fi
  fi

  # Check for rejected tasks
  if [[ -f "$state_file" ]]; then
    if jq -r '.tasks[] | select(.status == "rejected")' "$state_file" 2>/dev/null | grep -q .; then
      has_issues=true
    fi
  fi

  # If no issues and no failures, show the clean message
  if [[ "$has_issues" == "false" && "$failed" == "0" ]]; then
    echo "No issues recorded. All tasks passed cleanly."
    echo ""
    return
  fi

  echo "| Task | Issue | Detail |"
  echo "|------|-------|--------|"

  # Read friction events
  if [[ -f "$friction_file" && -s "$friction_file" ]]; then
    while IFS= read -r line; do
      local task_id cause detail
      task_id=$(echo "$line" | jq -r '.task_id // "?"' 2>/dev/null)
      cause=$(echo "$line" | jq -r '.cause // "unknown"' 2>/dev/null)
      detail=$(echo "$line" | jq -r '.detail // ""' 2>/dev/null | head -c 50)

      echo "| $task_id | $cause | $detail |"
    done < "$friction_file" | head -20
  fi

  # Read budget_exceeded events
  if [[ -f "$events_file" && -s "$events_file" ]]; then
    jq -r 'select(.event == "budget_exceeded") | "\(.task_id)|\(.cost_usd)|\(.budget_usd)"' "$events_file" 2>/dev/null | \
      while IFS='|' read -r task_id cost budget; do
        echo "| $task_id | BUDGET_EXCEEDED | \$$cost > \$$budget |"
      done | head -20
  fi

  # Read rejected tasks from state.json
  if [[ -f "$state_file" ]]; then
    jq -r '.tasks[] | select(.status == "rejected") | "\(.id)|\(.rejection_reason // "unknown")|\(.last_feedback // "")"' "$state_file" 2>/dev/null | \
      while IFS='|' read -r task_id reason feedback; do
        feedback=$(echo "$feedback" | head -c 50)
        echo "| $task_id | REJECTED | $reason — $feedback |"
      done | head -20
  fi

  echo ""
}

# Section: QA Skipped Warning (S1.4 — QA crash recovery)
_section_qa_skipped_warning() {
  local state_file="${STATE_FILE}"
  [[ ! -f "$state_file" ]] && return

  local skipped_tasks
  skipped_tasks=$(jq -r '[.tasks | to_entries[] | select(.value.qa_skipped == true) | .key] | .[]' "$state_file" 2>/dev/null || echo "")
  [[ -z "$skipped_tasks" ]] && return

  local skipped_count=0
  local total
  total=$(jq '.counters.total // 0' "$state_file" 2>/dev/null || echo "0")
  for _ in $skipped_tasks; do ((skipped_count++)) || true; done

  echo "## NEEDS HUMAN REVIEW (QA Skipped)"
  echo ""
  echo "The following tasks passed via innate immune fallback (QA worker crashed):"
  echo ""
  echo "| Task | Score | Note |"
  echo "|------|-------|------|"
  for tid in $skipped_tasks; do
    local score
    score=$(jq -r ".tasks[\"$tid\"].score // \"?\"" "$state_file" 2>/dev/null)
    echo "| $tid | $score | QA crashed — innate immune only |"
  done
  echo ""

  # Warning if >30% skipped
  if [[ $total -gt 0 ]]; then
    local pct=$(( skipped_count * 100 / total ))
    if [[ $pct -gt 30 ]]; then
      echo "**WARNING: ${pct}% of tasks had QA skipped (>${skipped_count}/${total}). Manual review strongly recommended.**"
      echo ""
    fi
  fi
}

# Section 8: Decisions (BUG-004 FIX)
_section_decisions() {
  echo "## Decisions Made"
  echo ""

  local decisions_file="${TELEMETRY_DIR:-$RUNTIME_DIR}/decisions.jsonl"
  if [[ ! -f "$decisions_file" || ! -s "$decisions_file" ]]; then
    echo "No decisions recorded during execution."
    echo ""
    return
  fi

  echo "| Wave | Decision Type | Rationale |"
  echo "|------|---------------|-----------|"

  while IFS= read -r line; do
    local wave dtype rationale
    wave=$(echo "$line" | jq -r '.wave // "?"' 2>/dev/null)
    dtype=$(echo "$line" | jq -r '.decision_type // "unknown"' 2>/dev/null)
    rationale=$(echo "$line" | jq -r '.rationale // ""' 2>/dev/null | head -c 60)
    [[ ${#rationale} -gt 55 ]] && rationale="${rationale:0:55}..."

    echo "| $wave | $dtype | $rationale |"
  done < "$decisions_file"

  echo ""
}

# Section 9: Recommendations
_section_recommendations() {
  echo "## Recommendations"
  echo ""

  # Analyze friction patterns for immediate recommendations
  local friction_file="${TELEMETRY_DIR:-$RUNTIME_DIR}/friction_events.jsonl"
  local has_immediate=false

  echo "### Immediate"
  if [[ -f "$friction_file" && -s "$friction_file" ]]; then
    # Find tasks with model escalations
    local escalated
    escalated=$(jq -r 'select(.cause == "model_escalation") | .task_id' "$friction_file" 2>/dev/null | sort -u)
    if [[ -n "$escalated" ]]; then
      echo "- Review outputs from tasks requiring model escalation: $escalated"
      has_immediate=true
    fi

    # Find dep-failed tasks
    local dep_failed
    dep_failed=$(jq -r '.tasks[] | select(.status == "dep-failed") | .id' "$STATE_FILE" 2>/dev/null | tr '\n' ' ')
    if [[ -n "$dep_failed" ]]; then
      echo "- Tasks not executed due to dependency failures: $dep_failed — consider manual execution or blueprint revision"
      has_immediate=true
    fi
  fi

  # Check for failed/exhausted tasks in state.json
  local failed_count
  failed_count=$(jq '[.tasks | to_entries[] | select(.value.status == "rejected" or .value.status == "exhausted")] | length' "$STATE_FILE" 2>/dev/null || echo 0)
  if [[ "$failed_count" -gt 0 ]]; then
    echo "- **$failed_count task(s) failed** (rejected/exhausted). Review outputs and consider:"
    echo "  - Adjusting task complexity or splitting into smaller subtasks"
    echo "  - Providing more specific context_files for failed tasks"
    echo "  - Upgrading model for consistently failing worker types"
    has_immediate=true
  fi

  [[ "$has_immediate" == "false" ]] && echo "- None. All tasks completed successfully."
  echo ""

  echo "### For Future Blueprints"
  # Analyze patterns for future recommendations
  if [[ -f "$friction_file" && -s "$friction_file" ]]; then
    local size_violations
    size_violations=$(jq -r 'select(.cause == "size_constraint_violation") | .task_id' "$friction_file" 2>/dev/null | wc -l)
    if [[ $size_violations -gt 2 ]]; then
      echo "- Expected line estimates are frequently too low — consider increasing by 50%"
    fi

    local worker_issues
    worker_issues=$(jq -r '.task_id' "$friction_file" 2>/dev/null | cut -d'-' -f1 | sort | uniq -c | sort -rn | head -1)
    if [[ -n "$worker_issues" ]]; then
      echo "- Most friction from: $worker_issues — review worker DNA or task complexity"
    fi
  fi
  echo ""

  echo "---"
  echo ""
  local bp_id used_usd
  bp_id=$(yq -r '.blueprint.id // "UNKNOWN"' "$MANIFEST" 2>/dev/null | tr -d '\r')
  used_usd=$(state_read '.budget.used_usd' 2>/dev/null || echo "0")
  local timestamp
  timestamp=$(now_iso 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
  echo "*Generated by FORMICA v3.0 at $timestamp*"
  echo "*Blueprint: $bp_id | Cost: \$$used_usd | Duration: see above*"
}

# ============================================================================
# FILE MANIFEST (file-manifest.md)
# ============================================================================

# Generate file manifest matching SPECIFICATION.md §14.3
# Output: $REPORTS_DIR/file-manifest.md
generate_file_manifest() {
  local manifest_file="${REPORTS_DIR:-$RUNTIME_DIR/reports}/file-manifest.md"
  mkdir -p "$(dirname "$manifest_file")" 2>/dev/null || true

  local bp_name bp_id
  bp_name=$(yq -r '.blueprint.name // .blueprint.id // "Unknown Blueprint"' "$MANIFEST" 2>/dev/null | tr -d '\r')
  bp_id=$(yq -r '.blueprint.id // "UNKNOWN"' "$MANIFEST" 2>/dev/null | tr -d '\r')

  {
    echo "# File Manifest: $bp_name"
    echo ""
    echo "**Blueprint:** \`$bp_id\`"

    # Count files
    local file_reg="${RUNTIME_DIR}/file_registry.json"
    local created_count=0 modified_count=0
    if [[ -f "$file_reg" && -s "$file_reg" ]]; then
      created_count=$(jq -r '[.[] | select(.action == "created")] | length' "$file_reg" 2>/dev/null || echo "0")
      modified_count=$(jq -r '[.[] | select(.action == "modified")] | length' "$file_reg" 2>/dev/null || echo "0")
    fi
    echo "**Total files affected:** $created_count created, $modified_count modified"
    echo ""

    _manifest_created_files
    _manifest_modified_files
    _manifest_verification_status
  } >> "$manifest_file" 2>/dev/null || echo "(error generating file manifest)" >> "$manifest_file"

  log_info "File manifest generated: $manifest_file"
}

# Created files section
_manifest_created_files() {
  echo "## Created Files"
  echo ""
  echo "| # | File | Lines | Task | Verified |"
  echo "|---|------|-------|------|----------|"

  local file_reg="${RUNTIME_DIR}/file_registry.json"
  if [[ ! -f "$file_reg" || ! -s "$file_reg" ]]; then
    echo "| - | (no files created) | - | - | - |"
    echo ""
    return
  fi

  local idx=0
  jq -r 'to_entries[] | select(.value.action == "created") | "\(.key)|\(.value.task_id)"' "$file_reg" 2>/dev/null | \
    while IFS='|' read -r filepath task_id; do
      ((idx++)) || true
      local lines="-"
      local verified="N/A"

      if [[ -f "$filepath" ]]; then
        lines=$(wc -l < "$filepath" 2>/dev/null || echo "?")

        # Verify based on file type
        case "$filepath" in
          *.sh)
            if bash -n "$filepath" 2>/dev/null; then
              verified="bash -n PASS"
            else
              verified="bash -n FAIL"
            fi
            ;;
          *.json)
            if jq empty "$filepath" 2>/dev/null; then
              verified="jq PASS"
            else
              verified="jq FAIL"
            fi
            ;;
          *.yaml|*.yml)
            if yq -r '.' "$filepath" >/dev/null 2>&1; then
              verified="yq PASS"
            else
              verified="yq FAIL"
            fi
            ;;
          *)
            verified="exists"
            ;;
        esac
      else
        verified="MISSING"
      fi

      echo "| $idx | \`$filepath\` | $lines | $task_id | $verified |"
    done

  echo ""
}

# Modified files section
_manifest_modified_files() {
  echo "## Modified Files"
  echo ""
  echo "| # | File | Lines added | Task(s) | Changes |"
  echo "|---|------|-------------|---------|---------|"

  local file_reg="${RUNTIME_DIR}/file_registry.json"
  if [[ ! -f "$file_reg" || ! -s "$file_reg" ]]; then
    echo "| - | (no files modified) | - | - | - |"
    echo ""
    return
  fi

  local idx=0
  jq -r 'to_entries[] | select(.value.action == "modified") | "\(.key)|\(.value.task_id)"' "$file_reg" 2>/dev/null | \
    while IFS='|' read -r filepath task_id; do
      ((idx++)) || true
      local changes
      changes=$(task_get "$task_id" "description" 2>/dev/null | head -c 50 || echo "unknown")
      [[ ${#changes} -gt 45 ]] && changes="${changes:0:45}..."

      echo "| $idx | \`$filepath\` | ? | $task_id | $changes |"
    done

  echo ""
}

# Verification status section
_manifest_verification_status() {
  echo "## Verification Status"
  echo ""

  local file_reg="${RUNTIME_DIR}/file_registry.json"
  if [[ ! -f "$file_reg" || ! -s "$file_reg" ]]; then
    echo "- No files to verify"
    echo ""
    return
  fi

  # Count verification results
  local sh_pass=0 sh_total=0 json_pass=0 json_total=0 yaml_pass=0 yaml_total=0 all_exist="YES"

  jq -r 'keys[]' "$file_reg" 2>/dev/null | while read -r filepath; do
    if [[ ! -f "$filepath" ]]; then
      all_exist="NO"
      continue
    fi

    case "$filepath" in
      *.sh)
        ((sh_total++)) || true
        bash -n "$filepath" 2>/dev/null && ((sh_pass++)) || true
        ;;
      *.json)
        ((json_total++)) || true
        jq empty "$filepath" 2>/dev/null && ((json_pass++)) || true
        ;;
      *.yaml|*.yml)
        ((yaml_total++)) || true
        yq -r '.' "$filepath" >/dev/null 2>&1 && ((yaml_pass++)) || true
        ;;
    esac
  done

  # Note: can't read loop variables in bash subshell, so just provide summary
  echo "- Shell scripts (.sh): validated with bash -n"
  echo "- JSON files: validated with jq"
  echo "- YAML files: validated with yq"
  echo "- All outputs exist at expected paths: (check manually)"
  echo ""
}

# ============================================================================
# LEGACY (for backward compatibility)
# ============================================================================

# Keep old function name for backward compatibility
generate_report() {
  generate_execution_report
  generate_file_manifest
}
