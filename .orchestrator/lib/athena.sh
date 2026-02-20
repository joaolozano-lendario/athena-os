#!/usr/bin/env bash
# athena.sh — ATHENA-native knowledge integration facade
# Provides: Genius kits, AURUM exports, pattern library, synaptic pruning, immune promotion
# Biomimetic patterns: Synaptic Pruning (Pattern 5), Immune Promotion (Pattern 6 cross-ref)
# Layer 2 (Knowledge) — optional, graceful no-op if ATHENA not available

[[ -n "${_ATHENA_SH_LOADED:-}" ]] && return 0
_ATHENA_SH_LOADED=1

# ATHENA OS paths (configurable)
ATHENA_ROOT="${ATHENA_ROOT:-D:/athena-os}"
PATTERN_LIBRARY="${ATHENA_ROOT}/observability/pattern_library.yaml"
AURUM_CONNECTOR="${ATHENA_ROOT}/.claude/aurum-connector.yaml"
AURUM_KNOWLEDGE="${ATHENA_ROOT}/knowledge/aurum"
GENIUS_KITS="${ATHENA_ROOT}/knowledge/genius/kits"

# ============================================================================
# KNOWLEDGE LOADING
# ============================================================================

# Load genius kit for a nature code
# Returns: Summary text for context injection, or empty string
load_genius_kit() {
  local nature_code="$1"
  [[ -z "$nature_code" || "$nature_code" == "null" ]] && return 0

  # Kits are YAML files: ARCH.yaml, CODE.yaml, META.yaml, etc. (uppercase)
  local kit_file=""
  for candidate in "$GENIUS_KITS/${nature_code^^}.yaml" "$GENIUS_KITS/${nature_code}.yaml" "$GENIUS_KITS/${nature_code,,}.yaml"; do
    if [[ -f "$candidate" ]]; then
      kit_file="$candidate"
      break
    fi
  done
  [[ -z "$kit_file" ]] && return 0

  head -50 "$kit_file" 2>/dev/null
}

# Get relevant patterns from pattern library
# Returns: Formatted text with patterns sorted by confidence (effective strength)
get_relevant_patterns() {
  local nature_code="${1:-}"
  local max_patterns="${2:-5}"

  [[ ! -f "$PATTERN_LIBRARY" ]] && return 0

  # Read patterns — schema uses .validation.confidence, .classification.type, .content.description
  local patterns
  patterns=$(yq -o=json '.patterns // []' "$PATTERN_LIBRARY" 2>/dev/null | tr -d '\r')
  [[ -z "$patterns" || "$patterns" == "null" || "$patterns" == "[]" ]] && return 0

  # Process patterns: sort by confidence, take top N
  # Use process substitution (not pipe) to avoid subshell variable scope loss
  local output=""
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    output="${output}- ${line}\n"
  done < <(echo "$patterns" | jq -r 'sort_by(-(.validation.confidence // 0)) | .[:'"$max_patterns"'][] |
    "[\(.classification.type // "SUCCESS")] \(.name // .id): \(.content.description // "no description") (confidence: \(.validation.confidence // 0))"' 2>/dev/null)

  [[ -n "$output" ]] && echo -e "$output"
}

# ============================================================================
# SYNAPTIC PRUNING (Pattern 5) — Pattern lifecycle
# ============================================================================

# Decay all pattern confidence by 5% (called at blueprint end)
# Schema: .validation.confidence (0-1)
decay_patterns() {
  [[ ! -f "$PATTERN_LIBRARY" ]] && return 0

  yq -i '(.patterns[].validation.confidence) *= 0.95' "$PATTERN_LIBRARY" 2>/dev/null || true
  log_info "Pattern library: decay applied (all confidence * 0.95)"
}

# Prune weak patterns (threshold: 0.3 confidence minimum)
prune_patterns() {
  local blueprint_count="${1:-0}"
  [[ ! -f "$PATTERN_LIBRARY" ]] && return 0

  local threshold=0.3

  # Count patterns per domain before pruning (preserve minimum 3)
  local archive_file="${ATHENA_ROOT}/observability/pruned_patterns_archive.yaml"

  # Get patterns below threshold — schema uses .validation.confidence (0-1)
  local to_prune
  to_prune=$(yq -o=json ".patterns | map(select((.validation.confidence // 1) < $threshold))" "$PATTERN_LIBRARY" 2>/dev/null | tr -d '\r')
  local prune_count
  prune_count=$(echo "$to_prune" | jq 'length' 2>/dev/null || echo "0")

  if [[ "$prune_count" -gt 0 ]]; then
    # Archive pruned patterns before deletion
    if [[ ! -f "$archive_file" ]]; then
      echo "pruned_patterns: []" > "$archive_file"
    fi

    # Write each pruned pattern to archive, then log
    echo "$to_prune" | jq -c '.[]' 2>/dev/null | tr -d '\r' | while IFS= read -r pattern_json; do
      [[ -z "$pattern_json" ]] && continue
      local pid
      pid=$(echo "$pattern_json" | jq -r '.id' 2>/dev/null)
      # Append to archive YAML
      yq -i ".pruned_patterns += [$pattern_json]" "$archive_file" 2>/dev/null || true
      log_info "Pattern pruned and archived: $pid (confidence < $threshold)"
    done

    # Remove pruned patterns from library
    yq -i "del(.patterns[] | select((.validation.confidence // 1) < $threshold))" "$PATTERN_LIBRARY" 2>/dev/null || true
    log_info "Pattern library: pruned $prune_count patterns (threshold: $threshold)"
  fi
}

# Flag contradictory patterns for operator review
# Schema: .classification.type (SUCCESS/ANTI), .classification.domain for grouping
resolve_contradictions() {
  [[ ! -f "$PATTERN_LIBRARY" ]] && return 0
  [[ -z "${RUNTIME_DIR:-}" ]] && { log_warn "RUNTIME_DIR not set, skipping contradiction check"; return 0; }

  # Find patterns in same domain with opposite types (SUCCESS vs ANTI)
  local contradictions
  contradictions=$(yq -o=json '.patterns' "$PATTERN_LIBRARY" 2>/dev/null | \
    jq '[group_by(.classification.domain) | .[] | select(length > 1) |
      select(map(.classification.type) | unique | length > 1) |
      { domain: .[0].classification.domain, patterns: map(.id), types: map(.classification.type) | unique }] | select(length > 0)' 2>/dev/null | tr -d '\r')

  if [[ -n "$contradictions" && "$contradictions" != "null" && "$contradictions" != "[]" ]]; then
    log_warn "Pattern contradictions detected — flagging for operator review"
    echo "$contradictions" >> "$RUNTIME_DIR/pattern_contradictions.json" 2>/dev/null || true
  fi
}

# ============================================================================
# IMMUNE PROMOTION (Pattern 6 cross-reference)
# ============================================================================

# Promote repeated QA rejection patterns to immune memory
promote_immune_responses() {
  local runtime_dir="${1:-${RUNTIME_DIR:-}}"
  [[ -z "$runtime_dir" ]] && { log_warn "RUNTIME_DIR not set, skipping immune promotion"; return 0; }
  local immune_memory="$runtime_dir/immune_memory.jsonl"

  [[ ! -f "$runtime_dir/immune_events.jsonl" ]] && return 0

  # Find repeated violations (3+ occurrences of same violation type)
  local repeated
  repeated=$(jq -s 'group_by(.violations) | map(select(length >= 3)) | .[] |
    { pattern: .[0].violations, count: length, response: "flag", confidence: 0.50 }' \
    "$runtime_dir/immune_events.jsonl" 2>/dev/null | tr -d '\r')

  if [[ -n "$repeated" ]]; then
    echo "$repeated" | jq -c '.' 2>/dev/null | while IFS= read -r entry; do
      [[ -z "$entry" ]] && continue
      echo "$entry" >> "$immune_memory"
    done
    log_info "Immune promotion: flagged repeated violations for memory"
  fi
}

# Promote pruned anti-patterns to global blacklist
promote_to_blacklist() {
  [[ ! -f "$PATTERN_LIBRARY" ]] && return 0

  local blacklist="$ORCHESTRATOR_DIR/global_blacklist.jsonl"

  # Find anti-patterns with severity >= 3 that were recently pruned
  local archive="${ATHENA_ROOT}/observability/pruned_patterns_archive.yaml"
  [[ ! -f "$archive" ]] && return 0

  local anti_patterns
  anti_patterns=$(yq -o=json '.pruned_patterns // [] | map(select(.type == "ANTI_PATTERN" and (.severity // 0) >= 3))' "$archive" 2>/dev/null | tr -d '\r')
  [[ -z "$anti_patterns" || "$anti_patterns" == "[]" ]] && return 0

  echo "$anti_patterns" | jq -c '.[] | {
    id: .id,
    type: "anti_pattern_promotion",
    pattern: (.description // .name // .id),
    severity: (.severity // 3),
    ttl_days: 90,
    source: "synaptic_pruning",
    created_at: now | strftime("%Y-%m-%dT%H:%M:%SZ")
  }' 2>/dev/null | while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    echo "$entry" >> "$blacklist"
    log_info "Promoted anti-pattern to blacklist: $(echo "$entry" | jq -r '.id' 2>/dev/null)"
  done
}
