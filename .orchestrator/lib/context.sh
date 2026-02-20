#!/usr/bin/env bash
# context.sh — Layered context pack assembly for workers
# Layers: Universal → Domain → Dependency → Project → Signals/Constraints

[[ -n "${_CONTEXT_SH_LOADED:-}" ]] && return 0
_CONTEXT_SH_LOADED=1

# Source consciousness map (v4.2 — FORMICA SAPIENS)
if [[ -f "${ORCHESTRATOR_DIR:-}/lib/consciousness.sh" ]]; then
  source "${ORCHESTRATOR_DIR}/lib/consciousness.sh"
fi

# Assemble context pack for worker execution (layered composition)
assemble_context_pack() {
  local task_id="$1"
  local task_desc="$2"
  local acceptance_criteria="$3"  # JSON array string
  local context_files="$4"        # JSON array of file paths
  local worker_type="$5"
  local qa_criteria="$6"          # JSON array string
  local last_feedback="$7"
  local output_file="$8"
  local output_path="${9:-}"
  local qa_threshold="${10:-80}"
  local worker_tools="${11:-}"     # v4.2: tool list for double-load prevention

  # Token budget from allometry (default 60000 for backward compat)
  local max_tokens="${CONTEXT_TOKEN_BUDGET:-60000}"

  # Build context pack using layers
  {
    # Layer 0: Project conventions (FORMICA v3.0)
    _layer_project_conventions

    # Layer 0.3: Budget awareness (v4.2)
    _layer_budget_awareness

    # Layer 0.5: Consciousness map (v4.2 — FORMICA SAPIENS)
    _layer_consciousness "$task_id"

    # Layer 1: Universal (task definition, criteria, output format)
    _layer_universal "$task_id" "$task_desc" "$acceptance_criteria" "$output_path"

    # Layer 2: Constraints (negative pheromone soft constraints)
    _layer_constraints

    # Layer 3: Domain (genius kit, AURUM exports — if available)
    _layer_domain

    # Layer 4: Project (reference material / context files)
    _layer_project "$context_files" "$worker_tools"

    # Layer 4.5: Evaluate feedback (strategic guidance from upstream evaluations)
    _layer_evaluate_feedback "$task_id"

    # Layer 5: Colony signals (trophallaxis)
    _layer_colony_signals

    # Layer 6: QA rubric
    _layer_qa_rubric "$qa_criteria" "$qa_threshold"

    # Layer 6.5: Historical friction (FORMICA v3.0)
    _layer_historical_friction "$worker_type"

    # Layer 7: Feedback from previous attempt (if rework)
    _layer_feedback "$last_feedback"

  } > "$output_file"

  # Token budget check and truncation if needed
  local total_tokens
  total_tokens=$(estimate_tokens < "$output_file")

  if [[ $total_tokens -gt $max_tokens ]]; then
    log_warn "Context pack for $task_id is ${total_tokens} tokens (max ${max_tokens}). Truncating flexible layers."
    _truncate_context_pack "$task_id" "$task_desc" "$acceptance_criteria" "$context_files" \
      "$worker_type" "$qa_criteria" "$last_feedback" "$output_file" "$max_tokens" \
      "$output_path" "$qa_threshold" "$worker_tools"
  else
    log_info "Context pack assembled: ${total_tokens} tokens (budget: ${max_tokens})"
  fi
}

# ============================================================================
# CONTEXT LAYERS
# ============================================================================

# Layer 0: Project conventions (FORMICA v3.0)
# Extracts naming/structure conventions from project CLAUDE.md (max 15 lines)
_layer_project_conventions() {
  local claude_md=""

  # Try project_dir CLAUDE.md first
  if [[ -n "${PROJECT_DIR:-}" && -f "$PROJECT_DIR/.claude/CLAUDE.md" ]]; then
    claude_md="$PROJECT_DIR/.claude/CLAUDE.md"
  elif [[ -f "$ORCHESTRATOR_DIR/../.claude/CLAUDE.md" ]]; then
    claude_md="$ORCHESTRATOR_DIR/../.claude/CLAUDE.md"
  fi

  if [[ -n "$claude_md" && -f "$claude_md" ]]; then
    echo "# PROJECT CONVENTIONS"
    echo ""
    # Extract lines mentioning conventions, naming, structure, patterns
    # Then filter out noise: box-drawing chars, markdown tables, short lines, tree chars
    grep -iE '(convention|naming|structure|pattern|style|format|rule)' "$claude_md" 2>/dev/null | \
      grep -v '[│├└┌┐─═╔╗╚╝╠╣]' | \
      grep -v '^\s*|' | \
      grep -v '^\s*[├└]' | \
      awk 'length > 9' | \
      head -"$(config_read "colony.convention_max_lines" "15")"
    echo ""
  fi
}

# Layer 1: Universal — task definition, criteria, output path
# CRITICAL: Never truncated
_layer_universal() {
  local task_id="$1" task_desc="$2" acceptance_criteria="$3" output_path="$4"

  echo "# TASK"
  echo ""
  echo "$task_desc"
  echo ""
  echo "## Acceptance Criteria"
  echo ""
  echo "$acceptance_criteria" | jq -r '.[] | "- \(.)"' 2>/dev/null || echo "$acceptance_criteria"
  echo ""
  echo "## Output Path"
  echo ""
  echo "Write your output to: $output_path"
  echo ""
}

# Layer 2: Constraints — negative pheromone soft constraints
# Truncation priority: 2 (moderate — keep before colony signals)
_layer_constraints() {
  # Only if routing.sh is loaded and has soft constraints
  if ! type apply_negative_pheromone &>/dev/null; then
    return 0
  fi

  local soft_constraints=""
  # Capture soft constraints from fd 3 using temp file to avoid fd redirection pitfalls
  local tmp_soft="/tmp/orch-soft-constraints-${BASHPID:-$$}-${RANDOM}"
  apply_negative_pheromone "${RUNTIME_DIR:-}" 3>"$tmp_soft" 1>/dev/null 2>/dev/null || true
  soft_constraints=$(cat "$tmp_soft" 2>/dev/null || true)
  rm -f "$tmp_soft"

  if [[ -n "$soft_constraints" ]]; then
    echo "# CONSTRAINTS (from colony memory — avoid these patterns)"
    echo ""
    while IFS='|' read -r severity bl_type pattern bl_id; do
      [[ -z "$pattern" ]] && continue
      echo "- [$bl_type] AVOID: $pattern (severity: $severity)"
    done <<< "$soft_constraints"
    echo ""
  fi
}

# Layer 3: Domain — genius kit, AURUM exports (if athena.sh loaded)
# Truncation priority: 6 (low — truncate before context files)
_layer_domain() {
  # Only if athena.sh facade is loaded
  if ! type load_genius_kit &>/dev/null; then
    return 0
  fi

  local nature_code
  nature_code=$(yq -r '.blueprint.nature_code // ""' "$MANIFEST" 2>/dev/null | tr -d '\r')
  [[ -z "$nature_code" || "$nature_code" == "null" ]] && return 0

  local genius_content
  genius_content=$(load_genius_kit "$nature_code" 2>/dev/null) || true
  if [[ -n "$genius_content" ]]; then
    echo "# DOMAIN KNOWLEDGE"
    echo ""
    echo "$genius_content"
    echo ""
  fi

  # Patterns from colony memory
  local patterns_content
  patterns_content=$(get_relevant_patterns "$nature_code" 2>/dev/null) || true
  if [[ -n "$patterns_content" ]]; then
    echo "# PATTERNS (from colony memory)"
    echo ""
    echo "$patterns_content"
    echo ""
  fi
}

# Layer 0.3: Budget awareness (v4.2 — FORMICA SAPIENS)
# Priority: 0 (NEVER truncated)
_layer_budget_awareness() {
  local budget_remaining
  budget_remaining=$(state_read ".budget.total_usd - .budget.used_usd" 2>/dev/null || echo "unknown")
  local tokens_budget="${CONTEXT_TOKEN_BUDGET:-60000}"
  echo ""
  echo "## RESOURCE AWARENESS"
  echo "Token budget for this context: ${tokens_budget} tokens"
  echo "Cost budget remaining: \$${budget_remaining}"
  echo "Manage output complexity accordingly."
  echo ""
}

# Layer 0.5: Consciousness map — situational awareness for workers (v4.2)
# Priority: 0 (NEVER truncated)
_layer_consciousness() {
  local task_id="${1:-}"
  [[ -z "$task_id" ]] && return 0

  # Generate consciousness map for this task
  if type generate_consciousness_map &>/dev/null; then
    generate_consciousness_map "$task_id" "${RUNTIME_DIR:-}" 2>/dev/null || true
  fi

  # Read and inject the generated map
  local map_file="${RUNTIME_DIR:-}/consciousness-map.md"
  if [[ -f "$map_file" && -s "$map_file" ]]; then
    cat "$map_file"
    echo ""
  fi
}

# Layer 4: Project — reference material from context_files
# Truncation priority: 5 (moderate-low — truncate after domain)
# v4.2: Double-load prevention — skip large files when worker has Read tools
_layer_project() {
  local context_files="$1"
  local worker_tools="${2:-}"

  # Double-load prevention config
  local dlp_enabled
  dlp_enabled=$(config_read "context.double_load_prevention.enabled" "false")
  local dlp_threshold
  dlp_threshold=$(config_read "context.double_load_prevention.line_threshold" "500")

  # Check if worker has Read tools
  local has_read_tools=false
  if [[ -n "$worker_tools" ]] && echo "$worker_tools" | grep -qi "Read"; then
    has_read_tools=true
  fi

  echo "# REFERENCE MATERIAL"
  echo ""

  if [[ -n "$context_files" ]] && [[ "$context_files" != "null" ]]; then
    echo "$context_files" | jq -r '.[]' 2>/dev/null | tr -d '\r' | while IFS= read -r file; do
      if [[ -f "$file" ]]; then
        local filename
        filename=$(basename "$file")

        # Double-load prevention: skip large files when worker can Read
        if [[ "$dlp_enabled" == "true" && "$has_read_tools" == "true" ]]; then
          local line_count
          line_count=$(wc -l < "$file" 2>/dev/null || echo 0)
          if [[ $line_count -gt $dlp_threshold ]]; then
            echo "--- $filename (reference only) ---"
            echo "Reference file: $filename at $file ($line_count lines). Use Read tool to access specific sections as needed."
            echo "--- end ---"
            echo ""
            continue
          fi
        fi

        echo "--- $filename ---"
        cat "$file"
        echo ""
        echo "--- end ---"
        echo ""
      else
        log_warn "Context file not found: $file"
      fi
    done
  fi
}

# Layer 5: Colony signals — trophallaxis injection
# Truncation priority: 3 (moderate-high — truncate first among flexible layers)
_layer_colony_signals() {
  local signals_file="${RUNTIME_DIR:-}/colony_signals.jsonl"
  [[ ! -f "$signals_file" ]] && return 0

  local max_signals="${SIGNAL_INJECTION_MAX:-3}"

  # Filter by intensity >= 0.4, sort by intensity desc, take max
  local signals
  local _sig_floor=$(config_read "colony.signal_intensity_floor" "0.4")
  signals=$(jq -s '[.[] | select(.intensity >= '"$_sig_floor"')] | sort_by(-.intensity) | .[:'"$max_signals"']' "$signals_file" 2>/dev/null | tr -d '\r')

  local signal_count
  signal_count=$(echo "$signals" | jq 'length' 2>/dev/null || echo "0")

  if [[ "$signal_count" -gt 0 ]]; then
    echo "# COLONY SIGNALS (observations from peer workers)"
    echo ""

    # v4.2: Enrich with source reliability from decision log
    local decision_log="${RUNTIME_DIR:-}/decision-log.jsonl"
    echo "$signals" | jq -c '.[]' 2>/dev/null | tr -d '\r' | while IFS= read -r sig; do
      local sig_type sig_msg sig_tid sig_intensity
      sig_type=$(echo "$sig" | jq -r '.type' 2>/dev/null)
      sig_msg=$(echo "$sig" | jq -r '.signal' 2>/dev/null)
      sig_tid=$(echo "$sig" | jq -r '.task_id' 2>/dev/null)
      sig_intensity=$(echo "$sig" | jq -r '.intensity' 2>/dev/null)

      # Calculate reliability indicator from decision log
      local indicator="●"  # default: normal
      if [[ -f "$decision_log" && -s "$decision_log" ]]; then
        local avg_score
        avg_score=$(jq -rs "[.[] | select(.task_id == \"$sig_tid\") | .score] | if length > 0 then (add / length) else 0 end" "$decision_log" 2>/dev/null || echo "0")
        if [[ -n "$avg_score" ]] && awk -v s="$avg_score" 'BEGIN { exit !(s > 85) }' 2>/dev/null; then
          indicator="★"  # high confidence
        elif [[ -n "$avg_score" ]] && awk -v s="$avg_score" 'BEGIN { exit !(s < 70) }' 2>/dev/null; then
          indicator="○"  # low confidence
        fi
      fi

      echo "- $indicator [$sig_type] $sig_msg (from $sig_tid, intensity $sig_intensity)"
    done
    echo ""
  fi
}

# Layer 6.5: Historical friction (FORMICA v3.0)
# Injects warnings from previous friction events for this worker type
# Truncation priority: 4 (moderate — keep before context files)
_layer_historical_friction() {
  local worker_type="${1:-}"
  [[ -z "$worker_type" ]] && return 0

  # Use get_worker_friction from friction.sh if available
  if ! type get_worker_friction &>/dev/null; then
    return 0
  fi

  local warnings
  warnings=$(get_worker_friction "$worker_type" 2>/dev/null)
  [[ -z "$warnings" ]] && return 0

  echo "# FRICTION WARNINGS (from previous attempts by $worker_type workers)"
  echo ""
  echo "Previous workers of your type encountered these issues:"
  echo ""
  echo "$warnings"
  echo ""
  echo "Address these proactively in your output."
  echo ""
}

# Layer 6: QA rubric
# Truncation priority: 1 (high — keep after critical layers)
_layer_qa_rubric() {
  local qa_criteria="$1" qa_threshold="$2"

  echo "# QA RUBRIC (How your work will be judged)"
  echo ""
  echo "$qa_criteria" | jq -r '.[] | "- \(.)"' 2>/dev/null || echo "$qa_criteria"
  echo ""
  echo "Minimum score to pass: ${qa_threshold}"
  echo ""
}

# Layer 7: Feedback from previous attempt (if rework)
# CRITICAL: Never truncated
_layer_feedback() {
  local last_feedback="$1"

  if [[ -n "$last_feedback" ]] && [[ "$last_feedback" != "null" ]]; then
    echo "# FEEDBACK FROM PREVIOUS ATTEMPT"
    echo ""
    echo "Your previous attempt was scored below threshold. Fix these issues:"
    echo ""
    echo "$last_feedback"
    echo ""
    echo "Focus on the feedback above. Do NOT repeat the same mistakes."
    echo ""
  fi
}

# Layer 4.5: Evaluate feedback — strategic guidance from upstream evaluations
# Truncation priority: 5 (can be truncated, but before colony signals)
_layer_evaluate_feedback() {
  local task_id="${1:-}"
  [[ -z "$task_id" ]] && return 0
  [[ -z "${RUNTIME_DIR:-}" ]] && return 0

  local eval_dir="$RUNTIME_DIR/evaluations"
  [[ ! -d "$eval_dir" ]] && return 0

  # Find upstream dependencies for this task
  local deps
  deps=$(jq -r ".tasks[\"$task_id\"].depends_on // [] | .[]" "$STATE_FILE" 2>/dev/null | tr -d '\r')
  [[ -z "$deps" ]] && return 0

  local has_feedback=false
  local feedback_output=""

  while IFS= read -r upstream_tid; do
    [[ -z "$upstream_tid" ]] && continue
    local eval_file="$eval_dir/${upstream_tid}.json"
    [[ ! -f "$eval_file" ]] && continue

    # Try to parse as JSON
    local suggestions guidance coherence
    suggestions=$(jq -r '.enhancement_suggestions // [] | .[] | "- \(.)"' "$eval_file" 2>/dev/null | tr -d '\r')
    guidance=$(jq -r ".downstream_guidance[\"$task_id\"] // \"\"" "$eval_file" 2>/dev/null | tr -d '\r')
    coherence=$(jq -r '.coherence_notes // ""' "$eval_file" 2>/dev/null | tr -d '\r')

    # Skip if no useful content
    [[ -z "$suggestions" && -z "$guidance" && -z "$coherence" ]] && continue

    has_feedback=true
    feedback_output+="**From upstream task $upstream_tid:**"$'\n'
    if [[ -n "$guidance" ]]; then
      feedback_output+="- **For you:** $guidance"$'\n'
    fi
    if [[ -n "$suggestions" ]]; then
      feedback_output+="$suggestions"$'\n'
    fi
    if [[ -n "$coherence" ]]; then
      feedback_output+="- **Coherence:** $coherence"$'\n'
    fi
    feedback_output+=$'\n'
  done <<< "$deps"

  if [[ "$has_feedback" == "true" ]]; then
    echo "# STRATEGIC GUIDANCE (from upstream evaluation)"
    echo ""
    echo "$feedback_output"
  fi
}

# ============================================================================
# TRUNCATION (budget enforcement with priority ordering)
# ============================================================================

# Internal: truncate context pack to fit budget using priority ordering
# Priority (truncate highest number first):
#   NEVER: L1 (task spec), L7 (retry feedback)
#   3: L5 (colony signals)
#   4: L6.5 (historical friction)
#   5: L4 (context files)
#   6: L3 (domain knowledge)
#   2: L2 (constraints)
#   1: L6 (QA rubric) — keep as much as possible
_truncate_context_pack() {
  local task_id="$1"
  local task_desc="$2"
  local acceptance_criteria="$3"
  local context_files="$4"
  local worker_type="$5"
  local qa_criteria="$6"
  local last_feedback="$7"
  local output_file="$8"
  local max_tokens="$9"
  local output_path="${10:-}"
  local qa_threshold="${11:-80}"
  local worker_tools="${12:-}"

  # CRITICAL layers (never truncate): L1 + L7
  local critical_content=""
  critical_content=$(_layer_universal "$task_id" "$task_desc" "$acceptance_criteria" "$output_path")
  if [[ -n "$last_feedback" && "$last_feedback" != "null" ]]; then
    critical_content+=$'\n'
    critical_content+=$(_layer_feedback "$last_feedback")
  fi

  local critical_tokens
  critical_tokens=$(estimate_tokens <<< "$critical_content")

  # Budget available for flexible layers
  local _safety=$(config_read "token_estimation.truncation_safety_margin" "500")
  local available=$((max_tokens - critical_tokens - _safety))

  if [[ $available -lt 1000 ]]; then
    log_error "Cannot fit context pack under token budget even with truncation"
    available=1000
  fi

  # Flexible layers with priority (lower priority number = keep first when budget tight)
  declare -A layer_content
  declare -A layer_tokens
  declare -A layer_priority

  # S2.5: Truncation order: L5→L3→L6.5→L4→L2 (higher priority number = truncated first)
  # Protected (priority 1): L0 conventions, L6 QA rubric

  # L0: Project conventions (priority 1 — protected)
  layer_content[conventions]=$(_layer_project_conventions)
  layer_tokens[conventions]=$(estimate_tokens <<< "${layer_content[conventions]}")
  layer_priority[conventions]=1

  # L2: Constraints/pheromone (priority 2 — last to truncate among flexible)
  layer_content[constraints]=$(_layer_constraints)
  layer_tokens[constraints]=$(estimate_tokens <<< "${layer_content[constraints]}")
  layer_priority[constraints]=2

  # L6: QA rubric (priority 1 — protected)
  layer_content[qa_rubric]=$(_layer_qa_rubric "$qa_criteria" "$qa_threshold")
  layer_tokens[qa_rubric]=$(estimate_tokens <<< "${layer_content[qa_rubric]}")
  layer_priority[qa_rubric]=1

  # L4: Context files (priority 3 — truncate after friction)
  layer_content[context_files]=$(_layer_project "$context_files" "$worker_tools")
  layer_tokens[context_files]=$(estimate_tokens <<< "${layer_content[context_files]}")
  layer_priority[context_files]=3

  # L6.5: Historical friction (priority 4 — truncate after domain)
  layer_content[friction]=$(_layer_historical_friction "$worker_type")
  layer_tokens[friction]=$(estimate_tokens <<< "${layer_content[friction]}")
  layer_priority[friction]=4

  # L3: Domain (priority 5 — truncate after colony signals)
  layer_content[domain]=$(_layer_domain)
  layer_tokens[domain]=$(estimate_tokens <<< "${layer_content[domain]}")
  layer_priority[domain]=5

  # L4.5: Evaluate feedback (priority 5.5 — truncated before signals, after domain)
  layer_content[evaluate]=$(_layer_evaluate_feedback "$task_id")
  layer_tokens[evaluate]=$(estimate_tokens <<< "${layer_content[evaluate]}")
  layer_priority[evaluate]=5

  # L5: Colony signals (priority 6 — truncated first)
  layer_content[signals]=$(_layer_colony_signals)
  layer_tokens[signals]=$(estimate_tokens <<< "${layer_content[signals]}")
  layer_priority[signals]=6

  # Sort layers by priority (ascending — lower priority = keep first)
  local sorted_layers=()
  while IFS= read -r line; do
    sorted_layers+=("$line")
  done < <(
    for layer in "${!layer_priority[@]}"; do
      echo "${layer_priority[$layer]}|$layer"
    done | sort -t'|' -k1,1n | cut -d'|' -f2
  )

  # Allocate budget to layers in priority order
  local used=0
  declare -A included_layers
  declare -A truncated_layers

  for layer in "${sorted_layers[@]}"; do
    local tokens="${layer_tokens[$layer]}"

    if [[ $tokens -eq 0 ]]; then
      # Empty layer, include without cost
      included_layers[$layer]=1
      continue
    fi

    if [[ $((used + tokens)) -le $available ]]; then
      # Fits completely
      included_layers[$layer]=1
      used=$((used + tokens))
    else
      # Need to truncate or skip
      local remaining=$((available - used))

      local _min_rem=$(config_read "token_estimation.truncation_min_remaining" "200")
      if [[ $remaining -gt $_min_rem ]]; then
        # Truncate this layer to fit remaining budget
        truncated_layers[$layer]=$remaining
        used=$available
        break
      else
        # No room left, skip this and all lower priority layers
        break
      fi
    fi
  done

  # Rebuild context pack with included/truncated layers
  {
    # Critical layers first (L0.3 + L0.5 + L1)
    _layer_budget_awareness
    _layer_consciousness "$task_id"
    _layer_universal "$task_id" "$task_desc" "$acceptance_criteria" "$output_path"

    # Flexible layers in display order (not priority order)
    if [[ -n "${layer_content[conventions]}" && -n "${included_layers[conventions]:-}" ]]; then
      echo "${layer_content[conventions]}"
    fi

    if [[ -n "${layer_content[constraints]}" && -n "${included_layers[constraints]:-}" ]]; then
      echo "${layer_content[constraints]}"
    fi

    if [[ -n "${layer_content[domain]}" ]]; then
      if [[ -n "${included_layers[domain]:-}" ]]; then
        echo "${layer_content[domain]}"
      elif [[ -n "${truncated_layers[domain]:-}" ]]; then
        local char_limit=$((truncated_layers[domain] * $(config_read "token_estimation.truncation_char_multiplier" "4")))
        echo "# DOMAIN KNOWLEDGE (truncated to fit token budget)"
        echo ""
        echo "${layer_content[domain]}" | head -c "$char_limit"
        echo ""
        echo "... [truncated] ..."
        echo ""
      fi
    fi

    if [[ -n "${layer_content[context_files]}" ]]; then
      if [[ -n "${included_layers[context_files]:-}" ]]; then
        echo "${layer_content[context_files]}"
      elif [[ -n "${truncated_layers[context_files]:-}" ]]; then
        local char_limit=$((truncated_layers[context_files] * $(config_read "token_estimation.truncation_char_multiplier" "4")))
        echo "# REFERENCE MATERIAL (truncated to fit token budget)"
        echo ""
        echo "${layer_content[context_files]}" | head -c "$char_limit"
        echo ""
        echo "... [truncated] ..."
        echo ""
      fi
    fi

    if [[ -n "${layer_content[evaluate]:-}" && -n "${included_layers[evaluate]:-}" ]]; then
      echo "${layer_content[evaluate]}"
    fi

    if [[ -n "${layer_content[signals]}" && -n "${included_layers[signals]:-}" ]]; then
      echo "${layer_content[signals]}"
    fi

    if [[ -n "${layer_content[qa_rubric]}" && -n "${included_layers[qa_rubric]:-}" ]]; then
      echo "${layer_content[qa_rubric]}"
    fi

    if [[ -n "${layer_content[friction]}" && -n "${included_layers[friction]:-}" ]]; then
      echo "${layer_content[friction]}"
    fi

    # Critical layer last (L7)
    if [[ -n "$last_feedback" && "$last_feedback" != "null" ]]; then
      _layer_feedback "$last_feedback"
    fi

  } > "$output_file"

  local final_tokens
  final_tokens=$(estimate_tokens < "$output_file")
  log_info "Context pack truncated: ${final_tokens} tokens (budget: ${max_tokens})"
}

# ============================================================================
# TOKEN ESTIMATION
# ============================================================================

# Detect chars-per-token ratio by file extension
# S2.5: code (2 chars/token), prose (4.5), mixed (3.5 default)
_chars_per_token() {
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

# Estimate tokens from text (file or stdin)
# S2.5: Context-aware — uses file extension to select chars/token ratio
# Usage: estimate_tokens < file.txt
#        estimate_tokens <<< "$string_var"
#        estimate_tokens "path/to/file.sh"         (uses code ratio)
#        estimate_tokens "path/to/file.sh" 1000     (uses byte count directly)
estimate_tokens() {
  local filepath="${1:-}"
  local byte_count="${2:-}"

  # Mode 1: filepath + byte_count provided → fast estimation without reading
  if [[ -n "$filepath" && -n "$byte_count" ]]; then
    local cpt
    cpt=$(_chars_per_token "$filepath")
    awk -v b="$byte_count" -v c="$cpt" 'BEGIN { printf "%d", int(b / c) }'
    return 0
  fi

  local input=""

  # Check if stdin has data
  if [[ ! -t 0 ]]; then
    input=$(cat)
  elif [[ -n "$filepath" ]]; then
    if [[ -f "$filepath" ]]; then
      input=$(cat "$filepath")
    else
      echo "0"
      return 0
    fi
  else
    echo "0"
    return 0
  fi

  # Calculate tokens with type-aware ratio (use awk for float division)
  local char_count=${#input}
  local cpt
  cpt=$(_chars_per_token "$filepath")
  awk -v cc="$char_count" -v c="$cpt" 'BEGIN { printf "%d", int(cc / c) }'
}

# Estimate context pack tokens without full assembly
estimate_pack_tokens() {
  local task_id="$1"

  local context_files
  context_files=$(task_get "$task_id" "context_files")
  local total_size=0

  if [[ -n "$context_files" ]] && [[ "$context_files" != "null" ]]; then
    echo "$context_files" | jq -r '.[]' 2>/dev/null | tr -d '\r' | while IFS= read -r file; do
      if [[ -f "$file" ]]; then
        wc -c < "$file"
      fi
    done | awk '{sum+=$1} END {print int(sum/4)}'
  else
    echo "0"
  fi
}
