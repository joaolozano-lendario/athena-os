---
paths:
  - ".planning/**"
  - "outputs/blueprints/**"
---

# Execution Mode Rules

Regras ativas durante execução de Blueprints.

---

## Commits

- **Um commit por task** — Nunca agrupar múltiplas tasks
- **Formato:** `{type}({epic}-{task}): {description}`
  - Exemplo: `feat(E1-T1.1.1): Create CONTEXT-MANIFESTO.md`
- **Nunca usar** `git add .` — Adicionar arquivos individualmente
- **Incluir** Co-Authored-By quando apropriado

---

## Progress Tracking

- **Atualizar STATE.md** após cada task completada
- **Logar erros** em `observability/circuit_breaker_log.yaml`
- **Manter métricas** de iterations, time, tokens

---

## Error Handling

- **2 falhas** na mesma abordagem → pivotar estratégia
- **Documentar** o que foi tentado antes de pivotar
- **Circuit breaker** ativa após 3+ loops sem progresso

---

## Completion Signaling

- **EXIT_SIGNAL: true** quando task está completa
- **Verificar** acceptance criteria do `<done>` antes de sinalizar
- **Dual-gate:** indicators >= 2 AND EXIT_SIGNAL

---

## Context Management

- **Fresh context** para cada task quando possível
- **Summarize** antes de tasks longas
- **Delegate** para subagent quando foco profundo necessário

---

## Referências

@knowledge/execution/COMPLETION-GATES.md
@knowledge/execution/CIRCUIT-BREAKER.md
@knowledge/execution/PROGRESS-TRACKING.md
