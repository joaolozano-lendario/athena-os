#!/usr/bin/env bash
# ingest.sh — F0: INGEST — Blueprint compatibility manifest generation
# Part of FORMICA v3.0 execution engine

[[ -n "${_INGEST_SH_LOADED:-}" ]] && return 0
_INGEST_SH_LOADED=1

# Valid model names for F0 validation
declare -A VALID_MODELS=(
  [haiku]=1
  [sonnet]=1
  [opus]=1
  [claude-haiku-4-5]=1
  [claude-sonnet-4-5]=1
  [claude-opus-4-6]=1
)

# ============================================================================
# COMPATIBILITY MANIFEST GENERATION
# ============================================================================

# Generate legacy-format manifest from blueprint package
# This bridges checkpoint-map.yaml (nested epics→tasks) to the flat MANIFEST
# format that validate_manifest/init_blueprint/execute_task expect.
#
# Args: blueprint_path output_file
generate_compat_manifest() {
  local blueprint_path="$1"
  local output_file="$2"

  local metadata_file="$blueprint_path/_metadata.yaml"
  local checkpoint_map="$blueprint_path/checkpoint-map.yaml"

  [[ ! -f "$metadata_file" ]] && die "Missing _metadata.yaml in $blueprint_path"
  [[ ! -f "$checkpoint_map" ]] && die "Missing checkpoint-map.yaml in $blueprint_path"

  # Read metadata
  local bp_id bp_name
  bp_id=$(yq -r '.id // .blueprint_id // ""' "$metadata_file" 2>/dev/null | tr -d '\r')
  bp_name=$(yq -r '.name // .title // .slug // ""' "$metadata_file" 2>/dev/null | tr -d '\r')

  [[ -z "$bp_id" || "$bp_id" == "null" ]] && die "Blueprint ID missing from _metadata.yaml"

  # Read global config from checkpoint-map
  local target_project max_budget default_model max_retries qa_threshold max_parallel
  target_project=$(yq -r '.target_project // ""' "$checkpoint_map" 2>/dev/null | tr -d '\r')
  max_budget=$(yq -r '.max_budget_usd // 50' "$checkpoint_map" 2>/dev/null | tr -d '\r')
  default_model=$(yq -r '.default_model // "haiku"' "$checkpoint_map" 2>/dev/null | tr -d '\r')
  max_retries=$(yq -r '.max_retries // 2' "$checkpoint_map" 2>/dev/null | tr -d '\r')
  qa_threshold=$(yq -r '.qa_threshold // 80' "$checkpoint_map" 2>/dev/null | tr -d '\r')
  max_parallel=$(yq -r '.max_parallel // 3' "$checkpoint_map" 2>/dev/null | tr -d '\r')

  # Read optional exec-arch config
  local exec_arch="$blueprint_path/exec-arch.yaml"
  local mode="quality"
  if [[ -f "$exec_arch" ]]; then
    local ea_mode
    ea_mode=$(yq -r '.execution.mode // ""' "$exec_arch" 2>/dev/null | tr -d '\r')
    [[ -n "$ea_mode" && "$ea_mode" != "null" ]] && mode="$ea_mode"
  fi

  # Extract flat task list from checkpoint-map (with full descriptions)
  # yq v4 doesn't support jq-style object creation, so: yq→JSON→jq reshape
  local tasks_json
  tasks_json=$(yq -o json '.epics[].tasks[]' "$checkpoint_map" 2>/dev/null | \
    jq -s '[.[] | {
      id, title: (.title // ""), worker, model, description,
      output, context_files: (.context_files // []),
      acceptance_criteria: (.acceptance_criteria // []),
      depends_on: (.depends_on // []),
      expected_format: (.expected_format // "markdown"),
      expected_lines: (.expected_lines // 100)
    }]')

  if [[ -z "$tasks_json" || "$tasks_json" == "null" || "$tasks_json" == "[]" ]]; then
    die "No tasks extracted from checkpoint-map.yaml"
  fi

  local task_count
  task_count=$(echo "$tasks_json" | jq 'length')
  log_info "F0: Extracted $task_count tasks from checkpoint-map"

  # F0 validations (acceptance criteria count, model validity)
  local validation_warnings=0
  for ((i=0; i<task_count; i++)); do
    local tid criteria_count model
    tid=$(echo "$tasks_json" | jq -r ".[$i].id")
    criteria_count=$(echo "$tasks_json" | jq ".[$i].acceptance_criteria | length")
    model=$(echo "$tasks_json" | jq -r ".[$i].model // \"haiku\"")

    if [[ "$criteria_count" -lt 2 ]]; then
      log_warn "F0: Task $tid has only $criteria_count acceptance criteria (min 2)"
      ((validation_warnings++)) || true
    fi

    if [[ -z "${VALID_MODELS[$model]:-}" ]]; then
      die "F0: Task $tid has invalid model: $model"
    fi
  done

  [[ $validation_warnings -gt 0 ]] && log_warn "F0: $validation_warnings validation warnings"

  # Build workers section from unique worker types in tasks
  local workers_json
  workers_json=$(echo "$tasks_json" | jq '
    [.[].worker] | unique | map({
      (.): {
        prompt: ("workers/" + . + ".md"),
        tools: (
          if . == "analyst" then "Read,Grep,Glob,WebSearch,WebFetch"
          elif . == "architect" then "Read,Write,Grep,Glob"
          elif . == "implementer" then "Read,Write,Edit,Bash,Grep,Glob"
          elif . == "writer" then "Read,Write,Edit,Grep,Glob"
          elif . == "forger" then "Read,Write,Edit,Bash,Grep,Glob"
          else "Read,Write,Grep,Glob"
          end
        )
      }
    }) | add
  ')

  # Read coherence section (v4.1 hooks system)
  local coherence_json
  coherence_json=$(yq -o json '.coherence // {}' "$checkpoint_map" 2>/dev/null | tr -d '\r')
  [[ -z "$coherence_json" || "$coherence_json" == "null" ]] && coherence_json='{}'

  # Build compat manifest (JSON — yq reads JSON transparently)
  mkdir -p "$(dirname "$output_file")"

  local _task_budget
  _task_budget=$(config_read "orchestration.default_task_budget_usd" "0.50")

  jq -n \
    --arg bp_id "$bp_id" \
    --arg bp_name "${bp_name:-$bp_id}" \
    --arg project_dir "$target_project" \
    --argjson max_parallel "${max_parallel:-3}" \
    --argjson max_retries "${max_retries:-2}" \
    --argjson qa_threshold "${qa_threshold:-80}" \
    --arg default_model "${default_model:-haiku}" \
    --arg qa_model "haiku" \
    --argjson max_budget "${max_budget:-50}" \
    --arg mode "$mode" \
    --argjson task_budget "$_task_budget" \
    --argjson workers "$workers_json" \
    --argjson tasks "$tasks_json" \
    --argjson coherence "$coherence_json" \
    '{
      coherence: $coherence,
      blueprint: {
        id: $bp_id,
        name: $bp_name,
        project_dir: $project_dir
      },
      config: {
        max_parallel: $max_parallel,
        max_retries: $max_retries,
        qa_threshold: $qa_threshold,
        default_model: $default_model,
        qa_model: $qa_model,
        task_budget_usd: $task_budget,
        max_budget_usd: $max_budget,
        mode: $mode
      },
      workers: $workers,
      tasks: [
        $tasks[] | {
          id: .id,
          worker: .worker,
          model: .model,
          description: .description,
          output: .output,
          budget_usd: $task_budget,
          context_files: .context_files,
          acceptance_criteria: .acceptance_criteria,
          depends_on: .depends_on,
          expected_format: .expected_format,
          expected_lines: .expected_lines,
          qa: {
            threshold: $qa_threshold,
            model: $qa_model,
            criteria: .acceptance_criteria
          }
        }
      ]
    }' > "$output_file"

  log_info "F0: Compat manifest generated: $output_file ($task_count tasks)"
}
