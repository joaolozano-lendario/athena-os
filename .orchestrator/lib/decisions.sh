#!/usr/bin/env bash
# decisions.sh — Structured decision logging for FORMICA
# Part of FORMICA SAPIENS v4.2
# Provides: log_decision, get_recent_decisions, detect_instability

[[ -n "${_DECISIONS_SH_LOADED:-}" ]] && return 0
_DECISIONS_SH_LOADED=1

# ============================================================================
# log_decision(task_id, wave, attempt, model, routing_reason,
#              tokens_in, tokens_out, cost_usd, duration_s,
#              verdict, score, colony_signal, insight)
# Appends structured JSONL entry to decision log.
# ============================================================================
log_decision() {
  local task_id="$1"
  local wave="${2:-0}"
  local attempt="${3:-1}"
  local model="${4:-sonnet}"
  local routing_reason="${5:-default}"
  local tokens_in="${6:-0}"
  local tokens_out="${7:-0}"
  local cost_usd="${8:-0}"
  local duration_s="${9:-0}"
  local verdict="${10:-UNKNOWN}"
  local score="${11:-0}"
  local colony_signal="${12:-}"
  local insight="${13:-}"

  local log_file="${RUNTIME_DIR:-}/decision-log.jsonl"
  [[ -z "${RUNTIME_DIR:-}" ]] && return 0

  # Sanitize strings for JSON
  colony_signal=$(echo "$colony_signal" | tr '"' "'" | tr '\n' ' ' | head -c 200)
  insight=$(echo "$insight" | tr '"' "'" | tr '\n' ' ' | head -c 200)

  local entry="{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")\",\"task_id\":\"$task_id\",\"wave\":$wave,\"attempt\":$attempt,\"model\":\"$model\",\"routing_reason\":\"$routing_reason\",\"tokens_in\":$tokens_in,\"tokens_out\":$tokens_out,\"cost_usd\":$cost_usd,\"duration_s\":$duration_s,\"verdict\":\"$verdict\",\"score\":$score,\"colony_signal\":\"$colony_signal\",\"insight\":\"$insight\"}"

  # Validate JSON before appending
  if echo "$entry" | jq . >/dev/null 2>&1; then
    if type append_jsonl &>/dev/null; then
      append_jsonl "$log_file" "$entry" 2>/dev/null || true
    else
      echo "$entry" >> "$log_file"
    fi
  else
    echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)\",\"task_id\":\"$task_id\",\"wave\":$wave,\"verdict\":\"$verdict\",\"score\":$score,\"error\":\"json_sanitize_failed\"}" >> "$log_file"
  fi
}

# ============================================================================
# get_recent_decisions(n)
# Returns last N entries formatted for consciousness map injection.
# ============================================================================
get_recent_decisions() {
  local n="${1:-3}"
  local log_file="${RUNTIME_DIR:-}/decision-log.jsonl"

  [[ ! -f "$log_file" || ! -s "$log_file" ]] && return 0

  tail -"$n" "$log_file" 2>/dev/null | while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local tid model verdict score insight
    tid=$(echo "$line" | jq -r '.task_id // "?"' 2>/dev/null | tr -d '\r')
    model=$(echo "$line" | jq -r '.model // "?"' 2>/dev/null | tr -d '\r')
    verdict=$(echo "$line" | jq -r '.verdict // "?"' 2>/dev/null | tr -d '\r')
    score=$(echo "$line" | jq -r '.score // 0' 2>/dev/null | tr -d '\r')
    insight=$(echo "$line" | jq -r '.insight // ""' 2>/dev/null | tr -d '\r' | head -c 60)
    if [[ -n "$insight" ]]; then
      echo "- $tid: $model → $verdict ($score) — \"$insight\""
    else
      echo "- $tid: $model → $verdict ($score)"
    fi
  done
}

# ============================================================================
# detect_instability(window_size)
# Calculates σ of QA scores over last window_size tasks.
# Returns: STABLE (σ<=0.3), WARNING (σ>0.3), CRITICAL (σ>0.5)
# ============================================================================
detect_instability() {
  local window="${1:-5}"
  local log_file="${RUNTIME_DIR:-}/decision-log.jsonl"

  [[ ! -f "$log_file" || ! -s "$log_file" ]] && { echo "STABLE"; return 0; }

  local scores
  scores=$(tail -"$window" "$log_file" 2>/dev/null | jq -r '.score // 0' 2>/dev/null | tr -d '\r')
  [[ -z "$scores" ]] && { echo "STABLE"; return 0; }

  local count
  count=$(echo "$scores" | wc -l)
  [[ "$count" -lt 2 ]] && { echo "STABLE"; return 0; }

  # Calculate normalized σ (divide scores by 100 first so σ is on 0-1 scale)
  local result
  result=$(echo "$scores" | awk '
    { vals[NR] = $1 / 100; sum += $1 / 100; n++ }
    END {
      if (n < 2) { print "STABLE"; exit }
      mean = sum / n
      for (i = 1; i <= n; i++) {
        diff = vals[i] - mean
        sumsq += diff * diff
      }
      sigma = sqrt(sumsq / (n - 1))
      if (sigma > 0.5) print "CRITICAL"
      else if (sigma > 0.3) print "WARNING"
      else print "STABLE"
    }
  ')

  echo "${result:-STABLE}"
}
