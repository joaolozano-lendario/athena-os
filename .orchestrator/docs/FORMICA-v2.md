# FORMICA v2.0 — Documentation

**Version:** 2.0
**Status:** Implemented
**Predecessor:** FORMIGA v1.0 (7,051 lines, 8 blueprints, 9 bugs fixed)

---

## 1. Overview

FORMICA v2.0 evolves the tested orchestration engine into a self-improving autonomous execution system. Key additions:

- Intelligent model selection with escalation (haiku → sonnet → opus)
- QA criteria auto-generation from worker type rubrics (zero API cost)
- Friction tracking with cause classification
- Pre-execution wizard with cost estimates
- Beautiful markdown blueprint reports (9 sections)
- Meta-reports for system evolution (3-layer diagnostic)
- Epigenetic markers for cross-blueprint learning
- Orchestrator decision logging

## 2. Model Strategy

| Tier | Model | Use Case | Cost/task |
|------|-------|----------|-----------|
| STRATEGY | opus | advisory, meta-loop, blueprint→blueprint | ~$0.15 |
| LABOR | haiku | all workers (default), QA, meta-report L3 | ~$0.012 |
| CRAFT | sonnet | escalation target after 2 haiku failures | ~$0.04 |

Haiku default saves ~43% vs sonnet. Opus advisory adds ~$0.30/blueprint.

## 3. Orchestration Modes

Set via `config.mode` in blueprint YAML (default: "quality").

| Parameter | economic | quality | speed | guided |
|-----------|----------|---------|-------|--------|
| max_parallel | 1 | 2 | 4 | 2 |
| default_model | haiku | haiku | haiku | haiku |
| qa_threshold | 70 | 85 | 75 | 80 |
| max_retries | 1 | 3 | 2 | 3 |
| advisory | off | on | off | on |
| budget_factor | 0.7x | 1.5x | 1.0x | 1.2x |
| human_pause | — | — | — | every_wave |

Individual YAML overrides (e.g., `config.max_parallel: 3`) always win over mode defaults.

**File:** `lib/modes.sh`

## 4. QA Auto-Generation

Static rubrics per worker type eliminate the need for manual QA criteria in blueprint YAML.

**Worker rubrics (5 criteria each):**
- **analyst:** source citation, quantitative data, obs vs interp, structured output, no speculation
- **architect:** implementable designs, rationale+alternatives, trade-offs, cross-refs, conventions
- **implementer:** valid syntax, naming conventions, all files created, no TODOs, verified
- **writer:** clear language, heading hierarchy, evidence-backed, audience-matched, actionable

**Criteria merge:** explicit YAML criteria (weight 2x) + base rubric (weight 1x).

**Retry refinement:** Low-scoring criteria (< 75) get `[PRIORITY]` annotation on rework.

**Cost:** Zero API calls — all rubrics are hardcoded bash/jq.

**File:** `lib/qa.sh` (additions)

## 5. Friction Tracking

Every non-PASS QA verdict generates a friction event with classified cause.

**Cause categories (keyword-based):**
1. `budget_exhaustion` — budget/exceeded/killed/truncated
2. `format_violation` — format/structure/syntax/schema
3. `incomplete_output` — missing/incomplete/lacking
4. `missing_quantitative_data` — quantitative/number/count
5. `missing_citations` — source/cite/reference
6. `quality_below_threshold` — default fallback

**Output:** `$RUNTIME_DIR/friction_events.jsonl`

**Usage:** Reports, meta-reports, context Layer 7 (friction warnings for workers).

**File:** `lib/friction.sh`

## 6. Pre-Execution Wizard

Single-screen plan display shown before blueprint execution.

**Sections:**
- Banner (FORMICA version, blueprint, project, mode)
- Validation (task count, DAG, workers)
- Worker distribution (tasks per worker type)
- Wave map (execution waves with task IDs)
- Cost estimate (best/expected/worst)
- Warnings (missing QA criteria, budget risks)
- Mode description

**Flags:** `--dry-run` shows plan and exits. `--interactive` waits for confirmation.

**File:** `lib/wizard.sh`

## 7. Beautiful Reports

9-section markdown blueprint report (replaces YAML-only report).

**Sections:**
1. Title + metadata
2. Executive summary (pass rate, cost, first-pass rate)
3. Metrics dashboard (table format)
4. Budget breakdown (workers vs QA, ASCII bar)
5. Cost per task (table with status icons)
6. Task dependency graph (ASCII with scores)
7. Colony intelligence (signals table)
8. Friction analysis (causes + affected tasks)
9. Appendix (collapsible raw events, advisory, immune)

Legacy YAML report is also generated for backward compatibility.

**File:** `lib/report.sh`

## 8. Meta-Report

3-layer diagnostic generated after every blueprint.

**Layer 1 (deterministic):** Score distribution, cost by model, timing — from state.json/events.jsonl.

**Layer 2 (deterministic):** Friction causes ranked by frequency, worker type analysis, budget incidents.

**Layer 3 (haiku ~$0.02):** System evolution assessment — trend, systemic issues, pattern updates, recommendations, health score. Uses `schemas/meta-report.json` for structured output.

Graceful degradation: if Layer 3 haiku call fails, Layers 1+2 still provide diagnostics.

**Files:** `lib/meta_report.sh`, `schemas/meta-report.json`

## 9. Epigenetic Markers

Cross-blueprint learning that persists between blueprints.

**Marker types:**
- `budget_adjustments` — per-worker-type budget multipliers
- `qa_overrides` — extra QA criteria for problem worker types
- `model_hints` — recommended model for task patterns
- `blueprint_history` — list of blueprints that contributed evidence

**Rule:** Markers require evidence from 2+ blueprints (prevents overfitting).

**File:** `lib/epigenetics.sh` → `epigenetic_markers.yaml`

## 10. Model Escalation

Automatic model upgrade after consecutive QA failures.

**Path:** haiku → sonnet → opus

**Trigger:** 2 consecutive QA failures on the same model.

**Behavior:** Attempt counter resets on escalation. Escalation logged to events.jsonl and decisions.jsonl.

## 11. Decision Logging

Key orchestrator decisions logged to `$RUNTIME_DIR/decisions.jsonl`.

**Decision types:** model_selection, escalation, budget_allocation, wave_transition.

**Format:** `{ts, decision, task_id, inputs, choice, rationale, alternatives}`

## 12. Migration from v1

**Backward compatibility:** All existing blueprint YAMLs work unchanged.

**New optional fields:**
- `config.mode` — orchestration mode (default: "quality")
- Tasks without explicit `qa.criteria` get auto-generated rubrics

**No breaking changes.** All v1 features preserved:
- Allometry, immune system, negative pheromone, trophallaxis
- Advisory reviews, meta-loop, file conflict detection
- Budget controls, adaptive scaling, pattern library

---

*FORMICA v2.0 — Autonomous Orchestration Evolution*
