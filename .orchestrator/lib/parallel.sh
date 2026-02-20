#!/usr/bin/env bash
# parallel.sh — Background PID management for concurrent workers
# IMPORTANT: reap_finished and count_running MUST be called directly (not in subshell)
# because they modify global arrays PIDS/EXITS.

[[ -n "${_PARALLEL_SH_LOADED:-}" ]] && return 0
_PARALLEL_SH_LOADED=1

# ============================================================================
# GLOBALS
# ============================================================================

declare -gA PIDS=()
declare -gA EXITS=()
LAST_REAPED=0  # Set by reap_finished (avoids subshell capture)

# ============================================================================
# PARALLEL EXECUTION FUNCTIONS
# ============================================================================

# Reap finished background processes.
# Sets LAST_REAPED to count. Modifies PIDS and EXITS arrays.
# MUST be called in parent context (NOT inside $()).
reap_finished() {
  LAST_REAPED=0

  local _pids_to_remove=()
  for task_id in "${!PIDS[@]}"; do
    local pid="${PIDS[$task_id]}"

    if ! kill -0 "$pid" 2>/dev/null; then
      # Process finished
      local exit_code=0
      wait "$pid" 2>/dev/null || exit_code=$?

      EXITS[$task_id]=$exit_code
      _pids_to_remove+=("$task_id")
      ((LAST_REAPED++)) || true

      log_debug "Reaped task '$task_id' (PID $pid) with exit code $exit_code"
      log_event "{\"event\":\"reap\",\"task_id\":\"$task_id\",\"pid\":$pid,\"exit_code\":$exit_code,\"timestamp\":\"$(now_iso)\"}"
    fi
  done

  # Remove reaped PIDs (done after iteration to avoid modifying array during loop)
  for task_id in "${_pids_to_remove[@]}"; do
    unset "PIDS[$task_id]"
  done
}

kill_all() {
  log_warn "Killing all running tasks (${#PIDS[@]} processes)"

  # Send SIGTERM first
  for task_id in "${!PIDS[@]}"; do
    local pid="${PIDS[$task_id]}"
    kill "$pid" 2>/dev/null || true
  done

  sleep "$(config_read "orchestration.kill_timeout_s" "2")"

  # Send SIGKILL to survivors
  for task_id in "${!PIDS[@]}"; do
    local pid="${PIDS[$task_id]}"
    if kill -0 "$pid" 2>/dev/null; then
      log_warn "Force killing task '$task_id' (PID $pid)"
      kill -9 "$pid" 2>/dev/null || true
    fi
  done

  # Clear arrays
  PIDS=()
  EXITS=()
}

# Return count of running processes (safe to call from parent context)
count_running() {
  echo "${#PIDS[@]}"
}
