# FORMICA v4.0.0 — Ship-Ready Release

**Date:** 2026-02-19
**Tag:** `v4.0.0-stable`
**Branch:** `private`

---

## Summary

FORMICA v4.0.0 is the ship-ready release of the biomimetic orchestrator. Three stability sprints (E1→E2→E3) transformed v3.7 into a production-grade system with 15 stories, 20 commits, and comprehensive adversarial testing.

---

## Changelog (v3.7 → v4.0)

### E1: Critical Fixes → v3.8.0 (6 stories)

| Commit | Change |
|--------|--------|
| `8a145f1` | Atomic state writes with CAS version counter |
| `78a0a6e` | Atomic budget reserve/reconcile + orphan cleanup |
| `4b5d1b5` | QA score/verdict coherence validation |
| `5256897` | QA crash recovery with innate immune fallback |
| `e4fd30a` | File registry: persist conflict deps + cycle detection |
| `eaeed26` | Budget guard before per-task model override |
| `641d7d9` | CAS sleep portability + budget_reserve idempotency |

### E2: Structural Evolution → v3.9.0 (6 stories)

| Commit | Change |
|--------|--------|
| `d4ef8e6` | Immune memory promotion per wave + dedup |
| `4e6040c` | Mandatory innate checks — infer format/lines |
| `52b2f7a` | Advisory hard veto cancel + config thresholds |
| `8bfb531` | Pheromone mkdir-based lock + jq failure protection |
| `2de5770` | Meta-loop wall-clock timeout with partial report |
| `c1f21b1` | Type-aware token estimation + truncation order |
| `8f38688` | Cancel/pause status preserve + signal evap jq guard |

### E3: Config & Adversarial → v4.0.0 (3 stories)

| Commit | Change |
|--------|--------|
| `ec9845f` | Centralize 150 hardcoded values into formiga.config.yaml |
| `1ab1ac0` | 6 adversarial campaigns (28 assertions, all PASS) |
| *this* | VERSION 4.0.0 + release notes + git tag |

---

## Breaking Changes

### API Changes

1. **`apply_advisory()`** — Returns 2 for cancel (was only 0 or 1). Callers must handle exit code 2.

2. **`resume_blueprint()`** — Rejects resume after `cancel` status. Previously would resume cancelled blueprints.

3. **`estimate_tokens(filepath, bytes)`** — New fast mode with type-aware ratio. First task uses `wc -w * 7.9`, subsequent tasks use `* 0.8` (cache factor).

4. **Advisory thresholds externalized** — `coherence_pause`, `coherence_cancel`, `min_wave`, `pass_rate_floor` now read from config with 3-layer chain: `formiga.config.yaml` → manifest → hardcoded default.

### New Functions

- `config_read(key, default)` — Read from `formiga.config.yaml` with yq, fallback to default
- `validate_config()` — Startup validation (warns on out-of-range, never crashes)
- `promote_immune_memory()` — Per-wave immune memory promotion
- `innate_immune_check()` — Mandatory format/size/line-count validation

### New Files

- `.orchestrator/formiga.config.yaml` — Centralized configuration (180 lines, 15 sections)
- `.orchestrator/lib/config.sh` — Config reader + validator
- `.orchestrator/tests/test-config-defaults.sh` — Backward compatibility (142 assertions)
- `.orchestrator/tests/test-adversarial-suite.sh` — Adversarial suite (28 assertions)

---

## Migration Guide

### From v3.7 to v4.0

1. **No action required for basic usage.** All defaults match v3.9 behavior. Removing `formiga.config.yaml` produces identical results.

2. **If you call `apply_advisory()` directly**, update callers to handle exit code 2 (cancel).

3. **If you use `--resume`**, note that cancelled blueprints can no longer be resumed. Use `--restart` instead.

4. **To customize thresholds**, edit `formiga.config.yaml` instead of modifying lib/*.sh source. See `formiga.config.yaml` for all 150+ configurable values.

### Config Customization Examples

```yaml
# Reduce QA threshold for speed
qa:
  pass_threshold_default: 70

# Increase budget for architect workers
orchestration:
  default_task_budget_usd: 0.75

# Switch to economic mode defaults
modes:
  quality:
    max_retries: 1
    budget_factor: 0.80
```

---

## Test Results

| Test Suite | Assertions | Result |
|------------|-----------|--------|
| Sprint Gate v3.8 (CAS, budget, QA, routing) | 20 | PASS |
| Config Backward Compat | 142 | PASS |
| Adversarial Suite (6 campaigns) | 28 | PASS |
| **Total** | **190** | **ALL PASS** |

---

## Known Limitations

1. **Windows-only tested.** MSYS2/Git Bash on Windows 10. macOS/Linux should work but untested.
2. **yq v4 required.** `yq v3` syntax differs for `//` fallback operator.
3. **jq floating point.** `3 * 0.30 = 0.8999...` in jq. Test assertions use awk tolerance.
4. **No config hot-reload.** Changes to `formiga.config.yaml` require blueprint restart.

---

## Metrics

- **15 stories** across 3 sprints
- **20 commits** (E1: 8, E2: 8, E3: 4)
- **~9000 lines** of orchestrator code (39 files)
- **150 config_read calls** replacing hardcoded values
- **190 test assertions** across 3 test suites
- **Zero state corruption** in adversarial testing

---

*FORMICA v4.0.0 — Ship-Ready*
*"From biomimicry to production — every circuit closed, every threshold configurable."*
