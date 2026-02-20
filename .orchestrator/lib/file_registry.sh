#!/usr/bin/env bash
# file_registry.sh — File conflict detection and execution wave generation
# Merges DAG dependencies with file read/write conflicts for safe parallel execution

[[ -n "${_FILE_REGISTRY_SH_LOADED:-}" ]] && return 0
_FILE_REGISTRY_SH_LOADED=1

# Build file registry from blueprint manifest
# Parses files_read/files_write per task, builds conflict matrix
# Output: runtime/{blueprint-id}/file_registry.json
build_file_registry() {
  local manifest="$1"
  local output_file="$2"  # e.g., runtime/{blueprint-id}/file_registry.json

  local task_count
  task_count=$(yq -r '.tasks | length' "$manifest")

  local registry="{}"

  for i in $(seq 0 $((task_count - 1))); do
    local tid
    tid=$(yq -r ".tasks[$i].id" "$manifest" | tr -d '\r')

    # Parse files_read (optional, defaults to empty array)
    local files_read
    files_read=$(yq -o=json ".tasks[$i].files_read // []" "$manifest" | tr -d '\r')

    # Parse files_write (optional, defaults to empty array)
    local files_write
    files_write=$(yq -o=json ".tasks[$i].files_write // []" "$manifest" | tr -d '\r')

    registry=$(echo "$registry" | jq \
      --arg tid "$tid" \
      --argjson fr "$files_read" \
      --argjson fw "$files_write" \
      '.[$tid] = { "files_read": $fr, "files_write": $fw }')
  done

  echo "$registry" | jq '.' > "$output_file"
  log_info "File registry built: $task_count tasks, output: $output_file"
}

# Detect file conflicts between tasks
# Returns JSON array of conflict objects: {task_a, task_b, file, type}
# Types: write_write (both write), read_after_write (A writes, B reads)
detect_file_conflicts() {
  local registry_file="$1"

  [[ ! -f "$registry_file" ]] && { echo "[]"; return 0; }

  local conflicts="[]"
  local task_ids
  task_ids=$(jq -r 'keys[]' "$registry_file" | tr -d '\r')

  # Compare all task pairs
  local tasks_arr=()
  while IFS= read -r tid; do
    [[ -n "$tid" ]] && tasks_arr+=("$tid")
  done <<< "$task_ids"

  local n=${#tasks_arr[@]}
  for ((a=0; a<n; a++)); do
    for ((b=a+1; b<n; b++)); do
      local tid_a="${tasks_arr[$a]}"
      local tid_b="${tasks_arr[$b]}"

      # Check write-write conflicts
      local ww_conflicts
      ww_conflicts=$(jq -r --arg a "$tid_a" --arg b "$tid_b" \
        '(.[$a].files_write // []) as $wa | (.[$b].files_write // []) as $wb |
         [$wa[] as $f | select($wb | index($f))] | .[]' "$registry_file" 2>/dev/null | tr -d '\r')

      for file in $ww_conflicts; do
        [[ -z "$file" ]] && continue
        conflicts=$(echo "$conflicts" | jq \
          --arg a "$tid_a" --arg b "$tid_b" --arg f "$file" \
          '. + [{"task_a": $a, "task_b": $b, "file": $f, "type": "write_write"}]')
      done

      # Check read-after-write: A writes, B reads
      local raw_conflicts
      raw_conflicts=$(jq -r --arg a "$tid_a" --arg b "$tid_b" \
        '(.[$a].files_write // []) as $wa | (.[$b].files_read // []) as $rb |
         [$wa[] as $f | select($rb | index($f))] | .[]' "$registry_file" 2>/dev/null | tr -d '\r')

      for file in $raw_conflicts; do
        [[ -z "$file" ]] && continue
        conflicts=$(echo "$conflicts" | jq \
          --arg a "$tid_a" --arg b "$tid_b" --arg f "$file" \
          '. + [{"task_a": $a, "task_b": $b, "file": $f, "type": "read_after_write"}]')
      done

      # Check read-after-write: B writes, A reads
      raw_conflicts=$(jq -r --arg a "$tid_a" --arg b "$tid_b" \
        '(.[$b].files_write // []) as $wb | (.[$a].files_read // []) as $ra |
         [$wb[] as $f | select($ra | index($f))] | .[]' "$registry_file" 2>/dev/null | tr -d '\r')

      for file in $raw_conflicts; do
        [[ -z "$file" ]] && continue
        conflicts=$(echo "$conflicts" | jq \
          --arg a "$tid_b" --arg b "$tid_a" --arg f "$file" \
          '. + [{"task_a": $a, "task_b": $b, "file": $f, "type": "read_after_write"}]')
      done
    done
  done

  echo "$conflicts"
}

# Generate execution waves merging DAG + file conflict dependencies
# Output: runtime/{blueprint-id}/execution_waves.json
generate_execution_waves() {
  local state_file="$1"
  local registry_file="$2"
  local output_file="$3"

  # Get file conflicts as additional dependency edges
  local conflicts
  conflicts=$(detect_file_conflicts "$registry_file")

  local conflict_count
  conflict_count=$(echo "$conflicts" | jq 'length')

  if [[ "$conflict_count" -gt 0 ]]; then
    log_info "File conflicts detected: $conflict_count — adding implicit dependencies to state"

    # S1.5: Inject file conflict deps into REAL state.json (not temp file)
    while IFS= read -r conflict; do
      local task_a task_b ctype
      task_a=$(echo "$conflict" | jq -r '.task_a' | tr -d '\r')
      task_b=$(echo "$conflict" | jq -r '.task_b' | tr -d '\r')
      ctype=$(echo "$conflict" | jq -r '.type' | tr -d '\r')

      # Add dependency: task_b depends on task_a (only if not already there)
      local already_dep
      already_dep=$(state_read ".tasks[\"$task_b\"].depends_on // [] | index(\"$task_a\") != null" 2>/dev/null || echo "false")

      if [[ "$already_dep" != "true" ]]; then
        state_write ".tasks[\"$task_b\"].depends_on = ((.tasks[\"$task_b\"].depends_on // []) + [\"$task_a\"] | unique)"
        log_info "File conflict ($ctype): $task_b now depends on $task_a"
        log_event "{\"ts\":\"$(now_iso)\",\"event\":\"file_conflict_dep\",\"task_a\":\"$task_a\",\"task_b\":\"$task_b\",\"conflict_type\":\"$ctype\"}"
      fi
    done < <(echo "$conflicts" | jq -c '.[]' 2>/dev/null | tr -d '\r')

    # Re-validate DAG after injection — detect cycles
    if ! detect_cycles "$state_file"; then
      log_error "CYCLE DETECTED after file conflict dep injection — ESCALATING"
      log_event "{\"ts\":\"$(now_iso)\",\"event\":\"dag_cycle_detected\",\"cause\":\"file_conflict_injection\"}"
      return 1
    fi

    # Generate waves from the now-updated real state
    local waves="[]"
    local wave_num=0
    while IFS= read -r wave_line; do
      [[ -z "$wave_line" ]] && continue
      ((wave_num++)) || true
      local task_arr
      task_arr=$(echo "$wave_line" | jq -R 'split(" ") | map(select(length > 0))')
      waves=$(echo "$waves" | jq --argjson w "$task_arr" --argjson n "$wave_num" \
        '. + [{"wave": $n, "tasks": $w}]')
    done < <(get_execution_waves "$state_file")
  else
    # No file conflicts — use standard DAG waves
    local waves="[]"
    local wave_num=0
    while IFS= read -r wave_line; do
      [[ -z "$wave_line" ]] && continue
      ((wave_num++)) || true
      local task_arr
      task_arr=$(echo "$wave_line" | jq -R 'split(" ") | map(select(length > 0))')
      waves=$(echo "$waves" | jq --argjson w "$task_arr" --argjson n "$wave_num" \
        '. + [{"wave": $n, "tasks": $w}]')
    done < <(get_execution_waves "$state_file")
  fi

  # Write execution waves
  jq -n --argjson w "$waves" --argjson c "$conflicts" \
    '{"waves": $w, "conflicts": $c, "total_waves": ($w | length)}' > "$output_file"

  log_info "Execution waves generated: $(echo "$waves" | jq 'length') waves, $conflict_count file conflicts"
}
