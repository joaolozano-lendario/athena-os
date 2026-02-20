#!/usr/bin/env bash
# epigenetics.sh — Cross-blueprint learning markers for FORMICA v3.0
# Markers persist between blueprints and influence future execution.
# Rule: only create/update markers when evidence exists in 2+ blueprints.

[[ -n "${_EPIGENETICS_SH_LOADED:-}" ]] && return 0
_EPIGENETICS_SH_LOADED=1

# ============================================================================
# MARKER FILE
# ============================================================================

MARKERS_FILE="${MEMORY_DIR:-$ORCHESTRATOR_DIR}/epigenetic-markers.yaml"

# Associative arrays populated by load_markers, consumed by get_budget_adjustment/get_model_hint
declare -gA BUDGET_ADJUSTMENTS=()
declare -gA MODEL_HINTS=()

# ============================================================================
# SAVE MARKERS (atomic write helper)
# ============================================================================

# Write markers file atomically: write to temp, then move
save_markers() {
  local tmp_file="${MARKERS_FILE}.tmp"

  # Write to temp file
  yq eval '.' "$MARKERS_FILE" > "$tmp_file" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    log_warn "Failed to write temporary markers file: $tmp_file"
    return 1
  fi

  # Atomic move to real location
  if mv "$tmp_file" "$MARKERS_FILE"; then
    return 0
  else
    log_warn "Failed to move temporary markers file to $MARKERS_FILE"
    rm -f "$tmp_file" 2>/dev/null
    return 1
  fi
}

# ============================================================================
# LOAD MARKERS (called at blueprint start)
# ============================================================================

# Load markers and apply to current blueprint configuration
load_markers() {
  [[ ! -f "$MARKERS_FILE" ]] && return 0

  log_info "Loading epigenetic markers from: $MARKERS_FILE"

  # Populate BUDGET_ADJUSTMENTS global from YAML
  BUDGET_ADJUSTMENTS=()
  local adjustments
  adjustments=$(yq -r '.budget_adjustments // {} | to_entries[] | "\(.key)=\(.value)"' "$MARKERS_FILE" 2>/dev/null | tr -d '\r')
  while IFS= read -r entry; do
    [[ -z "$entry" || "$entry" == "null" ]] && continue
    local wtype multiplier
    wtype="${entry%%=*}"
    multiplier="${entry#*=}"
    [[ -z "$wtype" ]] && continue
    [[ ! "$multiplier" =~ ^[0-9]+\.?[0-9]*$ ]] && continue
    local _epi_min=$(config_read "epigenetics.multiplier_min" "0.50")
    local _epi_max=$(config_read "epigenetics.multiplier_max" "3.00")
    if awk -v m="$multiplier" -v mn="$_epi_min" -v mx="$_epi_max" 'BEGIN { if (m < mn || m > mx) exit 1 }'; then
      BUDGET_ADJUSTMENTS["$wtype"]="$multiplier"
      log_info "Epigenetic: budget adjustment for $wtype = ${multiplier}x"
      log_event "{\"ts\":\"$(now_iso)\",\"event\":\"epigenetic_applied\",\"type\":\"budget_adjustment\",\"worker_type\":\"$wtype\",\"multiplier\":$multiplier}"
    else
      log_warn "Epigenetic: skipping invalid multiplier for $wtype (out of range [0.5, 3.0]): $multiplier"
    fi
  done <<< "$adjustments"

  # Populate MODEL_HINTS global from YAML
  MODEL_HINTS=()
  local hints
  hints=$(yq -r '.model_hints // {} | to_entries[] | "\(.key)=\(.value)"' "$MARKERS_FILE" 2>/dev/null | tr -d '\r')
  while IFS= read -r entry; do
    [[ -z "$entry" || "$entry" == "null" ]] && continue
    local pattern model
    pattern="${entry%%=*}"
    model="${entry#*=}"
    [[ -z "$pattern" || -z "$model" ]] && continue
    MODEL_HINTS["$pattern"]="$model"
    log_info "Epigenetic: model hint for '$pattern' = $model"
  done <<< "$hints"

  # L1: Seed pheromone table from persistent markers
  if [[ -n "${RUNTIME_DIR:-}" ]]; then
    local pheromone_data
    pheromone_data=$(yq -r '.pheromone_evidence // {} | to_entries[] | "\(.key)=\(.value.avg)=\(.value.n)"' "$MARKERS_FILE" 2>/dev/null | tr -d '\r')
    if [[ -n "$pheromone_data" && "$pheromone_data" != "null" ]]; then
      init_pheromone
      local pheromone_file="${RUNTIME_DIR}/pheromone_table.json"
      while IFS='=' read -r key avg n; do
        [[ -z "$key" || -z "$avg" ]] && continue
        local tmp; tmp=$(mktemp)
        jq --arg k "$key" --argjson avg "$avg" --argjson n "$n" \
          '.[$k] = {"avg": $avg, "n": $n}' "$pheromone_file" > "$tmp" && mv "$tmp" "$pheromone_file"
      done <<< "$pheromone_data"
      log_info "Pheromone table seeded from epigenetic markers"
    fi
  fi

  local blueprint_count
  blueprint_count=$(yq -r '.blueprint_count // 0' "$MARKERS_FILE" 2>/dev/null | tr -d '\r')
  log_info "Epigenetic markers loaded (from $blueprint_count previous blueprints)"
}

# Get budget adjustment multiplier for a worker type
# Returns multiplier (default 1.0 if no adjustment)
get_budget_adjustment() {
  local worker_type="$1"

  # Fast path: read from in-memory global (populated by load_markers)
  if [[ -n "${BUDGET_ADJUSTMENTS[$worker_type]:-}" ]]; then
    echo "${BUDGET_ADJUSTMENTS[$worker_type]}"
    return 0
  fi

  [[ ! -f "$MARKERS_FILE" ]] && echo "1.0" && return 0

  local multiplier
  multiplier=$(yq -r ".budget_adjustments.\"$worker_type\" // 1.0" "$MARKERS_FILE" 2>/dev/null | tr -d '\r')
  echo "${multiplier:-1.0}"
}

# Get model hint for a worker type
# Returns model name or empty string
get_model_hint() {
  local worker_type="$1"

  # Fast path: read from in-memory global (populated by load_markers)
  if [[ -n "${MODEL_HINTS[$worker_type]:-}" ]]; then
    echo "${MODEL_HINTS[$worker_type]}"
    return 0
  fi

  [[ ! -f "$MARKERS_FILE" ]] && return 0

  local hint
  hint=$(yq -r ".model_hints.\"$worker_type\" // \"\"" "$MARKERS_FILE" 2>/dev/null | tr -d '\r')
  [[ -n "$hint" && "$hint" != "null" ]] && echo "$hint"
}

# ============================================================================
# UPDATE MARKERS (called after meta-report)
# ============================================================================

# Update markers based on current blueprint's friction data and events
update_markers() {
  local friction_file="$RUNTIME_DIR/friction_events.jsonl"
  local events_file="${TELEMETRY_DIR:-$RUNTIME_DIR/telemetry}/events.jsonl"

  # Initialize markers file if it doesn't exist
  if [[ ! -f "$MARKERS_FILE" ]]; then
    cat > "$MARKERS_FILE" <<'EOF'
# FORMICA Epigenetic Markers
# Auto-generated from blueprint data. Do not edit manually.
# Rule: markers require evidence from 2+ blueprints.

budget_adjustments: {}
qa_overrides: {}
model_hints: {}
blueprint_count: 0
last_updated: null
blueprint_history: []
EOF
  fi

  # Increment blueprint count
  local current_count
  current_count=$(yq -r '.blueprint_count // 0' "$MARKERS_FILE" 2>/dev/null | tr -d '\r')
  local new_count=$((current_count + 1))

  # Record this blueprint in history
  local blueprint_entry
  blueprint_entry=$(printf '%s' "$BLUEPRINT_ID")

  # Analyze friction for budget adjustments
  if [[ -f "$friction_file" && -s "$friction_file" ]]; then
    _update_budget_markers "$friction_file" "$new_count"
  fi

  # Analyze events for model hints
  if [[ -f "$events_file" ]]; then
    _update_model_hints "$events_file" "$new_count"
  fi

  # Update metadata with atomic write
  yq -i ".blueprint_count = $new_count | .last_updated = \"$(now_iso)\"" "$MARKERS_FILE" 2>/dev/null || true
  yq -i ".blueprint_history += [\"$BLUEPRINT_ID\"]" "$MARKERS_FILE" 2>/dev/null || true
  save_markers || true

  log_info "Epigenetic markers updated (blueprint $new_count)"
}

# ============================================================================
# INTERNAL: MARKER UPDATES
# ============================================================================

_update_budget_markers() {
  local friction_file="$1"
  local blueprint_count="$2"

  # Only create markers after N+ blueprints of evidence
  local _min_bp=$(config_read "epigenetics.min_blueprints_for_evidence" "2")
  [[ "$blueprint_count" -lt "$_min_bp" ]] && return 0

  # Find worker types with budget_exhaustion friction
  local _min_fric=$(config_read "epigenetics.budget_exhaustion_min_count" "2")
  local budget_workers
  budget_workers=$(jq -s '[.[] | select(.cause == "budget_exhaustion")] | group_by(.worker_type) | .[] | {worker: .[0].worker_type, count: length}' \
    "$friction_file" 2>/dev/null | jq -r "select(.count >= $_min_fric) | .worker" 2>/dev/null | tr -d '\r')

  for wtype in $budget_workers; do
    # Increase budget multiplier by 0.2 (cap at 3.0)
    local current
    current=$(yq -r ".budget_adjustments.\"$wtype\" // 1.0" "$MARKERS_FILE" 2>/dev/null | tr -d '\r')

    # Validate current value before using
    if [[ ! "$current" =~ ^[0-9]+\.?[0-9]*$ ]]; then
      log_warn "Epigenetic: invalid multiplier in markers for $wtype, skipping"
      continue
    fi

    local _step=$(config_read "epigenetics.budget_multiplier_step" "0.20")
    local _epi_min=$(config_read "epigenetics.multiplier_min" "0.50")
    local _epi_max=$(config_read "epigenetics.multiplier_max" "3.00")
    local new_mult
    new_mult=$(awk -v c="$current" -v s="$_step" -v mx="$_epi_max" 'BEGIN { n = c + s; if (n > mx) n = mx; printf "%.1f", n }')

    # Validate new value in range
    if awk -v m="$new_mult" -v mn="$_epi_min" -v mx="$_epi_max" 'BEGIN { if (m >= mn && m <= mx) exit 0; else exit 1 }'; then
      yq -i ".budget_adjustments.\"$wtype\" = $new_mult" "$MARKERS_FILE" 2>/dev/null || true
      log_info "Epigenetic: budget for $wtype adjusted to ${new_mult}x"
    else
      log_warn "Epigenetic: computed multiplier out of range for $wtype: $new_mult"
    fi
  done
}

_update_model_hints() {
  local events_file="$1"
  local blueprint_count="$2"

  # Only create markers after N+ blueprints of evidence
  local _min_bp=$(config_read "epigenetics.min_blueprints_for_evidence" "2")
  [[ "$blueprint_count" -lt "$_min_bp" ]] && return 0

  # Find tasks that required model escalation
  local escalated
  escalated=$(jq -r 'select(.event == "model_escalation") | .task_id' "$events_file" 2>/dev/null | sort -u | tr -d '\r')

  for tid in $escalated; do
    # Extract worker type pattern (e.g., "architect" tasks tend to need escalation)
    local wtype
    wtype=$(jq -r --arg tid "$tid" 'select(.event == "task_spawn" and .task_id == $tid) | .worker' "$events_file" 2>/dev/null | head -1 | tr -d '\r')
    [[ -z "$wtype" || "$wtype" == "null" ]] && continue

    # Record model hint
    yq -i ".model_hints.\"$wtype\" = \"sonnet\"" "$MARKERS_FILE" 2>/dev/null || true
    log_info "Epigenetic: model hint for $wtype workers = sonnet"
  done

  # Scan innate immune rejections — worker types that get rejected need model upgrade
  local immune_rejected_types
  immune_rejected_types=$(jq -r 'select(.event == "innate_immune_reject") | .task_id' "$events_file" 2>/dev/null | sort -u | tr -d '\r')

  for tid in $immune_rejected_types; do
    local wtype
    wtype=$(jq -r --arg tid "$tid" 'select(.event == "task_spawn" and .task_id == $tid) | .worker' "$events_file" 2>/dev/null | head -1 | tr -d '\r')
    [[ -z "$wtype" || "$wtype" == "null" ]] && continue

    # Only hint if not already set
    local existing_hint
    existing_hint=$(yq -r ".model_hints.\"$wtype\" // \"\"" "$MARKERS_FILE" 2>/dev/null | tr -d '\r')
    if [[ -z "$existing_hint" || "$existing_hint" == "null" ]]; then
      yq -i ".model_hints.\"$wtype\" = \"sonnet\"" "$MARKERS_FILE" 2>/dev/null || true
      log_info "Epigenetic: model hint for $wtype workers = sonnet (innate immune failures)"
    fi
  done
}
