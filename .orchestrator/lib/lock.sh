#!/usr/bin/env bash
# lock.sh — mkdir-based locking with stale detection

[[ -n "${_LOCK_SH_LOADED:-}" ]] && return 0
_LOCK_SH_LOADED=1

# ============================================================================
# LOCKING FUNCTIONS
# ============================================================================

is_lock_stale() {
  local name="$1"
  local lock_dir="${LOCKS_DIR}/${name}.lock"

  if [[ ! -d "$lock_dir" ]]; then
    return 1  # No lock exists, not stale
  fi

  local pid_file="${lock_dir}/pid"
  if [[ ! -f "$pid_file" ]]; then
    # Lock dir exists but no PID file — stale
    rm -rf "$lock_dir"
    return 0
  fi

  local pid
  pid=$(cat "$pid_file" 2>/dev/null || echo "")

  if [[ -z "$pid" ]]; then
    # Empty PID file — stale
    rm -rf "$lock_dir"
    return 0
  fi

  # Check if process is running
  if ! kill -0 "$pid" 2>/dev/null; then
    # PID not running — stale
    rm -rf "$lock_dir"
    return 0
  fi

  # Check lock age (> 60 seconds)
  local now
  now=$(date +%s)
  local lock_mtime
  lock_mtime=$(stat -c %Y "$lock_dir" 2>/dev/null || stat -f %m "$lock_dir" 2>/dev/null || echo "$now")
  local age=$(( now - lock_mtime ))

  local _stale_age=$(config_read "orchestration.lock_stale_age_s" "60")
  if [[ $age -gt $_stale_age ]] && ! kill -0 "$pid" 2>/dev/null; then
    # Old lock and PID not running — stale
    rm -rf "$lock_dir"
    return 0
  fi

  return 1  # Lock is active
}
