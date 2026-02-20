# /athena:cancel

> Parada de emergência do Ralph Loop

---

## Descrição

Comando para **parar execução imediatamente** de forma segura, preservando estado e permitindo retomada posterior.

**CRITICAL:** Este comando:
- Para IMEDIATAMENTE qualquer execução ativa
- Salva estado atual para resume
- Gera emergency report
- Deixa projeto em estado limpo e recuperável

---

## Uso

```bash
/athena:cancel [reason] [options]
```

### Argumentos

| Argumento | Descrição | Exemplo |
|-----------|-----------|---------|
| `reason` | Razão do cancelamento (opcional) | "Found critical bug" |

### Options

| Option | Descrição | Default |
|--------|-----------|---------|
| `--force` | Cancelar sem confirmação | false |
| `--rollback` | Reverter mudanças do épico atual | false |
| `--keep-changes` | Manter mudanças (apenas parar) | true |

---

## Processo

### 1. DETECT

```yaml
Verificar:
  - Há execução ativa (.planning/STATE.md → status: RUNNING)?
  - Qual task/epic atual?
  - Estado de git (commits pendentes, files modificados)
```

### 2. CONFIRM (se não --force)

```yaml
Mostrar:
  - Estado atual (epic/task)
  - Progresso até agora
  - O que será afetado
  - Opções (keep/rollback)

Aguardar:
  - Confirmação do operador
```

### 3. STOP

```yaml
Parada:
  - Enviar signal de parada para agents ativos
  - Aguardar graceful shutdown (max 10s)
  - Se timeout: kill forcefully
```

### 4. SAVE STATE

```yaml
Atualizar .planning/STATE.md:
  status: "CANCELLED"
  cancelled_at: [timestamp]
  cancelled_reason: [reason]
  resumable: true/false

Salvar:
  - Snapshot do progresso atual
  - Logs até momento do cancel
```

### 5. CLEANUP (condicional)

```yaml
SE --rollback:
  - Reverter commits do épico atual
  - Restaurar files para último épico completo
  - Limpar partial artifacts
  - resumable: false

SE --keep-changes (default):
  - Manter todos commits
  - Manter todos files
  - Apenas marcar como CANCELLED
  - resumable: true
```

### 6. REPORT

```yaml
Gerar:
  - .planning/cancellation-report.md
  - Mostrar o que foi completado
  - Mostrar o que ficou pendente
  - Instruções de resume
  - Atualizar observability/execution_log.yaml
```

---

## Confirmação Interativa

Se não usar `--force`, o comando pede confirmação:

```
═══════════════════════════════════════════════════════════
CANCEL EXECUTION
═══════════════════════════════════════════════════════════

Active execution detected:
  Execution ID:    EXEC-2026-01-20-143022
  Blueprint:       BP-2026-01-20-001
  Status:          RUNNING
  Progress:        60% (3/5 epics complete)
  Current:         EPIC-004 > TASK-012 (loop 3/20)
  Elapsed:         1h 23m

If you cancel now:
  ✓ Epics 1-3 are complete and will be preserved
  ◉ Epic 4 is 50% done (2/4 tasks)
  ○ Epic 5 is not started

Options:
  [K]eep changes from Epic 4 and stop
  [R]ollback Epic 4 completely
  [C]ontinue execution (don't cancel)

Your choice [K/R/C]:
```

---

## Modos de Cancelamento

### Keep Changes (default)

```yaml
behavior:
  - Para execução imediatamente
  - Salva estado atual
  - Mantém TODOS commits e files
  - Estado: CANCELLED mas RESUMABLE

use_when:
  - Precisa parar temporariamente
  - Quer preservar trabalho parcial
  - Vai retomar depois
```

### Rollback

```yaml
behavior:
  - Para execução
  - Reverte épico atual completamente
  - Restaura para último épico completo
  - Limpa artifacts parciais

use_when:
  - Épico atual está com problemas
  - Quer "undo" do épico em andamento
  - Prefere estado limpo
```

---

## State Após Cancelamento

```yaml
# .planning/STATE.md após cancel
execution_id: "EXEC-2026-01-20-143022"
blueprint_id: "BP-2026-01-20-001"
status: "CANCELLED"
started_at: "2026-01-20T14:30:22Z"
cancelled_at: "2026-01-20T15:54:10Z"
cancelled_reason: "User requested stop for urgent bug fix"

resumable: true  # false se --rollback

completed_epics: [1, 2, 3]
partial_epic: 4
partial_epic_progress:
  completed_tasks: [10, 11]
  in_progress_task: 12
  pending_tasks: [13]

resume_instructions:
  - Verificar estado do git
  - Executar: /athena:execute --resume
  - Ou: /athena:execute-epic 4 (apenas Epic 4)
```

---

## Cancellation Report

Gerado automaticamente em `.planning/cancellation-report.md` com:
- Trabalho completado (épicos e tasks)
- Trabalho parcial (atual epic)
- Trabalho pendente
- Instruções de resume
- Files modificados

---

## Exemplo de Uso

```bash
# Cancelar com confirmação
/athena:cancel

# Cancelar imediatamente
/athena:cancel --force

# Cancelar e reverter épico atual
/athena:cancel --rollback

# Cancelar com razão documentada
/athena:cancel "Found critical bug in core logic"

# Force cancel mantendo tudo
/athena:cancel --keep-changes --force
```

---

## Quando Usar

| Situação | Comando |
|----------|---------|
| Precisa parar temporariamente | `/athena:cancel --keep-changes` |
| Épico atual está errado | `/athena:cancel --rollback` |
| Urgência (bug crítico) | `/athena:cancel --force` |
| Quer recomeçar do zero | `/athena:cancel --rollback` |

---

## Retomar Após Cancel

```bash
# Se foi --keep-changes
/athena:execute --resume

# Se foi --rollback
/athena:execute  # Vai pular épicos completos

# Reexecutar apenas épico parcial
/athena:execute-epic [epic-id]
```

---

## Safety Measures

```yaml
pre_cancel_checks:
  - Backup current state
  - Snapshot git status
  - Validate .planning/ integrity

during_cancel:
  - Graceful shutdown first
  - Force only if necessary
  - Never lose data

post_cancel:
  - State is consistent
  - Resumable if possible
  - Clear instructions
```

---

## Regras

- **SEMPRE** salvar state antes de parar
- **NUNCA** perder commits/trabalho sem avisar
- **GRACEFUL** shutdown antes de force kill
- **CLEAR** instructions para retomar
- **SAFE** rollback (nunca corromper git)

---

## Referências

- @knowledge/execution/RALPH-LOOP.md
- @knowledge/execution/CIRCUIT-BREAKER.md
- @protocols/P5-EXECUTE.md

---

*ATHENA OS 3.0 - Execution Module*
*"Parar com segurança é tão importante quanto executar."*
