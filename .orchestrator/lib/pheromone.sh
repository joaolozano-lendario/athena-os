#!/usr/bin/env bash
# pheromone.sh — Pheromone table for evidence-based model routing
# Storage: $RUNTIME_DIR/pheromone_table.json
# FORMICA v3.5

[[ -n "${_PHEROMONE_SH_LOADED:-}" ]] && return 0
_PHEROMONE_SH_LOADED=1

EVAPORATION_RATE=$(config_read "pheromone.evaporation_rate" "0.9")

# Initialize pheromone table (idempotent)
init_pheromone() {
  local pheromone_file="${RUNTIME_DIR}/pheromone_table.json"
  [[ -f "$pheromone_file" ]] && return
  echo '{}' > "$pheromone_file"
}

# Record a QA score for worker_type + model combination (running average)
# S2.3: mkdir-based lock to prevent concurrent read-modify-write races
record_pheromone() {
  local worker_type="$1" model="$2" score="$3"
  local pheromone_file="${RUNTIME_DIR}/pheromone_table.json"

  init_pheromone

  local lock_dir="${pheromone_file}.lock"
  local retries=0
  local _lock_ms=$(config_read "pheromone.lock_timeout_ms" "5000")
  local max_retries=$((_lock_ms / 100))  # Each retry sleeps 0.1s

  # Acquire lock
  while ! mkdir "$lock_dir" 2>/dev/null; do
    ((retries++)) || true
    if [[ $retries -ge $max_retries ]]; then
      rm -rf "$lock_dir" 2>/dev/null || true
      mkdir "$lock_dir" 2>/dev/null || {
        log_warn "record_pheromone: lock acquisition failed after $max_retries retries"
        return 1
      }
      break
    fi
    sleep 0.1
  done

  local key="${worker_type}__${model}"
  local current count
  current=$(jq -r ".\"$key\".avg // 0" "$pheromone_file" 2>/dev/null || echo 0)
  count=$(jq -r ".\"$key\".n // 0" "$pheromone_file" 2>/dev/null || echo 0)

  local new_avg new_count
  new_count=$((count + 1))
  new_avg=$(awk -v c="$current" -v n="$count" -v s="$score" 'BEGIN { printf "%.1f", (c * n + s) / (n + 1) }')

  local tmp
  tmp=$(mktemp)
  if jq --arg k "$key" --argjson avg "$new_avg" --argjson n "$new_count" \
    '.[$k] = {"avg": $avg, "n": $n}' \
    "$pheromone_file" > "$tmp" 2>/dev/null; then
    mv "$tmp" "$pheromone_file"
    log_debug "Pheromone recorded: $key avg=$new_avg n=$new_count"
  else
    rm -f "$tmp"
    log_warn "record_pheromone: jq failed for $key"
  fi

  # Release lock
  rm -rf "$lock_dir" 2>/dev/null || true
}

# Get pheromone score for worker_type + model
get_pheromone() {
  local worker_type="$1" model="$2"
  local pheromone_file="${RUNTIME_DIR}/pheromone_table.json"
  local key="${worker_type}__${model}"
  jq -r ".\"$key\".avg // 0" "$pheromone_file" 2>/dev/null || echo 0
}

# Evaporate all pheromone scores (call at wave start)
# S2.3: Verify jq exit code before mv — preserve file on jq failure
evaporate_pheromones() {
  local pheromone_file="${RUNTIME_DIR}/pheromone_table.json"
  [[ ! -f "$pheromone_file" ]] && return

  local tmp
  tmp=$(mktemp)
  if jq --argjson rate "$EVAPORATION_RATE" \
    'to_entries | map(.value.avg = (.value.avg * $rate | . * 10 | round / 10)) | from_entries' \
    "$pheromone_file" > "$tmp" 2>/dev/null; then
    mv "$tmp" "$pheromone_file"
    log_info "Pheromone evaporation applied (rate: $EVAPORATION_RATE)"
  else
    rm -f "$tmp"
    log_warn "Pheromone evaporation failed (jq error) — file preserved"
  fi
}

# Evaporate old signals and friction events (TTL-based cleanup)
evaporate_signals() {
  local current_wave="${1:-0}"
  local signal_ttl=$(config_read "pheromone.signal_ttl_waves" "2")
  local friction_ttl=$(config_read "pheromone.friction_ttl_waves" "3")

  for file_type in "colony_signals" "friction_events"; do
    local file="${RUNTIME_DIR}/${file_type}.jsonl"
    [[ ! -f "$file" ]] && continue

    local ttl=$signal_ttl
    [[ "$file_type" == "friction_events" ]] && ttl=$friction_ttl
    local min_wave=$((current_wave - ttl))

    local tmp
    tmp=$(mktemp)
    if jq -c "select(.wave >= $min_wave)" "$file" > "$tmp" 2>/dev/null; then
      mv "$tmp" "$file"
    else
      rm -f "$tmp"
      log_warn "Signal evaporation failed (jq error) for $file_type — file preserved"
    fi
  done

  log_debug "Signal evaporation applied (wave=$current_wave)"
}

# L1: Save pheromone evidence to epigenetic markers for cross-blueprint persistence
save_pheromone_to_markers() {
  local pheromone_file="${RUNTIME_DIR}/pheromone_table.json"
  [[ ! -f "$pheromone_file" ]] && return 0
  [[ ! -f "$MARKERS_FILE" ]] && return 0

  # Merge pheromone averages into epigenetic markers as model_scores
  local entries
  entries=$(jq -r 'to_entries[] | "\(.key)=\(.value.avg)=\(.value.n)"' "$pheromone_file" 2>/dev/null)
  while IFS='=' read -r key avg n; do
    [[ -z "$key" || -z "$avg" ]] && continue
    local _min_obs=$(config_read "pheromone.min_observations" "2")
    [[ "$n" -lt "$_min_obs" ]] && continue
    yq -i ".pheromone_evidence.\"$key\" = {\"avg\": $avg, \"n\": $n}" "$MARKERS_FILE" 2>/dev/null || true
  done <<< "$entries"

  log_info "Pheromone evidence saved to epigenetic markers"
}
