# FORMICA v4.2.0 — FORMICA SAPIENS (Intelligence Upgrade)

**Date:** 2026-02-20
**Tag:** `v4.2.0`
**Branch:** `private`
**Blueprint:** BP-2026-02-20-004
**Pattern:** PAT-024 Three-Sprint Stabilization (Fix → Consciousness → Evaluate)

---

## Summary

FORMICA SAPIENS upgrades the orchestrator from reactive execution to situational awareness. Workers now know where they are in the DAG, what happened before them, who depends on them, and how much budget remains. Gateway tasks receive strategic quality enrichment via an optional Evaluate layer. Token estimation migrates from word-based to char-based with tool-use amplification multipliers, and 4 known bugs are fixed.

---

## Changelog (v4.1.0 → v4.2.0)

### E1: Fix & Calibrate (6 tasks)

| Change | File | Detail |
|--------|------|--------|
| Char-based token estimation | `budget.sh` | `_estimate_chars_per_token()` by file extension (code=2, prose=5, config=3) + `_get_tool_use_multiplier()` per worker type |
| Tool-use multipliers config | `formiga.config.yaml` | `budget.tool_use_multipliers` (7 entries: analyst=2.5, implementer=3.0, etc.) |
| Context double-load prevention | `context.sh` | Skip files > 500 lines in context_files when worker has Read tools |
| Budget awareness injection | `context.sh` | L0.3: token budget + cost remaining injected in every context pack |
| Budget guard threshold | `formiga.config.yaml` | `budget_guard_pct`: 30 → 15 |
| Poll interval | `formiga.config.yaml` | `poll_interval_s`: 2 → 0.5 |
| BUG-1: Float arithmetic | `context.sh` | `$(())` → `awk` for division with decimal ratios (lines 517, 542) |
| BUG-2: QA false positives | `qa.sh` | Scores >= 85 exempt from rejection keyword check |
| BUG-3: Wave numbering | — | Investigated, found correct — no change needed |
| BUG-4: File registry path | `report.sh` | `TELEMETRY_DIR` → `RUNTIME_DIR` (5 occurrences) |

### E2: Consciousness (7 tasks)

| Change | File | Detail |
|--------|------|--------|
| Decision log | `lib/decisions.sh` (NEW) | `log_decision()` JSONL, `get_recent_decisions(n)`, `detect_instability(window)` with σ-based STABLE/WARNING/CRITICAL |
| Integrate decision log | `orchestrate.sh` | `log_decision` after `route_verdict` with 13 fields |
| Consciousness map | `lib/consciousness.sh` (NEW) | DAG position, budget, colony intel, decision log, stability — 225-word hard cap |
| Consciousness as L0.5 | `context.sh` | `_layer_consciousness()` between L0 and L1, priority 0 (never truncated) |
| Map update post-task | `orchestrate.sh` | `update_consciousness_map` after `process_worker_exit` |
| Colony signal credibility | `context.sh` | ★ (>85), ● (70-85), ○ (<70) reliability indicators from decision-log.jsonl |

### E3: Evaluate Layer (5 tasks)

| Change | File | Detail |
|--------|------|--------|
| Evaluator worker prompt | `workers/evaluator.md` (NEW) | Strategic quality evaluator — NOT QA, focuses on downstream guidance |
| Evaluate config | `formiga.config.yaml` | `evaluate:` section (enabled, trigger=gateway, min_score=85, min_budget=40%, model=opus, budget=$0.30) |
| Evaluate integration | `orchestrate.sh` | `should_evaluate()` + `run_evaluate()` — triggers on PASS for gateway tasks |
| Evaluate downstream injection | `context.sh` | `_layer_evaluate_feedback()` as L4.5 — injects strategic guidance for downstream tasks |

---

## New Files (3 files)

```
.orchestrator/lib/decisions.sh       (107 lines) — Structured decision logging
.orchestrator/lib/consciousness.sh   (131 lines) — Situational awareness map generator
.orchestrator/workers/evaluator.md   (37 lines)  — Strategic quality evaluator prompt
```

## Modified Files

| File | Lines Changed | Summary |
|------|---------------|---------|
| `orchestrate.sh` | +~150 | Decision log, consciousness map, evaluate layer |
| `lib/context.sh` | +~80 | L0.3 budget, L0.5 consciousness, L4.5 evaluate, colony credibility |
| `lib/budget.sh` | +~50 | Char-based estimation, tool-use multipliers |
| `lib/qa.sh` | +~5 | High-confidence coherence exemption |
| `lib/report.sh` | ~5 | File registry path fix |
| `formiga.config.yaml` | +~20 | 3 new sections, 2 value changes |
| `tests/sprint-gate-v38.sh` | ~4 | Adjusted thresholds for new behavior |
| `tests/test-adversarial-suite.sh` | ~4 | Updated expectations for QA coherence |

---

## Config Changes

### New Sections
```yaml
budget:
  tool_use_multipliers:
    analyst: 2.5, writer: 1.1, qa: 1.5
    implementer: 3.0, architect: 2.0, advisor: 1.2, default: 1.5

evaluate:
  enabled: true, trigger: "gateway", min_score: 85
  min_budget_remaining_pct: 40, model: "opus", budget_usd: 0.30

context:
  double_load_prevention:
    enabled: true, line_threshold: 500, inject_read_instruction: true
```

### Value Changes
- `routing.budget_guard_pct`: 30 → 15
- `orchestration.poll_interval_s`: 2 → 0.5

---

## Test Results

| Test Suite | Assertions | Result |
|------------|-----------|--------|
| Sprint Gate v3.8 | 20 | PASS |
| Config Backward Compat | 142 | PASS |
| Adversarial Suite | 28 | PASS |
| Hook Unit Tests | 21 | PASS |
| **Total** | **211** | **ALL PASS** |

### Evaluate Logic Validation (5 cases)
- Gateway + score=90 + budget=70% → triggers
- Non-gateway → skipped
- Score=75 < min_score=85 → skipped
- Budget=20% < min=40% → skipped
- enabled=false → skipped

---

## Context Pack Layer Order (v4.2)

```
L0:   Project conventions (priority 0 — never truncated)
L0.3: Budget awareness (priority 0)
L0.5: Consciousness map (priority 0)
L1:   Task spec + acceptance criteria (priority 0)
L2:   Constraints / negative pheromone (priority 2)
L3:   Domain knowledge / AURUM (priority 5)
L4:   Reference material / context files (priority 3)
L4.5: Evaluate feedback (priority 5)
L5:   Colony signals (priority 6)
L6:   QA rubric (priority 1)
L6.5: Historical friction (priority 4)
L7:   Retry feedback (priority 0 — never truncated)
```

---

## Breaking Changes

None. All new features are backward compatible:
- Consciousness map: generated only if `consciousness.sh` available
- Decision log: guarded by `type log_decision` check
- Evaluate layer: disabled by default config fallback (`false`)
- Double-load prevention: requires `worker_tools` parameter (defaults to empty)
- Tool-use multipliers: default=1.0 if config missing

---

## Migration Guide

No migration required. Removing new config sections falls back to v4.1.0 behavior.

---

## Metrics

- **3 new files** (275 lines of intelligence infrastructure)
- **~300 lines modified** across 8 existing files
- **211 test assertions** ALL PASS across 4 suites
- **3 checkpoints** PASSED (CP-1, CP-2, CP-3)
- **4 epics**, 19 tasks executed
- **32 blueprints** tracked in epigenetic markers

---

*FORMICA v4.2.0 — FORMICA SAPIENS*
*"Workers that know where they are, what happened, and what matters."*
