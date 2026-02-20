# P5: PROTOCOLO DE EXECUÇÃO

> Transformar Blueprint em realidade através da FORMICA execution engine

**Versão:** 3.0.0
**Gate de Saída:** G5 - A execução atingiu os critérios de sucesso do Blueprint?
**Referência:** docs/architecture/02-PROTOCOLS.md

---

## Objetivo

Executar o Blueprint cristalizado através da **FORMICA** — o braço executor autônomo de ATHENA. FORMICA opera como um organismo que executa, não um script que roda: consciência via meta-supervisor, adaptação em tempo real, aprendizado entre blueprints.

---

## Entrada

- Blueprint validado (G4 PASSED)
- Pacote completo em `outputs/blueprints/{date}/{slug}/`:
  - `checkpoint-map.yaml` (input primário — estrutura executável)
  - `exec-arch.yaml` (contexto arquitetural)
  - `_metadata.yaml` (identificação)
  - `taxonomy-config.yaml` (roteamento de outputs)
- Projeto-alvo preparado e acessível

---

## Saída

### Humano (markdown, scannable, beautiful)
- `reports/execution-report.md` — relatório completo ("wake-up document")
- `reports/file-manifest.md` — arquivos criados/modificados com verificação
- `progress.txt` — monitoramento ao vivo (tail -f)

### AI (JSON/JSONL, machine-parseable)
- `reports/diagnostic.json` — diagnóstico estruturado para P6
- `reports/handoff.yaml` — handoff F3→P6
- `state.json` — estado completo da execução
- 7 telemetry streams (events, cost, decisions, friction, colony, immune, advisory)

### Memória Persistente (cross-blueprint)
- `memory/epigenetic-markers.yaml` — ajustes calibrados (2+ blueprints)
- `memory/immune-memory.jsonl` — padrões imunes promovidos
- `memory/pattern-candidates.yaml` — padrões candidatos para P6

### Arquivo Permanente
- `outputs/blueprints/{date}/{slug}/EXECUTION-REPORT.md` — cópia permanente no pacote

---

## Lifecycle: F0 → F1 → F2 → F3

### F0: INGEST (espelha P1 DECODE)

**Propósito:** Decodificar Blueprint em plano executável.

```yaml
ENTRADA: Blueprint package (outputs/blueprints/{date}/{slug}/)

LÊ:
  - checkpoint-map.yaml (input primário)
  - exec-arch.yaml (contexto arquitetural)
  - _metadata.yaml (identificação)
  - memory/epigenetic-markers.yaml (ajustes de execuções passadas)

PROCESSAMENTO:
  1. Parse checkpoint-map → extrai tasks flat
  2. Validação 8-pontos:
     a. Campos obrigatórios (id, worker, model, output, criteria, etc.)
     b. Workers existem em .orchestrator/workers/
     c. context_files existem no projeto
     d. Models válidos (haiku, sonnet, opus)
     e. acceptance_criteria >= 2 por task
     f. depends_on referenciam tasks existentes
     g. DAG acíclico (algoritmo de Kahn)
     h. Custo estimado <= max_budget
  3. Computar waves (topological sort)
  4. Detectar conflitos de arquivo (múltiplas tasks → mesmo file)
  5. Serializar tasks conflitantes (injetar deps sintéticas)
  6. Aplicar allometry (colony size → context budget)
  7. Aplicar epigenetics (ajustes cross-blueprint)
  8. Aplicar mode profile (se definido em exec-arch)
  9. Compilar execution-plan.json (flat, indexado, waves computed)

ESCREVE:
  - runtime/{bp-id}/execution-plan.json
  - runtime/{bp-id}/state.json (inicializado)
  - telemetry/events.jsonl (blueprint_start)

GATE G5.0: "Blueprint é executável?"
  PASS: Todos os 8 checks verdes
  FAIL: Lista TODOS os erros, sugere correções, aborta
```

**Exemplo de validação:**
```
Validating checkpoint-map.yaml...
✓ 20 tasks found
✓ All workers exist
✓ All context files exist
✓ DAG acyclic (10 waves)
✗ T-1.5.1 missing acceptance_criteria
✗ T-2.2.2 references non-existent depends_on: T-2.2.1
RESULT: ABORT — fix 2 issues and retry
```

---

### F1: PREPARE (espelha P2 ARCHITECT)

**Propósito:** Arquitetar a execução e obter confirmação do operador.

```yaml
ENTRADA: execution-plan.json

LÊ:
  - workers/*.md (verificar existência)
  - Project target files (verificar context_files)
  - memory/epigenetic-markers.yaml (warnings para wizard)

PROCESSAMENTO:
  1. Calcular custo:
     best = Σ(worker_cost + qa_cost) por task
     expected = best × 1.3 (overhead 30% retry)
     worst = best × max_retries
  2. Gerar wave map visual (ASCII, task IDs por wave)
  3. Detectar warnings:
     - Tasks sem QA criteria explícitas
     - Budget tight (expected > 80% max)
     - Worker types com histórico ruim (epigenetics)
     - Conflitos de arquivo detectados
  4. Wizard display (box-drawing, ANSI colors)
  5. Worker distribution por tipo

ESCREVE:
  - stdout (wizard interativo)
  - telemetry/events.jsonl (prepare_complete)

GATE G5.1: "Operador confirma execução?"
  CONFIRM → F2
  DRY-RUN → exit 0 (sem execução)
  ABORT → exit 1
```

**Exemplo de wizard:**
```
╔═══════════════════════════════════════════════════════════════════════╗
║  FORMICA v3.0 — Blueprint Execution Plan                              ║
╠═══════════════════════════════════════════════════════════════════════╣
║  Blueprint: FORMICA v2.0 (BP-2026-02-16-003)                         ║
║  Mode: quality | Tasks: 20 | Waves: 10                               ║
║  Duration: ~35min (estimated)                                         ║
╠═══════════════════════════════════════════════════════════════════════╣
║  COST ESTIMATE                                                        ║
║  ├─ Best case:     $2.80 (100% first-pass)                          ║
║  ├─ Expected:      $3.64 (30% retry overhead)                       ║
║  └─ Worst case:    $8.40 (max retries)                              ║
║  Budget: $5.00 available                                             ║
╠═══════════════════════════════════════════════════════════════════════╣
║  WAVE MAP                                                             ║
║  Wave 1: T-1.1.1, T-1.2.1, T-1.5.1, T-2.1.2, T-3.1.1 (5 parallel)   ║
║  Wave 2: T-1.1.2, T-1.4.1, T-1.6.1 (3 parallel)                     ║
║  ... (8 more waves)                                                   ║
╠═══════════════════════════════════════════════════════════════════════╣
║  WARNINGS                                                             ║
║  ⚠ T-1.7.1 has no explicit QA criteria (will auto-generate)         ║
║  ⚠ implementer workers failed 40% in last blueprint                  ║
╠═══════════════════════════════════════════════════════════════════════╣
║  Proceed? [y/N]                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
```

---

### F2: EXECUTE (espelha P3 FRAGMENT — processa cada átomo)

**Propósito:** Executar cada task atômica com QA, adaptação em tempo real, consciência via meta-supervisor.

```yaml
ENTRADA: execution-plan.json + state.json

ESTRUTURA DE LOOP:
  POR WAVE:
    1. Health check (meta-supervisor)
    2. Get ready tasks (deps satisfeitas, status=pending)
    3. POR TASK (paralelo até MAX_PARALLEL):
       a. Barrier check (Immune L1 — budget, DNA, diretório)
       b. Model selection (task.model → epigenetics → budget)
       c. Context assembly (8 layers, token budget enforced)
       d. Spawn worker (claude CLI, --setting-sources "")
       e. Extract output
       f. Innate immune check (L2 — size, format, preamble)
       g. Blacklist check (negative pheromone hard constraints)
       h. QA criteria generation (auto se necessário)
       i. QA execution (Sentinel squad)
       j. Verdict parse (score, pass/rework/reject)
       k. Signal extraction (trophallaxis — colony.jsonl)
       l. Verdict routing (update state, retry, fail)
       m. Friction classification (8 categorias)
       n. Model escalation (consecutive failures → upgrade)
    4. Advisory review (entre waves, coherence check)
    5. Allometry adaptation (ajustar context budget)
  LOOP: Até todas tasks terminais OU budget esgotado

ESCREVE:
  - state.json (atomic writes via mutex)
  - Todos os 7 telemetry streams
  - attempts/{task}/attempt-{n}/ (context, response, output, QA)
  - progress.txt (human-readable live log)

GATE G5.2: "Todas tasks completas ou budget esgotado?"
  Não completadas + budget disponível → continua loop
  Sim → F3
```

**Componentes Principais:**

#### Context Assembly (8 Layers)

```yaml
L0: Project Conventions (~500 tokens)
    - Estilo de código, patterns do projeto
L1: Task Specification (~600 tokens, NEVER truncate)
    - id, description, acceptance_criteria, output path
L2: Negative Pheromone (~200 tokens)
    - Blacklist patterns (hard + soft constraints)
L3: Domain Knowledge (~300 tokens)
    - Genius kit (se nature_code definido)
L4: Context Files (~2000-8000 tokens, CAN truncate)
    - Arquivos listados em task.context_files
L5: Colony Signals (~200-500 tokens, CAN truncate)
    - Trophallaxis — descobertas de tasks anteriores
L6: Friction Warnings (~200 tokens)
    - Avisos de falhas de workers do mesmo tipo
L7: Retry Feedback (~300 tokens, NEVER truncate)
    - Feedback do QA em retry (se attempt > 1)

Token Budget: 3000-60000 (allometry → colony size)
Truncation: Preserva L1 e L7, trunca L4→L5→L3 se necessário
```

#### Worker Squads

| Squad | Worker Type | Mission | Tools | Model |
|-------|------------|---------|-------|-------|
| **Scouts** | analyst | Reconhecimento — map, analisar, descobrir | Read, Grep, Glob | haiku/sonnet |
| **Architects** | architect | Design — planejar, decidir, estruturar | Read, Grep, Glob | sonnet |
| **Builders** | implementer | Construção — código, config, integração | Read, Write, Edit, Grep, Glob | haiku/sonnet |
| **Scribes** | writer | Documentação — explicar, registrar, reportar | Read, Write, Grep, Glob | haiku |
| **Sentinels** | qa | Quality gate — julgar, validar, detectar | Read, Grep, Glob (read-only) | haiku |
| **Advisor** | advisor | Metacognição — revisar waves, sugerir adaptação | Read, Grep, Glob (read-only) | sonnet |

#### QA Loop

```yaml
1. Worker executa → output gerado
2. Innate immune (L2) → checks mecânicos (size, format, preamble)
3. Blacklist check → violações de negative pheromone
4. QA spawn → Sentinel julga contra criteria
5. Verdict parse → {score 0-100, verdict PASS/REWORK/REJECT, feedback}
6. Routing:
   score >= 80 AND verdict=PASS → COMPLETE
   score 60-79 AND attempts < max → REWORK (retry com feedback)
   score < 60 OR exhausted → REJECT/EXHAUSTED (cascade failure)
```

#### Meta-Supervisor OODA Loop

Roda **após cada task completion**. Transforma FORMICA de "script que roda tasks" em "organismo que executa conscientemente."

```yaml
OBSERVE:
  - state.json (completed, failed, pending, running)
  - friction.jsonl (últimos 10 eventos)
  - cost.jsonl (spent, velocity)
  - decisions.jsonl (adaptações recentes)

ORIENT (computar indicadores):
  - pass_rate = completed / (completed + failed)
  - cost_velocity = spent / budgeted
  - friction_trend = last_5 vs previous_5
  - worker_performance per type

DECIDE (aplicar heurísticas):
  CRITICAL: pass_rate < 30% AND attempts > 6
    → FORCE_ADVISORY + LOG alert
  CRITICAL: cost_velocity > 1.5
    → SWITCH_ECONOMIC + LOG alert
  ADAPT: worker_type.pass_rate < 40%
    → INCREASE_CONTEXT_BUDGET(+30%)
  ADAPT: friction_trend INCREASING
    → FORCE_EARLY_ADVISORY
  ADAPT: budget_remaining < 20%
    → FORCE_HAIKU + REDUCE_RETRIES

ACT:
  - Modificar globals (MAX_PARALLEL, DEFAULT_MODEL, QA_THRESHOLD)
  - Registrar em decisions.jsonl
  - Se CRITICAL → events.jsonl {type:meta_alert}
```

#### Advisory Review (Between Waves)

```yaml
Trigger: Entre waves (se ADVISORY_ENABLED e wave > 1)

Input:
  - state.json (todas tasks completadas nesta wave)
  - colony.jsonl (sinais emitidos)
  - friction.jsonl (eventos de fricção)
  - Outputs das tasks completadas

Process:
  1. Ler todos outputs da wave
  2. Check cross-references (naming consistency, assumptions)
  3. Avaliar QA score trajectory
  4. Identificar riscos de integração para próxima wave

Output: JSON {coherence_score 0-10, quality_trend, recommendations[], adjustments{}}

Action:
  coherence < 5 → PAUSE blueprint (operador decide)
  coherence 5-6 → STRONG ADAPT (model upgrade, QA threshold +5, parallel -1)
  coherence 7-8 → MILD ADAPT (aplicar sugestões low-risk)
  coherence 9-10 → CONTINUE (nenhuma mudança)
```

---

### F3: SYNTHESIZE (espelha P4 CRYSTALLIZE)

**Propósito:** Cristalizar resultados e telemetria em relatórios (humano) e memória persistente (AI).

```yaml
ENTRADA: state.json + telemetry/ + attempts/ + task outputs

LÊ:
  - Todos os 7 telemetry streams
  - state.json
  - memory/epigenetic-markers.yaml

PROCESSAMENTO:
  1. HUMAN REPORTS:
     a. execution-report.md (beautiful, scannable, 100-200 lines)
        - Dashboard, cost breakdown, per-task results, wave timeline
        - Issues encountered, recommendations
     b. file-manifest.md (todos arquivos criados/modificados)
        - Verificação (bash -n, JSON parse, schema validation)
        - Line count, purpose, task que criou

  2. AI DIAGNOSTIC (3 níveis):
     L1: Score distribution + cost breakdown (determinístico jq/bash)
     L2: Friction analysis + issues sistêmicos (determinístico jq/bash)
     L3: System evolution assessment (1 haiku call, ~$0.02, structured)

  3. MEMORY UPDATE:
     a. Epigenetic markers (2+ blueprint evidence, calibrado)
     b. Immune promotion (innate→adaptive, conservative: flag not reject)
     c. Pattern candidates (staging para P6 revisar)

  4. HANDOFF:
     a. diagnostic.json (P6 consumption)
     b. handoff.yaml (F3→P6 bridge — structured summary)

ESCREVE:
  - reports/execution-report.md (HUMAN primary)
  - reports/file-manifest.md (HUMAN primary)
  - reports/diagnostic.md (HUMAN debug)
  - reports/diagnostic.json (AI/P6 primary)
  - reports/handoff.yaml (AI/P6 primary)
  - memory/epigenetic-markers.yaml (updated)
  - memory/immune-memory.jsonl (promoted patterns)
  - memory/pattern-candidates.yaml (staging)
  - telemetry/events.jsonl (blueprint_complete)

COPY:
  - reports/execution-report.md → outputs/blueprints/{date}/{slug}/EXECUTION-REPORT.md
    (arquivo permanente ao lado do Blueprint)

GATE G5.3: "Relatórios gerados e memória atualizada?"
  Sim → Notifica operador, blueprint completo, pronto para P6
```

**Exemplo de execution-report.md (excerpt):**

```markdown
# Execution Report: FORMICA v2.0

**Blueprint:** BP-2026-02-16-003
**Date:** 2026-02-16 14:30:05 → 15:02:30 (32m25s)
**Status:** PARTIAL (18/20 tasks)
**Cost:** $3.42 (estimate: $3.64)

---

## Results Dashboard

| Metric | Value |
|--------|-------|
| Tasks | 18/20 passed (90%) |
| First-pass rate | 75% |
| Retries | 8 across 6 tasks |
| Waves | 9/10 completed |
| Cost | $3.42 / $5.00 budget (68%) |
| Duration | 32m25s |
| Model distribution | haiku: 14, sonnet: 4, opus: 0 |

## What Was Created

| File | Status | Purpose |
|------|--------|---------|
| `.orchestrator/lib/modes.sh` | Created (96 lines) | 4 orchestration mode profiles |
| `.orchestrator/lib/friction.sh` | Created (111 lines) | Friction event classification |
| `.orchestrator/orchestrate.sh` | Modified (+180 lines) | Mode/wizard/friction/report hooks |

See [file-manifest.md](./file-manifest.md) for complete details.

## Cost Breakdown

```
Workers   ████████████████░░░░  $2.10  (61%)
QA        ████░░░░░░░░░░░░░░░░  $0.55  (16%)
Advisory  ███░░░░░░░░░░░░░░░░░  $0.34  (10%)
Retries   ███░░░░░░░░░░░░░░░░░  $0.40  (12%)
Meta-rpt  ░░░░░░░░░░░░░░░░░░░░  $0.03  (1%)
──────────────────────────────────────────
Total     ████████████████████  $3.42
```

## Recommendations

### Immediate
- Review T-1.7.1 output carefully (required model escalation)
- T-3.3.1 was blocked (dep-failed) — address T-2.2.2 and re-run

### For Future Blueprints
- Implementer expected_lines estimates 2x too low on average
- Consider sonnet default for architect tasks (3x token consumption)
```

---

## State Machine

### Task States

```
PENDING → (deps ok, barrier ok) → RUNNING
RUNNING → (QA score >= 80) → COMPLETED
RUNNING → (score 60-79, attempts < max) → REWORK → PENDING (retry)
RUNNING → (score < 60) → REJECTED
RUNNING → (attempts >= max) → EXHAUSTED
REJECTED/EXHAUSTED → cascade → downstream tasks → DEP-FAILED
PENDING → (barrier fail) → ABORTED
PENDING → (budget insuficiente) → BUDGET_BLOCKED
```

### Blueprint States

```
initializing → (F0 start)
ready → (F0 complete, execution-plan compiled)
preparing → (F1 wizard computing)
confirmed → (F1 operator confirmed)
executing → (F2 first task spawned)
paused → (advisory coherence < 5 OR SIGINT)
synthesizing → (F3 start, all tasks terminal)
complete → (F3 complete, reports generated)
aborted → (budget exhausted OR cancel)
```

---

## Command Syntax

### Execução Básica

```bash
# Executar Blueprint (wizard interativo)
.orchestrator/orchestrate.sh outputs/blueprints/2026-02-16/formica-v2/

# Auto-approve (skip wizard)
.orchestrator/orchestrate.sh outputs/blueprints/2026-02-16/formica-v2/ --auto-approve

# Dry-run (F0+F1 only, sem execução)
.orchestrator/orchestrate.sh outputs/blueprints/2026-02-16/formica-v2/ --dry-run
```

### Controle de Sessão

```bash
# Resume (após interrupção)
.orchestrator/orchestrate.sh --resume BP-2026-02-16-003

# Restart (ignorar estado, começar do zero)
.orchestrator/orchestrate.sh outputs/blueprints/2026-02-16/formica-v2/ --restart

# Abandon (marcar como abortado, limpar locks)
.orchestrator/orchestrate.sh --abandon BP-2026-02-16-003
```

### Monitoramento

```bash
# Live monitoring
tail -f runtime/BP-2026-02-16-003/progress.txt

# Check state
jq '.status, .counters' runtime/BP-2026-02-16-003/state.json
```

---

## Telemetry Streams

### Write Matrix

| Stream | Writer | Format | Quando |
|--------|--------|--------|--------|
| `events.jsonl` | orchestrate.sh, state.sh, qa.sh, routing.sh | `{ts, type, task_id?, data}` | Cada evento significativo |
| `cost.jsonl` | cost.sh | `{ts, type, task_id?, model, input_tokens, output_tokens, cost_usd}` | Cada API call |
| `decisions.jsonl` | routing.sh, advisory.sh, meta-supervisor | `{ts, type, task_id?, inputs, choice, rationale}` | Cada decisão de roteamento |
| `friction.jsonl` | friction.sh | `{ts, task_id, worker_type, score, cause, feedback_excerpt}` | Cada non-PASS verdict |
| `colony.jsonl` | qa.sh (signal extraction) | `{ts, task_id, type, text, intensity, wave}` | Cada QA que emite signal |
| `immune.jsonl` | qa.sh (innate check) | `{ts, task_id, layer, check, result, detail}` | Cada immune check |
| `advisory_reviews.jsonl` | advisory.sh | `{ts, wave, coherence_score, recommendations[]}` | Entre waves |

### Read Matrix — Who Consults What

| Reader | Reads | When | Why |
|--------|-------|------|-----|
| context.sh L5 | colony.jsonl | Context assembly | Inject signals (trophallaxis) |
| context.sh L6 | friction.jsonl | Context assembly | Warn same-type worker |
| routing.sh | events.jsonl | Model selection | Count consecutive failures |
| routing.sh | epigenetic-markers.yaml | Model selection | Apply cross-blueprint hints |
| qa.sh innate | immune-memory.jsonl | Output check | Adaptive patterns |
| advisory.sh | state.json + colony.jsonl + friction.jsonl | Between waves | Evaluate wave health |
| meta-supervisor | state.json + friction.jsonl + cost.jsonl | After each task | Detect systemic issues |
| F3 (report/meta_report) | ALL .jsonl + state.json | Synthesis | Generate reports |
| F3 (epigenetics) | friction.jsonl + events.jsonl + diagnostic.json | Synthesis | Update markers |

---

## Integration: ATHENA ↔ FORMICA

### P4 → F0 Handoff

```
P4 cristaliza:
  - outputs/blueprints/{date}/{slug}/checkpoint-map.yaml (PRIMARY INPUT)
  - outputs/blueprints/{date}/{slug}/exec-arch.yaml (context)
  - outputs/blueprints/{date}/{slug}/_metadata.yaml (identification)

F0 valida:
  - 8 validation checks (fields, workers, files, DAG, budget)
  - Se PASS → compila execution-plan.json
  - Se FAIL → lista TODOS erros, sugere fix, aborta
```

### F3 → P6 Handoff

```
F3 gera:
  - reports/handoff.yaml (summary estruturado)
  - reports/diagnostic.json (L1+L2+L3 analysis)

P6 lê:
  - handoff.yaml → parse results, friction, cost, patterns
  - diagnostic.json → deep metrics
  - Escreve: execution_log.yaml, pattern_library.yaml, blueprints-archive.yaml
```

### Ciclo Completo

```
P0: REFLECT → lê execution_log (de P6 anterior)
P1: DECODE → intent-spec.yaml
P2: ARCHITECT → exec-arch.yaml
P3: FRAGMENT → checkpoint-map.yaml (FORMICA-compatible)
P4: CRYSTALLIZE → blueprint package
═══════════════════════════════════════════════════════════════════
F0: INGEST → valida + compila
F1: PREPARE → wizard + confirmação
F2: EXECUTE → waves + QA + adapt
F3: SYNTHESIZE → reports + memory + handoff
═══════════════════════════════════════════════════════════════════
P6: LEARN → lê handoff + diagnostic, atualiza execution_log
NEXT P0: lê execution_log → ciclo fecha
```

---

## Biomimetic Intelligence

FORMICA incorpora 6 padrões biomimetic que transformam execução mecânica em orgânica:

### Negative Pheromone
- **Conceito:** Formigas marcam caminhos ruins para evitar.
- **Implementação:** Blacklist patterns (global + runtime) em context L2.
- **Effect:** Workers evitam padrões que falharam antes.

### Trophallaxis
- **Conceito:** Formigas compartilham alimento boca-a-boca, transferindo informação química.
- **Implementação:** colony.jsonl — QA extrai signals, context L5 injeta em futuros workers.
- **Effect:** Worker A descobre → Worker B (outra wave) recebe o conhecimento.

### Quorum Sensing
- **Conceito:** Bactérias sentem densidade populacional antes de mudar comportamento.
- **Implementação:** Advisory usa quorum decision (se 60%+ tasks sugerem padrão, act).
- **Effect:** Adaptações não acontecem por 1 falha, mas por tendência confirmada.

### Allometry
- **Conceito:** Organismos pequenos têm cérebros proporcionalmente maiores.
- **Implementação:** Context budget = 60000 × (8/n)^0.75 (power law).
- **Effect:** Colônia pequena (8 tasks) → 60K tokens/task. Colônia grande (100 tasks) → 15K tokens/task.

### Synaptic Pruning
- **Conceito:** Cérebros eliminam sinapses pouco usadas.
- **Implementação:** Epigenetics decay — markers sem evidência em 10 blueprints → removed.
- **Effect:** Sistema não acumula superstições, só mantém padrões validados.

### Immune System (3 camadas)
- **L1 Barriers:** Pre-spawn checks (budget, DNA, directory).
- **L2 Innate:** Post-output checks (size, format, preamble, memory).
- **L3 Adaptive:** Learned patterns (immune-memory.jsonl, promoted by F3).
- **Effect:** Sistema aprende a rejeitar padrões ruins sem QA overhead.

---

## Checklist de Pré-Execução

Antes de rodar F0:

- [ ] Blueprint package completo (checkpoint-map, exec-arch, _metadata)
- [ ] Projeto-alvo acessível
- [ ] Budget definido em exec-arch ou usar default
- [ ] Workers necessários existem em .orchestrator/workers/
- [ ] Git repository limpo (se aplicável)
- [ ] Dependencies instaladas (se aplicável)

---

## Checklist de Pós-Execução

Antes de passar para P6 (LEARN):

- [ ] execution-report.md gerado e revisado
- [ ] file-manifest.md verificado (arquivos existem)
- [ ] Todos acceptance criteria validados (ou failures documentados)
- [ ] Gate G5 PASSED (ou PARTIAL com razão clara)
- [ ] handoff.yaml + diagnostic.json gerados
- [ ] Memória persistente atualizada (epigenetics, immune)

---

## Exemplo de Execução

### Contexto
- Blueprint: "FORMICA v2.0" (BP-2026-02-16-003)
- Epics: 3 | Tasks: 20 | Waves: 10
- Projeto: `D:/athena-os/.orchestrator`
- Budget: $5.00 | Mode: quality

### Flow

```
[14:30:05] F0: INGEST
  ✓ checkpoint-map.yaml parsed (20 tasks)
  ✓ 8 validation checks PASS
  ✓ DAG computed (10 waves)
  ✓ File conflicts detected: orchestrate.sh (6 writers → serialized)
  ✓ execution-plan.json compiled
  → state: ready

[14:30:06] F1: PREPARE
  ╔═════════════════════════════════════════════════════════╗
  ║  Blueprint: FORMICA v2.0                                ║
  ║  Cost: $2.80 / $3.64 / $8.40 (best/exp/worst)          ║
  ║  Tasks: 20 | Waves: 10 | Duration: ~35min              ║
  ╚═════════════════════════════════════════════════════════╝
  Proceed? y
  → state: confirmed

[14:30:07] F2: EXECUTE

  ═══ WAVE 1/10 (7 tasks) ═══════════════════════════════
  ▶ T-1.1.1 modes.sh [builder/haiku]
  ▶ T-1.2.1 friction.sh [builder/haiku]
  ▶ T-1.3.1 qa-criteria [builder/haiku]
  ▶ T-1.5.1 report.sh [builder/haiku]
  ▶ T-2.1.2 epigenetics.sh [builder/haiku]
  ✓ T-1.2.1 score=91 cost=$0.07 (55s)
  ✓ T-1.5.1 score=87 cost=$0.09 (68s)
  ✓ T-1.1.1 score=89 cost=$0.08 (65s)
  ✓ T-1.3.1 score=85 cost=$0.07 (58s)
  ✓ T-2.1.2 score=95 cost=$0.10 (72s)

  📋 ADVISORY (coherence=8, trend=stable)
     No adjustments needed

  ═══ WAVE 2/10 (4 tasks) ═══════════════════════════════
  ▶ T-1.1.2 integrate modes [builder/haiku]
  ▶ T-1.4.1 wizard.sh [builder/haiku]
  ▶ T-1.6.1 context layers [builder/haiku]
  ◐ T-1.1.2 REWORK (score=65: size_constraint_violation)
  ✓ T-1.4.1 score=86 cost=$0.08 (60s)
  ✓ T-1.6.1 score=84 cost=$0.09 (65s)
  ▶ T-1.1.2 [retry, builder/haiku]
  ✓ T-1.1.2 score=82 cost=$0.07 (50s)

  ... (waves 3-9)

  ═══ WAVE 10/10 (1 task) ═══════════════════════════════
  ✗ T-3.3.1 DEP-FAILED (blocked by T-2.2.2 EXHAUSTED)

[15:02:30] F3: SYNTHESIZE
  ✓ execution-report.md generated (141 lines)
  ✓ file-manifest.md generated (62 lines)
  ✓ diagnostic L1+L2 (deterministic)
  ✓ diagnostic L3 (haiku call, $0.02)
  ✓ handoff.yaml generated
  ✓ Epigenetics updated (3 markers)
  ✓ Immune promoted (2 patterns → flag)
  ✓ Report copied to blueprint package
  → state: complete

[15:02:30] ═══ COMPLETE ═══════════════════════════════════
           18/20 tasks passed | $3.42 / $5.00 | 32m25s
           Report: runtime/BP-2026-02-16-003/reports/execution-report.md
```

---

## Métricas Capturadas

```yaml
execution:
  - total_time
  - time_per_wave
  - time_per_task
  - attempts_per_task

quality:
  - pass_rate (completed / attempted)
  - first_pass_rate (first attempt / total)
  - avg_qa_score
  - friction_events

resources:
  - cost_breakdown (worker, QA, advisory, retries)
  - tokens_per_task
  - model_distribution

adaptation:
  - advisory_runs
  - meta_supervisor_interventions
  - model_escalations
  - allometry_adjustments
```

**Destino:** F3 consolidates into diagnostic.json + handoff.yaml

---

## Referências

- `knowledge/execution/EXECUTION-MANIFESTO.md`
- `knowledge/execution/RALPH-INTEGRATION.md` (deprecated)
- `knowledge/execution/COMPLETION-GATES.md`
- `knowledge/orchestration/MULTI-AGENT-PATTERNS.md`
- `docs/architecture/08-ORCHESTRATION.md`
- `docs/architecture/10-EXECUTION.md`
- `.orchestrator/docs/FORMICA-v2.md`

---

*"Um organismo que executa, não um script que roda." — FORMICA v3.0*
*"Da arquitetura à execução — excelência em cada etapa." — ATHENA OS 3.0*
