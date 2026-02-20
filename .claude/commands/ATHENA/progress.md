# /athena:progress

> Visualizar progresso da execução atual

---

## Descrição

Comando para monitorar execução de Blueprint em andamento ou completa.

**Output inclui:**
- Status geral da execução
- Progresso por épico (visual)
- Tasks completadas vs pendentes
- Métricas de tempo e tokens
- Últimas atividades (log)
- Circuit breaker status
- Próximos passos sugeridos

---

## Uso

```bash
/athena:progress [options]
```

### Options

| Option | Descrição | Default |
|--------|-----------|---------|
| `--detail LEVEL` | brief, normal, verbose | normal |
| `--watch` | Atualiza a cada 5s (live mode) | false |
| `--epic N` | Mostrar apenas épico específico | all |
| `--json` | Output em JSON (automação) | false |
| `--history` | Mostrar histórico de execuções | false |

---

## Output Formats

### Brief (--detail brief)

```
═══════════════════════════════════════════════════════════
ATHENA EXECUTION PROGRESS
═══════════════════════════════════════════════════════════

Blueprint:    BP-2026-01-20-001
Status:       RUNNING
Progress:     ████████████░░░░░░░░ 60% (3/5 epics)
Time:         1h 23m (estimated 35m remaining)

Current:      EPIC-004: Database Setup
              └─► TASK-012: Create migration files (loop 3/20)

Next:         EPIC-005: API Endpoints
```

### Normal (default)

```
═══════════════════════════════════════════════════════════
ATHENA EXECUTION PROGRESS
═══════════════════════════════════════════════════════════

Execution ID:    EXEC-2026-01-20-143022
Blueprint ID:    BP-2026-01-20-001
Status:          RUNNING
Started:         2026-01-20 14:30:22
Elapsed:         1h 23m 45s
Estimated:       35m remaining

───────────────────────────────────────────────────────────
EPIC BREAKDOWN
───────────────────────────────────────────────────────────

✓ EPIC-001: Project Setup              [COMPLETE] 12m 34s
  ├─ ✓ TASK-001: Initialize repo
  ├─ ✓ TASK-002: Setup dependencies
  └─ ✓ TASK-003: Configure tooling

✓ EPIC-002: Data Models                [COMPLETE] 23m 12s
  ├─ ✓ TASK-004: Define schemas
  ├─ ✓ TASK-005: Create types
  └─ ✓ TASK-006: Add validations

✓ EPIC-003: Core Logic                 [COMPLETE] 34m 56s
  ├─ ✓ TASK-007: Implement handlers
  ├─ ✓ TASK-008: Add error handling
  └─ ✓ TASK-009: Write tests

◉ EPIC-004: Database Setup              [RUNNING]  13m 03s
  ├─ ✓ TASK-010: Setup PostgreSQL
  ├─ ✓ TASK-011: Configure connection
  ├─ ◉ TASK-012: Create migrations      [LOOP 3/20]
  └─ ○ TASK-013: Seed data              [PENDING]

○ EPIC-005: API Endpoints               [PENDING]
  ├─ ○ TASK-014: Setup Express
  ├─ ○ TASK-015: Define routes
  ├─ ○ TASK-016: Add middleware
  └─ ○ TASK-017: Integration tests

───────────────────────────────────────────────────────────
METRICS
───────────────────────────────────────────────────────────

Epics:         3/5 complete (60%)
Tasks:         12/17 complete (70.6%)
Commits:       12 atomic commits
Tests:         All passing
Errors:        0 failures, 2 retries
Circuit:       Normal (no triggers)

───────────────────────────────────────────────────────────
ACTIVITY LOG (last 5)
───────────────────────────────────────────────────────────

14:53:25  [TASK-012] Loop 3: Generating migration file
14:51:10  [TASK-012] Loop 2: Schema validation failed, retry
14:49:45  [TASK-011] Complete: Connection configured
14:47:22  [TASK-010] Complete: PostgreSQL setup
14:45:10  [EPIC-004] Started: Database Setup

───────────────────────────────────────────────────────────
NEXT STEPS
───────────────────────────────────────────────────────────

Current task should complete in ~2 minutes
Then:
  → TASK-013: Seed data
  → EPIC-005: API Endpoints

Estimated completion: 2026-01-20 16:09
```

### Verbose (--detail verbose)

Inclui logs detalhados por task, token usage, file changes, git commits, error traces.

---

## Dados Lidos

```yaml
Sources:
  - .planning/STATE.md (execution state)
  - observability/execution_log.yaml (metrics)
  - .planning/logs/*.log (activity log)

Métricas Calculadas:
  - Progress percentage (epics e tasks)
  - Tempo médio por task
  - Estimativa de tempo restante
  - Circuit breaker triggers
```

---

## Exemplo de Uso

```bash
# Ver progresso atual
/athena:progress

# Ver apenas Epic 3
/athena:progress --epic 3

# Watch mode
/athena:progress --watch

# Verbose details
/athena:progress --detail verbose

# JSON para script
/athena:progress --json | jq '.progress.tasks.percentage'

# Histórico
/athena:progress --history

# Outro projeto
/athena:progress --path /path/to/project/.planning
```

---

## Quando Usar

| Situação | Comando |
|----------|---------|
| Verificar progresso | `/athena:progress` |
| Monitorar execução longa | `/athena:progress --watch` |
| Debug task específica | `/athena:progress --detail verbose --epic N` |
| Automação/CI | `/athena:progress --json` |
| Ver execuções anteriores | `/athena:progress --history` |

---

## Outputs

```
Console:
└── Formatted progress display

Files (não modifica nada):
└── Apenas lê .planning/STATE.md e logs
```

---

## Regras

- **READ-ONLY** - Nunca modifica state ou arquivos
- **FAST** - Deve executar em < 1s
- **CLEAR** - UI limpa e escaneável rapidamente
- **HELPFUL** - Sempre sugerir próximos passos

---

## Referências

- @knowledge/execution/RALPH-LOOP.md
- @protocols/P5-EXECUTE.md
- @observability/execution_log.yaml

---

*ATHENA OS 3.0 - Execution Module*
*"Visibilidade total, zero surpresas."*
