---
paths:
  - "**/*"
---

# Context Budget Rules

Regras para gestão eficiente do budget de contexto.

---

## Thresholds

| Usage | Status | Ação |
|-------|--------|------|
| 0-50% | GREEN | Normal operation |
| 50-70% | YELLOW | Monitor, prune if possible |
| 70-80% | ORANGE | Considerar /compact |
| 80-90% | RED | Delegar para subagent |
| 90%+ | CRITICAL | Emergency action required |

---

## Optimization Strategies

### Progressive Loading
- Usar `@filename` para carregar sob demanda
- **Não** carregar arquivos "por precaução"
- Carregar apenas quando referência é necessária

### Discovery Before Read
- Usar **Glob** para encontrar arquivos
- Usar **Grep** para buscar conteúdo
- **Depois** usar Read no arquivo relevante

### Summarization
- Resumir conversas longas periodicamente
- Usar /compact antes de tasks complexas
- Manter apenas contexto relevante para task atual

---

## Anti-Patterns

### Preloading
```
❌ Ler 10 arquivos no início "para ter contexto"
✓ Ler arquivos conforme necessidade surge
```

### Speculative Reading
```
❌ "Talvez eu precise desse arquivo..."
✓ Buscar com Grep/Glob, depois ler se relevante
```

### History Hoarding
```
❌ Manter toda história de conversa
✓ Summarize e /compact periodicamente
```

---

## Delegation Triggers

Considerar delegar para subagent quando:
- Task requer foco profundo (>15 min)
- Contexto atual está >70%
- Task é independente (não precisa de estado atual)

---

## Referências

@knowledge/context-engineering/TOKEN-BUDGET.md
@knowledge/context-engineering/CACHE-OPTIMIZER.md
