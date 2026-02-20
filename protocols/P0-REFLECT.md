# P0: REFLECT — Protocolo de Reflexão Pré-Execução

> **"Antes de agir, pensar. Antes de pensar, refletir sobre como pensar."**

---

## PROPÓSITO

P0: REFLECT é o protocolo de meta-cognição que executa **antes** de iniciar qualquer Blueprint. Seu objetivo é:

1. Consultar execuções anteriores
2. Detectar a natureza do projeto
3. Ativar configuração cognitiva ideal
4. Antecipar riscos e adaptar approach

---

## TRIGGER

P0 executa automaticamente:
- Antes de iniciar `/ATHENA:tasks:forge-blueprint`
- Pode ser invocado manualmente via `/ATHENA:tasks:reflect`

---

## INPUTS

```yaml
inputs:
  # Do execution_log.yaml
  last_executions:
    count: 5
    fields: [blueprint_id, nature, lessons, patterns]

  # Do pattern_library.yaml
  patterns:
    relevant_to: "{nature detectada}"
    status: "VALIDATED"

  # Do operador
  current_request:
    raw_intent: "{o que o operador pediu}"
    context_provided: "{contexto adicional}"

  # Do STATE.yaml
  system_state:
    active_work: null  # deve estar IDLE
    last_blueprint: "{referência}"
```

---

## PROCESSO

### Step 1: Carregar Contexto Historico

```yaml
action: "Read observability/execution_log.yaml"
extract_from: "executions[] (last 5 entries)"
fields:
  - lessons
  - patterns_discovered
  - genius.nature_detected
  - status
```

Concrete: Read `observability/execution_log.yaml`, extract last 5 entries from `executions[]`.
If empty, this is the first execution — proceed without historical context.

### Step 1.5: Consultar AURUM (Conditional)

```yaml
condition: "D:/cognitive-refinery directory exists"

IF available:
  1. Read .claude/aurum-connector.yaml (paths + domain mapping)
  2. Map nature_code → domains via nature_to_domain_map
  3. Read matching files from knowledge/aurum/{lenses|skills|pills|patterns}/
  4. Load top 3 most relevant into context

IF not available:
  Continue without AURUM. Check knowledge/aurum/ for locally cached exports.
```

Note: Full AURUM logic is in `rules/aurum-integration.md` (auto-loaded).

### Step 2: Detectar Natureza

```yaml
action: "Executar Nature Detection no current_request"

process:
  1. Analisar keywords
  2. Identificar objetivo
  3. Prever artefatos
  4. Determinar nature code

output:
  nature_detected: "COPY|ARCH|META|DATA|PROD|BRAND|LEARN|CODE"
  confidence: 0.0-1.0
  secondary_natures: []
```

### Step 3: Verificar Similaridade

```yaml
action: "Comparar com execuções anteriores"

questions:
  - "Este request é similar a algum anterior?"
  - "Que lições daquele se aplicam aqui?"
  - "Que erros evitar desta vez?"

output:
  similar_blueprints: []
  applicable_lessons: []
  risks_from_history: []
```

### Step 4: Carregar Cognitive Kit

```yaml
action: "Ativar kit baseado na nature detectada"

process:
  1. Carregar kits/{NATURE}.yaml
  2. Montar dream_team
  3. Identificar domain_lenses relevantes
  4. Carregar anti_patterns a evitar

output:
  kit_loaded: "{nature}"
  dream_team: ["{persona_1}", "{persona_2}", ...]
  active_lenses: ["{lens_1}", "{lens_2}", ...]
  anti_patterns_to_avoid: []
```

### Step 5: Antecipar Riscos

```yaml
action: "Identificar onde pode travar"

based_on:
  - Historical blockers
  - Nature-specific challenges
  - Current request complexity

output:
  anticipated_risks: []
  preemptive_mitigations: []
```

### Step 6: Formular Perguntas Preventivas

```yaml
action: "Identificar ambiguidades antes de começar"

questions:
  - "O que não está claro no request?"
  - "Que suposições estou fazendo?"
  - "O que preciso clarificar com operador?"

output:
  clarification_questions: []
  assumptions_to_validate: []
```

### Step 7: Adaptar Parâmetros

```yaml
action: "Ajustar configuração baseado em reflexão"

adaptations:
  - Gate criteria específicos para este nature
  - Lentes a priorizar
  - Personas a consultar em cada fase
  - Checkpoints adicionais se complexidade alta

output:
  adapted_parameters:
    gates: {}
    lenses_priority: []
    consultation_points: []
    extra_checkpoints: []
```

---

## OUTPUTS

```yaml
P0_output:
  nature_detected: ""
  confidence: 0.0

  kit_activated:
    name: ""
    dream_team: []
    lenses: []

  historical_context:
    similar_blueprints: []
    applicable_lessons: []
    patterns_to_apply: []

  risk_assessment:
    anticipated_risks: []
    mitigations: []

  clarifications_needed:
    questions: []
    assumptions: []

  adapted_config:
    gates: {}
    checkpoints: []
    special_considerations: []

  ready_to_proceed: true|false
  blockers_if_not_ready: []
```

---

## GATE: G0

**Critério:** Reflexão completa e sistema pronto para iniciar

**Pass indicators:**
- Nature detectada com confidence > 0.5
- Kit carregado apropriadamente
- Nenhum blocker crítico identificado
- Clarificações resolvidas ou documentadas

**Fail indicators:**
- Nature incerta (confidence < 0.5)
- Clarificações críticas pendentes
- Blocker identificado sem mitigação

**Ação se FAIL:** Resolver antes de prosseguir para P1

---

## INTEGRAÇÃO COM STATE.yaml

Após P0 completo, atualizar STATE.yaml (minimal update only):

```yaml
current_session:
  active_blueprint: "{new BP-ID}"
  current_phase: "P1_DECODE"

active_work:
  status: "FORGING"

system:
  last_updated: "{date}"
```

Do NOT write genius_config, observability tracking, or execution details to STATE.
Those are ephemeral to the current session context.

---

## EXEMPLOS

### Exemplo: Request de Copywriting

```yaml
request: "Criar landing page para curso de produtividade"

P0_output:
  nature_detected: "COPY"
  confidence: 0.85
  secondary: ["LEARN", "PROD"]

  kit_activated:
    name: "COPY"
    dream_team: ["schwartz", "halbert", "hopkins"]
    lenses: ["awareness", "sophistication", "big_idea"]

  similar_blueprints:
    - BP-2026-01-10-005: "Landing page curso finanças"
      lesson: "Começar com awareness level, não feature"

  clarifications_needed:
    - "Qual awareness level do público-alvo?"
    - "Nível de sofisticação do mercado de produtividade?"
```

---

## COMANDOS

Invocação manual:
```
/ATHENA:tasks:reflect
```

---

*ATHENA OS 3.1 — P0: REFLECT*
*"Reflexão estruturada é preparação inteligente."*
