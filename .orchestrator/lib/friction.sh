#!/usr/bin/env bash
# friction.sh — Friction event extraction, cause classification, and summary
# FORMICA v3.0: Every non-PASS verdict is a friction event with a classified cause.

[[ -n "${_FRICTION_SH_LOADED:-}" ]] && return 0
_FRICTION_SH_LOADED=1

# ============================================================================
# FRICTION EVENT EXTRACTION
# ============================================================================

# Extract and classify friction event after non-PASS QA verdict
# Called from orchestrate.sh after route_verdict returns non-zero
extract_friction_event() {
  local task_id="$1"
  local worker_type="$2"
  local verdict="$3"
  local score="$4"
  local feedback="$5"
  local attempt="$6"

  local cause
  cause=$(_classify_friction_cause "$feedback")

  local friction_file="${RUNTIME_DIR}/friction_events.jsonl"
  local ts
  ts=$(now_iso)

  # Escape quotes in feedback for JSON
  local safe_feedback
  local _max_fb=$(config_read "friction.max_feedback_chars" "500")
  safe_feedback=$(echo "$feedback" | tr '"' "'" | tr '\n' ' ' | head -c "$_max_fb")

  append_jsonl "$friction_file" "{\"ts\":\"$ts\",\"task_id\":\"$task_id\",\"worker_type\":\"$worker_type\",\"verdict\":\"$verdict\",\"score\":$score,\"cause\":\"$cause\",\"attempt\":$attempt,\"feedback\":\"$safe_feedback\"}"

  log_debug "Friction event: task=$task_id cause=$cause verdict=$verdict score=$score"
}

# Classify friction cause by keyword matching on QA feedback
# Returns one of 8 categories (ordered by specificity — most specific first):
#   1. size_constraint_violation
#   2. budget_exhaustion
#   3. output_duplication
#   4. protocol_violation
#   5. format_violation
#   6. incomplete_output
#   7. missing_quantitative_data
#   8. quality_below_threshold
_classify_friction_cause() {
  local feedback="$1"
  local lower
  lower=$(echo "$feedback" | tr '[:upper:]' '[:lower:]')

  # Most specific causes first (prevents misclassification)
  if echo "$lower" | grep -qE 'word.?count|too (long|short)|exceed.* words|over.* words|under.* words|length|verbose|concise|trim'; then
    echo "size_constraint_violation"
  elif echo "$lower" | grep -qE 'budget|exceeded.*budget|killed|token.?limit|truncat|max.?budget'; then
    echo "budget_exhaustion"
  elif echo "$lower" | grep -qE 'duplicat|repeated|verbatim|copied|append|twice|double'; then
    echo "output_duplication"
  elif echo "$lower" | grep -qE 'preamble|commentary|process|"let me"|"i will"|"writing.*to"'; then
    echo "protocol_violation"
  elif echo "$lower" | grep -qE 'format|structure|syntax|schema|invalid|parse|yaml|json'; then
    echo "format_violation"
  elif echo "$lower" | grep -qE 'missing|incomplete|lacking|absent|not found|omit'; then
    echo "incomplete_output"
  elif echo "$lower" | grep -qE 'quantitative|number|count|metric|data|statistic|evidence|cite'; then
    echo "missing_quantitative_data"
  else
    echo "quality_below_threshold"
  fi
}

# ============================================================================
# FRICTION TREND ANALYSIS
# ============================================================================

# Analyze friction trend by comparing last 5 events vs previous 5
# Returns: "increasing" | "stable" | "decreasing"
# Used by meta-supervisor OODA loop (orient phase)
friction_trend() {
  local friction_file="${RUNTIME_DIR}/friction_events.jsonl"

  [[ ! -f "$friction_file" || ! -s "$friction_file" ]] && echo "stable" && return 0

  local total_lines
  total_lines=$(wc -l < "$friction_file")

  # Need at least N events to calculate trend
  local _trend_min=$(config_read "friction.trend_min_events" "10")
  [[ "$total_lines" -lt "$_trend_min" ]] && echo "stable" && return 0

  # Extract last N and previous N events
  local _trend_win=$(config_read "friction.trend_window_size" "5")
  local recent_score previous_score
  recent_score=$(tail -"$_trend_win" "$friction_file" | jq -s '[.[].score] | add / length' 2>/dev/null || echo "0")
  previous_score=$(tail -$((_trend_win * 2)) "$friction_file" | head -"$_trend_win" | jq -s '[.[].score] | add / length' 2>/dev/null || echo "0")

  # Scores are 0.0-1.0, higher score = more severe
  # If recent is higher, friction is increasing
  local delta
  delta=$(awk "BEGIN {printf \"%.3f\", $recent_score - $previous_score}")

  local _trend_delta=$(config_read "friction.trend_delta_threshold" "0.05")
  if awk -v d="$delta" -v t="$_trend_delta" "BEGIN {exit !(d > t)}"; then
    echo "increasing"
  elif awk -v d="$delta" -v t="$_trend_delta" "BEGIN {exit !(d < -t)}"; then
    echo "decreasing"
  else
    echo "stable"
  fi
}

# Check if same cause appears >= threshold times consecutively in recent events
# Returns: 0 (true) if threshold met, 1 (false) otherwise
# Args: cause, threshold (default 3)
same_cause_consecutive() {
  local cause="$1"
  local threshold="${2:-3}"
  local friction_file="${RUNTIME_DIR}/friction_events.jsonl"

  [[ ! -f "$friction_file" || ! -s "$friction_file" ]] && return 1

  local consecutive=0
  local event_cause
  while IFS= read -r event_cause; do
    if [[ "$event_cause" == "$cause" ]]; then
      ((consecutive++)) || true
      [[ $consecutive -ge $threshold ]] && return 0
    else
      consecutive=0
    fi
  local _cons_win=$(config_read "friction.consecutive_scan_window" "15")
  done < <(tail -"$_cons_win" "$friction_file" | jq -r '.cause' 2>/dev/null)

  return 1
}

# ============================================================================
# FRICTION SUMMARY (for reports and meta-report)
# ============================================================================

# Get friction summary as JSON
# Returns: { causes: { cause: count }, affected_tasks: [...], worker_types: { type: count } }
get_friction_summary() {
  local friction_file="${RUNTIME_DIR}/friction_events.jsonl"

  if [[ ! -f "$friction_file" || ! -s "$friction_file" ]]; then
    echo '{"causes":{},"affected_tasks":[],"worker_types":{},"total":0}'
    return 0
  fi

  jq -s '{
    causes: (group_by(.cause) | map({key: .[0].cause, value: length}) | from_entries),
    affected_tasks: ([.[].task_id] | unique),
    worker_types: (group_by(.worker_type) | map({key: .[0].worker_type, value: length}) | from_entries),
    total: length
  }' "$friction_file" 2>/dev/null || echo '{"causes":{},"affected_tasks":[],"worker_types":{},"total":0}'
}

# Get friction patterns for a specific worker type (used by context.sh Layer 7)
# Returns human-readable warnings for injection into worker context
get_worker_friction() {
  local worker_type="$1"
  local friction_file="${RUNTIME_DIR}/friction_events.jsonl"

  [[ ! -f "$friction_file" || ! -s "$friction_file" ]] && return 0

  local worker_events
  worker_events=$(jq -s --arg wt "$worker_type" '[.[] | select(.worker_type == $wt)]' "$friction_file" 2>/dev/null)

  local event_count
  event_count=$(echo "$worker_events" | jq 'length' 2>/dev/null || echo "0")
  [[ "$event_count" -eq 0 ]] && return 0

  # Group by cause and format as warnings
  echo "$worker_events" | jq -r '
    group_by(.cause) |
    sort_by(-length) |
    .[:'$(config_read "friction.max_worker_patterns" "5")'] |
    .[] |
    "- \(.[0].cause) (\(length) occurrence\(if length > 1 then "s" else "" end)): \(.[0].feedback | split(" ") | .[:20] | join(" "))..."
  ' 2>/dev/null
}
