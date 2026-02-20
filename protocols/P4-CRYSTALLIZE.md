# P4: PROTOCOLO DE CRISTALIZACAO

> Transformar em artefatos prontos para exportar

**Versao:** 2.0.0
**Gate de Saida:** G4 - O Blueprint e auto-contido e transferivel?
**Referencia:** docs/architecture/02-PROTOCOLS.md

---

## Objetivo

Consolidar todos os outputs anteriores em artefatos finais, prontos para exportacao e execucao:
- Blueprint Operacional
- Activation Prompt (opcional)
- Taxonomy Config (output routing)
- Checkpoint Map (FORMICA-compatible)
- Metadata

Garantir que o blueprint gerado pelo P3 seja enriquecido com:
- Campos FORMICA (worker, model, output, context_files, etc.)
- Mapeamento de outputs (quem produz, onde vai)
- Estrutura de runtime (telemetria, relatórios, artefatos)

---

## Entrada

- Intent Specification (P1)
- Execution Architecture (P2)
- Checkpoint Map (P3)

---

## Saida

- `BLUEPRINT.md` - Documento mestre
- `ACTIVATION.md` - Prompt de ativacao (opcional, preservado para referência humana)
- `taxonomy-config.yaml` - Configuracao de outputs e routing
- `checkpoint-map.yaml` - Mapa de execução FORMICA-compatible
- `_metadata.yaml` - Metadados do pacote
- Gate G4 PASSED

---

## Processo de Execucao

### Passo 4.1: Consolidacao de Artefatos

Reunir todos os outputs anteriores:

```yaml
artifacts_to_consolidate:
  - source: "outputs/intent-spec.yaml"
    target: "Blueprint secao 2"

  - source: "outputs/exec-arch.yaml"
    target: "Blueprint secao 3"

  - source: "outputs/checkpoint-map.yaml"
    target: "Blueprint secao 4"
```

### Passo 4.2: Geracao do BLUEPRINT.md

Criar documento mestre usando template:

**Estrutura:**

```markdown
# BLUEPRINT OPERACIONAL
# {TITULO DO PROJETO}

## 1. SUMARIO EXECUTIVO
   - 1.1 O Que E
   - 1.2 Por Que Existe (JTBD)
   - 1.3 Resultado Esperado
   - 1.4 Estimativas

## 2. INTENT SPECIFICATION
   - 2.1 Dimensoes
   - 2.2 Criterios de Sucesso

## 3. EXECUTION ARCHITECTURE
   - 3.1 Visao Geral (Diagrama)
   - 3.2 Fases
   - 3.3 Detalhamento das Fases
   - 3.4 Agentes

## 4. CHECKPOINT MAP
   - 4.1 Visao Geral
   - 4.2 Epicos Detalhados
   - 4.3 Checkpoints

## 5. TAXONOMY CONFIG
   - 5.1 Output Routing
   - 5.2 Runtime Structure
   - 5.3 Human vs AI Outputs

## 6. GUIA DE EXECUCAO
   - 6.1 Pre-requisitos
   - 6.2 Primeiro Passo
   - 6.3 Fluxo de Execucao
   - 6.4 Pontos de Atencao

## 7. CRITERIOS DE SUCESSO FINAL

## ANEXOS
```

Ver template completo: `templates/blueprints/BLUEPRINT-TEMPLATE.md`

### Passo 4.3: Geracao do ACTIVATION.md (OPCIONAL)

Criar prompt de ativacao para referência humana:

**Status:** OPCIONAL - FORMICA lê checkpoint-map.yaml diretamente. ACTIVATION.md preservado para documentação humana.

**Estrutura (se gerado):**

```markdown
# ACTIVATION PROMPT
# {TITULO}

## CONTEXTO
- Operador
- Projeto
- Blueprint ID
- Data

## BLUEPRINT
- Localizacao
- Acao Obrigatoria (ler primeiro)

## INSTRUCOES DE EXECUCAO
1. Preparacao
2. Iniciar Execucao
3. Durante Execucao
4. Finalizacao

## REGRAS INVIOLAVEIS
- NAO pular etapas
- NAO ignorar checkpoints
- SEMPRE atualizar STATE

## PRIMEIRO COMANDO
{comando inicial}

## EM CASO DE BLOQUEIO
{procedimento}
```

Ver template: `templates/prompts/ACTIVATION-TEMPLATE.md`

### Passo 4.4: Enriquecimento do Checkpoint Map com Campos FORMICA

P3 gera checkpoint-map.yaml basico. P4 enriquece com:

1. **worker**: Tipo de worker (analyst, implementer, writer, architect)
2. **model**: Modelo a usar (haiku, sonnet, opus)
3. **output**: Caminho exato do arquivo de saida
4. **context_files**: Lista de arquivos para contexto
5. **expected_format**: Formato esperado (md, yaml, json, sh, etc.)
6. **expected_lines**: Numero esperado de linhas (±30%)
7. **qa.criteria**: Criterios de QA gerados ou refinados

**Exemplo de task FORMICA-compatible:**

```yaml
- id: "T-1.1.1"
  title: "Create lib/modes.sh with 4 mode profiles"

  # P3 basic fields
  description: |
    Create .orchestrator/lib/modes.sh implementing 4 orchestration modes:
    economic, quality, speed, guided. Each mode is a bash associative array.
  acceptance_criteria:
    - "4 modes defined as associative arrays"
    - "apply_orchestration_mode() sets all 10 global variables"
    - "bash -n validates without errors"
    - "Source guard pattern ([[ -n ${_MODES_SH_LOADED:-} ]])"

  # P4 FORMICA fields (added here)
  worker: "implementer"
  model: "haiku"
  output: ".orchestrator/lib/modes.sh"
  context_files:
    - ".orchestrator/orchestrate.sh"
  expected_format: "sh"
  expected_lines: 100

  # Dependencies
  depends_on: []

  # Optional QA overrides
  qa:
    criteria:
      - "All 4 modes present"
      - "Functions present and callable"
      - "No syntax errors"
    threshold: 75
```

**Schema Global do Checkpoint Map:**

```yaml
# checkpoint-map.yaml

schema_version: "FORMICA-v3.0"

metadata:
  blueprint_id: "BP-YYYY-MM-DD-NNN"
  created_at: "ISO-8601"
  target_project: "{path/to/project}"
  target_dir: "{relative/dir}"
  nature_code: ["CODE", "ARCH", "META"]

global_config:
  max_budget_usd: 25.0
  default_model: "haiku"
  max_retries: 2
  qa_threshold: 75
  max_parallel: 4

epics:
  - id: "E-1"
    title: "{epic title}"
    objective: "{objetivo}"
    acceptance_criteria:
      - "{criteria}"
    stories:
      - id: "S-1.1"
        title: "{story title}"
        tasks:
          - id: "T-1.1.1"
            title: "{task title}"
            description: "{description}"
            worker: "{analyst|implementer|writer|architect}"
            model: "{haiku|sonnet|opus}"
            output: "{output/path}"
            context_files:
              - "{input/file1}"
              - "{input/file2}"
            expected_format: "{md|yaml|json|sh}"
            expected_lines: 150
            acceptance_criteria:
              - "{criteria}"
            depends_on: ["T-1.0.1"]
```

### Passo 4.5: Geracao do taxonomy-config.yaml

Definir ROTEAMENTO DE OUTPUTS (quem produz, onde vai):

```yaml
# taxonomy-config.yaml
# Output routing and runtime structure

metadata:
  version: "FORMICA-v3.0"
  blueprint_id: "BP-YYYY-MM-DD-NNN"

output_map:
  # Mapeamento: quais epicos/tasks produzem quais arquivos

  human_outputs:
    # Relatórios para o operador (em outputs/blueprints/{date}/{slug}/)
    - type: "execution-report"
      source: "F3: report.sh"
      destination: "outputs/blueprints/{date}/{slug}/EXECUTION-REPORT.md"
      audience: "operator"
      description: "Human-readable execution summary + results"

    - type: "file-manifest"
      source: "F3: report.sh"
      destination: "outputs/blueprints/{date}/{slug}/FILE-MANIFEST.md"
      audience: "operator"
      description: "List of all files created/modified during execution"

    - type: "progress-log"
      source: "F2: orchestrate.sh"
      destination: "outputs/blueprints/{date}/{slug}/PROGRESS.txt"
      audience: "operator"
      description: "Real-time execution log (waves, tasks, costs)"

  ai_outputs:
    # Telemetry streams (em .orchestrator/runtime/{bp}/)
    - type: "events.jsonl"
      source: "F0-F3: all phases"
      consumer: ["meta-report", "pattern-library", "P6-LEARN"]
      schema: "events-schema.json"
      purpose: "Event stream (task_start, task_complete, qa_rework, friction, etc.)"

    - type: "cost.jsonl"
      source: "F0-F3: cost tracking"
      consumer: ["meta-report", "advisory"]
      schema: "cost-schema.json"
      purpose: "Token usage + cost per task, per model, per phase"

    - type: "decisions.jsonl"
      source: "F2: routing.sh, allometry.sh"
      consumer: ["meta-report", "pattern-library"]
      schema: "decisions-schema.json"
      purpose: "Model escalations, retry routing, budget adjustments"

    - type: "friction.jsonl"
      source: "F2: execute_task() failures"
      consumer: ["meta-report", "pattern-library", "P6-LEARN"]
      schema: "friction-schema.json"
      purpose: "Friction events (budget, format, quality, duration, etc.)"

    - type: "colony.jsonl"
      source: "F2: QA workers extract signals"
      consumer: ["next blueprint quorum sensing"]
      schema: "colony-schema.json"
      purpose: "Trophallaxis signals (best practices, anti-patterns)"

    - type: "immune.jsonl"
      source: "F2: immune system barriers"
      consumer: ["F3: meta-report", "P6-LEARN"]
      schema: "immune-schema.json"
      purpose: "Immune rejections (format, line count, syntax, etc.)"

    - type: "execution-plan.json"
      source: "F0: checkpoint-map compiler"
      consumer: "F1-F3 all phases"
      purpose: "Compiled task DAG with cost estimates, topological sort"

runtime_structure:
  # Estrutura de diretórios durante execução

  root: ".orchestrator/runtime/{bp}/"

  directories:
    - path: "telemetry/"
      contains: "events.jsonl, cost.jsonl, decisions.jsonl, friction.jsonl, colony.jsonl, immune.jsonl"
      lifecycle: "persistent"
      consumer: "F3 meta_report.sh"

    - path: "attempts/{task_id}/"
      contains: "attempt-{n}/context-pack.md, response.json, output.{fmt}"
      lifecycle: "per-task, kept for audit"
      pruned_after: "G4 pass"

    - path: "outputs/"
      contains: "Task outputs (routed by taxonomy-config)"
      lifecycle: "permanent"
      example: "config-analysis.md, test-results.json, implementation.sh"

    - path: "criteria/"
      contains: "qa-criteria.json per task (generated from acceptance_criteria)"
      lifecycle: "per-wave"

    - path: "advisory/"
      contains: "qa-reports.json (one per wave advisory review)"
      lifecycle: "per-wave"

    - path: "memory/"
      contains: "epigenetic-markers.yaml, immune-memory.jsonl, pattern-candidates.yaml"
      lifecycle: "persistent"
      consumer: "next blueprint (P0 REFLECT)"

task_output_routing:
  # Onde cada task escreve seus outputs

  rule: "Each task.output path is relative to project root"

  examples:
    - task_id: "T-1.1.1"
      output: ".orchestrator/lib/modes.sh"
      routed_to: "root_project/.orchestrator/lib/modes.sh"

    - task_id: "T-2.3.1"
      output: "src/components/ui.jsx"
      routed_to: "root_project/src/components/ui.jsx"

  special_cases:
    - type: "analysis output"
      pattern: "**/analysis*.md"
      retention: "permanent (in outputs/ dir)"

    - type: "configuration output"
      pattern: "**/*config*.yaml"
      retention: "permanent (source of truth)"

    - type: "temporary output"
      pattern: "**/tmp/**"
      retention: "cleaned after wave"

state_and_memory:
  state_file: ".orchestrator/runtime/{bp}/state.json"
  update_frequency: "after every task terminal state"

  memory_dir: ".orchestrator/memory/"
  contents:
    - "epigenetic-markers.yaml (learned patterns)"
    - "immune-memory.jsonl (promoted rejections)"
    - "pattern-candidates.yaml (staging for P6)"

naming_conventions:
  blueprint_id: "BP-YYYY-MM-DD-NNN"
  checkpoint_id: "CKPT-YYYY-MM-DD-NNN"
  timestamp_format: "ISO-8601"
  task_id: "T-{epic}.{story}.{sequence}"

  files:
    - "executive-report: {BLUEPRINT_ID}-report-{DATE}.md"
    - "manifest: {BLUEPRINT_ID}-manifest-{DATE}.md"
    - "telemetry: {type}.jsonl (e.g., events.jsonl, cost.jsonl)"
```

### Passo 4.6: Geracao do _metadata.yaml

Criar metadados do pacote:

```yaml
# _metadata.yaml

blueprint:
  id: "BP-{YYYY-MM-DD}-{NNN}"
  version: "1.0.0"
  created_at: "{ISO-8601}"
  created_by: "ATHENA OS v3.1"

source_artifacts:
  intent_spec: "INT-{id}"
  exec_arch: "ARCH-{id}"
  checkpoint_map: "CKPT-{id}"

artifacts:
  - file: "BLUEPRINT.md"
    type: "primary"
    size: "{bytes}"
    checksum: "{md5}"

  - file: "ACTIVATION.md"
    type: "activation"
    note: "Optional - preserved for human reference only"

  - file: "intent-spec.yaml"
    type: "specification"

  - file: "exec-arch.yaml"
    type: "architecture"

  - file: "checkpoint-map.yaml"
    type: "execution"
    note: "FORMICA primary input"

  - file: "taxonomy-config.yaml"
    type: "configuration"
    note: "Output routing and runtime structure"

validation:
  gates_passed: ["G1", "G2", "G3", "G4"]
  validated_at: "{ISO-8601}"
  formica_compatible: true
  required_fields_present:
    - "worker"
    - "model"
    - "output"
    - "context_files"
    - "expected_format"
    - "expected_lines"
    - "qa.criteria"

export_history: []
```

### Passo 4.7: Salvamento dos Arquivos

Salvar tudo na estrutura correta:

```
outputs/blueprints/{YYYY-MM-DD}/{slug}/
+-- BLUEPRINT.md
+-- ACTIVATION.md (opcional)
+-- intent-spec.yaml
+-- exec-arch.yaml
+-- checkpoint-map.yaml
+-- taxonomy-config.yaml
+-- _metadata.yaml
```

---

## Gate G4: Validacao Final

**Pergunta Central:** O Blueprint e auto-contido, transferivel e FORMICA-compatible?

### Teste de Transferibilidade

> Se alguem que nunca viu este projeto ler apenas o Blueprint, consegue executar sem perguntas adicionais?

### Teste de Compatibilidade FORMICA

> Se FORMICA ler o checkpoint-map.yaml, consegue compilar um execution-plan.json executavel?

### Checklist de Validacao

| Criterio | Peso | Verificacao |
|----------|------|-------------|
| Blueprint completo? | CRITICO | Todas as 7 secoes preenchidas? |
| Activation disponivel? | ALTO | Instrucoes de ativacao sao claras? |
| Taxonomy definida? | CRITICO | Output routing mapeado completamente? |
| Checkpoint Map FORMICA-compatible? | CRITICO | Todos os 11 campos presentes? |
| Sem referencias quebradas? | ALTO | Todos os paths existem ou sao templates? |
| Linguagem clara? | ALTO | Sem jargao inexplicado? |
| Primeiro passo acionavel? | MEDIO | Pode comecar imediatamente? |
| DAG acyclic? | CRITICO | Nao ha circular dependencies? |
| Criterios QA geroniveis? | ALTO | Acceptance criteria sao objetivos? |

### Regra de Passagem

- Todos os criterios CRITICO devem ser atendidos
- Todos os criterios ALTO devem ser atendidos
- Checkpoint-map valida contra schema FORMICA-v3.0

### Se Falhar

1. Identificar quais criterios falharam
2. Revisar e completar secoes faltantes
3. Enriquecer checkpoint-map com campos FORMICA
4. Clarificar linguagem ambigua
5. Corrigir referencias quebradas
6. Re-executar Gate G4

---

## Verificacoes de Qualidade

### Verificacao 1: Completude

```yaml
completeness_check:
  blueprint:
    - secao_1_sumario: true
    - secao_2_intent: true
    - secao_3_arch: true
    - secao_4_checkpoints: true
    - secao_5_taxonomy: true
    - secao_6_guia: true
    - secao_7_criterios: true

  checkpoint_map:
    - schema_version: true
    - metadata: true
    - global_config: true
    - epics_complete: true
    - all_tasks_formica_fields: true

  taxonomy_config:
    - output_map: true
    - runtime_structure: true
    - task_output_routing: true
    - state_and_memory: true
```

### Verificacao 2: Consistencia

```yaml
consistency_check:
  - "IDs no Blueprint = IDs nos YAMLs"
  - "Fases no Blueprint = Fases na Architecture"
  - "Tasks no Blueprint = Tasks no Checkpoint Map"
  - "Projeto-alvo consistente em todos os arquivos"
  - "Output paths no Checkpoint Map = rotas em taxonomy-config"
  - "Worker types documentados em exec-arch match tarefas"
```

### Verificacao 3: Referencias

```yaml
reference_check:
  - "Todos os arquivos referenciados existem (ou sao placeholders)"
  - "Todos os paths sao validos (forward slashes, sem wildcards)"
  - "Todos os IDs resolvem (task, epic, story)"
  - "Todas as depends_on referencias existem"
  - "Todos os context_files rastreáveis"
```

### Verificacao 4: FORMICA Compatibility

```yaml
formica_compatibility_check:
  - "Cada task tem worker type valido"
  - "Cada task tem model valido (haiku, sonnet, opus)"
  - "Cada task tem output path exato"
  - "Cada task tem context_files lista (pode ser vazia)"
  - "Cada task tem expected_format"
  - "Cada task tem expected_lines numero"
  - "Schema matches FORMICA-v3.0"
  - "DAG acyclic (topological sort possivel)"
  - "global_config presente com todos os campos"
```

---

## Output Final

### Resumo para o Operador

Apos G4 PASS, apresentar:

```
==================================================
BLUEPRINT GERADO COM SUCESSO
==================================================

ID: BP-2026-02-16-001
Titulo: {titulo}
Projeto-alvo: {projeto}

Arquivos gerados:
- outputs/blueprints/2026-02-16/{slug}/BLUEPRINT.md
- outputs/blueprints/2026-02-16/{slug}/ACTIVATION.md (opcional)
- outputs/blueprints/2026-02-16/{slug}/*.yaml

Status FORMICA: COMPATIBLE
- Todos os 11 campos presentes
- DAG validado
- Pronto para execução via FORMICA

Proximos passos:
1. Revisar BLUEPRINT.md (human-facing)
2. Executar `/ATHENA:execute` com blueprint_path
3. FORMICA compilará execution-plan.json automaticamente
4. Monitor execução via runtime/{bp}/telemetry/

==================================================
```

---

## Checklist Final

Antes de finalizar:

- [ ] BLUEPRINT.md com todas as 7 secoes
- [ ] ACTIVATION.md gerado (ou marcado como opcional)
- [ ] taxonomy-config.yaml definido (output routing completo)
- [ ] checkpoint-map.yaml com todos os 11 campos FORMICA
- [ ] _metadata.yaml completo
- [ ] Arquivos salvos na estrutura correta
- [ ] FORMICA compatibility check PASS
- [ ] Gate G4 PASSED
- [ ] STATE.yaml atualizado
- [ ] Resumo apresentado ao operador

---

*"Um Blueprint que FORMICA nao consegue compilar e um Blueprint que falhou." - ATHENA v3.1*
