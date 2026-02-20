#!/usr/bin/env bash
# state.sh — State management for blueprint orchestrator
# Sourced by orchestrate.sh — provides CRUD operations on state.json

[[ -n "${_STATE_SH_LOADED:-}" ]] && return 0
_STATE_SH_LOADED=1

# Dependencies: utils.sh, lock.sh (loaded by parent)
# Globals used: STATE_FILE, EVENTS_FILE

# Path exports for runtime directory structure
# Initially empty — populated when RUNTIME_DIR is set via state_init_dirs()
export TELEMETRY_DIR="${RUNTIME_DIR:-}/telemetry"
export REPORTS_DIR="${RUNTIME_DIR:-}/reports"
export ATTEMPTS_DIR="${RUNTIME_DIR:-}/attempts"
export CRITERIA_DIR="${RUNTIME_DIR:-}/criteria"
export ADVISORY_DIR="${RUNTIME_DIR:-}/advisory"
export MEMORY_DIR="${ORCHESTRATOR_DIR:-.orchestrator}/memory"

# Initialize runtime directory structure
# Call after RUNTIME_DIR is set
state_init_dirs() {
  [[ -z "$RUNTIME_DIR" ]] && die "state_init_dirs: RUNTIME_DIR not set"

  # Re-export path variables now that RUNTIME_DIR is set
  export TELEMETRY_DIR="${RUNTIME_DIR}/telemetry"
  export REPORTS_DIR="${RUNTIME_DIR}/reports"
  export ATTEMPTS_DIR="${RUNTIME_DIR}/attempts"
  export CRITERIA_DIR="${RUNTIME_DIR}/criteria"
  export ADVISORY_DIR="${RUNTIME_DIR}/advisory"
  export MEMORY_DIR="${ORCHESTRATOR_DIR:-.orchestrator}/memory"

  mkdir -p "$TELEMETRY_DIR" || die "Failed to create telemetry dir"
  mkdir -p "$REPORTS_DIR" || die "Failed to create reports dir"
  mkdir -p "$ATTEMPTS_DIR" || die "Failed to create attempts dir"
  mkdir -p "$CRITERIA_DIR" || die "Failed to create criteria dir"
  mkdir -p "$ADVISORY_DIR" || die "Failed to create advisory dir"
  mkdir -p "$MEMORY_DIR" || die "Failed to create memory dir"

  log_info "Initialized runtime directory structure: $RUNTIME_DIR"
}

# Create initial state.json from blueprint manifest
# Args: blueprint_id manifest_path config_json tasks_json
init_state() {
  local blueprint_id=$1
  local manifest_path=$2
  local config_json=$3
  local tasks_json=$4

  [[ -z "$blueprint_id" ]] && die "init_state: blueprint_id required"
  [[ -z "$manifest_path" ]] && die "init_state: manifest_path required"
  [[ ! -f "$config_json" ]] && die "init_state: config_json not found: $config_json"
  [[ ! -f "$tasks_json" ]] && die "init_state: tasks_json not found: $tasks_json"

  local timestamp
  timestamp=$(now_iso)

  local budget_limit
  budget_limit=$(jq -r '.budget.limit_usd // 50' "$config_json")

  local tmp="${STATE_FILE}.tmp.$$"

  # Construct initial state with jq
  jq -n \
    --arg bid "$blueprint_id" \
    --arg mpath "$manifest_path" \
    --arg ts "$timestamp" \
    --argjson config "$(cat "$config_json")" \
    --argjson tasks "$(cat "$tasks_json")" \
    --argjson budget_limit "$budget_limit" \
    '{
      _version: 0,
      blueprint_id: $bid,
      manifest_path: $mpath,
      status: "running",
      started_at: $ts,
      updated_at: $ts,
      config: $config,
      budget: {
        limit_usd: $budget_limit,
        used_usd: 0.0,
        estimated_remaining: $budget_limit
      },
      tasks: (
        $tasks | to_entries | map({
          key: .key,
          value: (.value + {
            status: "pending",
            worker: .value.worker,
            model: .value.model,
            depends_on: (.value.depends_on // []),
            attempts: 0,
            score: null,
            pid: null,
            started_at: null,
            completed_at: null,
            last_feedback: null
          })
        }) | from_entries
      ),
      counters: {
        running: 0,
        completed: 0,
        failed: 0,
        total: ($tasks | length)
      }
    }' > "$tmp" || die "Failed to create initial state"

  mv "$tmp" "$STATE_FILE" || die "Failed to write state file"
  log_info "Initialized state: $STATE_FILE"
}

# Read state with jq filter
# Args: jq_filter
# Returns: jq output on success, empty string on failure (does NOT die)
state_read() {
  local filter=$1
  if [[ -z "$filter" ]]; then filter='.'; fi
  if [[ ! -f "$STATE_FILE" ]]; then
    log_warn "state_read: State file not found: $STATE_FILE" 2>/dev/null || true
    return 1
  fi

  local result
  result=$(jq -r "$filter" "$STATE_FILE" 2>/dev/null | tr -d '\r') || {
    log_warn "state_read: jq filter failed: $filter" 2>/dev/null || true
    return 1
  }
  echo "$result"
}

# Write state with jq filter (atomic + locked + CAS version counter)
# Args: jq_filter
# Uses mkdir-based lock to prevent concurrent read-modify-write races.
# CAS: reads _version before write, increments it, retries on version mismatch.
# $BASHPID gives actual subshell PID (unlike $$ which is inherited).
state_write() {
  local filter=$1
  [[ -z "$filter" ]] && die "state_write: filter required"
  [[ ! -f "$STATE_FILE" ]] && die "State file not found: $STATE_FILE"

  local cas_attempt=0
  local max_cas=$(config_read "orchestration.cas_max_retries" "5")

  while [[ $cas_attempt -lt $max_cas ]]; do
    local lock_dir="${STATE_FILE}.lock"
    local retries=0
    local _lock_ms=$(config_read "orchestration.lock_timeout_ms" "20000")
    local max_retries=$((_lock_ms / 100))  # Each retry sleeps 0.1s

    # Acquire lock (spin with mkdir)
    while ! mkdir "$lock_dir" 2>/dev/null; do
      ((retries++)) || true
      if [[ $retries -ge $max_retries ]]; then
        # Force break stale lock
        rm -rf "$lock_dir" 2>/dev/null || true
        mkdir "$lock_dir" 2>/dev/null || die "state_write: cannot acquire lock after ${max_retries} retries"
        break
      fi
      sleep 0.1
    done

    # Read version before modification
    local version_before
    version_before=$(jq -r '._version // 0' "$STATE_FILE" 2>/dev/null) || version_before=0

    # Use BASHPID for unique temp file (real subshell PID, not inherited $$)
    local tmp="${STATE_FILE}.tmp.${BASHPID:-$$}.${RANDOM}"
    local timestamp
    timestamp=$(now_iso)

    # Read-modify-write under lock: apply filter + increment _version
    jq "$filter | ._version = (._version // 0) + 1 | .updated_at = \"$timestamp\"" "$STATE_FILE" > "$tmp" 2>/dev/null
    local jq_exit=$?

    if [[ $jq_exit -ne 0 ]]; then
      rm -f "$tmp"
      rm -rf "$lock_dir" 2>/dev/null || true
      die "Failed to apply state update: $filter"
    fi

    # CAS check: verify version hasn't changed between lock acquire and write
    local version_now
    version_now=$(jq -r '._version // 0' "$STATE_FILE" 2>/dev/null) || version_now=0

    if [[ "$version_before" != "$version_now" ]]; then
      # Version changed — another writer snuck in (stale lock break race)
      rm -f "$tmp"
      rm -rf "$lock_dir" 2>/dev/null || true
      ((cas_attempt++)) || true
      local backoff_s
      backoff_s=$(awk -v a="$cas_attempt" 'BEGIN { printf "%.1f", 0.1 * a }')
      log_warn "state_write: CAS retry $cas_attempt/$max_cas (version $version_before→$version_now, backoff ${backoff_s}s)"
      sleep "$backoff_s"
      continue
    fi

    mv "$tmp" "$STATE_FILE" || {
      rm -rf "$lock_dir" 2>/dev/null || true
      die "Failed to write state atomically"
    }

    # Release lock
    rm -rf "$lock_dir" 2>/dev/null || true
    return 0
  done

  die "state_write: CAS failed after $max_cas retries (concurrent modification)"
}

# Write state and return a jq-extracted result in one atomic operation.
# Args: jq_filter result_filter
# The jq_filter modifies state; result_filter extracts a value from the new state.
# Returns: result of result_filter applied to the post-write state.
state_write_and_read() {
  local filter=$1
  local result_filter=$2
  [[ -z "$filter" ]] && die "state_write_and_read: filter required"
  [[ -z "$result_filter" ]] && die "state_write_and_read: result_filter required"
  [[ ! -f "$STATE_FILE" ]] && die "State file not found: $STATE_FILE"

  local cas_attempt=0
  local max_cas=$(config_read "orchestration.cas_max_retries" "5")

  while [[ $cas_attempt -lt $max_cas ]]; do
    local lock_dir="${STATE_FILE}.lock"
    local retries=0
    local _lock_ms=$(config_read "orchestration.lock_timeout_ms" "20000")
    local max_retries=$((_lock_ms / 100))

    while ! mkdir "$lock_dir" 2>/dev/null; do
      ((retries++)) || true
      if [[ $retries -ge $max_retries ]]; then
        rm -rf "$lock_dir" 2>/dev/null || true
        mkdir "$lock_dir" 2>/dev/null || die "state_write_and_read: cannot acquire lock after ${max_retries} retries"
        break
      fi
      sleep 0.1
    done

    local version_before
    version_before=$(jq -r '._version // 0' "$STATE_FILE" 2>/dev/null) || version_before=0

    local tmp="${STATE_FILE}.tmp.${BASHPID:-$$}.${RANDOM}"
    local timestamp
    timestamp=$(now_iso)

    # Apply filter, increment version, write to temp
    jq "$filter | ._version = (._version // 0) + 1 | .updated_at = \"$timestamp\"" "$STATE_FILE" > "$tmp" 2>/dev/null
    local jq_exit=$?

    if [[ $jq_exit -ne 0 ]]; then
      rm -f "$tmp"
      rm -rf "$lock_dir" 2>/dev/null || true
      die "state_write_and_read: Failed to apply update: $filter"
    fi

    # CAS check
    local version_now
    version_now=$(jq -r '._version // 0' "$STATE_FILE" 2>/dev/null) || version_now=0

    if [[ "$version_before" != "$version_now" ]]; then
      rm -f "$tmp"
      rm -rf "$lock_dir" 2>/dev/null || true
      ((cas_attempt++)) || true
      local backoff_s
      backoff_s=$(awk -v a="$cas_attempt" 'BEGIN { printf "%.1f", 0.1 * a }')
      log_warn "state_write_and_read: CAS retry $cas_attempt/$max_cas (backoff ${backoff_s}s)"
      sleep "$backoff_s"
      continue
    fi

    # Extract result from the new state BEFORE moving into place
    local result
    result=$(jq -r "$result_filter" "$tmp" 2>/dev/null) || {
      rm -f "$tmp"
      rm -rf "$lock_dir" 2>/dev/null || true
      die "state_write_and_read: result_filter failed: $result_filter"
    }

    mv "$tmp" "$STATE_FILE" || {
      rm -rf "$lock_dir" 2>/dev/null || true
      die "state_write_and_read: Failed to write state atomically"
    }

    rm -rf "$lock_dir" 2>/dev/null || true
    echo "$result"
    return 0
  done

  die "state_write_and_read: CAS failed after $max_cas retries"
}

# Update task status and recalculate counters in a single atomic write
# Args: task_id new_status
task_set_status() {
  local task_id=$1
  local new_status=$2

  [[ -z "$task_id" ]] && die "task_set_status: task_id required"
  [[ -z "$new_status" ]] && die "task_set_status: new_status required"

  state_write '
    .tasks["'"$task_id"'"].status = "'"$new_status"'" |
    .counters.running = ([.tasks[] | select(.status == "running")] | length) |
    .counters.completed = ([.tasks[] | select(.status == "completed")] | length) |
    .counters.failed = ([.tasks[] | select(.status | IN("rejected","exhausted","dep-failed","aborted","budget_blocked"))] | length)
  '
  log_event "{\"ts\":\"$(now_iso)\",\"event\":\"task_status\",\"task_id\":\"$task_id\",\"status\":\"$new_status\"}"
}

# Set arbitrary task field
# Args: task_id field value (value is raw jq expression)
task_set_field() {
  local task_id=$1
  local field=$2
  local value=$3

  [[ -z "$task_id" ]] && die "task_set_field: task_id required"
  [[ -z "$field" ]] && die "task_set_field: field required"

  state_write ".tasks[\"$task_id\"].$field = $value"
}

# Get task field value
# Args: task_id field
task_get() {
  local task_id=$1
  local field=$2

  [[ -z "$task_id" ]] && die "task_get: task_id required"
  [[ -z "$field" ]] && die "task_get: field required"

  state_read ".tasks[\"$task_id\"].$field"
}

# Get list of ready tasks (pending + all deps completed)
# Single atomic jq query — no per-task reads.
get_ready_tasks() {
  [[ ! -f "$STATE_FILE" ]] && return 0

  state_read '
    .tasks as $all |
    $all | to_entries | map(
      select(
        .value.status == "pending" and
        ((.value.depends_on // []) | all(. as $d | $all[$d].status == "completed"))
      )
    ) | map(.key) | .[]
  '
}

# Check if blueprint is done (no pending/running tasks)
is_blueprint_done() {
  [[ ! -f "$STATE_FILE" ]] && return 1

  local active
  active=$(state_read '[.tasks[] | select(.status | IN("pending","running","rework"))] | length')

  [[ "$active" -eq 0 ]]
}

# Get blueprint status summary
get_blueprint_status() {
  [[ ! -f "$STATE_FILE" ]] && return 1

  state_read '{
    status: .status,
    running: .counters.running,
    completed: .counters.completed,
    failed: .counters.failed,
    total: .counters.total
  }'
}

# Mark blueprint as completed/failed
set_blueprint_status() {
  local new_status=$1
  [[ -z "$new_status" ]] && die "set_blueprint_status: status required"

  state_write ".status = \"$new_status\""
  log_event "{\"ts\":\"$(now_iso)\",\"event\":\"blueprint_status\",\"status\":\"$new_status\"}"
}
