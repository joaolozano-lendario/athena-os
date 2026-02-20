# ATHENA: Learn

Executa o protocolo **P6: LEARN** — aprendizado pos-execucao.

---

## TRIGGER

Este comando foi invocado. Execute P6: LEARN.

---

## INSTRUÇÕES

### 1. IDENTIFICAR BLUEPRINT

Se Blueprint recente na conversa, usar esse.
Se nao, ler `STATE.yaml` → `current_session.last_completed_blueprint`.
Se nenhum encontrado, perguntar ao operador.

### 2. COLETAR DADOS

Compilar informacoes sobre a execucao:
- Tempo por fase
- Gates que passaram/falharam
- Decisoes tomadas
- Dificuldades encontradas

### 3. AVALIAR + IDENTIFICAR

- O que funcionou bem? (approaches, lenses, personas)
- Onde travou? (bottlenecks, wrong assumptions, surprises)
- Padroes de sucesso a documentar?
- Anti-patterns a evitar?

### 4. ESCREVER EXECUTION LOG

**File:** `observability/execution_log.yaml`
**Action:** Append new entry to `executions[]`

```yaml
- id: "EXEC-{YYYY-MM-DD}-{NNN}"
  blueprint_id: "{BP-ID}"
  title: "{title}"
  target_project: "{path}"
  started_at: "{date}"
  completed_at: "{date}"
  status: "COMPLETED|PARTIAL|FAILED"
  execution_method: "{how}"
  phases_executed:
    P0_REFLECT: true|false
    P1_DECODE: true|false
    P2_ARCHITECT: true|false
    P3_FRAGMENT: true|false
    P4_CRYSTALLIZE: true|false
    P5_EXECUTE: true|false
    P6_LEARN: true
  metrics:
    tasks_completed: N
    tasks_total: N
  genius:
    nature_detected: ["{NATURE}"]
  lessons:
    - "{lesson}"
  patterns_discovered:
    - "{pattern}"
```

Update `metrics_summary` counts at bottom of file.

### 5. ESCREVER PATTERN LIBRARY (se novos padroes)

**File:** `observability/pattern_library.yaml`
**Action:** Append to `patterns[]` or `anti_patterns[]`

For success patterns:
```yaml
- id: "PAT-{NNN}"
  name: "{name}"
  classification:
    domain: "{NATURE}"
    type: "SUCCESS"
  discovery:
    discovered_in: "{BP-ID}"
  content:
    description: "{what}"
    when_to_apply: "{when}"
    how_to_apply: "{how}"
  validation:
    confidence: 0.0-1.0
    times_applied: 1
```

### 6. ESCREVER AURUM FEEDBACK (condicional)

**Condition:** `D:/cognitive-refinery` exists
**File:** `D:/cognitive-refinery/00-inbox/feedback/athena/feedback-{BP-ID}-{date}.yaml`

```yaml
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
timestamp: "{date}"
```

If AURUM offline, skip silently.

### 7. ATUALIZAR STATE.yaml (minimal)

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

### 8. APRESENTAR RESUMO

```markdown
## P6: LEARN — Aprendizado Capturado

**Blueprint:** {BP-ID} | **Status:** {COMPLETED/PARTIAL}

### Licoes
1. {licao}

### Padroes
- {padrao}

### Updates
- execution_log.yaml: entry appended
- pattern_library.yaml: {N} patterns added
- AURUM feedback: {written|skipped}
- STATE.yaml: reset to IDLE
```

### 9. SOLICITAR FEEDBACK

"Como voce avalia esta execucao? (1-5)"

---

*P6: LEARN | ATHENA OS v3.1.0*
