# Execution Engine Module

> **"Da arquitetura à realidade — execução autônoma com precisão."**

---

## Overview

Este módulo documenta o Execution Engine do ATHENA OS 3.0, que transforma Blueprints em código/conteúdo real através de:

- **Ralph Loop** — Iteração autônoma com Stop Hooks
- **GSD Framework** — Estrutura .planning/, XML tasks, atomic commits
- **Dual-Gate Completion** — Verificação rigorosa antes de exit
- **Circuit Breaker** — Proteção contra loops infinitos

---

## Files

| File | Description |
|------|-------------|
| `EXECUTION-MANIFESTO.md` | Philosophy: iteration over perfection |
| `RALPH-INTEGRATION.md` | Ralph Loop Stop Hooks, completion promise |
| `GSD-STRUCTURE.md` | .planning/ directory, STATE.md, file naming |
| `XML-TASK-FORMAT.md` | Task XML format with action/verify/done |
| `COMPLETION-GATES.md` | Dual-gate system, checkpoint types |
| `CIRCUIT-BREAKER.md` | Triggers, actions, recovery patterns |
| `PROGRESS-TRACKING.md` | STATE.md, metrics, dashboard |

---

## Quick Start

### Execute a Blueprint
```
/athena:execute outputs/blueprints/2026-01-20/my-blueprint --max-iterations 50
```

### Execute Single Epic
```
/athena:execute-epic E1
```

### Quick Mode (Skip Verification)
```
/athena:execute-quick "Fix all TypeScript errors"
```

### Check Progress
```
/athena:progress
```

### Emergency Stop
```
/athena:cancel
```

---

## Key Concepts

### Ralph Loop
- Stop Hook intercepts exit attempts
- Completion Promise defines success
- Continues until dual-gate passes

### Dual-Gate Completion
EXIT requires BOTH:
1. `completion_indicators >= 2`
2. `EXIT_SIGNAL: true`

### Circuit Breaker Triggers
- 3+ loops without progress
- Same error repeated 3x
- Token limit at 90%

### XML Task Format
```xml
<task type="auto">
  <name>Task N: Action name</name>
  <files>path/to/files</files>
  <action>What to do</action>
  <verify>Command to verify</verify>
  <done>Acceptance criteria</done>
</task>
```

---

## Related

- `knowledge/context-engineering/` — Context optimization
- `knowledge/orchestration/` — Multi-agent patterns
- `templates/execution/` — STATE, PLAN, SUMMARY templates
- `.claude/hooks/` — Stop handler, intel updater

---

*ATHENA OS 3.0 — Execution Engine Module*
