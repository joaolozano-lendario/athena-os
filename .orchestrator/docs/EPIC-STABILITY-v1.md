---
type: epic
project: formiga-orchestrator
created: 2026-02-19
agent: pedro-valerio
status: approved
version: 1.2
updated: 2026-02-19
update_note: "v1.2: Baseline v3.7 delta, recalibrated S1.1/S1.6/S2.2, added worker flakiness note. v1.1: Guardrails GR-1/2/3, Team Assignments, Rollback Protocol"
audit_source: epistemic-e2e-audit-2026-02-19
---

# EPIC: FORMIGA Stability & Ship-Readiness

> "A melhor coisa e voce impossibilitar caminhos."
> — Pedro Valerio

## Executive Summary

Auditoria epistemica end-to-end identificou **6 vulnerabilidades criticas**, **8 gaps de alta prioridade**, e **12 valores hardcoded** no FORMIGA v3.7. Este epico estabiliza o sistema ANTES de adicionar features novas.

**Baseline:** FORMIGA v3.7 (pos-fix de 4 bugs de concorrencia da v3.6)
**Score atual:** 7.2/10
**Score alvo:** 9.0/10
**Criterio de SHIP:** Zero P0 abertos + todos os P1 resolvidos ou mitigados com workaround documentado.

---

## Baseline v3.7 — O Que Ja Foi Resolvido

> A v3.6 implementou 12 incisoes baseadas em 28 artifacts AURUM. A v3.7 corrigiu 4 bugs
> introduzidos pela v3.6. Este epic parte do estado v3.7 como baseline.

### Ganhos ja realizados (NAO reimplementar)

| Area | O que v3.7 resolveu | Evidencia no codigo |
|------|---------------------|---------------------|
| QA Calibracao | QA nao rejeita mais output bom (auto-imunidade eliminada) | qa.sh: thresholds recalibrados |
| Advisory Guards | Advisory tem 3 guards condicionais + pode pausar blueprint | advisory.sh: linhas 86-110, 3-guard mechanism |
| Worker Resilience | Workers nao morrem em silencio — timeout, validacao JSONL, backoff | orchestrate.sh: timeout + retry com backoff |
| Pheromone Persistence | Aprendizado cross-blueprint funciona | pheromone.sh: save_pheromone_to_markers() persiste em MARKERS_FILE |
| Lock Mechanism | Lock melhorado de 5s force-break para 60s + PID check | lock.sh: is_lock_stale() com kill -0 + age > 60s |

### O que continua quebrado (escopo deste EPIC)

| Bug | Severity | Status v3.7 | Story |
|-----|----------|-------------|-------|
| C1: Sem version counter no state | CRITICAL | Nao resolvido | S1.1 |
| C2: Budget check/deduct separados | CRITICAL | Nao resolvido | S1.2 |
| C3: QA crash sem recovery | CRITICAL | Nao resolvido | S1.4 |
| C4: Score/verdict incoherence | CRITICAL | Nao resolvido | S1.3 |
| C5: get_ready_tasks multiplos reads | CRITICAL | Nao resolvido | S1.1 |
| C6: File registry deps em temp_state | CRITICAL | Nao resolvido | S1.5 |
| H1: Immune memory nunca promovida | HIGH | Nao resolvido | S2.1 |
| H3: Advisory pausa mas nao cancela | HIGH | Parcial (3 guards OK, falta veto hard) | S2.2 |
| H4: Model override bypassa budget | HIGH | Nao resolvido | S1.6 |
| H5: Pheromone sem file lock | HIGH | Nao resolvido | S2.3 |
| H6: Meta-loop sem wall-clock timeout | HIGH | Nao resolvido | S2.4 |
| H7: Token estimation 4 chars/token | HIGH | Nao resolvido | S2.5 |
| H8: expected_format/lines opcionais | HIGH | Nao resolvido | S2.6 |
| P2: 12+ valores hardcoded | MEDIUM | Nao resolvido | S3.1 |

### Gargalo atual (informativo, fora de escopo)

> **Worker flakiness**: O gargalo agora e o LLM, nao o orquestrador.
> - Haiku gasta ate 28 turns numa task simples (172 de 180s). Timeout mata.
> - Haiku pede permissao ao inves de produzir output. QA rejeita, task morre.
> - Nao-deterministico: mesma task, mesma config — as vezes 92, as vezes morre.
> - DAG amplifica: 1 braco falha → 50% das tasks morrem por dependencia.
>
> **Decisao**: Isso e problema do LLM provider, nao do orquestrador. FORA DE ESCOPO deste epic.
> Possivel mitigacao futura: retry com model escalation automatico (haiku fail → sonnet retry).

---

## Principios deste Epic

1. **Estabilizar > Evoluir** — Nenhuma feature nova ate Sprint 1 completo
2. **Mensuravel** — Cada story tem metricas de validacao objetivas
3. **Justificavel** — Cada fix referencia o bug especifico e o impacto real
4. **Incremental** — Cada story e deployavel independentemente
5. **Testavel** — Cada story inclui smoke test que DEVE passar

---

## Guardrails Obrigatorios (NUNCA PULAR)

> Estes guardrails existem porque bash concurrency e traicoeiro.
> Confianca de zero regressao sem eles: 70%. Com eles: 95%.
> **VETO se qualquer guardrail for ignorado.**

### GR-1: Branch por Story

```bash
# ANTES de iniciar qualquer story:
git checkout main
git checkout -b fix/S1.1-atomic-state  # exemplo

# DEPOIS de concluir + smoke test PASS:
git add -A && git commit -m "fix(state): atomic writes with version counter [S1.1]"

# SE smoke test FAIL ou regressao detectada:
git checkout main  # volta ao estado seguro, zero dano
git branch -D fix/S1.1-atomic-state  # descarta tentativa
```

**Regra:** Uma branch por story. Nunca implementar 2 stories na mesma branch.
**Por que:** Se fix A quebra fix B, git checkout main restaura tudo em 1 comando.
**VETO se:** Story implementada direto na main sem branch.

### GR-2: Smoke Test ANTES e DEPOIS

```
1. Escolher blueprint de referencia (ex: test-basic-3-tasks.yaml)
2. ANTES do fix: rodar blueprint, salvar output
3. Implementar o fix
4. DEPOIS do fix: rodar o MESMO blueprint
5. Comparar:
   - Output identico ou melhor → PASS
   - Output diferente sem justificativa → FAIL → rollback
   - Output pior → FAIL → rollback
6. Rodar smoke test especifico da story (definido no epic)
7. SO ENTAO fazer commit
```

**Regra:** Todo fix deve provar que nao piorou o que ja funcionava.
**Por que:** Bash nao tem type system. Um typo em state.sh pode cascatear para 10 arquivos.
**VETO se:** Story mergeada sem evidencia de smoke test antes/depois.

### GR-3: Uma Story por Vez, Nunca Paralelo

```
CORRETO:   S1.1 → test → merge → S1.2 → test → merge → ...
ERRADO:    S1.1 + S1.2 ao mesmo tempo
```

**Regra:** Completar, testar e mergear uma story antes de iniciar a proxima.
**Por que:** Cada fix altera comportamento de concorrencia. Dois fixes simultaneos = impossivel isolar qual quebrou.
**Excecao:** Stories de sprints diferentes NUNCA sao paralelas. Dentro do mesmo sprint, a ordem do epic e a ordem de execucao.
**VETO se:** Duas branches de story abertas ao mesmo tempo.

---

## Team Assignments por Sprint

### Sprint 1: Critical Fixes (v3.8)

| Role | Quem | Responsabilidade |
|------|------|-----------------|
| **Implementador** | Joao + Claude Code | Ler story, implementar fix, rodar smoke test |
| **QA** | `@qa` agent | Validar smoke tests, rodar campaigns de regressao |
| **Auditor** | Pedro Valerio (`@pedro-valerio`) | Audit de regressao ao final do sprint |

> **Nota:** Sprint 1 e 100% codigo bash de infraestrutura. Nao requer architect
> porque os fixes sao cirurgicos e bem definidos (lock → atomic, separate → single, etc.)

### Sprint 2: Structural Evolution (v3.9)

| Role | Quem | Responsabilidade |
|------|------|-----------------|
| **Architect** | `@architect` agent | Validar DESIGN de S2.1 (Immune Memory), S2.3 (Pheromone Lock), S2.5 (Token Estimation) ANTES de codificar |
| **Implementador** | Joao + Claude Code | Implementar apos design aprovado |
| **QA** | `@qa` agent | Smoke tests + regressao contra v3.8 |
| **Auditor** | Pedro Valerio (`@pedro-valerio`) | Audit de regressao ao final do sprint |

> **Nota:** Sprint 2 tem decisoes arquiteturais (immune memory promotion logic,
> advisory veto thresholds, token estimation heuristics). Architect VALIDA design
> antes de uma linha de codigo ser escrita. Implementador so comeca apos architect sign-off.

### Sprint 3: Config & Adversarial Tests (v4.0)

| Role | Quem | Responsabilidade |
|------|------|-----------------|
| **DevOps** | `@devops` agent | Liderar S3.1 (formiga.config.yaml) — config structure, validation, fallback logic |
| **Architect** | `@architect` agent | Revisar config schema, validar que defaults == v3.7 |
| **Implementador** | Joao + Claude Code | S3.2 (adversarial tests), S3.3 (release notes) |
| **QA** | `@qa` agent | Suite COMPLETA — 18 existentes + 6 adversariais |
| **Auditor** | Pedro Valerio (`@pedro-valerio`) | Audit FINAL — PV Score deve ser >= 9.0 |

> **Nota:** S3.1 e puro DevOps (externalize config, env vars, backward compat).
> DevOps lidera, Architect revisa. Implementador foca nos adversarial tests e release.

---

## Metricas de Sucesso (North Star)

| Metrica | Baseline (v3.7) | Target (v4.0) | Como Medir |
|---------|-----------------|---------------|------------|
| Caminhos errados possiveis | 17 | 0 criticos, ≤3 medium | Audit checklist |
| State corruption under parallel | Possivel | Impossivel | Stress test: 4 workers, 50 tasks |
| Budget overshoot max | N × max_task_cost | ≤ 1 × max_task_cost | Budget test com 4 parallel tasks |
| QA false positive rate | Unknown (score/verdict mismatch) | 0% | QA coherence test |
| Mean time to recover (crash) | Manual inspection | Auto-resume, ≤30s | Kill -9 durante execucao + resume |
| Config hardcoded values | 12 | 0 | Grep for magic numbers |
| Test coverage (campaigns) | 18 (functional) | 18 + 6 (adversarial) | Campaign count in campaigns/ |

---

## Version Strategy

```
v3.5  (legacy)   — Pre-AURUM, functional mas sem intelligence layer
v3.6  (legacy)   — 12 incisoes AURUM, introduziu 4 bugs novos
v3.7  (CURRENT)  — 4 bug fixes, advisory 3-guards, pheromone persistence, worker resilience
v3.8  (Sprint 1) — Critical fixes: state atomicity, budget safety, QA coherence, file registry
v3.9  (Sprint 2) — High fixes: immune learning, advisory hard veto, pheromone locking, wall-clock
v4.0  (Sprint 3) — Config externalization + adversarial test suite
v4.0  = SHIP-READY — Formal release, versioned config, documented thresholds
```

Cada versao e justificavel:
- **v3.7** (baseline): "QA calibrado, advisory com 3 guards, workers resilientes, pheromone persistente"
- **v3.8**: "Concurrency bugs que causam data loss foram eliminados (state, budget, file registry)"
- **v3.9**: "Sistema aprende com falhas (immune promotion), pode cancelar execucao (advisory hard veto), e respeita wall-clock"
- **v4.0**: "Todos os parametros configuraveis, testados adversarialmente, zero hardcoded values"

---

## Sprint 1: Critical Fixes (v3.8)

### Objetivo
Eliminar todas as vulnerabilidades que causam **data loss, budget violation, ou DAG violation** sob execucao paralela.

### Pre-requisito
Criar branch: `fix/stability-v3.8`

---

### S1.1: Atomic State Writes com Version Counter

**Arquivo:** `lib/state.sh`
**Bug:** C1 + C5 — Sem version counter (no optimistic locking). get_ready_tasks() faz O(N×M) reads separados. task_set_status() faz 2 writes separados (status + counters).
**Baseline v3.7:** Lock melhorou (60s + PID check vs 5s force-break). state_write() ja usa temp+mv atomico. Mas sem version counter, sem CAS, sem retry.
**Impacto:** State corruption silenciosa sob parallelismo. Tasks scheduladas antes de deps completarem.

#### O Que Mudar

1. Adicionar campo `_version` ao state.json (integer, incrementa a cada write)
2. Substituir lock por mkdir com `flock` (ou implementar compare-and-swap via version)
3. `state_write()` deve:
   - Ler version atual
   - Aplicar jq filter
   - Incrementar version
   - Write atomico (temp + mv)
   - Se version mudou entre read e write → retry (max 3x)
4. `get_ready_tasks()` deve ser uma UNICA query jq atomica:
   ```bash
   state_read '[
     .tasks | to_entries[] |
     select(
       .value.status == "pending" and
       ([.value.depends_on[]? ] | all(. as $dep |
         $ARGS.named[$dep] == "completed"
       ))
     ) | .key
   ]' --jsonargs $(state_read '.tasks | to_entries[] | select(.value.status == "completed") | .key')
   ```
5. `task_set_status()` deve fazer status + counters em UM UNICO state_write:
   ```bash
   state_write '
     .tasks["'$tid'"].status = "'$new_status'" |
     .tasks["'$tid'"].completed_at = "'$ts'" |
     .counters = {
       total: ([.tasks | to_entries[] | .key] | length),
       completed: ([.tasks[] | select(.status == "completed")] | length),
       failed: ([.tasks[] | select(.status == "rejected" or .status == "exhausted" or .status == "dep-failed")] | length),
       running: ([.tasks[] | select(.status == "running")] | length)
     } |
     ._version = (._version + 1)
   '
   ```

#### Acceptance Criteria

- [ ] state.json tem campo `_version` que incrementa monotonicamente
- [ ] Nenhuma chamada a `state_write` seguida de `update_counters` separado
- [ ] `get_ready_tasks()` e uma unica query jq (nao loop com task_get individuais)
- [ ] Lock timeout removido (sem force-break de lock alheio)
- [ ] Retry com backoff se version mismatch (max 3 retries, 100ms backoff)

#### Smoke Test

```bash
# Stress test: 4 parallel writers, 100 updates cada
for i in $(seq 1 4); do
  (for j in $(seq 1 100); do
    state_write ".test_$i = $j" 2>/dev/null
  done) &
done
wait
# Validar: state.json e JSON valido E _version == 400
version=$(jq '._version' state.json)
[[ "$version" -eq 400 ]] && echo "PASS" || echo "FAIL: version=$version"
```

#### Veto Conditions
- VETO se `update_counters()` ainda existir como funcao separada
- VETO se get_ready_tasks faz mais de 1 read ao state file
- VETO se state_write nao tem retry com backoff em caso de version mismatch

---

### S1.2: Atomic Budget Check-and-Deduct

**Arquivo:** `lib/cost.sh`
**Bug:** C2 — Race entre budget_check() e record_cost() permite estouro de N × max_task_cost.
**Impacto:** Blueprint gasta mais do que o limite configurado.

#### O Que Mudar

1. Eliminar `budget_check()` como funcao separada
2. Criar `budget_reserve()` que faz check + deduct atomicamente:
   ```bash
   budget_reserve() {
     local estimated_cost="$1"
     local task_id="$2"

     # Single atomic operation
     local result=$(state_write_and_read '
       if (.budget.limit_usd - .budget.used_usd) >= '$estimated_cost' then
         .budget.used_usd += '$estimated_cost' |
         .budget.reservations["'$task_id'"] = '$estimated_cost' |
         ._version += 1 |
         "RESERVED"
       else
         "INSUFFICIENT"
       end
     ')

     [[ "$result" == "RESERVED" ]] && return 0 || return 1
   }
   ```
3. Criar `budget_reconcile()` que ajusta reserva para custo real:
   ```bash
   budget_reconcile() {
     local task_id="$1"
     local actual_cost="$2"

     state_write '
       .budget.used_usd = (.budget.used_usd - .budget.reservations["'$task_id'"] + '$actual_cost') |
       del(.budget.reservations["'$task_id'"]) |
       ._version += 1
     '
   }
   ```
4. No `orchestrate.sh`, substituir:
   - `budget_check` antes de spawn → `budget_reserve`
   - `record_cost` apos worker → `budget_reconcile`

#### Acceptance Criteria

- [ ] `budget_check()` nao existe mais como funcao publica
- [ ] `budget_reserve()` e atomica (1 state_write)
- [ ] `budget_reconcile()` ajusta diferenca entre estimado e real
- [ ] Budget overshoot maximo = 1 × max_task_cost (ultima task pode exceder se reserva < real)
- [ ] Reservas nao reconciliadas sao tratadas no resume

#### Smoke Test

```bash
# 4 tasks tentam reservar $3 cada com budget de $10
# Resultado esperado: 3 RESERVED, 1 INSUFFICIENT
for i in $(seq 1 4); do
  (budget_reserve "3.00" "task-$i" && echo "RESERVED-$i" || echo "INSUFFICIENT-$i") &
done
wait
used=$(state_read '.budget.used_usd')
echo "Budget used: $used (expected: 9.00)"
```

#### Veto Conditions
- VETO se check e deduct sao operacoes separadas
- VETO se nao tem reconcile para ajustar custo real vs estimado

---

### S1.3: QA Score/Verdict Coherence Validation

**Arquivo:** `lib/qa.sh`
**Bug:** C4 — Score alto + verdict "REJECT" passa como PASS.
**Impacto:** Output com problemas conhecidos pelo QA e aceito pelo sistema.

#### O Que Mudar

1. Apos `parse_verdict()`, adicionar coherence check:
   ```bash
   validate_qa_coherence() {
     local score="$1"
     local verdict_text="$2"  # Raw verdict text from QA
     local derived_verdict="$3"  # What score says (PASS/REWORK/REJECT)

     # Detect contradiction
     if [[ "$derived_verdict" == "PASS" ]] && echo "$verdict_text" | grep -qiE "reject|fail|unacceptable|hallucin"; then
       log_warn "QA COHERENCE VIOLATION: score=$score suggests PASS but verdict text contains rejection language"
       echo "INCOHERENT"
       return 1
     fi

     if [[ "$derived_verdict" == "REJECT" ]] && echo "$verdict_text" | grep -qiE "excellent|perfect|well.done|passes"; then
       log_warn "QA COHERENCE VIOLATION: score=$score suggests REJECT but verdict text contains approval language"
       echo "INCOHERENT"
       return 1
     fi

     echo "COHERENT"
     return 0
   }
   ```
2. Se INCOHERENT → force REWORK (nao PASS, nao REJECT)
3. Injetar feedback: "QA COHERENCE VIOLATION: Score and verdict text contradict. Re-evaluate."
4. Logar evento: `qa_coherence_violation` em events.jsonl

#### Acceptance Criteria

- [ ] Score >= threshold + verdict text com "reject/fail/hallucin" → REWORK (nao PASS)
- [ ] Score < 60 + verdict text com "excellent/perfect" → REWORK (nao REJECT)
- [ ] Evento logado em events.jsonl com score, verdict_text, derived_verdict
- [ ] Incoherence conta como attempt (gasta retry)

#### Smoke Test

```bash
# Simular QA response com score=85 e verdict="REJECT - output has hallucinations"
echo '{"score": 85, "verdict": "REJECT", "feedback": "Output has hallucinations"}' > /tmp/qa-test.json
# validate_qa_coherence deve retornar INCOHERENT
result=$(validate_qa_coherence 85 "REJECT - output has hallucinations" "PASS")
[[ "$result" == "INCOHERENT" ]] && echo "PASS" || echo "FAIL"
```

#### Veto Conditions
- VETO se score sozinho determina verdict sem checar texto
- VETO se incoherence nao gasta retry attempt

---

### S1.4: QA Worker Crash Recovery

**Arquivo:** `lib/qa.sh`
**Bug:** C3 — QA worker crash (exit 2) nao tem recovery. Task fica orfã.
**Impacto:** Task nunca completa, pode bloquear dependentes.

#### O Que Mudar

1. Apos `run_qa()` retornar exit 2:
   ```bash
   if [[ $qa_exit -eq 2 ]]; then
     log_warn "QA worker crashed for $task_id. Falling back to innate immune."

     # Run innate immune as fallback
     if innate_immune_check "$task_id" "$output_path" "$expected_format" "$expected_lines"; then
       log_info "Innate immune PASSED for $task_id (QA skipped)"
       score=70  # Assign conservative passing score
       verdict="PASS_INNATE"
       feedback="QA worker unavailable. Passed innate immune check only. Manual review recommended."

       # Flag for human review
       task_set_field "$task_id" "qa_skipped" "true"
       log_event "qa_fallback" "$task_id" "innate_immune_only"
     else
       log_error "Innate immune FAILED for $task_id after QA crash"
       verdict="REJECT"
       feedback="QA worker crashed AND innate immune failed."
     fi
   fi
   ```
2. Tasks com `qa_skipped=true` devem aparecer no report final como "NEEDS HUMAN REVIEW"
3. Se mais de 30% das tasks tiveram qa_skipped → logar warning critico

#### Acceptance Criteria

- [ ] QA crash (exit 2) → fallback para innate immune (nao task orfã)
- [ ] Innate pass → score=70 + flag `qa_skipped=true`
- [ ] Innate fail → REJECT normal
- [ ] Report final lista tasks com qa_skipped
- [ ] Se >30% qa_skipped → warning no report

#### Smoke Test

```bash
# Simular QA crash: criar mock que retorna exit 2
# Verificar que task nao fica em limbo
# Verificar que fallback para innate immune funciona
```

#### Veto Conditions
- VETO se QA crash deixa task sem status final
- VETO se qa_skipped nao aparece no report

---

### S1.5: File Registry Dependencies Persistence

**Arquivo:** `lib/file_registry.sh`
**Bug:** C6 — File conflict dependencies sao injetadas em temp_state que e deletado. state.json real nunca recebe.
**Impacto:** Write conflicts entre tasks nao sao prevenidos apos wave 1.

#### O Que Mudar

1. Em `generate_execution_waves()`, injetar deps diretamente no state.json real:
   ```bash
   # ANTES (broken):
   # cp "$state_file" "$temp_state"
   # ... inject deps into temp_state ...
   # rm -f "$temp_state"  ← deps perdidas

   # DEPOIS (fixed):
   while IFS= read -r conflict; do
     task_a=$(echo "$conflict" | jq -r '.task_a')
     task_b=$(echo "$conflict" | jq -r '.task_b')

     # Inject directly into real state
     state_write '.tasks["'"$task_b"'"].depends_on = (
       (.tasks["'"$task_b"'"].depends_on // []) + ["'"$task_a"'"] | unique
     )'

     log_event "file_conflict_dep" "$task_b" "depends_on=$task_a (file conflict)"
   done < <(echo "$conflicts" | jq -c '.[]')
   ```
2. Apos injecao, re-validar DAG (ciclos podem ter sido introduzidos)
3. Se ciclo detectado → logar erro + ESCALAR (nao silenciar)

#### Acceptance Criteria

- [ ] File conflict deps estao no state.json real (nao temp file)
- [ ] DAG re-validado apos injecao de deps
- [ ] Se ciclo introduzido → erro explicito (nao deadlock silencioso)
- [ ] Eventos logados para cada dep injetada

#### Smoke Test

```bash
# Blueprint com 2 tasks escrevendo no mesmo arquivo
# Verificar: state.json contem dependencia entre elas
# Verificar: tasks executam sequencialmente (nao paralelo)
```

#### Veto Conditions
- VETO se file conflict deps vivem em temp file
- VETO se DAG nao e re-validado apos injecao

---

### S1.6: Model Override After Budget Guard

**Arquivo:** `lib/routing.sh`
**Bug:** H4 — Per-task model override (linhas 132-136) executa ANTES do budget guard (linhas 138-147). Manifest pode forcar opus em tudo.
**Baseline v3.7:** Comentario no codigo diz "v3.7: prevents epigenetic hints from bypassing budget check" — mas o per-task override AINDA bypassa. Apenas epigenetic hints foram corrigidos.
**Impacto:** Budget guard ineficaz para tasks com model override no manifest.

#### O Que Mudar

1. Mover budget guard para ANTES do per-task override:
   ```bash
   select_model() {
     # STAGE 1 (FIRST): Budget guard — CANNOT BE BYPASSED
     if [[ $budget_remaining_pct -lt 30 ]]; then
       if [[ $blocking_factor -ge 3 ]]; then
         : # Gateway exemption for critical path
       else
         echo "haiku"
         return
       fi
     fi

     # STAGE 2: Per-task override (now budget-safe)
     if [[ -n "$task_model" && "$task_model" != "null" ]]; then
       # Validate model is known
       case "$task_model" in
         haiku|sonnet|opus) echo "$task_model" ;;
         *) log_warn "Unknown model override: $task_model. Using default."; echo "$DEFAULT_MODEL" ;;
       esac
       return
     fi

     # ... rest of selection logic ...
   }
   ```
2. Adicionar validacao de model name (haiku|sonnet|opus only)

#### Acceptance Criteria

- [ ] Budget guard executa ANTES de per-task override
- [ ] Se budget < 30% → haiku forcado (exceto critical path)
- [ ] Model override validado (so aceita haiku|sonnet|opus)
- [ ] Log warning se model override desconhecido

#### Smoke Test

```bash
# Manifest com task_model="opus" + budget < 30%
# Verificar: haiku selecionado (budget guard vence)
```

#### Veto Conditions
- VETO se per-task override pode ignorar budget guard

---

### S1.DONE: Sprint 1 Completion Gate

**Criterios para fechar Sprint 1 e bumpar para v3.8:**

- [ ] Todas as 6 stories com status DONE
- [ ] Todos os smoke tests passando
- [ ] Stress test: 4 parallel workers, 50 tasks, zero state corruption
- [ ] Budget test: 4 parallel tasks, budget nao excede limit + 1 task_cost
- [ ] QA coherence test: score/verdict mismatch detectado 100%
- [ ] Regression: todas as 18 test campaigns existentes ainda passam
- [ ] CHANGELOG atualizado com "v3.8 — Stability: atomic state, budget safety, QA coherence"

---

## Sprint 2: Structural Evolution (v3.9)

### S2.1: Immune Memory Promotion

**Arquivo:** `lib/qa.sh`
**Bug:** H1 — Violacoes gravadas mas nunca promovidas para immune_memory.
**Impacto:** Sistema nao aprende com falhas repetidas.

#### O Que Mudar

1. Apos cada innate immune check, chamar `promote_immune_patterns()`:
   ```bash
   promote_immune_patterns() {
     local immune_events="$RUNTIME_DIR/immune_events.jsonl"
     local immune_memory="$RUNTIME_DIR/immune_memory.jsonl"

     # Count violations by type
     jq -s 'group_by(.violation_type) |
       map({type: .[0].violation_type, count: length}) |
       .[] | select(.count >= 3)' "$immune_events" |
     while IFS= read -r pattern; do
       local vtype=$(echo "$pattern" | jq -r '.type')
       # Add to immune memory if not already present
       if ! grep -q "\"$vtype\"" "$immune_memory" 2>/dev/null; then
         echo "{\"pattern\": \"$vtype\", \"response\": \"flag\", \"promoted_at\": \"$(date -u +%FT%TZ)\", \"occurrences\": $(echo "$pattern" | jq '.count')}" >> "$immune_memory"
         log_event "immune_promotion" "$vtype" "promoted after 3+ occurrences"
       fi
     done
   }
   ```
2. Chamar no final de cada wave (nao de cada task — batch efficiency)
3. Threshold: 3 ocorrencias do mesmo tipo → promover

#### Acceptance Criteria

- [ ] Violacao repetida 3x → adicionada a immune_memory.jsonl
- [ ] Immune memory consultada no innate check de tasks futuras
- [ ] Evento logado para cada promocao
- [ ] Threshold configuravel (default: 3)

---

### S2.2: Advisory Hard Veto + Configurable Thresholds

**Arquivo:** `lib/advisory.sh` + `orchestrate.sh`
**Bug:** H3 — Advisory pode pausar mas nao pode CANCELAR. Thresholds hardcoded.
**Baseline v3.7:** Advisory JA tem 3 guards condicionais (coherence < 5 + wave >= 2 + consecutive low + pass_rate <= 50%). JA pode pausar blueprint via `set_blueprint_status "paused"`. O que FALTA: (1) opcao de cancelamento hard, (2) thresholds configuraveis, (3) report parcial automatico no pause.
**Impacto:** Advisory pausa mas humano precisa intervir pra cancelar. Thresholds nao podem ser tunados por blueprint.

#### O Que Mudar

1. Adicionar `advisory_action: "cancel"` alem de `"pause"`:
   - Se coherence < 3 por 3 waves consecutivas → CANCEL (nao apenas pause)
   - Cancel = set status "cancelled" + gerar report parcial + return 2
2. Externalizar thresholds para manifest ou config:
   ```yaml
   advisory:
     coherence_pause_threshold: 5   # atualmente hardcoded
     coherence_cancel_threshold: 3  # novo
     min_wave_for_pause: 2          # atualmente hardcoded
     pass_rate_floor: 50            # atualmente hardcoded
   ```
3. Gerar report parcial automaticamente quando pause ou cancel
4. Log evento `advisory_pause` ou `advisory_cancel` em events.jsonl

#### Acceptance Criteria

- [ ] Advisory com coherence < 3 por 3 waves → blueprint CANCELADO (nao apenas pausado)
- [ ] Thresholds legiveis de config (fallback para defaults atuais se ausente)
- [ ] Pause e cancel geram report parcial automaticamente
- [ ] Resume possivel com `--resume` flag (apenas para pause, nao cancel)
- [ ] Eventos logados para pause e cancel

---

### S2.3: Pheromone File Locking

**Arquivo:** `lib/pheromone.sh`
**Bug:** H5 — record_pheromone() sem lock. Lost updates sob concorrencia.
**Impacto:** Evidence de routing corrompida.

#### O Que Mudar

1. Usar mesmo mecanismo de lock atomico de S1.1
2. `record_pheromone()` deve adquirir lock antes de read-modify-write
3. `evaporate_pheromones()` deve verificar jq exit code antes de mv

#### Acceptance Criteria

- [ ] record_pheromone usa lock
- [ ] evaporate nao sobrescreve arquivo com output vazio se jq falha
- [ ] Stress test: 4 concurrent record_pheromone → zero lost updates

---

### S2.4: Meta-Loop Wall-Clock Timeout

**Arquivo:** `lib/meta_loop.sh`
**Bug:** H6 — Sem timeout absoluto. Meta-loop pode rodar indefinidamente.
**Impacto:** Blueprint trava sem intervencao humana.

#### O Que Mudar

1. Adicionar `max_wall_clock_seconds` (default: 3600 = 1h)
2. Checar elapsed time antes de cada cycle
3. Se excedido → ESCALATE com report do que foi completado

#### Acceptance Criteria

- [ ] Wall-clock timeout configuravel
- [ ] Timeout → ESCALATE (nao crash)
- [ ] Report parcial gerado antes de exit

---

### S2.5: Token Estimation Context-Aware

**Arquivo:** `lib/context.sh`
**Bug:** H7 — Heuristica de 4 chars/token e 4x off para codigo.
**Impacto:** Context pack de codigo truncado prematuramente.

#### O Que Mudar

1. Detectar tipo de conteudo (code vs prose) baseado em extensao do arquivo
2. Code (.sh, .py, .js, .yaml, .json): 2 chars/token
3. Prose (.md, .txt): 4.5 chars/token
4. Mixed/unknown: 3.5 chars/token (conservador)

#### Acceptance Criteria

- [ ] Estimativa varia por tipo de arquivo
- [ ] Truncation acontece no layer correto (nao em code layers)
- [ ] Test: context pack com 50% code tem estimativa dentro de 20% do real

---

### S2.6: Mandatory Innate Immune Checks

**Arquivo:** `lib/qa.sh` + manifest validation
**Bug:** H8 — expected_format e expected_lines sao opcionais. Default desabilita innate checks.
**Impacto:** Maioria das tasks bypassa innate immune.

#### O Que Mudar

1. Na validacao de manifest, se task nao tem `expected_format`:
   - Inferir de `output` path extension (.md → md, .json → json, .yaml → yaml, .sh → sh)
2. Se task nao tem `expected_lines`:
   - Usar heuristica baseada em description length (short desc → 50 lines, long → 200)
3. Logar warning se nao foi possivel inferir

#### Acceptance Criteria

- [ ] Pelo menos format validation roda para toda task com output path
- [ ] Line count tem default razoavel (nao 0)
- [ ] Warning logado se inferencia falhou

---

### S2.DONE: Sprint 2 Completion Gate

- [ ] Todas as 6 stories com status DONE
- [ ] Immune memory evolui (test com 5 falhas identicas)
- [ ] Advisory pausa blueprint quando degradacao detectada
- [ ] Pheromone stress test passa
- [ ] Meta-loop respeita wall-clock timeout
- [ ] Regression: v3.8 campaigns passam
- [ ] CHANGELOG: "v3.9 — Intelligence: immune learning, advisory veto, pheromone safety"

---

## Sprint 3: Config Externalization & Adversarial Testing (v4.0)

### S3.1: Create formiga.config.yaml

**Arquivos:** Todos os lib/*.sh
**Bug:** P2 — 12 valores hardcoded.
**Impacto:** Impossibilidade de tunar sem editar codigo.

#### O Que Mudar

Criar `.orchestrator/formiga.config.yaml`:

```yaml
# FORMIGA Configuration — v4.0
# All values previously hardcoded in lib/*.sh

orchestration:
  lock_timeout_ms: 5000        # was: 50 * 100ms in state.sh
  kill_timeout_s: 2             # was: hardcoded in parallel.sh
  wall_clock_timeout_s: 3600    # was: missing (Sprint 2)

allometry:
  small_threshold: 8            # was: ALLOMETRY_SMALL in routing.sh
  medium_threshold: 25          # was: ALLOMETRY_MEDIUM in routing.sh
  token_budget_base: 60000      # was: hardcoded in routing.sh
  token_budget_exponent: 0.75   # was: hardcoded in routing.sh
  token_budget_floor: 3000      # was: hardcoded in routing.sh

routing:
  budget_guard_pct: 30          # was: hardcoded in routing.sh:140
  pheromone_threshold: 0.60     # was: hardcoded in routing.sh:182
  failure_rate_threshold: 0.30  # was: hardcoded in routing.sh:90
  retry_rate_threshold: 0.50    # was: hardcoded in routing.sh:97

pheromone:
  evaporation_rate: 0.9         # was: EVAPORATION_RATE in pheromone.sh
  signal_ttl_waves: 2           # was: hardcoded in pheromone.sh
  friction_ttl_waves: 3         # was: hardcoded in pheromone.sh

quorum:
  done_threshold: 0.90          # was: hardcoded in meta_loop.sh
  retry_threshold: 0.70         # was: hardcoded in meta_loop.sh
  reexecute_threshold: 0.40     # was: hardcoded in meta_loop.sh
  disagreement_threshold: 0.40  # was: hardcoded in meta_loop.sh

immune:
  promotion_threshold: 3        # was: hardcoded (Sprint 2)
  demand_signal_threshold: 3    # was: hardcoded in meta_loop.sh

token_estimation:
  code_chars_per_token: 2.0     # was: 4 for everything
  prose_chars_per_token: 4.5    # was: 4 for everything
  mixed_chars_per_token: 3.5    # was: 4 for everything
```

Cada lib/*.sh deve:
1. Ler config no startup: `CONFIG_FILE="${ORCHESTRATOR_DIR}/formiga.config.yaml"`
2. Usar `yq` para extrair valores
3. Fallback para defaults se config ausente (backward compatible)

#### Acceptance Criteria

- [ ] formiga.config.yaml existe com todos os 12+ valores
- [ ] Cada lib usa config (nao hardcoded)
- [ ] Sem config file → defaults identicos a v3.7 (backward compat)
- [ ] Comentarios no YAML explicam cada valor e range valido
- [ ] Validacao no startup: valores fora de range → warning

---

### S3.2: Adversarial Test Suite

**Arquivo:** `.orchestrator/campaigns/test-adversarial-*.yaml`
**Objetivo:** Provar que os fixes funcionam sob condicoes hostis.

#### Campaigns a Criar

1. **test-adversarial-budget.yaml** — 4 tasks tentam estourar budget simultaneamente
2. **test-adversarial-state-race.yaml** — Tasks que completam quase simultaneamente
3. **test-adversarial-qa-incoherent.yaml** — Worker projetado para gerar output que confunde QA
4. **test-adversarial-file-conflict.yaml** — 3 tasks escrevendo no mesmo arquivo
5. **test-adversarial-cascade.yaml** — Task critica falha, valida que TODAS dependentes marcam dep-failed
6. **test-adversarial-immune-bypass.yaml** — Output que tenta passar pelo innate immune

#### Acceptance Criteria

- [ ] 6 adversarial campaigns existem e passam
- [ ] Cada campaign documenta o que testa e o resultado esperado
- [ ] CI-ready: podem ser rodadas com `--auto-approve`

---

### S3.3: Version Manifest & Release Notes

1. Atualizar `VERSION` para `4.0.0`
2. Criar `RELEASE-v4.0.md` com:
   - Changelog desde v3.7
   - Breaking changes (se houver)
   - Migration guide para config
   - Known limitations
3. Tag git: `v4.0.0-stable`

#### Acceptance Criteria

- [ ] VERSION file = 4.0.0
- [ ] RELEASE-v4.0.md com todas as secoes
- [ ] Git tag criada

---

### S3.DONE: Sprint 3 Completion Gate (SHIP GATE)

- [ ] formiga.config.yaml funcional com todos os valores
- [ ] 6 adversarial campaigns passam
- [ ] Zero P0 abertos
- [ ] Zero P1 abertos
- [ ] Score PV: >= 9.0/10
- [ ] RELEASE-v4.0.md completo
- [ ] `v4.0.0-stable` taggeado

---

## Appendix A: Bug-to-Story Traceability

| Bug ID | Severity | Story | Status |
|--------|----------|-------|--------|
| C1 | CRITICAL | S1.1 | PENDING |
| C2 | CRITICAL | S1.2 | PENDING |
| C3 | CRITICAL | S1.4 | PENDING |
| C4 | CRITICAL | S1.3 | PENDING |
| C5 | CRITICAL | S1.1 | PENDING |
| C6 | CRITICAL | S1.5 | PENDING |
| H1 | HIGH | S2.1 | PENDING |
| H2 | HIGH | (addressed by S2.6 indirectly) | PENDING |
| H3 | HIGH | S2.2 | PENDING |
| H4 | HIGH | S1.6 | PENDING |
| H5 | HIGH | S2.3 | PENDING |
| H6 | HIGH | S2.4 | PENDING |
| H7 | HIGH | S2.5 | PENDING |
| H8 | HIGH | S2.6 | PENDING |
| P2-hardcoded | MEDIUM | S3.1 | PENDING |

---

## Appendix B: File Change Matrix

| File | S1.1 | S1.2 | S1.3 | S1.4 | S1.5 | S1.6 | S2.1 | S2.2 | S2.3 | S2.4 | S2.5 | S2.6 | S3.1 |
|------|------|------|------|------|------|------|------|------|------|------|------|------|------|
| state.sh | **X** | | | | | | | | | | | | X |
| cost.sh | | **X** | | | | | | | | | | | X |
| qa.sh | | | **X** | **X** | | | **X** | | | | | **X** | X |
| file_registry.sh | | | | | **X** | | | | | | | | |
| routing.sh | | | | | | **X** | | | | | | | X |
| pheromone.sh | | | | | | | | | **X** | | | | X |
| meta_loop.sh | | | | | | | | | | **X** | | | X |
| context.sh | | | | | | | | | | | **X** | | X |
| advisory.sh | | | | | | | | **X** | | | | | |
| orchestrate.sh | X | X | | | X | | | X | | | | | |

---

## Appendix C: Fresh Context Loading Instructions

Para implementar este epic em uma sessao fresh do Claude Code:

```
SETUP (uma vez por sessao):
  1. Ler este documento: D:\athena-os\.orchestrator\docs\EPIC-STABILITY-v1.md
  2. Ler secoes: Guardrails Obrigatorios + Team Assignments
  3. Identificar qual Sprint esta ativo (checar status das stories)
  4. Identificar proxima story PENDING

PARA CADA STORY (loop):
  a. GR-1: Criar branch → git checkout -b fix/S{X.Y}-{nome}
  b. Ler o arquivo indicado em "Arquivo:"
  c. GR-2 ANTES: Rodar blueprint de referencia, salvar output baseline
  d. Implementar as mudancas descritas em "O Que Mudar"
  e. GR-2 DEPOIS: Rodar mesmo blueprint, comparar com baseline
  f. Rodar smoke test especifico da story
  g. Validar contra "Acceptance Criteria" (todos os checkboxes)
  h. Verificar "Veto Conditions" (nenhum VETO ativo)
  i. GR-3: Commit + merge → so entao iniciar proxima story
  j. Atualizar status da story neste documento (PENDING → DONE)

SPRINT 2+: ANTES de implementar, consultar @architect para design approval.
SPRINT 3: @devops lidera S3.1. @architect revisa config schema.

AO FINAL DO SPRINT:
  1. Rodar "Completion Gate" (todos os checkboxes do S{X}.DONE)
  2. Chamar Pedro Valerio para audit: /squad-creator-pro:agents:pedro-valerio
     → *audit sprint-{X} regressao
  3. Se audit PASS → bumpar VERSION e tagger
  4. Se audit FAIL → corrigir issues antes de avancar
```

### Protocolo de Rollback

```
SE smoke test falha apos implementar story:
  1. git stash (ou git checkout -- .)
  2. Verificar se o problema e do fix ou do teste
  3. Se do fix: git checkout main && git branch -D fix/S{X.Y}-{nome}
  4. Repensar abordagem, criar nova branch, tentar novamente
  5. Se falhar 2x com mesma abordagem: mudar estrategia (Anti-Loop)
  6. Se 3a abordagem falhar: escalar para humano com diagnostico

SE regressao detectada no audit do sprint:
  1. Identificar qual story introduziu a regressao (git bisect)
  2. Reverter a story: git revert {commit}
  3. Re-implementar com fix da regressao
  4. Re-rodar audit completo
```

---

*"O que nao tem responsavel sera feito por ninguem."*
*"Nada volta num fluxo. NUNCA."*
*"Show!"*
