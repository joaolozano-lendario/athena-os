# /athena:execute-epic

> Executar épico específico de um Blueprint com precisão cirúrgica

---

## Descrição

Executa um épico isolado de um Blueprint, permitindo execução granular e re-tentativas focadas.

**Use casos principais:**
- Debugging de épico problemático
- Re-execução de épico que falhou
- Testing de componente específico antes de executar tudo
- Execução paralela manual (épicos independentes em sessões separadas)

---

## Uso

```bash
/athena:execute-epic [epic-id] [options]
```

### Argumentos

| Argumento | Descrição | Exemplo |
|-----------|-----------|---------|
| `epic-id` | ID do épico (EPIC-001 ou 1) | EPIC-002 |

### Options

| Option | Descrição | Default |
|--------|-----------|---------|
| `--blueprint PATH` | Path do Blueprint (opcional se STATE tem active) | STATE.yaml → active_blueprint |
| `--skip-verify` | Skip verification phase | false |
| `--max-iterations N` | Limite de iterações Ralph Loop | 50 |
| `--resume` | Continuar execução pausada | false |
| `--verbose` | Logging detalhado | false |

---

## Processo de Execução

### 1. LOAD & VALIDATE

```yaml
Ações:
  - LER: STATE.yaml (verificar active_blueprint)
  - LER: Blueprint especificado ou ativo
  - VALIDAR: Epic ID existe no Blueprint
  - VERIFICAR: Dependencies satisfeitas
  - CRIAR: .planning/epic-[id]/ (workspace isolado)
```

**Verificação de Dependências:**
Se épicos anteriores não estão completos, comando:
- Lista dependências faltantes
- Sugere executar épicos anteriores primeiro
- Pergunta se quer prosseguir anyway (DANGER mode)

### 2. PREPARE CONTEXT

```yaml
Compilar:
  - Epic metadata (title, goals, constraints)
  - Stories + tasks do épico
  - Dependencies (se houver)
  - Success criteria específicos
  - Orchestration hints
  - Prior patterns relevantes
```

### 3. EXECUTE (Ralph Loop)

```yaml
Loop por task:
  THINK: Analisar próxima task
  DO: Executar com ferramentas apropriadas
  CHECK: Verificar success criteria
  ADJUST: Corrigir se falhou

Circuit Breaker:
  - Max iterations: 50 (configurável)
  - Stale threshold: 3
  - Auto-escalate em falha crítica
```

### 4. VERIFY (se --skip-verify=false)

```yaml
Checklist:
  - Rodar testes automatizados
  - Validar artifacts gerados
  - Conferir acceptance criteria
  - Manual verification (se necessário)
```

### 5. DOCUMENT & UPDATE

```yaml
Logging:
  - observability/execution_log.yaml
  - .planning/epic-[id]/trace.md

State Update:
  - .planning/STATE.md
  - STATE.yaml (marcar epic como completo)
```

---

## Output Report

```markdown
# EPIC EXECUTION REPORT

Epic: [epic-id] - [title]
Blueprint: [path]
Started: [timestamp]
Completed: [timestamp]
Duration: [duration]

## Status
COMPLETED | FAILED | PARTIAL

## Metrics
- Total iterations: X
- Stories completed: Y/Z
- Tasks completed: A/B
- Tokens used: ~[estimate]

## Artifacts Generated
- [lista de arquivos criados/modificados]

## Issues Encountered
- [se houver]

## Next Steps
[se epic falhou ou parcial]
```

---

## Estados Possíveis

| Status | Descrição | Next Action |
|--------|-----------|-------------|
| `COMPLETED` | Todos tasks executados com sucesso | Marcar epic como done em STATE |
| `PARTIAL` | Alguns tasks completados | Re-executar com --resume |
| `FAILED` | Erro crítico / circuit breaker | Analisar logs, corrigir Blueprint |
| `BLOCKED` | Dependency não satisfeita | Executar epic dependente primeiro |

---

## Exemplo de Uso

```bash
# Executar épico do Blueprint ativo (em STATE.yaml)
/athena:execute-epic EPIC-002

# Especificar Blueprint manualmente
/athena:execute-epic EPIC-002 --blueprint outputs/blueprints/2026-01-20/blueprint.md

# Skip verification phase
/athena:execute-epic EPIC-001 --skip-verify

# Continuar épico pausado
/athena:execute-epic EPIC-003 --resume

# Verbose logging para debug
/athena:execute-epic EPIC-004 --verbose
```

---

## Quando Usar

### Re-execução de Falha
Épico falhou na execução completa → isolar e re-executar com logs detalhados.

### Testing Incremental
Validar um épico antes de executar Blueprint completo.

### Debugging
Rodar com --verbose para diagnosticar issues específicos.

### Execução Paralela (Manual)
Executar múltiplos épicos independentes em paralelo (sessões separadas).

---

## Anti-Patterns

- **Executar sem ler STATE** → Pode haver dependencies não satisfeitas
- **Forçar execução de epic bloqueado** → Ignorar dependencies gera falhas downstream
- **Skip verify em produção** → Sempre verificar em execuções críticas

---

## Integração com Observability

```yaml
Logs Gerados:
  - observability/execution_log.yaml
    - Entrada por epic
    - Iterations details
    - Failures & recoveries

  - .planning/epic-[id]/trace.md
    - Ralph Loop completo
    - Tool calls & outputs
    - Decision points
```

---

## Referências

- @knowledge/execution/RALPH-LOOP.md
- @knowledge/execution/COMPLETION-GATES.md
- @knowledge/execution/CIRCUIT-BREAKER.md
- @protocols/P5-EXECUTE.md

---

*ATHENA OS 3.0 - Execution Module*
*"Precisão cirúrgica, épico por épico."*
