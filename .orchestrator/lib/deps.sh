#!/usr/bin/env bash
# deps.sh — DAG validation and dependency management
# Sourced by orchestrate.sh — provides cycle detection and topological sort

[[ -n "${_DEPS_SH_LOADED:-}" ]] && return 0
_DEPS_SH_LOADED=1

# Dependencies: utils.sh (loaded by parent)

# Validate DAG: check all dependencies exist and no cycles
# Args: state_file
validate_dag() {
  local state_file=$1
  [[ ! -f "$state_file" ]] && die "validate_dag: state_file not found: $state_file"

  local valid=true

  # Check 1: All referenced dependencies exist
  local task_ids
  task_ids=$(jq -r '.tasks | keys[]' "$state_file" | tr -d '\r')

  while IFS= read -r task_id; do
    local deps
    deps=$(jq -r ".tasks[\"$task_id\"].depends_on[]?" "$state_file" | tr -d '\r')

    for dep in $deps; do
      if ! echo "$task_ids" | grep -qx "$dep"; then
        log_error "Task '$task_id' depends on non-existent task: '$dep'"
        valid=false
      fi
    done
  done <<< "$task_ids"

  # Check 2: No cycles
  if ! detect_cycles "$state_file"; then
    valid=false
  fi

  [[ "$valid" == "true" ]] && return 0 || return 1
}

# Detect cycles using Kahn's algorithm
# Args: state_file
detect_cycles() {
  local state_file=$1
  [[ ! -f "$state_file" ]] && die "detect_cycles: state_file not found: $state_file"

  declare -A in_degree
  declare -A dependents
  local task_ids
  task_ids=$(jq -r '.tasks | keys[]' "$state_file" | tr -d '\r')

  # Build in-degree map and dependents graph
  while IFS= read -r task_id; do
    in_degree[$task_id]=0
  done <<< "$task_ids"

  while IFS= read -r task_id; do
    local deps
    deps=$(jq -r ".tasks[\"$task_id\"].depends_on[]?" "$state_file" | tr -d '\r')

    if [[ -n "$deps" ]]; then
      local dep_count=0
      for dep in $deps; do
        ((dep_count++)) || true
        dependents[$dep]+=" $task_id"
      done
      in_degree[$task_id]=$dep_count
    fi
  done <<< "$task_ids"

  # Kahn's algorithm: queue tasks with in-degree 0
  local queue=()
  for task_id in "${!in_degree[@]}"; do
    if [[ ${in_degree[$task_id]} -eq 0 ]]; then
      queue+=("$task_id")
    fi
  done

  local processed_count=0

  while [[ ${#queue[@]} -gt 0 ]]; do
    local current="${queue[0]}"
    queue=("${queue[@]:1}")
    ((processed_count++)) || true

    # Reduce in-degree of dependents
    for dep_task in ${dependents[$current]:-}; do
      ((in_degree[$dep_task]--)) || true
      if [[ ${in_degree[$dep_task]} -eq 0 ]]; then
        queue+=("$dep_task")
      fi
    done
  done

  # If not all tasks processed, there's a cycle
  local total_tasks
  total_tasks=$(echo "$task_ids" | grep -c .)

  if [[ $processed_count -ne $total_tasks ]]; then
    log_error "Cycle detected in task dependencies"

    # Report which tasks form the cycle
    for task_id in "${!in_degree[@]}"; do
      if [[ ${in_degree[$task_id]} -gt 0 ]]; then
        local deps
        deps=$(jq -r ".tasks[\"$task_id\"].depends_on[]?" "$state_file" | tr -d '\r' | tr '\n' ' ')
        log_error "  Task in cycle: '$task_id' depends on: $deps"
      fi
    done

    return 1
  fi

  return 0
}

# Topological sort: return tasks in execution order
# Args: state_file
topological_sort() {
  local state_file=$1
  [[ ! -f "$state_file" ]] && die "topological_sort: state_file not found: $state_file"

  declare -A in_degree
  declare -A dependents
  local task_ids
  task_ids=$(jq -r '.tasks | keys[]' "$state_file" | tr -d '\r')

  # Build dependency graph
  while IFS= read -r task_id; do
    in_degree[$task_id]=0
  done <<< "$task_ids"

  while IFS= read -r task_id; do
    local deps
    deps=$(jq -r ".tasks[\"$task_id\"].depends_on[]?" "$state_file" | tr -d '\r')

    if [[ -n "$deps" ]]; then
      local dep_count=0
      for dep in $deps; do
        ((dep_count++)) || true
        dependents[$dep]+=" $task_id"
      done
      in_degree[$task_id]=$dep_count
    fi
  done <<< "$task_ids"

  # Process in waves (tasks with same level can run in parallel)
  local remaining=true
  while $remaining; do
    local wave=()

    # Find all tasks with in-degree 0
    for task_id in "${!in_degree[@]}"; do
      if [[ ${in_degree[$task_id]} -eq 0 ]]; then
        wave+=("$task_id")
      fi
    done

    if [[ ${#wave[@]} -eq 0 ]]; then
      break
    fi

    # Output current wave (space-separated)
    echo "${wave[@]}"

    # Remove processed tasks and update in-degrees
    for task_id in "${wave[@]}"; do
      unset in_degree[$task_id]

      for dep_task in ${dependents[$task_id]:-}; do
        if [[ -n "${in_degree[$dep_task]:-}" ]]; then
          ((in_degree[$dep_task]--)) || true
        fi
      done
    done

    if [[ ${#in_degree[@]} -eq 0 ]]; then
      remaining=false
    fi
  done
}

# Get execution waves (grouped by dependency level)
# Args: state_file
get_execution_waves() {
  topological_sort "$1"
}

# Cascade failure: mark all dependent tasks as dep-failed
# Args: task_id
cascade_failure() {
  local task_id=$1
  [[ -z "$task_id" ]] && die "cascade_failure: task_id required"
  [[ ! -f "$STATE_FILE" ]] && die "cascade_failure: STATE_FILE not set"

  # Build reverse dependency map (task -> what depends on it)
  local all_tasks
  all_tasks=$(state_read '.tasks | keys[]' | tr -d '\r')

  declare -A reverse_deps

  while IFS= read -r tid; do
    local deps
    deps=$(task_get "$tid" "depends_on[]" 2>/dev/null || echo "")

    for dep in $deps; do
      reverse_deps[$dep]+=" $tid"
    done
  done <<< "$all_tasks"

  # BFS to find all transitively dependent tasks
  local queue=("$task_id")
  declare -A visited
  visited[$task_id]=1

  while [[ ${#queue[@]} -gt 0 ]]; do
    local current="${queue[0]}"
    queue=("${queue[@]:1}")

    # Mark all direct dependents as dep-failed
    for dep_task in ${reverse_deps[$current]:-}; do
      if [[ -z "${visited[$dep_task]:-}" ]]; then
        visited[$dep_task]=1
        queue+=("$dep_task")

        local dep_status
        dep_status=$(task_get "$dep_task" "status")

        # Only cascade to tasks that haven't already failed/completed
        if [[ "$dep_status" == "pending" || "$dep_status" == "running" ]]; then
          log_warn "Cascading failure: $dep_task (depends on failed $current)"
          task_set_status "$dep_task" "dep-failed"
        fi
      fi
    done
  done
}

# Calculate blocking factor: how many tasks directly depend on this task
# Gateway tasks (blocking_factor >= 3) should get more protection
# Args: task_id
calc_blocking_factor() {
  local task_id="$1"
  [[ ! -f "$STATE_FILE" ]] && echo "0" && return

  local count
  count=$(jq -r "[.tasks | to_entries[] | select(.value.depends_on[]? == \"$task_id\")] | length" "$STATE_FILE" 2>/dev/null || echo 0)
  echo "$count"
}
