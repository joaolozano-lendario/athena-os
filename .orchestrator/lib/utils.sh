#!/usr/bin/env bash
# utils.sh — Logging, colors, platform detection, path normalization

[[ -n "${_UTILS_SH_LOADED:-}" ]] && return 0
_UTILS_SH_LOADED=1

# ============================================================================
# GLOBALS
# ============================================================================

ORCHESTRATOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLATFORM="unix"
if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
  PLATFORM="windows"
fi

# Colors (set by setup_colors)
RED=""
GREEN=""
YELLOW=""
BLUE=""
BOLD=""
RESET=""

# ============================================================================
# COLOR SETUP
# ============================================================================

setup_colors() {
  if [[ -t 2 ]] && command -v tput >/dev/null 2>&1 && [[ -z "${NO_COLOR:-}" ]]; then
    RED=$(tput setaf 1 2>/dev/null || echo "")
    GREEN=$(tput setaf 2 2>/dev/null || echo "")
    YELLOW=$(tput setaf 3 2>/dev/null || echo "")
    BLUE=$(tput setaf 4 2>/dev/null || echo "")
    BOLD=$(tput bold 2>/dev/null || echo "")
    RESET=$(tput sgr0 2>/dev/null || echo "")
  fi
}

setup_colors

# ============================================================================
# TIMESTAMP
# ============================================================================

now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# ============================================================================
# LOGGING
# ============================================================================

log_info() {
  local msg="$1"
  local timestamp
  timestamp=$(now_iso)
  echo "${BLUE}[INFO]${RESET} ${timestamp} ${msg}" >&2
  if [[ -n "${LOG_FILE:-}" ]]; then
    echo "[INFO] ${timestamp} ${msg}" >> "$LOG_FILE"
  fi
}

log_warn() {
  local msg="$1"
  local timestamp
  timestamp=$(now_iso)
  echo "${YELLOW}[WARN]${RESET} ${timestamp} ${msg}" >&2
  if [[ -n "${LOG_FILE:-}" ]]; then
    echo "[WARN] ${timestamp} ${msg}" >> "$LOG_FILE"
  fi
}

log_error() {
  local msg="$1"
  local timestamp
  timestamp=$(now_iso)
  echo "${RED}[ERROR]${RESET} ${timestamp} ${msg}" >&2
  if [[ -n "${LOG_FILE:-}" ]]; then
    echo "[ERROR] ${timestamp} ${msg}" >> "$LOG_FILE"
  fi
}

log_debug() {
  if [[ "${DEBUG:-0}" == "1" ]]; then
    local msg="$1"
    local timestamp
    timestamp=$(now_iso)
    echo "${BOLD}[DEBUG]${RESET} ${timestamp} ${msg}" >&2
    if [[ -n "${LOG_FILE:-}" ]]; then
      echo "[DEBUG] ${timestamp} ${msg}" >> "$LOG_FILE"
    fi
  fi
}

log_event() {
  local json_line="$1"
  if [[ -n "${EVENTS_FILE:-}" ]]; then
    append_jsonl "$EVENTS_FILE" "$json_line"
  fi
}

# ============================================================================
# UTILITIES
# ============================================================================

normalize_path() {
  local path="$1"
  echo "$path" | sed 's|\\|/|g'
}

die() {
  local msg="$1"
  log_error "$msg"
  exit 1
}

# Locked JSONL append — prevents concurrent interleaving on Windows/MSYS
append_jsonl() {
  local file="$1"
  local line="$2"
  local lock_dir="${file}.appendlock"
  local retries=0
  local _jl_max=$(config_read "orchestration.jsonl_lock_retries" "20")
  while ! mkdir "$lock_dir" 2>/dev/null; do
    ((retries++)) || true
    if [[ $retries -ge "$_jl_max" ]]; then
      rm -rf "$lock_dir" 2>/dev/null
      mkdir "$lock_dir" 2>/dev/null || true
      break
    fi
    sleep 0.05
  done
  # S1: Validate JSON before append (prevents cascade poisoning)
  if ! echo "$line" | jq empty 2>/dev/null; then
    log_warn "JSONL validation failed, skipping write to $file: ${line:0:100}"
    rm -rf "$lock_dir" 2>/dev/null || true
    return 1
  fi
  echo "$line" >> "$file"
  rm -rf "$lock_dir" 2>/dev/null || true
}
