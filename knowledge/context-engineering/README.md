# Context Engineering Module

> **"Context Engineering é a arte e ciência de preencher a janela de contexto com exatamente a informação certa."**

---

## Overview

Este módulo documenta os princípios, padrões e práticas de Context Engineering para ATHENA OS 3.0, sintetizando conhecimento de:

- **Manus Team** — KV-cache optimization, append-only context
- **Context Architect v8.2** — Strategy selection, threat playbooks
- **Claude Code Native** — Memory hierarchy, hooks, progressive loading
- **Research Papers** — Chain-of-Thought, RAG, ReAct patterns

---

## Files

| File | Description |
|------|-------------|
| `CONTEXT-MANIFESTO.md` | Philosophy and foundational principles |
| `TOKEN-BUDGET.md` | Token budget management (200K, thresholds, actions) |
| `MEMORY-HIERARCHY.md` | 4-tier memory system (global → project → local → rules) |
| `STRATEGY-SELECTOR.md` | 7 context strategies (Zero-Shot through Multi-Agent) |
| `CACHE-OPTIMIZER.md` | KV-cache optimization patterns |
| `THREAT-PLAYBOOKS.md` | 4 threat types and countermeasures |
| `PAYLOAD-TEMPLATES.md` | 3 payload variants (Quick, Deep, Creative) |

---

## Quick Start

### Compile a Context Payload
```
/athena:compile-context [quick|deep|creative]
```

### Analyze Token Budget
```
/athena:analyze-budget
```

---

## Key Concepts

### Token Budget
- **Total:** 200K tokens
- **Usable:** ~130K after system overhead
- **Instructions:** 100-150 effective max

### Memory Hierarchy
1. `~/.claude/CLAUDE.md` — Global
2. `./CLAUDE.md` — Project
3. `./CLAUDE.local.md` — Personal
4. `.claude/rules/*.md` — Path-conditional

### Strategies
1. Zero-Shot Direct
2. Few-Shot Exemplars
3. Chain-of-Thought
4. RAG (Retrieval-Augmented)
5. ReAct (Reasoning + Acting)
6. Multi-Agent Orchestration
7. Single-Agent Decomposition

---

## Related

- `knowledge/execution/` — Execution Engine
- `knowledge/orchestration/` — Orchestration patterns
- `templates/context/payload-variants/` — Payload templates

---

*ATHENA OS 3.0 — Context Engineering Module*
