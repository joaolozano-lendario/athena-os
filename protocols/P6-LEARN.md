# P6: LEARN — Protocolo de Aprendizado Pós-Execução

> **"O sistema que não aprende com suas execuções está condenado a repetir seus erros."**

---

## PROPÓSITO

P6: LEARN é o protocolo de meta-cognição que executa **após** completar qualquer Blueprint. Seu objetivo é:

1. Consumir dados de execução da FORMICA
2. Extrair lições aprendidas
3. Promover padrões para conhecimento persistente
4. Calibrar estimativas de confiança
5. Melhorar o sistema continuamente

---

## TRIGGER

P6 executa automaticamente:
- Após G5 passar em `/athena:execute` (conclusão de blueprint FORMICA)
- Pode ser invocado manualmente via `/ATHENA:tasks:learn`

---

## INPUTS

```yaml
inputs:
  # Blueprint recém executado
  blueprint:
    id: "{BP-ID}"
    title: ""
    target_project: ""
    nature: ""
    complexity: ""

  # Dados de execução (gerados por F3)
  formica_handoff:
    path: "runtime/{bp-id}/reports/handoff.yaml"
    contains: "results, friction, cost_analysis, pattern_candidates, epigenetic_updates"

  # Diagnóstico estruturado (consumido por P6)
  formica_diagnostic:
    path: "runtime/{bp-id}/reports/diagnostic.json"
    contains: "score_distribution, cost_breakdown, friction_analysis, systemic_issues"

  # Marcadores epigenéticos (verificação de consistência)
  epigenetics:
    path: ".orchestrator/memory/epigenetic-markers.yaml"
    purpose: "Verify markers updated correctly by F3"

  # Padrões candidatos (staging area)
  pattern_candidates:
    path: ".orchestrator/memory/pattern-candidates.yaml"
    purpose: "Evaluate for promotion to pattern_library"
```

---

## PROCESSO

### Step 1: Consumir Handoff de F3

```yaml
action: "Ler dados de execução do Blueprint via handoff.yaml"

read_handoff:
  file: "runtime/{bp-id}/reports/handoff.yaml"

extract:
  results:
    - total_tasks
    - passed_tasks
    - failed_tasks
    - first_pass_rate
    - total_cost_usd
    - duration_s

  friction:
    - top_causes (array de {cause, count})
    - most_affected_worker
    - trend (increasing|decreasing|stable)

  cost_analysis:
    - by_type (worker, qa, advisory, retries, meta_report)
    - by_worker (implementer, analyst, architect, writer)

  pattern_candidates:
    - array of {pattern, confidence, evidence_count, action}

  epigenetic_updates:
    - array of {marker, old_value, new_value, reason}
```

### Step 2: Consumir Diagnóstico de F3

```yaml
action: "Ler diagnóstico estruturado do Blueprint via diagnostic.json"

read_diagnostic:
  file: "runtime/{bp-id}/reports/diagnostic.json"

extract:
  score_distribution:
    - min, max, avg, median, p95

  cost_breakdown:
    - per_task
    - per_wave
    - cost_efficiency (cost_per_passed_task)

  friction_analysis:
    - major_causes (top 3)
    - root_causes (systemic vs one-off)
    - worker_type_impact

  systemic_issues:
    - documented problems affecting multiple tasks
    - recommendations for next blueprint
```

### Step 3: Verificar Marcadores Epigenéticos

```yaml
action: "Validar atualização correta dos marcadores por F3"

file: ".orchestrator/memory/epigenetic-markers.yaml"

verification:
  - All new markers have 2+ blueprint evidence?
    └─ Confidence: >= 0.7 required

  - No multiplier > 3.0? (anomaly detection)
    └─ If found: log warning + manual review flag

  - blueprint_count incremented?
    └─ Should = previous + 1

  - last_updated timestamp reflects current blueprint?
    └─ Verify timestamp matches blueprint execution time

output:
  if_anomaly_detected:
    - Log: "EPIGENETIC ANOMALY: {description}"
    - Action: Manual review required before promoting patterns
```

### Step 4: Avaliar O Que Funcionou

```yaml
action: "Identificar o que foi bem"

questions:
  - "Qual foi a taxa de sucesso? (first_pass_rate)"
  - "Quais worker types tiveram melhor performance?"
  - "Qual foi a tendência de friction? (decreasing = melhorando)"
  - "Adaptações do Advisory tiveram impacto positivo?"

output:
  what_worked:
    success_metrics: []
    effective_patterns: []
    good_decisions: []
    adaptive_moments: []
```

### Step 5: Identificar Dificuldades

```yaml
action: "Analisar o que foi difícil"

questions:
  - "Quais foram as top friction causes?"
  - "Qual worker type teve mais retries?"
  - "Custos comparados com estimativa?"
  - "Waves que tiveram mais problemas?"

output:
  difficulties:
    top_friction_causes: []  # from handoff.friction.top_causes
    cost_overruns: []
    model_escalations: []
    cascade_failures: []
```

### Step 6: Extrair Padrões

```yaml
action: "Identificar padrões emergentes para promoção"

source:
  - handoff.pattern_candidates (F3 staging)
  - friction_analysis (systemic patterns)
  - epigenetic_updates (cross-blueprint markers)

output:
  pattern_candidates: []
  anti_pattern_candidates: []
```

### Step 7: Pattern Promotion Workflow

```yaml
action: "Avaliar padrões candidatos para promoção"

for_each_pattern_in pattern_candidates:

  evaluate:
    # PROMOTION THRESHOLD
    if confidence >= 0.7 AND evidence_count >= 3:
      action: "PROMOTE to pattern_library"

      steps:
        1. Read pattern from pattern-candidates.yaml
        2. Write to observability/pattern_library.yaml
           └─ Add to patterns[] array with id, classification, validation
        3. Update metrics.total_patterns
        4. Log: "Pattern promoted: {name} (confidence: {conf})"
        5. Remove from pattern-candidates.yaml

    # INSUFFICIENT EVIDENCE
    elif evidence_count < 3:
      action: "WAIT for more evidence"

      steps:
        1. Keep in pattern-candidates.yaml
        2. Increment times_observed counter
        3. Log: "Pattern staging: {name} ({evidence_count}/3 evidence)"

    # LOW CONFIDENCE
    elif confidence < 0.7:
      action: "REJECT and document reason"

      steps:
        1. Log: "Pattern rejected: {name} (confidence: {conf} < 0.7)"
        2. Note: "Low confidence suggests inconsistent evidence"
        3. Remove from pattern-candidates.yaml
        4. Consider: if confidence was 0.65-0.69, may retry after more runs

output:
  promoted_patterns: ["PAT-XXX: {name}"]
  staging_patterns: ["Pattern {name}: {evidence_count}/3"]
  rejected_patterns: ["Pattern {name}: confidence too low"]
```

### Step 8: Epigenetic Marker Verification

```yaml
action: "Validar marcadores epigenéticos atualizados por F3"

file: ".orchestrator/memory/epigenetic-markers.yaml"

verify:
  structure:
    - budget_adjustments: {}
    - qa_overrides: {}
    - model_hints: {}
    - blueprint_count: (should be incremented)
    - last_updated: (should match execution time)
    - blueprint_history: (should include new bp-id)

  anomaly_detection:
    - LOOP each marker in all three dicts:
      - if value.multiplier > 3.0:
          └─ FLAG: "Multiplier anomaly: {marker} = {value} (>3.0)"
      - if value.confidence > 1.0:
          └─ FLAG: "Confidence anomaly: {marker} = {value} (>1.0)"
      - if value.evidence_count > 20:
          └─ WARNING: "High evidence count suggests over-fit"

output:
  if_anomalies_found:
    - List all anomalies
    - Action: "Manual review required"
    - Impact: "Pattern promotion halted until reviewed"

  if_clean:
    - Confirm: "Epigenetics updated correctly"
    - Proceed to pattern promotion
```

### Step 9: Coletar Dados da Execução

```yaml
action: "Compilar dados da execução recém concluída"

collect:
  - Total time (from handoff.duration_s)
  - Tasks completed / total (from handoff.results)
  - Cost vs estimate (from handoff.results.cost_vs_estimate)
  - Friction trend (from handoff.friction.trend)
  - Waves completed (from handoff.waves.total)
  - Advisory runs (from handoff.waves.advisory_runs)
```

### Step 10: Calibrar Confiança

```yaml
action: "Comparar confidence estimado vs realidade"

compare:
  - Blueprint complexity estimate vs actual (first_pass_rate)
  - Cost estimate vs actual (cost_vs_estimate)
  - Duration estimate vs actual

calibration:
  if_cost_overrun > 20%:
    adjustment: "Aumentar cost estimate em próximos blueprints similares"

  if_first_pass_rate < 60%:
    adjustment: "Considerar mais retries na estimativa de tempo"

  if_worker_failures > 30%:
    adjustment: "Aumentar context budget ou usar modelo maior"

output:
  calibration_insight:
    accuracy: "{estimate_delta}%"
    adjustment: "{recommendation}"
```

### Step 11: Gerar Lições

```yaml
action: "Cristalizar lições aprendidas"

template:
  - lesson: "{descrição da lição}"
    context: "{quando se aplica}"
    evidence: "{de onde veio — friction, cost, pattern}"
    applicable_to: "{nature ou worker_type específico}"

output:
  lessons_learned: []
```

### Step 12: Atualizar execution_log

```yaml
action: "Append entry to observability/execution_log.yaml"
file: "observability/execution_log.yaml"
location: "executions[] (append new entry)"

entry_format:
  - id: "EXEC-{YYYY-MM-DD}-{NNN}"
    blueprint_id: "{BP-ID}"
    title: "{title}"
    target_project: "{path}"
    started_at: "{date}"
    completed_at: "{date}"
    status: "COMPLETED|PARTIAL|FAILED"

    execution_summary:
      duration_s: {N}
      tasks:
        total: {N}
        passed: {N}
        failed: {N}
      first_pass_rate: 0.XX
      cost_usd: 0.XX
      cost_vs_estimate: 1.XX

    formica_telemetry:
      waves_executed: {N}
      waves_with_advisory: {N}
      friction_trend: "increasing|decreasing|stable"
      top_friction_causes: ["{cause1}", "{cause2}"]
      model_escalations_count: {N}

    phases_executed:
      P0_REFLECT: true|false
      P1_DECODE: true|false
      P2_ARCHITECT: true|false
      P3_FRAGMENT: true|false
      P4_CRYSTALLIZE: true|false
      P5_EXECUTE: false  # Deprecated, use P1-P4 + FORMICA (F0-F3)
      F0_INGEST: true|false
      F1_PREPARE: true|false
      F2_EXECUTE: true|false
      F3_SYNTHESIZE: true|false
      P6_LEARN: true

    genius:
      nature_detected: ["{NATURE}"]
      kits_used: ["{KIT}"]

    lessons:
      - "{lesson 1}"
      - "{lesson 2}"

    patterns_promoted:
      - id: "PAT-XXX"
        name: "{name}"
        confidence: 0.XX

    epigenetic_updates:
      - marker: "{marker}"
        change: "{old} → {new}"
        reason: "{reason}"
```

Also update `observability/pattern_library.yaml` if padrões foram promovidos:
- Add to `patterns[]` para success patterns
- Add to `anti_patterns[]` para anti-patterns
- Update `metrics.total_patterns` count

### Step 13: Atualizar STATE.yaml

```yaml
action: "Minimal STATE update"
file: "STATE.yaml"

updates:
  current_session.last_completed_blueprint: "{BP-ID}"
  current_session.current_phase: "IDLE"
  current_session.active_blueprint: null
  active_work.status: "IDLE"
  system.last_updated: "{date}"

NEVER write project details to STATE.yaml.
Project details go to observability/project-memory/{slug}.yaml
```

### Step 14: AURUM Feedback (Conditional)

```yaml
condition: "D:/cognitive-refinery directory exists"

IF available:
  Write YAML file to: D:/cognitive-refinery/00-inbox/feedback/athena/feedback-{BP-ID}-{date}.yaml

  Content:
    type: feedback
    source_system: "ATHENA"
    blueprint_id: "{BP-ID}"
    nature_code: "{NATURE}"
    exports_consumed:
      - id: "{EXPORT-ID}"
        effectiveness: effective|partial|not_helpful
    lessons:
      - "{lesson}"
    patterns:
      - "{pattern}"
    timestamp: "{ISO date}"

IF not available:
  Skip silently. No local fallback needed.
```

### Step 15: Sugerir Melhorias

```yaml
action: "Propor melhorias para o sistema"

consider:
  - Novos templates necessarios?
  - Ajustes em protocols (P3 worker fields, P4 taxonomy)?
  - Novas lenses uteis?
  - Personas a adicionar?
  - FORMICA adjustments (allometry, advisory, model hints)?

output:
  improvement_suggestions: []
```

---

## OUTPUTS

```yaml
P6_output:
  execution_summary:
    blueprint_id: ""
    status: "COMPLETED"
    total_time: ""
    success_rate: 0.0
    cost_usd: 0.0

  formica_metrics:
    waves_executed: 0
    friction_trend: "stable"
    top_causes: []
    model_escalations: 0

  what_worked:
    key_wins: []
    effective_workers: []
    good_decisions: []

  what_struggled:
    friction_causes: []
    failed_assumptions: []

  patterns_promoted:
    count: 0
    promoted: []
    staging: []

  lessons_learned:
    - lesson: ""
      applicable_to: ""

  calibration:
    cost_accuracy: 0.0
    adjustment_needed: ""

  knowledge_updates:
    execution_log: "updated"
    pattern_library: "N patterns promoted"
    epigenetic_markers: "updated"

  improvement_suggestions: []
```

---

## GATE: G6

**Critério:** Aprendizado capturado e sistema atualizado

**Pass indicators:**
- Execution log atualizado com F3 telemetry
- Pelo menos 1 lesson documented
- Patterns avaliados (promovidos ou rejeitados)
- Epigenetics verificados (anomalias detectadas ou confirmadas clean)
- Calibração realizada

**Fail indicators:**
- Nenhum aprendizado capturado
- Sistema não atualizado
- Handoff/diagnostic não processados

**Ação se FAIL:** Raro — P6 é sobre documentar, não pode realmente "falhar". Reprocessar em nova sessão se necessário.

---

## INTEGRAÇÃO COM STATE.yaml

Após P6 completo, atualizar STATE.yaml (minimal update only):

```yaml
current_session:
  active_blueprint: null
  current_phase: "IDLE"
  last_completed_blueprint: "{BP-ID}"

active_work:
  status: "IDLE"

system:
  last_updated: "{date}"
```

Also update `observability/blueprints-archive.yaml` if this was a new blueprint.

NEVER write project details, execution history, or metrics to STATE.yaml.
Those go to their respective files in `observability/`.

---

## FEEDBACK LOOP

P6 alimenta P0 da próxima execução:

```
P6 (atual) ───► execution_log ───► P0 (próxima)
            ├─► pattern_library ───┘
            ├─► epigenetic-markers ─┘
            └─► lessons_learned ────┘
```

Este loop é o que torna ATHENA um sistema que **aprende e melhora continuamente**.

---

## EXEMPLO

### Após Blueprint FORMICA v2.0 Execution

```yaml
P6_output:
  execution_summary:
    blueprint_id: "BP-2026-02-16-003"
    status: "COMPLETED"
    total_time: "32m25s"
    success_rate: 0.90
    cost_usd: 3.42

  formica_metrics:
    waves_executed: 9
    friction_trend: "decreasing"
    top_causes: ["size_constraint_violation", "incomplete_output"]
    model_escalations: 2

  what_worked:
    - "Wave-based parallel execution reduced total time 40%"
    - "Advisory between waves caught and corrected 3 potential failures"
    - "Implementer worker type performed well with proper context"

  what_struggled:
    - "size_constraint_violation: expected_lines estimates 30% low"
    - "Architect tasks consumed 3x budgeted tokens"

  patterns_promoted:
    - PAT-017: "Implementer line-count calibration"
      confidence: 0.82
      evidence_count: 4

  lessons_learned:
    - lesson: "Implementer tasks need +30% line budget"
      applicable_to: "implementer worker type"
      evidence: "4 tasks failed size constraint with identical pattern"

  epigenetic_updates:
    - marker: "implementer.expected_lines_multiplier"
      change: "1.0 → 1.3"
      reason: "4 overruns from 20 implementer tasks (20% failure rate)"

  improvement_suggestions:
    - "Tighten implementer line limits in checkpoint-map template"
    - "Consider sonnet-default for architect tasks (currently haiku failing 40%)"
```

---

## COMANDOS

Invocação manual:
```
/ATHENA:tasks:learn
```

Invocação após execução FORMICA:
```
P6 executa automaticamente após F3-SYNTHESIZE completa com sucesso
```

---

*ATHENA OS 3.1 — P6: LEARN*
*"O aprendizado contínuo transforma execução em excelência."*
