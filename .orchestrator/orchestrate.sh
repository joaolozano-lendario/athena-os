#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# FORMICA v3.0 — Conscious Execution Engine
# ATHENA's execution arm: F0 INGEST → F1 PREPARE → F2 EXECUTE → F3 SYNTHESIZE
# Bash orchestrator spawning independent claude -p workers with isolated context
# Biomimetic: Allometry, Immune System, Trophallaxis, Negative Pheromone
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries (core)
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/lock.sh"
source "$SCRIPT_DIR/lib/parallel.sh"
source "$SCRIPT_DIR/lib/state.sh"
source "$SCRIPT_DIR/lib/deps.sh"
source "$SCRIPT_DIR/lib/cost.sh"
source "$SCRIPT_DIR/lib/context.sh"
source "$SCRIPT_DIR/lib/qa.sh"

# Source libraries (intelligence layer — FORMIGA v1.0)
source "$SCRIPT_DIR/lib/file_registry.sh"
source "$SCRIPT_DIR/lib/routing.sh"
source "$SCRIPT_DIR/lib/advisory.sh"

# Source libraries (FORMICA v2.0)
source "$SCRIPT_DIR/lib/modes.sh"
source "$SCRIPT_DIR/lib/friction.sh"
source "$SCRIPT_DIR/lib/wizard.sh"
source "$SCRIPT_DIR/lib/report.sh"
source "$SCRIPT_DIR/lib/meta_report.sh"
source "$SCRIPT_DIR/lib/epigenetics.sh"

# Source libraries (FORMICA v3.0)
source "$SCRIPT_DIR/lib/ingest.sh"
source "$SCRIPT_DIR/lib/budget.sh"

# Source libraries (FORMICA v3.5)
source "$SCRIPT_DIR/lib/pheromone.sh"

# Source libraries (FORMICA v4.2 — SAPIENS)
source "$SCRIPT_DIR/lib/decisions.sh"
source "$SCRIPT_DIR/lib/consciousness.sh"

# Source meta-loop (conditional — only if meta_loop config exists)
source "$SCRIPT_DIR/lib/meta_loop.sh"

# Source ATHENA-native layer (optional — graceful no-op if not available)
if [[ -f "$SCRIPT_DIR/lib/athena.sh" ]]; then
  source "$SCRIPT_DIR/lib/athena.sh"
fi

# ============================================================================
# GLOBALS
# ============================================================================

MANIFEST=""
RUNTIME_DIR=""
BLUEPRINT_ID=""
MAX_PARALLEL=2
MAX_RETRIES=3
QA_THRESHOLD=80
DEFAULT_MODEL="sonnet"
QA_MODEL="haiku"
TASK_BUDGET=$(config_read "orchestration.default_task_budget_usd" "0.50")
TASK_TIMEOUT=$(config_read "orchestration.task_timeout_s" "600")
PROJECT_DIR=""
DRY_RUN=false
RESUME=false
STATUS_ONLY=false
INTERACTIVE=false
BLUEPRINT_PATH=""
AUTO_APPROVE=false
RESTART=false
ABANDON=false
export ORCHESTRATOR_DIR="$SCRIPT_DIR"
HOOK_SETTINGS=""

# === SELF-MODIFICATION PROTECTION (v3.4) ===
# Prevent workers from editing orchestrator code during execution.
# Restores on exit (normal or crash) via trap.
_protect_code() {
  chmod -w "$ORCHESTRATOR_DIR/orchestrate.sh" \
           "$ORCHESTRATOR_DIR"/lib/*.sh \
           "$ORCHESTRATOR_DIR"/workers/*.md 2>/dev/null || true
}
_unprotect_code() {
  chmod +w "$ORCHESTRATOR_DIR/orchestrate.sh" \
           "$ORCHESTRATOR_DIR"/lib/*.sh \
           "$ORCHESTRATOR_DIR"/workers/*.md 2>/dev/null || true
}
trap '_unprotect_code' EXIT

# === HOOK INFRASTRUCTURE (v4.1) ===
# Load Claude Code hook settings for cross-file coherence validation.
# Hooks are opt-in: only active when hooks/formica-hooks.json exists AND
# the blueprint manifest defines a coherence section with mode != "off".
_load_hook_settings() {
  local hooks_config="$ORCHESTRATOR_DIR/hooks/formica-hooks.json"
  local hooks_enabled
  hooks_enabled=$(config_read "hooks.enabled" "false")
  if [[ ! -f "$hooks_config" || "$hooks_enabled" == "false" ]]; then
    HOOK_SETTINGS=""
    return 0
  fi

  # Check if manifest defines coherence mode
  local coherence_mode
  coherence_mode=$(yq -r '.coherence.mode // "off"' "$MANIFEST" 2>/dev/null | tr -d '\r')
  if [[ "$coherence_mode" == "off" || -z "$coherence_mode" ]]; then
    HOOK_SETTINGS=""
    log_info "Hooks: coherence mode=off — hooks disabled"
    return 0
  fi

  # Load hook settings JSON (expand $ORCHESTRATOR_DIR in paths)
  HOOK_SETTINGS=$(sed "s|\${ORCHESTRATOR_DIR}|$ORCHESTRATOR_DIR|g" "$hooks_config")
  export FORMICA_RUNTIME_DIR="$RUNTIME_DIR"
  export FORMICA_PROJECT_DIR="${PROJECT_DIR:-}"
  export FORMICA_COHERENCE_MODE="$coherence_mode"

  # Generate coherence-map.json for hooks to read
  local coherence_map="$RUNTIME_DIR/coherence-map.json"
  yq -o=json '.coherence // {}' "$MANIFEST" 2>/dev/null | tr -d '\r' > "$coherence_map"

  log_info "Hooks: mode=$coherence_mode — settings loaded from $hooks_config"
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --manifest|-m)     MANIFEST="$(normalize_path "$2")"; shift 2 ;;
      --resume|-r)       RESUME=true; shift ;;
      --restart)         RESTART=true; shift ;;
      --abandon)         ABANDON=true; shift ;;
      --dry-run|-n)      DRY_RUN=true; shift ;;
      --auto-approve|-a) AUTO_APPROVE=true; shift ;;
      --parallel|-p)     MAX_PARALLEL="$2"; shift 2 ;;
      --status|-s)       STATUS_ONLY=true; shift ;;
      --interactive)     INTERACTIVE=true; shift ;;
      --debug)           DEBUG=1; shift ;;
      --help|-h)         show_help; exit 0 ;;
      *)
        if [[ -z "$MANIFEST" && -z "$BLUEPRINT_PATH" ]]; then
          if [[ -d "$1" ]]; then
            BLUEPRINT_PATH="$(normalize_path "$1")"; shift
          elif [[ -f "$1" ]]; then
            MANIFEST="$(normalize_path "$1")"; shift
          else
            die "Not found: $1"
          fi
        else
          die "Unknown option: $1"
        fi
        ;;
    esac
  done

  if [[ -z "$MANIFEST" && -z "$BLUEPRINT_PATH" ]]; then
    die "Usage: orchestrate.sh <blueprint-dir|manifest.yaml> [options]"
  fi
  if [[ -n "$MANIFEST" && ! -f "$MANIFEST" ]]; then
    die "Manifest not found: $MANIFEST"
  fi
  if [[ -n "$BLUEPRINT_PATH" && ! -d "$BLUEPRINT_PATH" ]]; then
    die "Blueprint directory not found: $BLUEPRINT_PATH"
  fi
}

show_help() {
  cat <<'HELP'
FORMICA v3.0 — Conscious Execution Engine

Usage: orchestrate.sh <blueprint-dir|manifest.yaml> [options]

Blueprint Directory (F0→F1→F2→F3 lifecycle):
  orchestrate.sh /path/to/blueprint/       Execute blueprint package
  orchestrate.sh /path/to/blueprint/ -n    Dry-run (validate + show plan)
  orchestrate.sh /path/to/blueprint/ -a    Auto-approve (skip confirmation)
  orchestrate.sh /path/to/blueprint/ -r    Resume interrupted blueprint
  orchestrate.sh /path/to/blueprint/ --restart  Clean restart
  orchestrate.sh /path/to/blueprint/ --abandon  Clean up interrupted state

Legacy Manifest:
  orchestrate.sh manifest.yaml             Execute from flat YAML manifest
  orchestrate.sh manifest.yaml --resume    Resume from manifest

Options:
  --manifest, -m      Path to blueprint YAML manifest (legacy)
  --resume, -r        Resume a previously interrupted blueprint
  --restart           Clean runtime and restart from scratch
  --abandon           Clean up interrupted blueprint state
  --dry-run, -n       Validate and show plan without executing
  --auto-approve, -a  Skip operator confirmation in F1
  --parallel, -p      Max concurrent workers (default: 2)
  --status, -s        Show current blueprint status and exit
  --interactive       Pause on critical failures for human review
  --debug             Enable debug logging
  --help, -h          Show this help

Lifecycle:
  F0: INGEST      Validate blueprint, compile execution plan
  F1: PREPARE     Show wizard (cost, waves, warnings), confirm
  F2: EXECUTE     Wave-based parallel execution with QA + retry
  F3: SYNTHESIZE  Reports, diagnostic, handoff, memory update
HELP
}

# ============================================================================
# MANIFEST VALIDATION
# ============================================================================

validate_manifest() {
  log_info "Validating manifest: $MANIFEST"

  # Parse blueprint metadata
  BLUEPRINT_ID=$(yq -r '.blueprint.id' "$MANIFEST") || die "Failed to parse blueprint.id"
  if [[ "$BLUEPRINT_ID" == "null" || -z "$BLUEPRINT_ID" ]]; then
    die "blueprint.id is required"
  fi

  PROJECT_DIR=$(yq -r '.blueprint.project_dir // ""' "$MANIFEST")
  PROJECT_DIR=$(normalize_path "$PROJECT_DIR")
  if [[ -n "$PROJECT_DIR" && ! -d "$PROJECT_DIR" ]]; then
    die "project_dir not found: $PROJECT_DIR"
  fi

  # Parse config with defaults
  MAX_PARALLEL=$(yq -r ".config.max_parallel // $MAX_PARALLEL" "$MANIFEST")
  MAX_RETRIES=$(yq -r ".config.max_retries // $MAX_RETRIES" "$MANIFEST")
  QA_THRESHOLD=$(yq -r ".config.qa_threshold // $QA_THRESHOLD" "$MANIFEST")
  DEFAULT_MODEL=$(yq -r ".config.default_model // \"$DEFAULT_MODEL\"" "$MANIFEST")
  QA_MODEL=$(yq -r ".config.qa_model // \"$QA_MODEL\"" "$MANIFEST")
  TASK_BUDGET=$(yq -r ".config.task_budget_usd // $TASK_BUDGET" "$MANIFEST")
  TASK_TIMEOUT=$(yq -r ".config.task_timeout_s // $TASK_TIMEOUT" "$MANIFEST")
  local _default_max=$(config_read "orchestration.default_max_budget_usd" "50")
  local MAX_BUDGET=$(yq -r ".config.max_budget_usd // $_default_max" "$MANIFEST")

  # Validate worker prompts exist
  local worker_names
  worker_names=$(yq -r '.workers | keys | .[]' "$MANIFEST" 2>/dev/null || echo "")
  for wname in $worker_names; do
    local wprompt
    wprompt=$(yq -r ".workers.$wname.prompt" "$MANIFEST")
    local wpath="$SCRIPT_DIR/$wprompt"
    if [[ ! -f "$wpath" ]]; then
      die "Worker prompt not found: $wpath (worker: $wname)"
    fi
  done

  # Validate tasks
  local task_count
  task_count=$(yq -r '.tasks | length' "$MANIFEST")
  if [[ "$task_count" -eq 0 ]]; then
    die "No tasks defined in manifest"
  fi

  # Collect all task output paths (these will be created during execution)
  local task_outputs=""
  for i in $(seq 0 $((task_count - 1))); do
    local out
    out=$(yq -r ".tasks[$i].output" "$MANIFEST")
    task_outputs="$task_outputs $out"
    if [[ -n "$PROJECT_DIR" ]]; then
      task_outputs="$task_outputs $PROJECT_DIR/$out"
    fi
  done

  # Check context files exist (skip files that are outputs of other tasks)
  local errors=0
  for i in $(seq 0 $((task_count - 1))); do
    local tid
    tid=$(yq -r ".tasks[$i].id" "$MANIFEST")
    local ctx_files
    ctx_files=$(yq -r ".tasks[$i].context_files[]?" "$MANIFEST" 2>/dev/null || echo "")
    for cf in $ctx_files; do
      # Skip if this context file is an output of another task
      local is_task_output=false
      for tout in $task_outputs; do
        if [[ "$cf" == "$tout" || "$PROJECT_DIR/$cf" == "$tout" ]]; then
          is_task_output=true
          break
        fi
      done
      if $is_task_output; then
        log_debug "Context file $cf is a task output — skipping existence check"
        continue
      fi

      local resolved="$cf"
      if [[ -n "$PROJECT_DIR" && ! -f "$cf" ]]; then
        resolved="$PROJECT_DIR/$cf"
      fi
      if [[ ! -f "$resolved" ]]; then
        log_error "Context file not found for task $tid: $cf"
        ((errors++)) || true
      fi
    done
  done
  if [[ $errors -gt 0 ]]; then
    die "Manifest validation failed: $errors context file(s) missing"
  fi

  # Build temp state for DAG validation
  local tmp_state="/tmp/orchestrator-dag-check-${BASHPID:-$$}-${RANDOM}.json"
  build_tasks_json "$MANIFEST" "$tmp_state"
  if ! validate_dag "$tmp_state"; then
    rm -f "$tmp_state"
    die "DAG validation failed"
  fi

  # Budget sanity check
  local total_estimated=0
  for i in $(seq 0 $((task_count - 1))); do
    local tb
    tb=$(yq -r ".tasks[$i].budget_usd // $TASK_BUDGET" "$MANIFEST")
    local _est_mult=$(config_read "pricing.expected_cost_multiplier" "1.30")
    total_estimated=$(awk -v t="$total_estimated" -v b="$tb" -v r="$MAX_RETRIES" -v m="$_est_mult" 'BEGIN { printf "%.2f", t + b * (r + 1) * m }' 2>/dev/null || echo "$total_estimated")
  done

  log_info "Manifest valid: $task_count tasks, budget \$${MAX_BUDGET}"

  # Apply allometry based on task count
  apply_allometry "$task_count"

  # Override allometry if manifest specifies advisory/routing config
  local advisory_cfg
  advisory_cfg=$(yq -r '.config.advisory.enabled // "auto"' "$MANIFEST" 2>/dev/null | tr -d '\r')
  if [[ "$advisory_cfg" == "true" ]]; then
    ADVISORY_ENABLED=true
  elif [[ "$advisory_cfg" == "false" ]]; then
    ADVISORY_ENABLED=false
  fi
  # "auto" = keep allometry decision

  # Build file registry for conflict detection
  local registry_file="/tmp/orchestrator-registry-${BASHPID:-$$}-${RANDOM}.json"
  build_file_registry "$MANIFEST" "$registry_file"

  # Inject file conflict dependencies into tmp_state for accurate wave display
  local conflicts
  conflicts=$(detect_file_conflicts "$registry_file")
  local conflict_count
  conflict_count=$(echo "$conflicts" | jq 'length' 2>/dev/null || echo "0")
  if [[ "$conflict_count" -gt 0 ]]; then
    log_info "File conflicts detected: $conflict_count — adjusting execution waves"
    while IFS= read -r conflict; do
      local task_a task_b
      task_a=$(echo "$conflict" | jq -r '.task_a' | tr -d '\r')
      task_b=$(echo "$conflict" | jq -r '.task_b' | tr -d '\r')
      local already_dep
      already_dep=$(jq --arg a "$task_a" --arg b "$task_b" '.tasks[$b].depends_on // [] | index($a) != null' "$tmp_state" 2>/dev/null | tr -d '\r')
      if [[ "$already_dep" != "true" ]]; then
        jq --arg a "$task_a" --arg b "$task_b" \
          '.tasks[$b].depends_on = (.tasks[$b].depends_on // [] | . + [$a])' \
          "$tmp_state" > "${tmp_state}.tmp" && mv "${tmp_state}.tmp" "$tmp_state"
      fi
    done < <(echo "$conflicts" | jq -c '.[]' 2>/dev/null | tr -d '\r')
  fi
  rm -f "$registry_file"

  # Show execution waves in dry-run
  if $DRY_RUN; then
    echo ""
    echo "=== DRY RUN: Execution Plan ==="
    echo "Blueprint: $(yq -r '.blueprint.name' "$MANIFEST")"
    echo "Tasks: $task_count"
    echo "Max parallel: $MAX_PARALLEL"
    echo "Budget: \$${MAX_BUDGET}"
    echo ""
    echo "Execution waves:"
    local wave_num=0
    while IFS= read -r wave; do
      [[ -z "$wave" ]] && continue
      ((wave_num++)) || true
      echo "  Wave $wave_num: $wave"
    done < <(get_execution_waves "$tmp_state")
    echo ""
    echo "Workers:"
    for wname in $worker_names; do
      local wmodel
      wmodel=$(yq -r ".workers.$wname.model // \"$DEFAULT_MODEL\"" "$MANIFEST")
      echo "  $wname ($wmodel)"
    done
    rm -f "$tmp_state"
    echo ""
    echo "=== Dry run complete. No workers spawned. ==="
    return 0
  fi

  rm -f "$tmp_state"
  return 0
}

# Build tasks JSON object from manifest for state initialization
build_tasks_json() {
  local manifest="$1"
  local output="$2"

  local task_count
  task_count=$(yq -r '.tasks | length' "$manifest")

  local tasks_obj="{}"
  for i in $(seq 0 $((task_count - 1))); do
    local tid wkr mdl deps_json
    tid=$(yq -r ".tasks[$i].id" "$manifest")
    wkr=$(yq -r ".tasks[$i].worker" "$manifest")
    mdl=$(yq -r ".tasks[$i].model // \"$DEFAULT_MODEL\"" "$manifest")
    deps_json=$(yq -o=json ".tasks[$i].depends_on // []" "$manifest")

    tasks_obj=$(echo "$tasks_obj" | jq \
      --arg tid "$tid" \
      --arg wkr "$wkr" \
      --arg mdl "$mdl" \
      --argjson deps "$deps_json" \
      '.[$tid] = { "worker": $wkr, "model": $mdl, "depends_on": $deps, "status": "pending", "attempts": 0, "score": null, "pid": null, "started_at": null, "completed_at": null, "last_feedback": null }')
  done

  echo "$tasks_obj" | jq '{ tasks: . }' > "$output"
}

# ============================================================================
# BLUEPRINT INITIALIZATION
# ============================================================================

init_blueprint() {
  RUNTIME_DIR="$(normalize_path "$(pwd)/runtime/$BLUEPRINT_ID")"

  # Create runtime directory structure (telemetry/, reports/, attempts/, criteria/, advisory/, memory/)
  state_init_dirs
  mkdir -p "$RUNTIME_DIR"/{locks,logs,contracts}

  # Set global paths (telemetry streams go to TELEMETRY_DIR subdirectory)
  STATE_FILE="$RUNTIME_DIR/state.json"
  EVENTS_FILE="$TELEMETRY_DIR/events.jsonl"
  COST_FILE="$TELEMETRY_DIR/cost.jsonl"
  LOCKS_DIR="$RUNTIME_DIR/locks"
  LOG_FILE="$RUNTIME_DIR/logs/orchestrator.log"

  # Build config JSON
  local config_file="/tmp/orchestrator-config-${BASHPID:-$$}-${RANDOM}.json"
  jq -n \
    --argjson mp "$MAX_PARALLEL" \
    --argjson mr "$MAX_RETRIES" \
    --argjson qt "$QA_THRESHOLD" \
    --argjson bl "$(yq -r ".config.max_budget_usd // $(config_read "orchestration.default_max_budget_usd" "50")" "$MANIFEST")" \
    '{ max_parallel: $mp, max_retries: $mr, qa_threshold: $qt, budget: { limit_usd: $bl } }' \
    > "$config_file"

  # Build tasks JSON
  local tasks_file="/tmp/orchestrator-tasks-${BASHPID:-$$}-${RANDOM}.json"
  build_tasks_json "$MANIFEST" "$tasks_file"
  # Extract just the tasks object
  local tasks_inner="/tmp/orchestrator-tasks-inner-${BASHPID:-$$}-${RANDOM}.json"
  jq '.tasks' "$tasks_file" > "$tasks_inner"

  # Initialize state
  init_state "$BLUEPRINT_ID" "$MANIFEST" "$config_file" "$tasks_inner"

  # Inject file conflict dependencies into state
  local registry_file="$RUNTIME_DIR/file_registry.json"
  build_file_registry "$MANIFEST" "$registry_file"
  local conflicts
  conflicts=$(detect_file_conflicts "$registry_file")
  local conflict_count
  conflict_count=$(echo "$conflicts" | jq 'length' 2>/dev/null || echo "0")
  if [[ "$conflict_count" -gt 0 ]]; then
    log_info "File conflicts detected: $conflict_count — injecting implicit dependencies into state"
    while IFS= read -r conflict; do
      local task_a task_b ctype
      task_a=$(echo "$conflict" | jq -r '.task_a' | tr -d '\r')
      task_b=$(echo "$conflict" | jq -r '.task_b' | tr -d '\r')
      ctype=$(echo "$conflict" | jq -r '.type' | tr -d '\r')
      # Add dependency: task_b depends on task_a
      local existing_deps
      existing_deps=$(state_read ".tasks[\"$task_b\"].depends_on // []" 2>/dev/null)
      local already_dep
      already_dep=$(echo "$existing_deps" | jq --arg a "$task_a" 'index($a) != null' 2>/dev/null | tr -d '\r')
      if [[ "$already_dep" != "true" ]]; then
        state_write ".tasks[\"$task_b\"].depends_on = ((.tasks[\"$task_b\"].depends_on // []) + [\"$task_a\"] | unique)"
        log_info "File conflict ($ctype): $task_b now depends on $task_a"
        log_event "{\"ts\":\"$(now_iso)\",\"event\":\"file_conflict_dep\",\"task_a\":\"$task_a\",\"task_b\":\"$task_b\",\"conflict_type\":\"$ctype\"}"
      fi
    done < <(echo "$conflicts" | jq -c '.[]' 2>/dev/null | tr -d '\r')

    # Re-validate DAG after file conflict dep injection
    if ! detect_cycles "$STATE_FILE" 2>/dev/null; then
      log_error "CYCLE DETECTED after file conflict dep injection — aborting"
      set_blueprint_status "failed"
      return 1
    fi
  fi

  # Load epigenetic markers (FORMICA v2.0)
  load_markers

  # Apply orchestration mode (FORMICA v2.0)
  local blueprint_mode
  blueprint_mode=$(yq -r '.config.mode // "quality"' "$MANIFEST" 2>/dev/null | tr -d '\r')
  apply_orchestration_mode "$blueprint_mode"
  log_event "{\"ts\":\"$(now_iso)\",\"event\":\"mode_applied\",\"mode\":\"$blueprint_mode\"}"
  _log_decision "mode_selection" "$BLUEPRINT_ID" "{\"task_count\":$(yq -r '.tasks | length' "$MANIFEST" 2>/dev/null),\"manifest_mode\":\"$blueprint_mode\"}" "$blueprint_mode" "Mode from manifest config.mode" "economic,speed,guided"

  # Allow individual YAML overrides to win over mode defaults
  local yaml_parallel yaml_retries yaml_threshold yaml_model yaml_qa_model
  yaml_parallel=$(yq -r '.config.max_parallel // ""' "$MANIFEST" 2>/dev/null | tr -d '\r')
  yaml_retries=$(yq -r '.config.max_retries // ""' "$MANIFEST" 2>/dev/null | tr -d '\r')
  yaml_threshold=$(yq -r '.config.qa_threshold // ""' "$MANIFEST" 2>/dev/null | tr -d '\r')
  yaml_model=$(yq -r '.config.default_model // ""' "$MANIFEST" 2>/dev/null | tr -d '\r')
  yaml_qa_model=$(yq -r '.config.qa_model // ""' "$MANIFEST" 2>/dev/null | tr -d '\r')
  [[ -n "$yaml_parallel" && "$yaml_parallel" != "null" ]] && MAX_PARALLEL="$yaml_parallel"
  [[ -n "$yaml_retries" && "$yaml_retries" != "null" ]] && MAX_RETRIES="$yaml_retries"
  [[ -n "$yaml_threshold" && "$yaml_threshold" != "null" ]] && QA_THRESHOLD="$yaml_threshold"
  [[ -n "$yaml_model" && "$yaml_model" != "null" ]] && DEFAULT_MODEL="$yaml_model"
  [[ -n "$yaml_qa_model" && "$yaml_qa_model" != "null" ]] && QA_MODEL="$yaml_qa_model"

  # Initialize events log
  log_event "{\"ts\":\"$(now_iso)\",\"event\":\"blueprint_start\",\"blueprint_id\":\"$BLUEPRINT_ID\",\"tasks_total\":$(yq -r '.tasks | length' "$MANIFEST"),\"mode\":\"$blueprint_mode\"}"

  # Cleanup temp files
  rm -f "$config_file" "$tasks_file" "$tasks_inner"

  log_info "Blueprint initialized: $BLUEPRINT_ID → $RUNTIME_DIR"
}

resume_blueprint() {
  RUNTIME_DIR="$(normalize_path "$(pwd)/runtime/$BLUEPRINT_ID")"
  [[ ! -d "$RUNTIME_DIR" ]] && die "No runtime directory found for blueprint: $BLUEPRINT_ID"

  # S2.2: Reject resume after advisory cancel
  local current_status
  current_status=$(jq -r '.status // ""' "$RUNTIME_DIR/state.json" 2>/dev/null | tr -d '\r')
  if [[ "$current_status" == "cancelled" ]]; then
    log_error "Blueprint $BLUEPRINT_ID was cancelled by advisory. Cannot resume a cancelled blueprint."
    log_error "To re-run, start a fresh execution with --restart."
    return 1
  fi

  # Clean stale state lock from previous interrupted run
  rm -rf "${RUNTIME_DIR}/state.json.lock" 2>/dev/null || true

  # Detect old flat structure and warn
  if [[ -f "$RUNTIME_DIR/events.jsonl" && ! -d "$RUNTIME_DIR/telemetry" ]]; then
    log_warn "Detected old flat runtime structure. Consider migrating to subdirectory layout."
  fi

  # Ensure subdirectory structure exists (handles migration of old flat layouts)
  state_init_dirs
  mkdir -p "$RUNTIME_DIR"/{locks,logs,contracts}

  STATE_FILE="$RUNTIME_DIR/state.json"
  EVENTS_FILE="$TELEMETRY_DIR/events.jsonl"
  COST_FILE="$TELEMETRY_DIR/cost.jsonl"
  LOCKS_DIR="$RUNTIME_DIR/locks"
  LOG_FILE="$RUNTIME_DIR/logs/orchestrator.log"

  [[ ! -f "$STATE_FILE" ]] && die "No state file found: $STATE_FILE"

  # Reset running tasks to pending (they were interrupted)
  local running_tasks
  running_tasks=$(state_read '[.tasks | to_entries[] | select(.value.status == "running") | .key] | .[]' 2>/dev/null || echo "")
  for tid in $running_tasks; do
    log_warn "Resetting interrupted task $tid: running → pending"
    task_set_status "$tid" "pending"
  done

  # Reset rework tasks to pending for re-execution
  local rework_tasks
  rework_tasks=$(state_read '[.tasks | to_entries[] | select(.value.status == "rework") | .key] | .[]' 2>/dev/null || echo "")
  for tid in $rework_tasks; do
    log_info "Re-queuing rework task $tid"
    task_set_status "$tid" "pending"
  done

  # Reconcile orphan budget reservations (tasks that had budget reserved but never completed)
  local orphan_reservations
  orphan_reservations=$(state_read '.budget.reservations // {} | keys[]' 2>/dev/null || echo "")
  if [[ -n "$orphan_reservations" ]]; then
    log_warn "Found orphan budget reservations — releasing"
    for tid in $orphan_reservations; do
      local reserved_amt
      reserved_amt=$(state_read ".budget.reservations[\"$tid\"] // 0")
      log_info "Releasing orphan reservation for $tid: \$${reserved_amt}"
      budget_reconcile "$tid" "0"
    done
  fi

  # Clean stale locks
  if [[ -d "$LOCKS_DIR" ]]; then
    for lock_dir in "$LOCKS_DIR"/*.lock; do
      [[ -d "$lock_dir" ]] || continue
      local name
      name=$(basename "$lock_dir" .lock)
      if is_lock_stale "$name"; then
        log_warn "Cleaned stale lock: $name"
      fi
    done
  fi

  set_blueprint_status "running"
  log_event "{\"ts\":\"$(now_iso)\",\"event\":\"blueprint_resume\",\"blueprint_id\":\"$BLUEPRINT_ID\"}"
  log_info "resumed blueprint: $BLUEPRINT_ID"
}

# ============================================================================
# BLUEPRINT EXECUTION
# ============================================================================

run_blueprint() {
  _protect_code  # v3.4: lock code files during execution
  log_info "starting blueprint: $BLUEPRINT_ID (max_parallel=$MAX_PARALLEL, advisory=$ADVISORY_ENABLED)"

  # Wave tracking for advisory hooks
  local current_wave_tasks=""
  local wave_num=0
  local tasks_completed_in_wave=0
  local tasks_total_in_wave=0
  local -a DEFERRED_CASCADES=()

  while ! is_blueprint_done; do
    # Reap finished workers (must be called in parent context, not $())
    reap_finished

    # Process exit codes from reaped tasks
    for tid in "${!EXITS[@]}"; do
      process_worker_exit "$tid" "${EXITS[$tid]}"
      # v4.2: Update consciousness map with latest DAG state
      if type update_consciousness_map &>/dev/null; then
        update_consciousness_map "$tid" "" "" "$RUNTIME_DIR" 2>/dev/null || true
      fi
      unset "EXITS[$tid]"
    done

    # Get ready tasks
    local ready
    ready=$(get_ready_tasks) || true

    # Wave transition detection: if new ready set differs from current wave
    if [[ -n "$ready" && "$ready" != "$current_wave_tasks" && ${#PIDS[@]} -eq 0 ]]; then
      # Process deferred cascades from this wave
      for failed_tid in "${DEFERRED_CASCADES[@]}"; do
        cascade_failure "$failed_tid" 2>/dev/null || true
      done
      DEFERRED_CASCADES=()

      # Wave completed — run advisory if enabled and not first wave
      if [[ $wave_num -gt 0 && "$ADVISORY_ENABLED" == "true" ]]; then
        log_info "Wave $wave_num completed. Running advisory review..."
        update_progress "advisory: wave $wave_num review starting" 2>/dev/null || true
        run_advisory "$BLUEPRINT_ID" "$wave_num" "${DEFAULT_MODEL:-sonnet}" || true
        local advisory_rc=0
        apply_advisory "$wave_num" || advisory_rc=$?
        if [[ $advisory_rc -eq 2 ]]; then
          log_error "Advisory triggered blueprint CANCEL"
          break
        elif [[ $advisory_rc -ne 0 ]]; then
          log_warn "Advisory triggered blueprint pause"
          break
        fi
        # Adapt allometry between waves
        # Compute actual failure_rate and retry_rate for allometry adaptation
        local failed_count completed_count total_attempts total_tasks_done
        failed_count=$(state_read '.counters.failed // 0' 2>/dev/null || echo "0")
        completed_count=$(state_read '.counters.completed // 0' 2>/dev/null || echo "0")
        total_tasks_done=$((completed_count + failed_count))
        [[ "$total_tasks_done" -eq 0 ]] && total_tasks_done=1
        local failure_rate retry_rate
        failure_rate=$(awk -v f="$failed_count" -v t="$total_tasks_done" 'BEGIN { printf "%.2f", f/t }')
        # retry_rate: tasks that needed retries / total tasks done
        total_attempts=$(state_read '[.tasks | to_entries[] | select(.value.status == "completed" or .value.status == "failed") | .value.attempt // 1] | add // 0' 2>/dev/null || echo "0")
        retry_rate=$(awk -v a="$total_attempts" -v t="$total_tasks_done" 'BEGIN { printf "%.2f", (a > t) ? (a - t) / t : 0 }')
        adapt_allometry "$failure_rate" "$retry_rate"
      fi
      current_wave_tasks="$ready"
      ((wave_num++)) || true
      tasks_completed_in_wave=0
      tasks_total_in_wave=$(echo "$ready" | wc -w)
      # Immune memory promotion at wave boundary (batch, not per task)
      promote_immune_memory 2>/dev/null || true
      # Pheromone evaporation at wave boundary
      evaporate_pheromones 2>/dev/null || true
      evaporate_signals "$wave_num" 2>/dev/null || true
      log_info "=== Wave $wave_num: $tasks_total_in_wave tasks ==="
      local total_waves
      total_waves=$(state_read '.counters.total' 2>/dev/null || echo "?")
      update_progress "=== WAVE $wave_num ($tasks_total_in_wave tasks) ===" 2>/dev/null || true
    fi

    # Count running (uses echo, safe in $())
    local running
    running=${#PIDS[@]}
    for tid in $ready; do
      if [[ "$running" -ge "$MAX_PARALLEL" ]]; then
        break
      fi

      # Budget reservation (atomic check+deduct)
      local task_budget
      task_budget=$(get_task_field_from_manifest "$tid" "budget_usd" "$TASK_BUDGET")
      if ! budget_reserve "$task_budget" "$tid"; then
        log_error "Budget exceeded. Aborting remaining tasks."
        abort_remaining
        break 2
      fi

      # Immune Layer 1: Pre-spawn barriers
      local worker_name
      worker_name=$(get_task_field_from_manifest "$tid" "worker" "implementer")
      if ! pre_spawn_barriers "$tid" "$worker_name" "$task_budget"; then
        log_warn "Task $tid ABORTED by immune barrier"
        task_set_status "$tid" "aborted"
        continue
      fi

      # Set status and started_at BEFORE fork to avoid race with background child
      # v3.7: Also set status=running here (not just in execute_task) to prevent
      # get_ready_tasks from re-dispatching during L2 stagger sleep
      task_set_field "$tid" "started_at" "\"$(now_iso)\""
      task_set_status "$tid" "running"

      # L2: Stagger launch — prevent thundering herd
      [[ $running -gt 0 ]] && sleep "$(config_read "orchestration.stagger_sleep_s" "2")"
      execute_task "$tid" &
      PIDS[$tid]=$!
      task_set_field "$tid" "pid" "$!"
      ((running++)) || true
    done

    # Print progress
    print_progress

    # If nothing to do and nothing running, we're stuck or done
    if [[ -z "$ready" && ${#PIDS[@]} -eq 0 ]]; then
      if ! is_blueprint_done; then
        log_warn "No ready tasks and no running workers — possible deadlock or all remaining tasks dep-failed"
        break
      fi
    fi

    sleep "$(config_read "orchestration.poll_interval_s" "2")"
  done

  # Final reap
  while [[ ${#PIDS[@]} -gt 0 ]]; do
    reap_finished
    for tid in "${!EXITS[@]}"; do
      process_worker_exit "$tid" "${EXITS[$tid]}"
      unset "EXITS[$tid]"
    done
    sleep 1
  done

  # Final advisory for last wave
  if [[ $wave_num -gt 0 && "$ADVISORY_ENABLED" == "true" ]]; then
    run_advisory "$BLUEPRINT_ID" "$wave_num" "${DEFAULT_MODEL:-sonnet}" || true
  fi

  # Determine final status (preserve cancel/pause set by advisory)
  local current_status
  current_status=$(state_read '.status' 2>/dev/null || echo "running")
  if [[ "$current_status" == "cancelled" || "$current_status" == "paused" ]]; then
    log_info "Blueprint status preserved: $current_status (set by advisory)"
  else
    local failed_count
    failed_count=$(state_read '.counters.failed')
    if [[ "$failed_count" -gt 0 ]]; then
      set_blueprint_status "completed"
      log_warn "Blueprint completed with $failed_count failed task(s)"
    else
      set_blueprint_status "completed"
      log_info "Blueprint completed successfully"
    fi
  fi

  local final_status
  final_status=$(state_read '.status' 2>/dev/null || echo "completed")
  log_event "{\"ts\":\"$(now_iso)\",\"event\":\"blueprint_complete\",\"status\":\"$final_status\",\"tasks_passed\":$(state_read '.counters.completed'),\"tasks_failed\":$(state_read '.counters.failed'),\"total_cost\":$(state_read '.budget.used_usd')}"
}

# ============================================================================
# TASK EXECUTION (Ralph Loop)
# ============================================================================

execute_task() {
  local task_id="$1"
  set +e  # Disable errexit — we handle errors explicitly in this subshell

  # C4 watchdog moved inside while loop (v3.7: per-attempt timeout, not cumulative)
  local _self_pid="$BASHPID"
  local _timeout_pid=""
  trap 'kill "$_timeout_pid" 2>/dev/null; wait "$_timeout_pid" 2>/dev/null || true' RETURN

  local task_idx
  task_idx=$(get_task_index "$task_id")
  local worker_name
  worker_name=$(yq -r ".tasks[$task_idx].worker" "$MANIFEST")
  local model
  model=$(yq -r ".tasks[$task_idx].model // \"$DEFAULT_MODEL\"" "$MANIFEST")
  local description
  description=$(yq -r ".tasks[$task_idx].description" "$MANIFEST")
  local output_path
  output_path=$(yq -r ".tasks[$task_idx].output" "$MANIFEST")
  local task_budget
  task_budget=$(yq -r ".tasks[$task_idx].budget_usd // $TASK_BUDGET" "$MANIFEST")
  # Apply epigenetic budget adjustment
  local budget_adj
  budget_adj=$(get_budget_adjustment "$worker_name") || budget_adj="1.0"
  if [[ "$budget_adj" != "1.0" ]]; then
    task_budget=$(awk -v b="$task_budget" -v a="$budget_adj" 'BEGIN { printf "%.2f", b * a }')
    log_info "Epigenetic budget adjustment for $worker_name: x${budget_adj} → \$${task_budget}"
  fi
  # Budget Intelligence: calculate safety budget from token-aware estimate
  local estimated_cost
  estimated_cost=$(estimate_task_cost "$MANIFEST" "$task_idx" "${PROJECT_DIR:-}") || estimated_cost="0.10"
  local safety_budget
  safety_budget=$(calculate_safety_budget "$estimated_cost" "$task_budget") || safety_budget="$task_budget"
  # Criticality-based protection: gateway tasks get scaled budget
  local blocking_factor
  blocking_factor=$(calc_blocking_factor "$task_id" 2>/dev/null || echo 0)
  local _gw_bf=$(config_read "routing.gateway_blocking_factor" "3")
  local _gw_mult=$(config_read "routing.gateway_budget_multiplier" "1.5")
  if [[ "$blocking_factor" -ge "$_gw_bf" ]]; then
    safety_budget=$(awk -v b="$safety_budget" -v m="$_gw_mult" 'BEGIN { printf "%.2f", b * m }')
    log_info "[$task_id] Gateway task (blocks $blocking_factor) — budget scaled to \$${safety_budget}"
  fi

  log_info "Budget: estimated=\$${estimated_cost}, safety=\$${safety_budget} (manifest=\$${task_budget}, blocks=$blocking_factor)"

  local qa_threshold_task
  qa_threshold_task=$(yq -r ".tasks[$task_idx].qa.threshold // $QA_THRESHOLD" "$MANIFEST")
  local qa_model_task
  qa_model_task=$(yq -r ".tasks[$task_idx].qa.model // \"$QA_MODEL\"" "$MANIFEST")

  # Resolve output path
  [[ -n "$PROJECT_DIR" ]] && output_path="$PROJECT_DIR/$output_path"
  output_path=$(normalize_path "$output_path")
  mkdir -p "$(dirname "$output_path")"

  # Get worker config
  local worker_prompt_path
  worker_prompt_path=$(yq -r ".workers.$worker_name.prompt" "$MANIFEST")
  local worker_tools
  worker_tools=$(yq -r ".workers.$worker_name.tools // \"Read,Write,Grep,Glob\"" "$MANIFEST")
  # Model routing via select_model (replaces static read)
  local retry_count
  retry_count=$(task_get "$task_id" "attempts" 2>/dev/null || echo "0")
  [[ "$retry_count" == "null" ]] && retry_count=0
  local budget_pct=100
  local used_usd limit_usd
  used_usd=$(state_read '.budget.used_usd' 2>/dev/null || echo "0")
  limit_usd=$(state_read '.budget.limit_usd' 2>/dev/null || echo "50")
  if command -v awk &>/dev/null; then
    budget_pct=$(awk -v u="$used_usd" -v l="$limit_usd" 'BEGIN { if (l>0) printf "%d", (1 - u/l) * 100; else print 100 }')
  fi
  local task_model_override
  task_model_override=$(yq -r ".tasks[$task_idx].model // \"\"" "$MANIFEST" 2>/dev/null | tr -d '\r')
  local worker_model
  worker_model=$(select_model "$worker_name" "$retry_count" "$budget_pct" "$task_model_override" "$blocking_factor")

  # Context file list (JSON array)
  local context_files
  context_files=$(yq -o=json ".tasks[$task_idx].context_files // []" "$MANIFEST")
  # Resolve relative paths against project_dir
  if [[ -n "$PROJECT_DIR" ]]; then
    context_files=$(echo "$context_files" | jq --arg pd "$PROJECT_DIR" '[.[] | if startswith("/") or startswith("D:") or startswith("C:") then . else ($pd + "/" + .) end]')
  fi

  # Analyst safety gate: restrict tools when context_files is empty
  if [[ "$worker_name" == "analyst" ]]; then
    local file_count
    file_count=$(echo "$context_files" | jq 'length' 2>/dev/null || echo 0)
    if [[ "$file_count" -eq 0 ]]; then
      log_warn "[$task_id] Analyst has empty context_files — restricting tools"
      worker_tools="WebSearch,WebFetch"
    fi
  fi

  # QA criteria (JSON array)
  local qa_criteria
  qa_criteria=$(yq -o=json ".tasks[$task_idx].qa.criteria // .tasks[$task_idx].acceptance_criteria // []" "$MANIFEST")

  # Acceptance criteria
  local acceptance_criteria
  acceptance_criteria=$(yq -o=json ".tasks[$task_idx].acceptance_criteria // []" "$MANIFEST")

  log_info "Executing task: $task_id (worker=$worker_name, model=$worker_model)"
  update_progress "▶ $task_id $(yq -r ".tasks[$task_idx].title // \"$task_id\"" "$MANIFEST" 2>/dev/null | head -1 | tr -d '\r') [$worker_name/$worker_model]" 2>/dev/null || true
  log_event "{\"ts\":\"$(now_iso)\",\"event\":\"task_spawn\",\"task_id\":\"$task_id\",\"worker\":\"$worker_name\",\"model\":\"$worker_model\",\"attempt\":1}"
  _log_decision "model_selection" "$task_id" "{\"worker\":\"$worker_name\",\"retries\":$retry_count,\"budget_pct\":$budget_pct}" "$worker_model" "Selected by routing.sh select_model" ""

  # Ralph Loop
  local max_attempts=$MAX_RETRIES
  local attempt=1
  local consecutive_failures_on_model=0
  local current_model="$worker_model"

  while [[ $attempt -le $max_attempts ]]; do
    # Ensure status is "running" at start of each attempt (prevents main loop re-spawn on rework)
    task_set_status "$task_id" "running"
    task_set_field "$task_id" "attempts" "$attempt"

    # Create attempt directory
    local attempt_dir="$ATTEMPTS_DIR/${task_id}-attempt-${attempt}"
    mkdir -p "$attempt_dir"

    # C4: Per-attempt timeout watchdog (v3.7: reset each attempt so retries get full window)
    [[ -n "$_timeout_pid" ]] && kill "$_timeout_pid" 2>/dev/null && wait "$_timeout_pid" 2>/dev/null || true
    ( sleep "${TASK_TIMEOUT:-600}" && log_warn "Task $task_id: TIMEOUT attempt $attempt (${TASK_TIMEOUT}s)" \
      && log_event "{\"ts\":\"$(now_iso)\",\"event\":\"task_timeout\",\"task_id\":\"$task_id\",\"timeout\":${TASK_TIMEOUT:-600},\"attempt\":$attempt}" \
      && kill -TERM "$_self_pid" 2>/dev/null ) &
    _timeout_pid=$!

    # Get feedback from previous attempt
    local last_feedback=""
    if [[ $attempt -gt 1 ]]; then
      last_feedback=$(task_get "$task_id" "last_feedback")
      [[ "$last_feedback" == "null" ]] && last_feedback=""
      # S5: Failed approach memory — force different strategy
      if [[ -n "$last_feedback" ]]; then
        last_feedback="IMPORTANT: Your previous attempt (attempt $((attempt-1))) FAILED. Do NOT repeat the same approach. Try a FUNDAMENTALLY different strategy.\n\n${last_feedback}"
      fi

      # S3: Stagnation detection — identical feedback = stuck
      if [[ $attempt -gt 2 && -n "$last_feedback" ]]; then
        local _s3_prev_fb _s3_curr_hash _s3_prev_hash
        _s3_prev_fb=$(task_get "$task_id" "prev_feedback" 2>/dev/null || echo "")
        _s3_curr_hash=$(echo "$last_feedback" | md5sum | cut -d' ' -f1)
        _s3_prev_hash=$(echo "$_s3_prev_fb" | md5sum | cut -d' ' -f1)
        if [[ "$_s3_curr_hash" == "$_s3_prev_hash" && -n "$_s3_prev_fb" && "$_s3_prev_fb" != "null" ]]; then
          log_warn "[$task_id] Stagnation detected: feedback unchanged across attempts"
          log_event "{\"ts\":\"$(now_iso)\",\"event\":\"stagnation\",\"task_id\":\"$task_id\",\"attempt\":$attempt}"
          # Escalate model on stagnation
          case "$current_model" in
            haiku*)  current_model="sonnet"; log_info "[$task_id] Stagnation → escalating to sonnet" ;;
            sonnet*) current_model="opus"; log_info "[$task_id] Stagnation → escalating to opus" ;;
          esac
          last_feedback="STAGNATION DETECTED: Your last 2 attempts produced identical feedback. You MUST use a completely different approach.\n\n${last_feedback}"
        fi
      fi
      # Save current feedback for next stagnation check
      task_set_field "$task_id" "prev_feedback" "$(echo "$last_feedback" | jq -Rs '.')" 2>/dev/null || true

      # Micro-fix budget reduction: 30% of normal budget for targeted repairs
      local rework_type
      rework_type=$(task_get "$task_id" "rework_type" 2>/dev/null || echo "full")
      [[ "$rework_type" == "null" ]] && rework_type="full"
      if [[ "$rework_type" == "micro_fix" ]]; then
        local _mf_frac=$(config_read "routing.micro_fix_budget_fraction" "0.30")
        safety_budget=$(awk -v b="$safety_budget" -v f="$_mf_frac" 'BEGIN { printf "%.2f", b * f }')
        log_info "[$task_id] Micro-fix: reduced budget to \$${safety_budget}"
      fi
    fi

    # Assemble context pack
    local context_pack="$attempt_dir/context-pack.md"
    assemble_context_pack \
      "$task_id" "$description" "$acceptance_criteria" "$context_files" \
      "$worker_name" "$qa_criteria" "$last_feedback" "$context_pack" \
      "$output_path" "$qa_threshold_task" "$worker_tools"

    # Build worker identity (system prompt)
    local worker_identity=""
    worker_identity="$(cat "$SCRIPT_DIR/workers/_base.md")"$'\n\n'"$(cat "$SCRIPT_DIR/$worker_prompt_path")"

    # Spawn worker
    local response_file="$attempt_dir/worker-response.json"
    local worker_log="$attempt_dir/worker.log"

    # Clear stale output file before each attempt so .result extraction works
    # (prevents innate immune from checking old content on restart/retry)
    if [[ -f "$output_path" ]]; then
      : > "$output_path"
    fi

    log_info "Spawning worker for $task_id (attempt $attempt/$max_attempts, model=$current_model)"

    local add_dir_args=()
    [[ -n "$PROJECT_DIR" ]] && add_dir_args=(--add-dir "$PROJECT_DIR")
    local hook_args=()
    if [[ -n "$HOOK_SETTINGS" ]]; then
      hook_args=(--settings "$HOOK_SETTINGS")
      export FORMICA_TASK_ID="$task_id"
    fi

    cat "$context_pack" | \
      env -u CLAUDECODE claude -p \
        --append-system-prompt "$worker_identity" \
        --model "$current_model" \
        --max-budget-usd "$safety_budget" \
        --tools "$worker_tools" \
        --setting-sources "" \
        "${hook_args[@]}" \
        "${add_dir_args[@]}" \
        --output-format json \
        --no-session-persistence \
        --dangerously-skip-permissions \
        2>"$worker_log" | tr -d '\r' > "$response_file" || true

    # Validate response: non-empty and valid JSON
    if [[ ! -s "$response_file" ]]; then
      log_error "Worker $task_id: claude produced empty response"
      echo '{"result":null,"stop_reason":"error","total_cost_usd":0}' > "$response_file"
    elif ! jq empty "$response_file" 2>/dev/null; then
      log_error "Worker $task_id: invalid JSON response — wrapping raw output"
      local raw
      raw=$(cat "$response_file")
      echo "{\"result\":$(echo "$raw" | jq -Rs '.'),\"stop_reason\":\"error\",\"total_cost_usd\":0}" > "$response_file"
    fi

    log_event "{\"ts\":\"$(now_iso)\",\"event\":\"task_output\",\"task_id\":\"$task_id\",\"attempt\":$attempt}"

    # Extract cost from response
    local cost
    cost=$(extract_cost_from_response "$response_file" "$worker_model")
    local input_t
    input_t=$(jq -r '((.usage.input_tokens // 0) + (.usage.cache_creation_input_tokens // 0) + (.usage.cache_read_input_tokens // 0))' "$response_file" 2>/dev/null || echo "0")
    local output_t
    output_t=$(jq -r '(.usage.output_tokens // 0)' "$response_file" 2>/dev/null || echo "0")
    record_cost "$task_id" "$attempt" "${cost:-0}" "$worker_model" "${input_t:-0}" "${output_t:-0}" "$worker_name"

    # Budget-kill detection: result=null + cost >= budget → worker was terminated
    local result_check
    result_check=$(jq -r '.result // "null"' "$response_file" 2>/dev/null | tr -d '\r')
    local stop_check
    stop_check=$(jq -r '.stop_reason // "null"' "$response_file" 2>/dev/null | tr -d '\r')
    local budget_killed=false
    if [[ "$result_check" == "null" && "$stop_check" == "null" && -n "${cost:-}" ]]; then
      local cost_exceeds
      local _bk_pct=$(config_read "routing.budget_kill_detection_pct" "0.90")
      cost_exceeds=$(awk -v c="${cost:-0}" -v b="$task_budget" -v p="$_bk_pct" 'BEGIN { print (c >= b * p) ? "yes" : "no" }')
      if [[ "$cost_exceeds" == "yes" ]]; then
        budget_killed=true
        log_warn "Task $task_id: BUDGET_EXCEEDED — worker killed at \$${cost} (budget: \$${task_budget})"
        log_event "{\"ts\":\"$(now_iso)\",\"event\":\"budget_exceeded\",\"task_id\":\"$task_id\",\"cost\":${cost},\"budget\":${task_budget},\"attempt\":$attempt}"
        # Adaptive budget scaling: increase 1.5x for next retry
        local _bk_scale=$(config_read "routing.budget_kill_scale_factor" "1.5")
        task_budget=$(awk -v b="$task_budget" -v s="$_bk_scale" 'BEGIN { printf "%.2f", b * s }')
        log_info "Task $task_id: budget scaled to \$${task_budget} for next attempt"
      fi
    fi

    # Verify output exists and is non-empty
    if [[ ! -s "$output_path" ]]; then
      # Worker may have written output via tools (file exists) or returned text in JSON
      local result_text
      result_text=$(jq -r '.result // empty' "$response_file" 2>/dev/null || echo "")
      if [[ -n "$result_text" && "$result_text" != "null" ]]; then
        # Strip preamble only for markdown outputs (preserve YAML/JSON/sh)
        local expected_fmt
        expected_fmt=$(yq -r ".tasks[$task_idx].expected_format // \"\"" "$MANIFEST" 2>/dev/null | tr -d '\r')
        if [[ "$expected_fmt" == "md" || "$expected_fmt" == "markdown" || "$expected_fmt" == "" || "$expected_fmt" == "null" ]]; then
          local stripped
          stripped=$(echo "$result_text" | sed -n '/^#/,$p')
          [[ -n "$stripped" ]] && result_text="$stripped"
        fi
        mkdir -p "$(dirname "$output_path")"
        echo "$result_text" > "$output_path"
        log_debug "Extracted result from JSON response → $output_path"
      fi
    fi

    # Stop gate check
    if [[ ! -s "$output_path" ]]; then
      if $budget_killed; then
        log_error "Task $task_id: no output — budget exceeded (attempt $attempt, next budget: \$${task_budget})"
        task_set_field "$task_id" "last_feedback" "\"BUDGET_EXCEEDED: Your previous attempt used \$${cost} and was killed. You have \$${task_budget} this time. Be more focused: read fewer files, produce output early, do not explore exhaustively.\""
      else
        log_error "Task $task_id: no output produced (attempt $attempt)"
      fi
      if [[ $attempt -ge $max_attempts ]]; then
        task_set_status "$task_id" "rejected"
        local reject_reason="NO_OUTPUT"
        $budget_killed && reject_reason="BUDGET_EXCEEDED"
        if $budget_killed; then
          task_set_field "$task_id" "rejection_reason" '"BUDGET_EXCEEDED"'
        else
          task_set_field "$task_id" "rejection_reason" '"NO_OUTPUT"'
        fi
        log_event "{\"ts\":\"$(now_iso)\",\"event\":\"qa_verdict\",\"task_id\":\"$task_id\",\"score\":0,\"verdict\":\"REJECT\",\"reason\":\"$reject_reason\"}"
        cascade_failure "$task_id"
        return 1
      fi
      ((attempt++)) || true
      continue
    fi

    # Copy output for audit trail (pre-strip version)
    cp "$output_path" "$attempt_dir/" 2>/dev/null || true

    # Strip preamble from output if detected (safety net before immune check)
    if [[ -s "$output_path" ]]; then
      local first_line_check
      first_line_check=$(head -1 "$output_path" 2>/dev/null)
      if echo "$first_line_check" | grep -qEi '(let me|i will|i have|i need|writing.*to|the path|the file|here is|sure|okay|certainly)'; then
        local stripped_output
        stripped_output=$(sed -n '/^#/,$p' "$output_path")
        if [[ -n "$stripped_output" ]]; then
          echo "$stripped_output" > "$output_path"
          log_debug "Stripped preamble from $output_path (first line was: ${first_line_check:0:60})"
        fi
      fi
    fi

    # Immune Layer 2: Innate immune check (pre-QA format validation)
    local expected_format
    expected_format=$(yq -r ".tasks[$task_idx].expected_format // \"\"" "$MANIFEST" 2>/dev/null | tr -d '\r')
    local expected_lines
    expected_lines=$(yq -r ".tasks[$task_idx].expected_lines // 0" "$MANIFEST" 2>/dev/null | tr -d '\r')

    # S2.6: Mandatory innate checks — infer format/lines if not specified
    if [[ -z "$expected_format" && -n "$output_path" ]]; then
      case "${output_path##*.}" in
        md)   expected_format="md" ;;
        json) expected_format="json" ;;
        yaml|yml) expected_format="yaml" ;;
        sh)   expected_format="sh" ;;
        *)    log_debug "Innate: unknown extension for $output_path, skipping format inference" ;;
      esac
    fi
    if [[ "$expected_lines" -eq 0 || -z "$expected_lines" ]]; then
      local desc_len=${#description}
      if [[ $desc_len -gt 0 ]]; then
        if [[ $desc_len -lt 100 ]]; then
          expected_lines=50
        else
          expected_lines=200
        fi
      else
        log_debug "Innate: no description for $task_id, skipping lines inference"
        expected_lines=0
      fi
    fi

    CURRENT_WORKER_TYPE="$worker_name"
    if ! innate_immune_check "$task_id" "$output_path" "$expected_format" "$expected_lines"; then
      log_warn "Task $task_id failed innate immune check — skipping QA (attempt $attempt)"
      # Extract specific violations from the immune event just logged
      local violations_str
      violations_str=$(tail -1 "$RUNTIME_DIR/immune_events.jsonl" 2>/dev/null | jq -r '.violations // "unknown"' 2>/dev/null | tr -d '\r')
      task_set_field "$task_id" "last_feedback" "\"Innate immune REJECTED: ${violations_str}. If PREAMBLE: your output must start with content (e.g., # Title), not process commentary. If LINE_COUNT: stay within ±30% of expected.\""
      if [[ $attempt -ge $max_attempts ]]; then
        task_set_status "$task_id" "rejected"
        task_set_field "$task_id" "rejection_reason" '"INNATE_IMMUNE"'
        log_event "{\"ts\":\"$(now_iso)\",\"event\":\"qa_verdict\",\"task_id\":\"$task_id\",\"score\":0,\"verdict\":\"REJECT\",\"reason\":\"innate_immune\"}"
        cascade_failure "$task_id"
        return 1
      fi
      ((attempt++)) || true
      continue
    fi

    # Negative pheromone: check output against hard blacklist
    # v3.7: Skip for analysts — they report/quote patterns, not produce them
    if [[ "$worker_name" != "analyst" ]] && ! check_blacklist_violations "$output_path" "$RUNTIME_DIR"; then
      log_warn "Task $task_id blacklist violation — auto-rejecting (attempt $attempt)"
      task_set_field "$task_id" "last_feedback" "\"Output matched blacklist pattern. Review and avoid blacklisted patterns.\""
      if [[ $attempt -ge $max_attempts ]]; then
        task_set_status "$task_id" "rejected"
        task_set_field "$task_id" "rejection_reason" '"BLACKLIST"'
        log_event "{\"ts\":\"$(now_iso)\",\"event\":\"qa_verdict\",\"task_id\":\"$task_id\",\"score\":0,\"verdict\":\"REJECT\",\"reason\":\"blacklist_violation\"}"
        cascade_failure "$task_id"
        return 1
      fi
      ((attempt++)) || true
      continue
    fi

    # Deterministic syntax validation before QA (saves $0.02/check for obvious errors)
    if [[ "$worker_name" == "implementer" && "$output_path" == *.sh ]]; then
      local syntax_err_file="/tmp/syntax-err-${BASHPID:-$$}-${RANDOM}"
      if ! bash -n "$output_path" 2>"$syntax_err_file"; then
        local syntax_err
        syntax_err=$(cat "$syntax_err_file" 2>/dev/null || echo "unknown syntax error")
        rm -f "$syntax_err_file"
        log_warn "[$task_id] Syntax error detected (pre-QA): $syntax_err"
        task_set_field "$task_id" "last_feedback" "$(echo "SYNTAX ERROR (deterministic check — no QA needed): $syntax_err" | jq -Rs '.')"
        if [[ $attempt -ge $max_attempts ]]; then
          task_set_status "$task_id" "rejected"
          task_set_field "$task_id" "rejection_reason" '"SYNTAX_ERROR"'
          cascade_failure "$task_id"
          return 1
        fi
        ((attempt++)) || true
        continue
      fi
      rm -f "$syntax_err_file"
    fi

    # QA scoring
    log_event "{\"ts\":\"$(now_iso)\",\"event\":\"qa_start\",\"task_id\":\"$task_id\",\"qa_model\":\"$qa_model_task\",\"attempt\":$attempt}"

    # QA budget: use task budget / 2 (QA should cost less than the work itself)
    local qa_budget
    local _qa_frac=$(config_read "qa.budget_fraction" "0.50")
    local _qa_min=$(config_read "qa.min_budget_usd" "0.15")
    qa_budget=$(awk -v tb="$task_budget" -v f="$_qa_frac" -v mn="$_qa_min" 'BEGIN { b = tb * f; if (b < mn) b = mn; printf "%.2f", b }')

    local qa_exit=0
    run_qa "$task_id" "$output_path" "$qa_criteria" "$qa_threshold_task" "$qa_model_task" \
      "${PROJECT_DIR:-$SCRIPT_DIR}" "$attempt" "$qa_budget" || qa_exit=$?

    if [[ $qa_exit -ne 0 ]]; then
      # S1.4: QA crash recovery — fallback to innate immune
      if [[ $qa_exit -eq 2 ]]; then
        log_warn "QA CRASHED for $task_id. Falling back to innate immune check."
        if innate_immune_check "$task_id" "$output_path" "$expected_format" "$expected_lines" 2>/dev/null; then
          local _qa_fallback=$(config_read "immune.qa_crash_fallback_score" "70")
          log_info "Innate immune PASSED for $task_id (QA fallback) — score=$_qa_fallback, PASS_INNATE"
          task_set_field "$task_id" "score" "$_qa_fallback"
          task_set_field "$task_id" "qa_skipped" "true"
          task_set_status "$task_id" "completed"
          task_set_field "$task_id" "completed_at" "\"$(now_iso)\""
          log_event "{\"ts\":\"$(now_iso)\",\"event\":\"qa_fallback\",\"task_id\":\"$task_id\",\"reason\":\"qa_crash\",\"innate_result\":\"PASS\"}"
          return 0
        else
          log_warn "Innate immune also FAILED for $task_id after QA crash"
          log_event "{\"ts\":\"$(now_iso)\",\"event\":\"qa_fallback\",\"task_id\":\"$task_id\",\"reason\":\"qa_crash\",\"innate_result\":\"FAIL\"}"
        fi
      fi

      log_error "QA execution failed for $task_id (attempt $attempt)"
      if [[ $attempt -ge $max_attempts ]]; then
        task_set_status "$task_id" "exhausted"
        task_set_field "$task_id" "rejection_reason" '"QA_EXHAUSTED"'
        cascade_failure "$task_id"
        return 1
      fi
      ((attempt++)) || true
      continue
    fi

    # Parse QA verdict
    local qa_response="$attempt_dir/qa-response.json"

    # Colony signal extraction (trophallaxis)
    if [[ -f "$qa_response" ]]; then
      extract_colony_signal "$qa_response" "$task_id" "${wave_num:-0}" 2>/dev/null || true
    fi

    # Worker signal extraction: capture <!-- SIGNAL: type | message | intensity --> from output
    if [[ -f "$output_path" ]]; then
      grep -o '<!-- SIGNAL: [^-]*' "$output_path" 2>/dev/null | sed 's/<!-- SIGNAL: //' | sed 's/ *$//' | while IFS='|' read -r sig_type sig_msg sig_intensity; do
        sig_type=$(echo "$sig_type" | xargs)
        sig_msg=$(echo "$sig_msg" | xargs | tr '"' "'")
        sig_intensity=$(echo "${sig_intensity:-0.5}" | xargs)
        [[ -z "$sig_type" ]] && continue
        local signal_json="{\"ts\":\"$(now_iso)\",\"task_id\":\"$task_id\",\"wave\":${wave_num:-0},\"type\":\"$sig_type\",\"signal\":\"$sig_msg\",\"intensity\":${sig_intensity:-0.5},\"source\":\"worker\"}"
        # Validate JSON before appending (prevents downstream jq -s poisoning)
        if echo "$signal_json" | jq . >/dev/null 2>&1; then
          append_jsonl "$RUNTIME_DIR/colony_signals.jsonl" "$signal_json" 2>/dev/null || true
        else
          log_warn "Malformed signal JSON, skipping: $signal_json"
        fi
      done || true  # grep returns 1 when no matches — don't propagate with pipefail

      # Log signal count for observability
      local signal_count
      signal_count=$(wc -l < "$RUNTIME_DIR/colony_signals.jsonl" 2>/dev/null || echo 0)
      log_debug "[$task_id] Colony signals total: $signal_count"
    fi

    local verdict_line
    verdict_line=$(parse_verdict "$qa_response" 2>/dev/null || echo "0|REJECT|QA parse failure")
    local score verdict feedback
    IFS='|' read -r score verdict feedback <<< "$verdict_line"

    # Coherence validation: detect score/text contradictions (S1.3)
    local coherence
    coherence=$(validate_qa_coherence "$score" "$feedback" "$verdict" 2>/dev/null || echo "COHERENT")
    if [[ "$coherence" == "INCOHERENT" ]]; then
      log_warn "QA INCOHERENT for $task_id (score=$score, verdict=$verdict) — forcing REWORK"
      verdict="REWORK"
      feedback="INCOHERENT QA: score/text mismatch detected. Original: $feedback"
    fi

    # Save verdict
    echo "{\"score\":$score,\"verdict\":\"$verdict\",\"feedback\":\"$(echo "$feedback" | sed 's/"/\\"/g')\"}" > "$attempt_dir/qa-verdict.json"

    # Record pheromone (QA score for worker_type + model)
    record_pheromone "$worker_name" "$current_model" "$score" 2>/dev/null || true

    # Route verdict (route_verdict logs qa_verdict event with full context)
    # Capture exit code without triggering set -e (route_verdict returns 1=REWORK, 2=REJECT)
    local route_result=0
    route_verdict "$task_id" "$score" "$verdict" "$feedback" "$max_attempts" "$qa_threshold_task" || route_result=$?

    # v4.2: Structured decision log (FORMICA SAPIENS)
    local _routing_reason
    _routing_reason=$(task_get "$task_id" "routing_reason" 2>/dev/null || echo "default")
    local _insight=""
    [[ $route_result -eq 0 ]] && _insight="PASS score=$score"
    [[ $route_result -eq 1 ]] && _insight="REWORK needed, attempt $attempt"
    [[ $route_result -eq 2 ]] && _insight="REJECTED/EXHAUSTED"
    if type log_decision &>/dev/null; then
      log_decision "$task_id" "${wave_num:-0}" "$attempt" "$current_model" \
        "$_routing_reason" "${input_t:-0}" "${output_t:-0}" "${cost:-0}" \
        "0" "$verdict" "$score" "" "$_insight" 2>/dev/null || true
    fi

    # Extract friction event on non-PASS verdicts (FORMICA v2.0)
    if [[ $route_result -ne 0 ]]; then
      extract_friction_event "$task_id" "$worker_name" "$verdict" "$score" "$feedback" "$attempt"
    fi

    case $route_result in
      0) # PASS
        log_info "Task $task_id PASSED (score: $score)"
        local task_cost_total
        task_cost_total=$(state_read ".budget.used_usd" 2>/dev/null || echo "0")
        update_progress "✓ $task_id score=$score cost=\$${task_cost_total} (attempt $attempt)" 2>/dev/null || true
        meta_supervisor_check "$task_id" 2>/dev/null || true
        # v4.2: Evaluate layer — strategic enrichment for gateway tasks
        if should_evaluate "$task_id" "$score" 2>/dev/null; then
          run_evaluate "$task_id" "$output_path" "$RUNTIME_DIR" 2>/dev/null || true
        fi
        consecutive_failures_on_model=0
        return 0
        ;;
      1) # REWORK
        log_info "Task $task_id needs REWORK (score: $score, attempt $attempt/$max_attempts)"
        ((consecutive_failures_on_model++)) || true

        # Model escalation (FORMICA v2.0): after 2 failures on same model, escalate
        if [[ $consecutive_failures_on_model -ge 2 ]]; then
          local prev_model="$current_model"
          case "$current_model" in
            haiku*)  current_model="sonnet" ;;
            sonnet*) current_model="opus" ;;
            opus*)   ;; # Already at max, keep trying
          esac
          if [[ "$current_model" != "$prev_model" ]]; then
            consecutive_failures_on_model=0
            log_warn "Model escalation: $prev_model → $current_model for $task_id (after 2 consecutive failures)"
            log_event "{\"ts\":\"$(now_iso)\",\"event\":\"model_escalation\",\"task_id\":\"$task_id\",\"from\":\"$prev_model\",\"to\":\"$current_model\",\"attempt\":$attempt}"
            _log_decision "escalation" "$task_id" "{\"failures\":2,\"prev_model\":\"$prev_model\"}" "$current_model" "2 consecutive QA failures on $prev_model" "$prev_model"
          fi
        fi

        # S4: Backoff between retry attempts
        sleep $((attempt * $(config_read "orchestration.retry_backoff_multiplier_s" "3")))
        ((attempt++)) || true
        ;;
      2) # REJECT/EXHAUSTED
        local final_status
        final_status=$(task_get "$task_id" "status" 2>/dev/null) || final_status="rejected"
        if [[ "$final_status" == "exhausted" ]]; then
          task_set_field "$task_id" "rejection_reason" '"QA_EXHAUSTED"'
        else
          task_set_field "$task_id" "rejection_reason" '"QA_REJECT"'
        fi
        log_error "Task $task_id FAILED (score: $score)"
        update_progress "✗ $task_id score=$score verdict=$verdict" 2>/dev/null || true
        # Move rejected output to attempt dir (clean project directory)
        if [[ -f "$output_path" ]]; then
          mv "$output_path" "$attempt_dir/rejected-$(basename "$output_path")" 2>/dev/null || true
          log_info "Moved rejected output to attempt dir"
        fi
        meta_supervisor_check "$task_id" 2>/dev/null || true
        return 1
        ;;
    esac
  done

  return 1
}

# ============================================================================
# DECISION LOGGING (FORMICA v2.0)
# ============================================================================

_log_decision() {
  local decision_type="$1"
  local task_id="$2"
  local inputs="$3"       # JSON string
  local choice="$4"
  local rationale="$5"
  local alternatives="${6:-}"

  local decisions_file="$TELEMETRY_DIR/decisions.jsonl"
  append_jsonl "$decisions_file" "{\"ts\":\"$(now_iso)\",\"decision\":\"$decision_type\",\"task_id\":\"$task_id\",\"inputs\":$inputs,\"choice\":\"$choice\",\"rationale\":\"$rationale\",\"alternatives\":\"$alternatives\"}" 2>/dev/null || true
}

# ============================================================================
# EVALUATE LAYER (FORMICA v4.2 — SAPIENS)
# Strategic quality enrichment for gateway tasks. NOT QA. Does not block.
# ============================================================================

should_evaluate() {
  local task_id="$1"
  local score="$2"

  # Check if evaluate is enabled
  local eval_enabled
  eval_enabled=$(config_read "evaluate.enabled" "false")
  [[ "$eval_enabled" != "true" ]] && return 1

  # Check trigger: "gateway" means task blocks 2+ downstream tasks
  local trigger
  trigger=$(config_read "evaluate.trigger" "gateway")
  if [[ "$trigger" == "gateway" ]]; then
    local bf
    bf=$(calc_blocking_factor "$task_id" 2>/dev/null || echo 0)
    [[ "$bf" -lt 2 ]] && return 1
  fi

  # Check minimum score
  local min_score
  min_score=$(config_read "evaluate.min_score" "85")
  [[ "$score" -lt "$min_score" ]] && return 1

  # Check budget remaining percentage
  local min_budget_pct
  min_budget_pct=$(config_read "evaluate.min_budget_remaining_pct" "40")
  local budget_total budget_used budget_pct_remaining
  budget_total=$(state_read '.budget.total_usd // .budget.limit_usd // 0' 2>/dev/null || echo 0)
  budget_used=$(state_read '.budget.used_usd // 0' 2>/dev/null || echo 0)
  budget_pct_remaining=$(awk -v t="$budget_total" -v u="$budget_used" 'BEGIN { if (t > 0) printf "%d", ((t - u) / t) * 100; else print 0 }')
  [[ "$budget_pct_remaining" -lt "$min_budget_pct" ]] && return 1

  return 0
}

run_evaluate() {
  local task_id="$1"
  local output_file="$2"
  local runtime_dir="$3"

  log_info "[$task_id] Evaluate layer triggered — strategic enrichment"
  log_event "{\"ts\":\"$(now_iso)\",\"event\":\"evaluate_start\",\"task_id\":\"$task_id\"}"

  # Prepare evaluations directory
  local eval_dir="$runtime_dir/evaluations"
  mkdir -p "$eval_dir"

  # Build minimal context for evaluator
  local eval_context="$eval_dir/${task_id}-context.md"
  {
    echo "# EVALUATE CONTEXT"
    echo ""
    echo "## Task Output"
    echo ""
    if [[ -f "$output_file" ]]; then
      head -200 "$output_file" 2>/dev/null || true
    else
      echo "(output file not found)"
    fi
    echo ""

    # Consciousness map
    if [[ -f "$runtime_dir/consciousness-map.md" ]]; then
      echo ""
      cat "$runtime_dir/consciousness-map.md" 2>/dev/null || true
      echo ""
    fi

    # Downstream tasks that depend on this task
    echo "## Downstream Tasks"
    echo ""
    local downstream
    downstream=$(jq -r "[.tasks | to_entries[] | select(.value.depends_on[]? == \"$task_id\") | .key] | .[]" "$STATE_FILE" 2>/dev/null || echo "")
    if [[ -n "$downstream" ]]; then
      while IFS= read -r ds_tid; do
        [[ -z "$ds_tid" ]] && continue
        local ds_desc
        ds_desc=$(jq -r ".tasks[\"$ds_tid\"].description // \"no description\"" "$STATE_FILE" 2>/dev/null | head -2 | tr -d '\r')
        echo "- **$ds_tid**: $ds_desc"
      done <<< "$downstream"
    else
      echo "(no downstream tasks)"
    fi
  } > "$eval_context"

  # Get evaluator worker prompt
  local evaluator_prompt="$SCRIPT_DIR/workers/evaluator.md"
  if [[ ! -f "$evaluator_prompt" ]]; then
    log_warn "[$task_id] Evaluator worker prompt not found — skipping evaluate"
    return 0
  fi
  local worker_identity
  worker_identity=$(cat "$evaluator_prompt" 2>/dev/null)

  # Spawn evaluator
  local eval_model
  eval_model=$(config_read "evaluate.model" "opus")
  local eval_budget
  eval_budget=$(config_read "evaluate.budget_usd" "0.30")
  local eval_response="$eval_dir/${task_id}-response.json"

  local eval_exit=0
  cat "$eval_context" | \
    env -u CLAUDECODE claude -p \
      --append-system-prompt "$worker_identity" \
      --model "$eval_model" \
      --max-budget-usd "$eval_budget" \
      --tools "Read" \
      --setting-sources "" \
      --output-format json \
      --no-session-persistence \
      --dangerously-skip-permissions \
      2>/dev/null | tr -d '\r' > "$eval_response" || eval_exit=$?

  if [[ $eval_exit -ne 0 || ! -s "$eval_response" ]]; then
    log_warn "[$task_id] Evaluate worker failed (exit=$eval_exit) — skipping"
    return 0
  fi

  # Extract and save evaluation result
  local eval_result
  eval_result=$(jq -r '.result // ""' "$eval_response" 2>/dev/null | tr -d '\r')
  if [[ -n "$eval_result" && "$eval_result" != "null" ]]; then
    echo "$eval_result" > "$eval_dir/${task_id}.json"
    log_info "[$task_id] Evaluate complete — saved to evaluations/${task_id}.json"
  else
    # Try .structured_output
    eval_result=$(jq -r '.structured_output // ""' "$eval_response" 2>/dev/null | tr -d '\r')
    if [[ -n "$eval_result" && "$eval_result" != "null" ]]; then
      echo "$eval_result" > "$eval_dir/${task_id}.json"
      log_info "[$task_id] Evaluate complete — saved to evaluations/${task_id}.json"
    else
      log_warn "[$task_id] Evaluate produced no usable result"
    fi
  fi

  # Record evaluate cost
  local eval_cost
  eval_cost=$(jq -r '.total_cost_usd // 0' "$eval_response" 2>/dev/null || echo "0")
  if [[ "$eval_cost" != "0" && "$eval_cost" != "null" ]]; then
    record_cost "$task_id" "evaluate" "${eval_cost:-0}" "$eval_model" "0" "0" "evaluator" 2>/dev/null || true
  fi

  log_event "{\"ts\":\"$(now_iso)\",\"event\":\"evaluate_complete\",\"task_id\":\"$task_id\",\"cost\":${eval_cost:-0}}"
  return 0
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

get_task_index() {
  local task_id="$1"
  local count
  count=$(yq -r '.tasks | length' "$MANIFEST")
  for i in $(seq 0 $((count - 1))); do
    local tid
    tid=$(yq -r ".tasks[$i].id" "$MANIFEST")
    if [[ "$tid" == "$task_id" ]]; then
      echo "$i"
      return 0
    fi
  done
  die "Task not found in manifest: $task_id"
}

get_task_field_from_manifest() {
  local task_id="$1"
  local field="$2"
  local default="$3"
  local idx
  idx=$(get_task_index "$task_id")
  local val
  val=$(yq -r ".tasks[$idx].$field // \"$default\"" "$MANIFEST")
  echo "$val"
}

process_worker_exit() {
  local task_id="$1"
  local exit_code="$2"

  local status
  status=$(task_get "$task_id" "status") || status="unknown"
  # Guard: if task already handled (by execute_task internally), skip
  if [[ "$status" == "rejected" || "$status" == "completed" || "$status" == "dep-failed" || "$status" == "exhausted" || "$status" == "aborted" ]]; then
    return 0
  fi

  if [[ $exit_code -ne 0 ]]; then
    log_error "Worker $task_id crashed (exit $exit_code) — marking rejected"
    task_set_status "$task_id" "rejected"
    task_set_field "$task_id" "rejection_reason" '"WORKER_CRASH"'
    DEFERRED_CASCADES+=("$task_id")
  fi
}

abort_remaining() {
  log_warn "Aborting remaining tasks due to budget exhaustion"
  local pending_tasks
  pending_tasks=$(state_read '[.tasks | to_entries[] | select(.value.status == "pending") | .key] | .[]' 2>/dev/null || echo "")
  for tid in $pending_tasks; do
    task_set_status "$tid" "aborted"
  done
  kill_all
}

print_progress() {
  local completed failed total running
  completed=$(state_read '.counters.completed')
  failed=$(state_read '.counters.failed')
  total=$(state_read '.counters.total')
  running=${#PIDS[@]}
  local used_usd
  used_usd=$(state_read '.budget.used_usd')

  # Write progress.txt
  {
    echo "=== Blueprint: $BLUEPRINT_ID ==="
    echo "Status: $(state_read '.status')"
    echo "Progress: $completed/$total completed, $failed failed, $running running"
    echo "Budget: \$${used_usd} used"
    echo ""
    echo "Tasks:"
    state_read '.tasks | to_entries[] | "\(.key): \(.value.status) (score: \(.value.score // "n/a"), attempts: \(.value.attempts))"'
  } > "$RUNTIME_DIR/progress.txt"

  # Also print to stderr
  printf "\r${GREEN}[%d/%d]${RESET} completed | ${RED}%d${RESET} failed | ${BLUE}%d${RESET} running | \$%.2f spent" \
    "$completed" "$total" "$failed" "$running" "$used_usd" >&2
}

# ============================================================================
# STATUS COMMAND
# ============================================================================

show_status() {
  BLUEPRINT_ID=$(yq -r '.blueprint.id' "$MANIFEST")
  RUNTIME_DIR="$(normalize_path "$(pwd)/runtime/$BLUEPRINT_ID")"
  STATE_FILE="$RUNTIME_DIR/state.json"

  [[ ! -f "$STATE_FILE" ]] && die "No state file found. Blueprint may not have been started."

  echo ""
  echo "=== Blueprint Status: $BLUEPRINT_ID ==="
  echo "Status: $(state_read '.status')"
  echo "Started: $(state_read '.started_at')"
  echo "Updated: $(state_read '.updated_at')"
  echo ""

  local total completed failed
  total=$(state_read '.counters.total')
  completed=$(state_read '.counters.completed')
  failed=$(state_read '.counters.failed')
  echo "Progress: $completed/$total completed, $failed failed"
  echo "Budget: \$$(state_read '.budget.used_usd') / \$$(state_read '.budget.limit_usd')"
  echo ""

  echo "Tasks:"
  echo "  $(printf '%-25s %-12s %-8s %-8s %s\n' 'ID' 'STATUS' 'SCORE' 'TRIES' 'WORKER')"
  echo "  $(printf '%-25s %-12s %-8s %-8s %s\n' '---' '---' '---' '---' '---')"

  state_read '.tasks | to_entries | sort_by(.key) | .[] | "\(.key)|\(.value.status)|\(.value.score // "-")|\(.value.attempts)|\(.value.worker)"' | \
    while IFS='|' read -r id status score attempts worker; do
      local color=""
      case "$status" in
        completed) color="$GREEN" ;;
        running)   color="$BLUE" ;;
        rejected|exhausted|dep-failed) color="$RED" ;;
        rework)    color="$YELLOW" ;;
      esac
      printf "  %-25s ${color}%-12s${RESET} %-8s %-8s %s\n" "$id" "$status" "$score" "$attempts" "$worker"
    done

  echo ""
}

# ============================================================================
# REPORT GENERATION (FORMICA v2.0 — delegates to lib/report.sh)
# ============================================================================

# generate_report and generate_execution_report are now provided by lib/report.sh
# generate_execution_report() produces both .md (beautiful) and .yaml (legacy)
generate_report() {
  generate_execution_report
}

# ============================================================================
# CLEANUP
# ============================================================================

cleanup() {
  log_warn "Received interrupt signal — cleaning up"
  kill_all

  # Release all locks
  if [[ -d "${LOCKS_DIR:-}" ]]; then
    rm -rf "$LOCKS_DIR"/*.lock 2>/dev/null || true
  fi

  # Save state
  if [[ -f "${STATE_FILE:-}" ]]; then
    set_blueprint_status "paused"
    log_event "{\"ts\":\"$(now_iso)\",\"event\":\"blueprint_interrupt\",\"blueprint_id\":\"$BLUEPRINT_ID\"}"
  fi

  log_info "Cleanup complete. Resume with: orchestrate.sh $MANIFEST --resume"
  exit 130
}

# ============================================================================
# META-SUPERVISOR OODA LOOP (FORMICA v3.0)
# ============================================================================

# Meta-supervisor consciousness loop — runs after each task completion
# OODA: Observe telemetry → Orient (indicators) → Decide (heuristics) → Act
# Only logs decisions when action is taken (NORMAL = silent)
meta_supervisor_check() {
  local task_id="${1:-}"

  # ─── OBSERVE ───
  local completed failed total pending used_usd limit_usd
  completed=$(state_read '.counters.completed' 2>/dev/null || echo "0")
  failed=$(state_read '.counters.failed' 2>/dev/null || echo "0")
  total=$(state_read '.counters.total' 2>/dev/null || echo "0")
  pending=$((total - completed - failed))
  used_usd=$(state_read '.budget.used_usd' 2>/dev/null || echo "0")
  limit_usd=$(state_read '.budget.limit_usd' 2>/dev/null || echo "50")

  local total_attempts
  total_attempts=$((completed + failed))
  [[ "$total_attempts" -eq 0 ]] && return 0  # Nothing to analyze yet

  # ─── ORIENT ───
  local pass_rate cost_velocity fric_trend budget_remaining_pct
  pass_rate=$(awk -v c="$completed" -v t="$total_attempts" 'BEGIN { printf "%.0f", (c/t)*100 }')
  cost_velocity=$(awk -v u="$used_usd" -v l="$limit_usd" 'BEGIN { if (l>0) printf "%.2f", u/l; else print 0 }')
  fric_trend=$(friction_trend 2>/dev/null || echo "stable")
  budget_remaining_pct=$(awk -v u="$used_usd" -v l="$limit_usd" 'BEGIN { if (l>0) printf "%.0f", (1-u/l)*100; else print 100 }')

  # ─── DECIDE + ACT ───
  local action_taken=false

  # CRITICAL: Pass rate dangerously low with enough data
  local _ms_pass=$(config_read "meta_supervisor.critical_pass_rate_pct" "30")
  local _ms_min=$(config_read "meta_supervisor.critical_min_samples" "6")
  if [[ "$pass_rate" -lt "$_ms_pass" && "$total_attempts" -gt "$_ms_min" ]]; then
    ADVISORY_ENABLED=true
    log_warn "META-SUPERVISOR: CRITICAL — pass_rate=$pass_rate% (n=$total_attempts). Forcing advisory."
    log_event "{\"ts\":\"$(now_iso)\",\"event\":\"meta_alert\",\"type\":\"low_pass_rate\",\"pass_rate\":$pass_rate,\"total_attempts\":$total_attempts}"
    _log_decision "meta_supervisor" "$task_id" "{\"pass_rate\":$pass_rate,\"total_attempts\":$total_attempts}" "FORCE_ADVISORY" "Pass rate critically low" ""
    action_taken=true
  fi

  # CRITICAL: Cost velocity exceeding budget
  local _ms_cv=$(config_read "meta_supervisor.critical_cost_velocity" "1.5")
  if awk -v cv="$cost_velocity" -v th="$_ms_cv" 'BEGIN { exit !(cv > th) }' 2>/dev/null; then
    DEFAULT_MODEL="haiku"
    QA_MODEL="haiku"
    MAX_RETRIES=1
    log_warn "META-SUPERVISOR: CRITICAL — cost_velocity=$cost_velocity. Switching to economic mode."
    log_event "{\"ts\":\"$(now_iso)\",\"event\":\"meta_alert\",\"type\":\"cost_overrun\",\"cost_velocity\":$cost_velocity,\"used\":$used_usd,\"limit\":$limit_usd}"
    _log_decision "meta_supervisor" "$task_id" "{\"cost_velocity\":$cost_velocity}" "SWITCH_ECONOMIC" "Cost velocity exceeds 1.5x budget" ""
    action_taken=true
  fi

  # CRITICAL: Same friction cause appearing 3+ times consecutively
  local recent_cause
  recent_cause=$(tail -1 "${TELEMETRY_DIR:-$RUNTIME_DIR}/friction.jsonl" 2>/dev/null | jq -r '.cause // empty' 2>/dev/null | tr -d '\r' || echo "")
  local _ms_fric=$(config_read "meta_supervisor.repeated_friction_threshold" "3")
  if [[ -n "$recent_cause" ]] && same_cause_consecutive "$recent_cause" "$_ms_fric" 2>/dev/null; then
    log_warn "META-SUPERVISOR: CRITICAL — cause '$recent_cause' repeated ${_ms_fric}+ times. Injecting warning."
    log_event "{\"ts\":\"$(now_iso)\",\"event\":\"meta_alert\",\"type\":\"repeated_friction\",\"cause\":\"$recent_cause\"}"
    _log_decision "meta_supervisor" "$task_id" "{\"cause\":\"$recent_cause\"}" "INJECT_WARNING" "Same friction cause 3+ consecutive times" ""
    action_taken=true
  fi

  # ADAPT: Budget running low
  local _ms_bcons=$(config_read "meta_supervisor.budget_conserve_pct" "20")
  if [[ "$budget_remaining_pct" -lt "$_ms_bcons" && "$pending" -gt 0 ]]; then
    DEFAULT_MODEL="haiku"
    MAX_RETRIES=1
    log_info "META-SUPERVISOR: ADAPT — budget=$budget_remaining_pct% remaining. Forcing haiku + 1 retry."
    _log_decision "meta_supervisor" "$task_id" "{\"budget_remaining_pct\":$budget_remaining_pct,\"pending\":$pending}" "BUDGET_CONSERVE" "Low budget, tasks remaining" ""
    action_taken=true
  fi

  # ADAPT: Friction increasing over recent tasks
  if [[ "$fric_trend" == "increasing" && "$total_attempts" -gt 3 ]]; then
    ADVISORY_ENABLED=true
    log_info "META-SUPERVISOR: ADAPT — friction trend increasing. Forcing advisory."
    _log_decision "meta_supervisor" "$task_id" "{\"friction_trend\":\"$fric_trend\"}" "FORCE_ADVISORY" "Friction trend increasing" ""
    action_taken=true
  fi

  # NORMAL: no action → no logging (prevent noise)
  $action_taken || return 0
}

# ============================================================================
# F0-F3 LIFECYCLE (FORMICA v3.0)
# ============================================================================

# F0: INGEST — Validate blueprint package, generate compat manifest
# Sets MANIFEST to the generated compat manifest path
f0_ingest() {
  local bp_id
  bp_id=$(yq -r '.id // .blueprint_id // ""' "$BLUEPRINT_PATH/_metadata.yaml" 2>/dev/null | tr -d '\r')
  [[ -z "$bp_id" ]] && die "Blueprint ID not found in $BLUEPRINT_PATH/_metadata.yaml"

  local runtime_base="$SCRIPT_DIR/runtime/$bp_id"

  # Handle --abandon
  if $ABANDON; then
    if [[ -d "$runtime_base" ]]; then
      rm -rf "$runtime_base"
      log_info "Abandoned blueprint $bp_id — runtime cleaned"
    else
      log_info "No runtime to abandon for $bp_id"
    fi
    exit 0
  fi

  # Handle --resume (compat manifest must already exist)
  if $RESUME; then
    local compat="$runtime_base/manifest.yaml"
    [[ ! -f "$compat" ]] && die "No manifest found for resume: $compat (run without --resume first)"
    MANIFEST="$compat"
    log_info "F0: Resuming blueprint $bp_id from existing manifest"
    return 0
  fi

  # Boot detection (only on fresh starts, not --restart)
  if ! $RESTART; then
    if detect_interrupted 2>/dev/null; then
      die "Interrupted blueprint detected. Use --resume to continue, --restart for clean start, or --abandon to remove"
    fi
  fi

  # Clean start or --restart
  if $RESTART && [[ -d "$runtime_base" ]]; then
    log_warn "Restarting: cleaning runtime for $bp_id"
    rm -rf "$runtime_base"
  fi

  log_info "═══ F0: INGEST ═══"
  mkdir -p "$runtime_base"
  generate_compat_manifest "$BLUEPRINT_PATH" "$runtime_base/manifest.yaml"
  MANIFEST="$runtime_base/manifest.yaml"
  log_info "F0: INGEST COMPLETE — Manifest ready"
}

# Detect interrupted blueprints in runtime/
# Returns 0 if interrupted blueprint found, 1 if none
detect_interrupted() {
  local runtime_base="$SCRIPT_DIR/runtime"
  [[ ! -d "$runtime_base" ]] && return 1

  local found=false
  for state_file in "$runtime_base"/*/state.json; do
    [[ ! -f "$state_file" ]] && continue
    local status bp_id completed total
    status=$(jq -r '.status // "unknown"' "$state_file" 2>/dev/null | tr -d '\r')
    if [[ "$status" == "running" || "$status" == "paused" ]]; then
      bp_id=$(jq -r '.blueprint_id // "unknown"' "$state_file" 2>/dev/null | tr -d '\r')
      completed=$(jq -r '.counters.completed // 0' "$state_file" 2>/dev/null | tr -d '\r')
      total=$(jq -r '.counters.total // 0' "$state_file" 2>/dev/null | tr -d '\r')
      log_warn "Interrupted: $bp_id ($completed/$total tasks complete, status=$status)"
      found=true
    fi
  done

  $found && return 0
  return 1
}

# F3: SYNTHESIZE — Generate all reports, update memory
f3_synthesize() {
  local blueprint_path="${1:-}"

  log_info "═══ F3: SYNTHESIZE ═══"

  # Human-facing reports
  generate_execution_report || log_warn "F3: execution report generation had errors"
  generate_file_manifest || log_warn "F3: file manifest generation had errors"

  # AI-facing diagnostic + handoff
  generate_diagnostic_json || log_warn "F3: diagnostic.json generation had errors"
  generate_handoff_yaml || log_warn "F3: handoff.yaml generation had errors"

  # Epigenetic markers update
  update_markers || log_warn "F3: epigenetics update had errors"

  # L1: Persist pheromone evidence to epigenetic markers
  save_pheromone_to_markers || log_warn "F3: pheromone persistence had errors"

  # Immune pattern promotion (conservative — creates "flag" entries)
  promote_immune_patterns 2>/dev/null || true

  # Pattern candidate staging (for P6 to promote)
  stage_pattern_candidates 2>/dev/null || true

  # Copy execution report to blueprint package
  if [[ -n "$blueprint_path" && -d "$blueprint_path" ]]; then
    local report_src="$REPORTS_DIR/execution-report.md"
    if [[ -f "$report_src" ]]; then
      cp "$report_src" "$blueprint_path/EXECUTION-REPORT.md" 2>/dev/null || true
      log_info "F3: Report copied to blueprint package"
    fi
  fi

  log_info "F3: SYNTHESIZE COMPLETE"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
  parse_args "$@"

  # Determine lifecycle mode
  local lifecycle_mode="legacy"
  [[ -n "$BLUEPRINT_PATH" ]] && lifecycle_mode="f0f3"

  # Status command
  if $STATUS_ONLY; then
    if [[ "$lifecycle_mode" == "f0f3" ]]; then
      local bp_id
      bp_id=$(yq -r '.id // .blueprint_id // ""' "$BLUEPRINT_PATH/_metadata.yaml" 2>/dev/null | tr -d '\r')
      MANIFEST="$SCRIPT_DIR/runtime/$bp_id/manifest.yaml"
      [[ ! -f "$MANIFEST" ]] && die "No manifest found. Blueprint may not have been started."
    fi
    show_status
    exit 0
  fi

  # ═══ F0: INGEST (blueprint directory only) ═══
  if [[ "$lifecycle_mode" == "f0f3" ]]; then
    f0_ingest
  fi

  # ═══ F1: PREPARE (validate + wizard + confirm) ═══
  [[ "$lifecycle_mode" == "f0f3" ]] && log_info "═══ F1: PREPARE ═══"

  validate_config
  validate_manifest
  run_wizard "$MANIFEST" "$INTERACTIVE"
  $DRY_RUN && exit 0

  [[ "$lifecycle_mode" == "f0f3" ]] && log_info "F1: PREPARE COMPLETE"

  # ═══ F2: EXECUTE ═══
  [[ "$lifecycle_mode" == "f0f3" ]] && log_info "═══ F2: EXECUTE ═══"

  trap cleanup INT TERM

  if $RESUME; then
    resume_blueprint
  else
    init_blueprint
  fi

  # Load hook settings for cross-file coherence (v4.1)
  _load_hook_settings

  # Run blueprint (with meta-loop if configured)
  local meta_loop_enabled
  meta_loop_enabled=$(yq -r '.config.meta_loop.enabled // false' "$MANIFEST" 2>/dev/null | tr -d '\r')
  local meta_loop_max
  meta_loop_max=$(yq -r '.config.meta_loop.max_cycles // 2' "$MANIFEST" 2>/dev/null | tr -d '\r')

  if [[ "$meta_loop_enabled" == "true" ]]; then
    log_info "Meta-loop enabled (max_cycles=$meta_loop_max)"
    run_meta_loop "$meta_loop_max"
  else
    run_blueprint
  fi

  [[ "$lifecycle_mode" == "f0f3" ]] && log_info "F2: EXECUTE COMPLETE"

  # ═══ F3: SYNTHESIZE ═══
  if [[ "$lifecycle_mode" == "f0f3" ]]; then
    f3_synthesize "$BLUEPRINT_PATH"
  else
    # Legacy synthesis
    generate_report
    generate_meta_report
    update_markers
  fi

  # P6 Learn: Pattern lifecycle (ATHENA-native layer, if available)
  if type decay_patterns &>/dev/null; then
    log_info "P6 Learn: Running pattern lifecycle..."
    decay_patterns
    prune_patterns "$(state_read '.counters.total' 2>/dev/null || echo 0)"
    promote_immune_responses "$RUNTIME_DIR"
    promote_to_blacklist
    resolve_contradictions

    # AURUM feedback (if cognitive-refinery exists)
    local aurum_inbox="D:/cognitive-refinery/00-inbox/feedback/athena"
    if [[ -d "$aurum_inbox" ]]; then
      local feedback_file="$aurum_inbox/feedback-${BLUEPRINT_ID}-$(date -u +%Y%m%d).yaml"
      cat > "$feedback_file" <<AURUM_EOF
type: feedback
source_system: "FORMICA"
blueprint_id: "$BLUEPRINT_ID"
nature_code: "$(yq -r '.blueprint.nature_code // ""' "$MANIFEST" 2>/dev/null | tr -d '\r')"
metrics:
  tasks_completed: $(state_read '.counters.completed' 2>/dev/null || echo 0)
  tasks_total: $(state_read '.counters.total' 2>/dev/null || echo 0)
  avg_qa_score: $(state_read '[.tasks | to_entries[] | select(.value.score != null) | .value.score] | if length > 0 then (add / length | round) else 0 end' 2>/dev/null || echo 0)
timestamp: "$(now_iso)"
AURUM_EOF
      log_info "AURUM feedback sent: $feedback_file"
    fi
  fi

  # Completion banner
  update_progress "=== COMPLETE ===" 2>/dev/null || true
  echo ""
  log_info "Blueprint $BLUEPRINT_ID complete."
  log_info "  Report:     $REPORTS_DIR/execution-report.md"
  log_info "  Manifest:   $REPORTS_DIR/file-manifest.md"
  log_info "  Diagnostic: $REPORTS_DIR/diagnostic.json"
  log_info "  Handoff:    $REPORTS_DIR/handoff.yaml"
  log_info "  Progress:   $RUNTIME_DIR/progress.txt"
}

main "$@"
