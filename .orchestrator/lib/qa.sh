#!/usr/bin/env bash
# qa.sh — QA execution, verdict parsing, routing, immune system, colony signaling
# Biomimetic patterns: Immune System (Pattern 6), Trophallaxis (Pattern 2)

[[ -n "${_QA_SH_LOADED:-}" ]] && return 0
_QA_SH_LOADED=1

# ============================================================================
# IMMUNE SYSTEM — Three-layer defense (Pattern 6)
# ============================================================================

# Layer 1: Pre-spawn barriers — catch doomed tasks before spending tokens
# Returns 0 if clear, 1 if task should be skipped
pre_spawn_barriers() {
  local task_id="$1"
  local worker_name="$2"
  local task_budget="${3:-0.50}"

  # Check 1: Budget sufficient
  if ! budget_has_remaining "$task_budget" 2>/dev/null; then
    log_warn "Immune barrier: budget insufficient for task $task_id"
    log_event "{\"ts\":\"$(now_iso)\",\"event\":\"immune_barrier\",\"task_id\":\"$task_id\",\"reason\":\"budget_insufficient\"}"
    return 1
  fi

  # Check 2: Worker DNA exists
  local worker_prompt
  worker_prompt=$(yq -r ".workers.$worker_name.prompt // \"\"" "$MANIFEST" 2>/dev/null | tr -d '\r')
  if [[ -z "$worker_prompt" || ! -f "$ORCHESTRATOR_DIR/$worker_prompt" ]]; then
    log_warn "Immune barrier: worker DNA not found for $worker_name (task $task_id)"
    log_event "{\"ts\":\"$(now_iso)\",\"event\":\"immune_barrier\",\"task_id\":\"$task_id\",\"reason\":\"worker_dna_missing\",\"worker\":\"$worker_name\"}"
    return 1
  fi

  # Check 3: Output directory writable
  local output_path
  output_path=$(get_task_field_from_manifest "$task_id" "output" "" 2>/dev/null)
  if [[ -n "$output_path" && -n "$PROJECT_DIR" ]]; then
    output_path="$PROJECT_DIR/$output_path"
  fi
  if [[ -n "$output_path" ]]; then
    local output_dir
    output_dir=$(dirname "$output_path")
    if [[ -n "$output_dir" ]] && ! mkdir -p "$output_dir" 2>/dev/null; then
      log_warn "Immune barrier: cannot create output directory for task $task_id"
      log_event "{\"ts\":\"$(now_iso)\",\"event\":\"immune_barrier\",\"task_id\":\"$task_id\",\"reason\":\"output_dir_unwritable\"}"
      return 1
    fi
  fi

  return 0
}

# Layer 2: Innate immune check — post-execution, pre-QA format validation
# Returns 0 if output passes basic checks, 1 if it fails
innate_immune_check() {
  local task_id="$1"
  local output_file="$2"
  local expected_format="${3:-}"     # json|yaml|sh|md (from manifest)
  local expected_lines="${4:-0}"     # Expected line count (0 = skip check)

  local violations=""

  # Check 1: File exists and non-empty
  if [[ ! -f "$output_file" ]]; then
    violations="${violations}FILE_MISSING "
  elif [[ ! -s "$output_file" ]]; then
    violations="${violations}FILE_EMPTY "
  else
    # Check 2: Size sanity (10B - 500KB)
    local file_size
    file_size=$(wc -c < "$output_file" 2>/dev/null || echo "0")
    local _min_bytes=$(config_read "immune.min_file_bytes" "10")
    local _max_bytes=$(config_read "immune.max_file_bytes" "512000")
    if [[ $file_size -lt $_min_bytes ]]; then
      violations="${violations}TOO_SMALL($file_size) "
    elif [[ $file_size -gt $_max_bytes ]]; then
      violations="${violations}TOO_LARGE($file_size) "
    fi

    # Check 3: Format validation
    case "$expected_format" in
      json)
        if ! jq '.' "$output_file" >/dev/null 2>&1; then
          violations="${violations}INVALID_JSON "
        fi
        ;;
      yaml)
        if command -v yq &>/dev/null; then
          if ! yq '.' "$output_file" >/dev/null 2>&1; then
            violations="${violations}INVALID_YAML "
          fi
        fi
        ;;
      sh)
        if ! bash -n "$output_file" 2>/dev/null; then
          violations="${violations}INVALID_SHELL "
        fi
        ;;
      md)
        # Check for at least one header
        if ! grep -qE '^#' "$output_file" 2>/dev/null; then
          violations="${violations}NO_MD_HEADER "
        fi
        ;;
    esac

    # Check 4: Line count sanity (30%-300% of expected)
    if [[ "$expected_lines" -gt 0 ]]; then
      local actual_lines
      actual_lines=$(wc -l < "$output_file" 2>/dev/null || echo "0")
      local _lc_min=$(config_read "immune.line_count_min_pct" "30")
      local _lc_max=$(config_read "immune.line_count_max_pct" "300")
      local min_lines=$((expected_lines * _lc_min / 100))
      local max_lines=$((expected_lines * _lc_max / 100))
      if [[ $actual_lines -lt $min_lines || $actual_lines -gt $max_lines ]]; then
        violations="${violations}LINE_COUNT($actual_lines,expected~$expected_lines) "
      fi
    fi

    # Check 5: Worker protocol violation — preamble/process commentary
    local first_line
    first_line=$(head -1 "$output_file" 2>/dev/null | tr '[:upper:]' '[:lower:]')
    if echo "$first_line" | grep -qEi '(let me|i will|i have|writing.*to|the path|here is|sure|okay|certainly)'; then
      violations="${violations}PREAMBLE_DETECTED "
    fi

    # Check 6: Immune memory matching
    local immune_memory="$RUNTIME_DIR/immune_memory.jsonl"
    if [[ -f "$immune_memory" ]]; then
      while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue
        local pattern response
        pattern=$(echo "$entry" | jq -r '.pattern // ""' 2>/dev/null | tr -d '\r')
        response=$(echo "$entry" | jq -r '.response // "flag"' 2>/dev/null | tr -d '\r')
        if [[ -n "$pattern" ]] && grep -qE "$pattern" "$output_file" 2>/dev/null; then
          violations="${violations}IMMUNE_MEMORY($pattern,$response) "
        fi
      done < "$immune_memory"
    fi
  fi

  # Report violations
  if [[ -n "$violations" ]]; then
    violations=$(echo "$violations" | xargs)  # Trim whitespace
    log_warn "Innate immune: task $task_id failed checks: $violations"
    append_jsonl "$RUNTIME_DIR/immune_events.jsonl" "{\"ts\":\"$(now_iso)\",\"task_id\":\"$task_id\",\"violations\":\"$violations\"}"
    log_event "{\"ts\":\"$(now_iso)\",\"event\":\"innate_immune_reject\",\"task_id\":\"$task_id\",\"violations\":\"$violations\"}"
    # Emit friction event so epigenetics can learn from innate immune rejections
    append_jsonl "${RUNTIME_DIR}/friction_events.jsonl" "{\"ts\":\"$(now_iso)\",\"task_id\":\"$task_id\",\"worker_type\":\"${CURRENT_WORKER_TYPE:-unknown}\",\"cause\":\"innate_immune_rejection\",\"detail\":\"$violations\"}"
    return 1
  fi

  return 0
}

# ============================================================================
# COLONY SIGNALING — Trophallaxis (Pattern 2)
# ============================================================================

# Extract colony signal from QA response and append to colony_signals.jsonl
extract_colony_signal() {
  local qa_response_file="$1"
  local task_id="$2"
  local wave_num="${3:-0}"

  [[ ! -f "$qa_response_file" ]] && return 0

  # Try to extract colony_signal from structured output
  local signal_type signal_text intensity
  signal_type=$(jq -r '.structured_output.colony_signal.type // empty' "$qa_response_file" 2>/dev/null | tr -d '\r')
  signal_text=$(jq -r '.structured_output.colony_signal.signal // empty' "$qa_response_file" 2>/dev/null | tr -d '\r')
  intensity=$(jq -r '.structured_output.colony_signal.intensity // empty' "$qa_response_file" 2>/dev/null | tr -d '\r')

  # Skip if no signal emitted
  [[ -z "$signal_type" || -z "$signal_text" ]] && return 0

  # Default intensity to 0.5
  [[ -z "$intensity" || "$intensity" == "null" ]] && intensity="0.5"

  # Append to colony signals log
  local signals_file="$RUNTIME_DIR/colony_signals.jsonl"
  append_jsonl "$signals_file" "{\"ts\":\"$(now_iso)\",\"task_id\":\"$task_id\",\"wave\":$wave_num,\"type\":\"$signal_type\",\"signal\":\"$(echo "$signal_text" | tr '"' "'")\",\"intensity\":$intensity}"

  log_debug "Colony signal extracted: type=$signal_type, intensity=$intensity (from $task_id)"
  return 0
}

# Execute QA review on task output
run_qa() {
  local task_id="$1"
  local output_file="$2"
  local qa_criteria="$3"       # JSON array
  local qa_threshold="$4"
  local qa_model="$5"
  local project_dir="$6"
  local attempt_num="$7"
  local qa_budget="${8:-0.20}"  # QA budget per call (default $0.20)

  local qa_log="$ATTEMPTS_DIR/${task_id}-attempt-${attempt_num}/qa.log"
  local qa_response="$ATTEMPTS_DIR/${task_id}-attempt-${attempt_num}/qa-response.json"

  if [[ ! -f "$output_file" ]]; then
    log_error "QA cannot proceed: output file missing: $output_file"
    return 2
  fi

  # Build QA prompt
  local criteria_list=$(echo "$qa_criteria" | jq -r 'to_entries | map("\(.key + 1). \(.value)") | join("\n")')

  local qa_prompt=$(cat <<EOF
# QA REVIEW

Review the following output for task "$task_id".

## Output to Review

$(cat "$output_file")

## Criteria

$criteria_list

## Scoring

Score 0-100 based on criteria above. Each criterion has equal weight.
- 90-100: Excellent, meets all criteria with high quality
- 80-89: Good, meets all criteria adequately
- 70-79: Acceptable, minor issues
- 60-69: Below standard, significant issues — needs rework
- Below 60: Unacceptable, fundamental problems — reject

Return your verdict as JSON with this structure:
{
  "score": <number 0-100>,
  "verdict": "<PASS|REWORK|REJECT>",
  "feedback": "<constructive feedback, especially for issues>"
}

Use PASS if score >= $qa_threshold, REWORK if 60 <= score < $qa_threshold, REJECT if score < 60.

IMPORTANT: Also check SCOPE COMPLIANCE. The output should implement EXACTLY what was requested — no more, no less. If the output adds features, sections, or content NOT in the criteria, flag as SCOPE_VIOLATION and reduce score by 10 points.
EOF
)

  log_info "Running QA for task $task_id (attempt $attempt_num)"

  # Execute QA instance
  echo "$qa_prompt" | \
    env -u CLAUDECODE claude -p \
      --append-system-prompt "$(cat "$ORCHESTRATOR_DIR/workers/qa.md")" \
      --model "$qa_model" \
      --max-budget-usd "$qa_budget" \
      --tools "" \
      --setting-sources "" \
      --output-format json \
      --json-schema "$(cat "$ORCHESTRATOR_DIR/schemas/qa-verdict.json")" \
      --no-session-persistence \
      --dangerously-skip-permissions \
      2>"$qa_log" | tr -d '\r' > "$qa_response"

  local qa_exit=$?

  if [[ $qa_exit -ne 0 ]]; then
    log_error "QA execution failed (exit $qa_exit). See: $qa_log"
    return 2
  fi

  # Record QA cost after successful execution
  local qa_cost
  local qa_input_tokens qa_output_tokens
  qa_cost=$(extract_cost_from_response "$qa_response" "$qa_model")
  read -r qa_input_tokens qa_output_tokens < <(extract_tokens_from_response "$qa_response")
  record_cost "qa-${task_id}" "$attempt_num" "$qa_cost" "$qa_model" "$qa_input_tokens" "$qa_output_tokens" "qa"

  log_info "QA completed. Response: $qa_response"
  return 0
}

# Parse verdict from QA response JSON
# Handles both structured JSON and free-form text in .result field
parse_verdict() {
  local qa_response_file="$1"

  if [[ ! -f "$qa_response_file" ]]; then
    echo "0|REJECT|QA response file not found"
    return 1
  fi

  local score="" verdict="" feedback=""

  # Strategy 1: --json-schema puts structured data in .structured_output
  score=$(jq -r '.structured_output.score // empty' "$qa_response_file" 2>/dev/null | tr -d '\r')
  verdict=$(jq -r '.structured_output.verdict // empty' "$qa_response_file" 2>/dev/null | tr -d '\r')
  feedback=$(jq -r '.structured_output.feedback // empty' "$qa_response_file" 2>/dev/null | tr -d '\r')

  # Strategy 2: Try .result as JSON (legacy or non-schema mode)
  if [[ -z "$score" || ! "$score" =~ ^[0-9]+$ ]]; then
    local result
    result=$(jq -r '.result // .content // ""' "$qa_response_file" 2>/dev/null | tr -d '\r')

    if [[ -n "$result" && "$result" != "null" ]]; then
      # Try parsing result as JSON
      local parsed_score
      parsed_score=$(echo "$result" | jq -r '.score // empty' 2>/dev/null | tr -d '\r')
      if [[ -n "$parsed_score" && "$parsed_score" =~ ^[0-9]+$ ]]; then
        score="$parsed_score"
        verdict=$(echo "$result" | jq -r '.verdict // empty' 2>/dev/null | tr -d '\r')
        feedback=$(echo "$result" | jq -r '.feedback // empty' 2>/dev/null | tr -d '\r')
      fi
    fi
  fi

  # Strategy 3: Extract from free-form text
  if [[ -z "$score" || ! "$score" =~ ^[0-9]+$ ]]; then
    local result
    result=$(jq -r '.result // ""' "$qa_response_file" 2>/dev/null | tr -d '\r')
    score=$(echo "$result" | grep -oiE '(overall[[:space:]]+)?score[:[[:space:]]]+([0-9]+)' | grep -oE '[0-9]+' | head -1)
    log_debug "Extracted score from text: $score"

    if [[ -z "$verdict" || ! "$verdict" =~ ^(PASS|REWORK|REJECT)$ ]]; then
      if echo "$result" | grep -qiE '\bPASS\b'; then verdict="PASS"
      elif echo "$result" | grep -qiE '\bREWORK\b'; then verdict="REWORK"
      elif echo "$result" | grep -qiE '\bREJECT\b'; then verdict="REJECT"
      fi
    fi

    if [[ -z "$feedback" ]]; then
      feedback=$(echo "$result" | head -5 | tr '\n' ' ')
    fi
  fi

  # Validate score
  if [[ -z "$score" || ! "$score" =~ ^[0-9]+$ ]]; then
    log_warn "Could not extract score from QA response"
    score=0
    verdict="REJECT"
    feedback="QA returned unparseable score"
  elif [[ $score -lt 0 || $score -gt 100 ]]; then
    log_warn "Score out of range: $score"
    score=0
    verdict="REJECT"
  fi

  # Derive verdict from score if not found
  if [[ -z "$verdict" || ! "$verdict" =~ ^(PASS|REWORK|REJECT)$ ]]; then
    local _pass_th=$(config_read "qa.pass_threshold_default" "80")
    local _rework_th=$(config_read "qa.rework_threshold_default" "60")
    if [[ $score -ge $_pass_th ]]; then
      verdict="PASS"
    elif [[ $score -ge $_rework_th ]]; then
      verdict="REWORK"
    else
      verdict="REJECT"
    fi
  fi

  # Escape pipe characters and truncate feedback (preserving actionable content)
  feedback=$(echo "$feedback" | tr '|' '/' | tr '\n' ' ')
  # Keep first 2000 chars (enough for full QA guidance, not just headers)
  local _fb_max=$(config_read "qa.feedback_max_chars" "2000")
  feedback="${feedback:0:$_fb_max}"

  echo "$score|$verdict|$feedback"
  return 0
}

# Validate coherence between score, verdict text, and derived verdict.
# Detects when QA LLM produces contradictory output (e.g., score=85 but text says "REJECT").
# Args: score verdict_text derived_verdict
# Returns: "COHERENT" or "INCOHERENT" (stdout)
validate_qa_coherence() {
  local score="$1"
  local verdict_text="$2"
  local derived_verdict="$3"

  local text_lower
  text_lower=$(echo "$verdict_text" | tr '[:upper:]' '[:lower:]')

  # Case 1: High score (PASS) but text contains rejection language
  # Skip for very high scores (>= 85) — these are confident PASS with analytical language
  if [[ "$derived_verdict" == "PASS" || $score -ge 80 ]] && [[ $score -lt 85 ]]; then
    if echo "$text_lower" | grep -qiE '\b(reject|fail|unacceptable|hallucin|poor quality|does not meet)\b'; then
      log_warn "QA coherence violation: score=$score derived=$derived_verdict but text contains rejection language"
      log_event "{\"ts\":\"$(now_iso)\",\"event\":\"qa_coherence_violation\",\"score\":$score,\"derived\":\"$derived_verdict\",\"direction\":\"high_score_negative_text\"}"
      echo "INCOHERENT"
      return 0
    fi
  fi

  # Case 2: Low score (REJECT) but text contains strong approval language
  if [[ "$derived_verdict" == "REJECT" || $score -lt 60 ]]; then
    if echo "$text_lower" | grep -qiE '\b(excellent|perfect|well.done|passes all|outstanding|flawless|great work)\b'; then
      log_warn "QA coherence violation: score=$score derived=$derived_verdict but text contains approval language"
      log_event "{\"ts\":\"$(now_iso)\",\"event\":\"qa_coherence_violation\",\"score\":$score,\"derived\":\"$derived_verdict\",\"direction\":\"low_score_positive_text\"}"
      echo "INCOHERENT"
      return 0
    fi
  fi

  echo "COHERENT"
  return 0
}

# Promote repeated immune violations to immune memory (call per wave)
# Scans immune_events.jsonl, groups by violation type, promotes types with >= 3 occurrences
promote_immune_memory() {
  local immune_events="$RUNTIME_DIR/immune_events.jsonl"
  local immune_memory="$RUNTIME_DIR/immune_memory.jsonl"

  [[ ! -f "$immune_events" || ! -s "$immune_events" ]] && return 0

  # Split violations into individual types, strip parameters (e.g., TOO_SMALL(5) → TOO_SMALL)
  # Group by base type, count >= 3 → promote
  local type_counts
  type_counts=$(jq -rs '
    [.[] | .violations | split(" ") | .[] | select(length > 0) | gsub("\\(.*\\)"; "")] |
    group_by(.) |
    map({type: .[0], count: length}) |
    .[] | select(.count >= '"$(config_read "immune.promotion_threshold" "3")"')
  ' "$immune_events" 2>/dev/null) || return 0

  [[ -z "$type_counts" ]] && return 0

  local promoted=0
  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    local vtype vcount
    vtype=$(echo "$entry" | jq -r '.type' 2>/dev/null | tr -d '\r')
    vcount=$(echo "$entry" | jq -r '.count' 2>/dev/null | tr -d '\r')

    [[ -z "$vtype" ]] && continue

    # Dedup: skip if already promoted
    if [[ -f "$immune_memory" ]] && grep -q "\"violation_type\":\"$vtype\"" "$immune_memory" 2>/dev/null; then
      continue
    fi

    # Map violation type to output-matching regex pattern
    local pattern=""
    case "$vtype" in
      PREAMBLE_DETECTED) pattern='(let me|i will|i have|writing.*to|the path|here is|sure|okay|certainly)' ;;
      *) pattern="$vtype" ;;
    esac

    append_jsonl "$immune_memory" "{\"violation_type\":\"$vtype\",\"pattern\":\"$pattern\",\"response\":\"flag\",\"count\":$vcount,\"promoted_at\":\"$(now_iso)\"}"
    ((promoted++)) || true
  done < <(echo "$type_counts" | jq -c '.')

  if [[ $promoted -gt 0 ]]; then
    log_info "Immune memory: promoted $promoted violation types (>= 3 occurrences)"
    log_event "{\"ts\":\"$(now_iso)\",\"event\":\"immune_promotion\",\"promoted\":$promoted}"
  fi
}

# Route based on QA verdict
route_verdict() {
  local task_id="$1"
  local score="$2"
  local verdict="$3"
  local feedback="$4"
  local max_retries="$5"
  local threshold="$6"

  local current_attempt
  current_attempt=$(task_get "$task_id" "attempts" 2>/dev/null || echo "1")
  if [[ -z "$current_attempt" || "$current_attempt" == "null" ]]; then
    current_attempt=1
  fi

  log_info "QA verdict for $task_id: score=$score verdict=$verdict (threshold=$threshold)"

  # PASS: score meets threshold (C1: score is authoritative, verdict text is advisory)
  if [[ $score -ge $threshold ]]; then
    log_info "Task $task_id PASSED QA (score: $score >= $threshold)"
    task_set_status "$task_id" "completed"
    task_set_field "$task_id" "score" "$score"
    task_set_field "$task_id" "completed_at" "\"$(now_iso)\""
    log_event "{\"ts\":\"$(now_iso)\",\"event\":\"qa_verdict\",\"task_id\":\"$task_id\",\"score\":$score,\"verdict\":\"PASS\"}"
    return 0
  fi

  # MICRO_FIX: targeted repair (C3: dynamic floor prevents empty range)
  local _mf_offset=$(config_read "qa.micro_fix_floor_offset" "15")
  local _mf_abs=$(config_read "qa.micro_fix_absolute_floor" "60")
  local micro_fix_floor=$((threshold - _mf_offset))
  [[ $micro_fix_floor -lt $_mf_abs ]] && micro_fix_floor=$_mf_abs
  if [[ $current_attempt -lt $max_retries ]] && [[ $score -ge $micro_fix_floor ]] && [[ $score -lt $threshold ]]; then
    log_info "Task $task_id MICRO_FIX (score: $score, attempt $current_attempt/$max_retries)"
    task_set_status "$task_id" "rework"
    task_set_field "$task_id" "rework_type" '"micro_fix"'
    # Extract ONLY failed criteria for targeted feedback
    local micro_feedback
    micro_feedback=$(echo "$feedback" | jq -r '.criteria[]? | select(.pass == false) | .name + ": " + .feedback' 2>/dev/null || echo "$feedback")
    task_set_field "$task_id" "last_feedback" "$(echo "MICRO-FIX: Address ONLY these issues (do NOT rewrite everything):\n$micro_feedback" | jq -Rs '.')"
    task_set_field "$task_id" "score" "$score"
    log_event "{\"ts\":\"$(now_iso)\",\"event\":\"qa_verdict\",\"task_id\":\"$task_id\",\"score\":$score,\"verdict\":\"MICRO_FIX\",\"attempt\":$current_attempt}"
    return 1
  fi

  # REWORK: score 60-69 — fixable but needs more substantial changes
  local _rw_floor=$(config_read "qa.rework_floor" "60")
  if [[ $current_attempt -lt $max_retries ]] && [[ $score -ge $_rw_floor ]]; then
    log_info "Task $task_id needs REWORK (score: $score, attempt $current_attempt/$max_retries)"
    task_set_status "$task_id" "rework"
    task_set_field "$task_id" "last_feedback" "$(echo "$feedback" | jq -Rs '.')"
    task_set_field "$task_id" "score" "$score"
    log_event "{\"ts\":\"$(now_iso)\",\"event\":\"qa_verdict\",\"task_id\":\"$task_id\",\"score\":$score,\"verdict\":\"REWORK\",\"attempt\":$current_attempt}"
    return 1
  fi

  # REJECT or EXHAUSTED: score too low or out of retries
  local final_verdict
  if [[ $current_attempt -ge $max_retries ]]; then
    log_error "Task $task_id EXHAUSTED retries (score: $score, attempts: $current_attempt/$max_retries)"
    task_set_status "$task_id" "exhausted"
    final_verdict="EXHAUSTED"
  else
    log_error "Task $task_id REJECTED by QA (score: $score < 60)"
    task_set_status "$task_id" "rejected"
    final_verdict="REJECT"
  fi

  task_set_field "$task_id" "score" "$score"
  task_set_field "$task_id" "last_feedback" "$(echo "$feedback" | jq -Rs '.')"
  log_event "{\"ts\":\"$(now_iso)\",\"event\":\"qa_verdict\",\"task_id\":\"$task_id\",\"score\":$score,\"verdict\":\"$final_verdict\",\"attempt\":$current_attempt}"

  # Cascade failure to dependent tasks (uses cascade_failure from deps.sh)
  cascade_failure "$task_id"

  return 2
}
