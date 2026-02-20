# FORMICA v4.1.0 — Cross-File Coherence Hooks

**Date:** 2026-02-20
**Tag:** `v4.1.0`
**Branch:** `private`
**Blueprint:** BP-2026-02-20-001

---

## Summary

FORMICA v4.1.0 adds a hook-based cross-file coherence system that prevents CSS↔HTML↔JS mismatches at write time. When enabled, PostToolUse hooks extract interface contracts (classes, IDs, data-attributes) from producer files, and PreToolUse hooks validate consumer files against those contracts before the write is committed. The system integrates with Claude Code's native hook infrastructure via `--settings`.

---

## Changelog (v4.0.0 → v4.1.0)

### E1: Hook Infrastructure (orchestrate.sh)

| Change | Detail |
|--------|--------|
| `_load_hook_settings()` | Reads `hooks.enabled` from config, loads `formica-hooks.json`, expands `$ORCHESTRATOR_DIR` paths |
| `--settings` injection | Conditionally passed to worker spawn when hooks are active |
| `FORMICA_TASK_ID` export | Per-task env var for hooks to identify which task produced/consumed a file |
| `contracts/` directory | Created in `init_blueprint()` and `resume_blueprint()` for contract storage |
| Coherence map | Generated from manifest during hook init, passed to validators |

### E2: Contract System (hooks/)

| File | Purpose |
|------|---------|
| `hooks/formica-hooks.json` | Claude Code settings template (PreToolUse + PostToolUse on Write) |
| `hooks/post-write-contract.sh` | Entry point: delegates to extractors based on file type |
| `hooks/pre-write-validator.sh` | Entry point: delegates to validators, exit 2 blocks write |
| `hooks/extractors/extract-html.sh` | Extracts classes, IDs, data-attributes from HTML |
| `hooks/extractors/extract-css.sh` | Extracts CSS selectors, variables |
| `hooks/extractors/extract-keywords.sh` | Extracts significant terms |
| `hooks/extractors/extract-generic.sh` | Content summary fallback |
| `hooks/validators/validate-html-css.sh` | Validates CSS selectors subset of HTML classes |
| `hooks/validators/validate-html-js.sh` | Validates DOM queries subset of HTML elements |
| `hooks/validators/validate-keywords.sh` | Validates required terms present |
| `hooks/validators/validate-generic.sh` | Always passes (inject/advisory mode) |

### Engine Changes

| File | Lines Changed | Change |
|------|---------------|--------|
| `orchestrate.sh` | +48 -3 | Hook globals, `_load_hook_settings()`, worker spawn, contracts dir |
| `lib/ingest.sh` | +7 | Coherence section in compat manifest |
| `formiga.config.yaml` | +6 | `hooks:` section (enabled, validators_dir, extractors_dir, etc.) |

---

## How It Works

```
Worker writes index.html
  → PostToolUse: extract-html.sh → contracts/build-html.contract.json
    { classes: [hero, hero-title, ...], ids: [], data_attributes: [] }

Worker writes styles.css
  → PreToolUse: validate-html-css.sh
    Reads build-html.contract.json
    Compares CSS selectors against HTML classes
    If orphan found → exit 2 (BLOCK) → worker self-corrects
    If clean → exit 0 (PASS) → write proceeds

  → PostToolUse: extract-css.sh → contracts/build-css.contract.json
```

---

## Configuration

```yaml
# formiga.config.yaml
hooks:
  enabled: true                    # Master switch
  validators_dir: "hooks/validators"
  extractors_dir: "hooks/extractors"
  contract_format: "json"
  strict_orphan_threshold: 0       # 0 = zero tolerance
```

**Opt-in design:** Set `hooks.enabled: false` (default) to disable entirely. Removing the hooks section or the config entry falls back to disabled.

---

## Test Results

| Test Suite | Assertions | Result |
|------------|-----------|--------|
| Sprint Gate v3.8 | 20 | PASS |
| Config Backward Compat | 142 | PASS |
| Adversarial Suite | 28 | PASS |
| **Hook Unit Tests** | **21** | **PASS** |
| **Total** | **211** | **ALL PASS** |

### E2E Micro Blueprint Test (S3.3)

| Metric | Result |
|--------|--------|
| Orphan CSS classes | 0 |
| Hook events | PostToolUse extracted contract, PreToolUse validated |
| QA scores | build-html: 92, build-css: 75 |
| Advisory coherence | 7 (both waves) |
| Total cost | $0.21 |
| Blueprint status | COMPLETE |

---

## New Files (13 files, 939 lines)

```
.orchestrator/hooks/
  formica-hooks.json              (26 lines)
  post-write-contract.sh          (78 lines)
  pre-write-validator.sh          (113 lines)
  extractors/
    extract-html.sh               (36 lines)
    extract-css.sh                (40 lines)
    extract-keywords.sh           (40 lines)
    extract-generic.sh            (29 lines)
  validators/
    validate-html-css.sh          (60 lines)
    validate-html-js.sh           (64 lines)
    validate-keywords.sh          (40 lines)
    validate-generic.sh           (4 lines)
.orchestrator/tests/
  test-hooks-unit.sh              (409 lines)
```

---

## Breaking Changes

None. Hooks are opt-in (disabled by default). All existing behavior unchanged.

---

## Known Limitations

1. **Contract extraction requires Python 3** for HTML/CSS parsing. Falls back gracefully if Python unavailable.
2. **Content passed via env vars** to avoid MSYS path resolution issues on Windows. Large files may hit shell limits.
3. **No hot-reload of hook settings.** Changes require blueprint restart.
4. **Pseudo-class filtering** in validators strips `:hover`, `:active`, etc. Complex CSS selectors (`:nth-child`, `::before`) may not be fully handled.

---

## Metrics

- **13 new files** (939 lines of hook infrastructure)
- **74 lines modified** in existing engine (orchestrate.sh, ingest.sh, config)
- **211 test assertions** across 4 test suites (21 new)
- **E2E validated** with micro blueprint (2 tasks, $0.21 cost)
- **30 blueprints** tracked in epigenetic markers

---

*FORMICA v4.1.0 — Cross-File Coherence*
*"Catch mismatches at write time, not at review time."*
