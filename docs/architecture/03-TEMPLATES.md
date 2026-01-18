# ATHENA OS — TEMPLATES DE ARTEFATOS

> Estruturas Padronizadas para Outputs Consistentes

**Versão:** 1.0.0
**Dependências:** 02-PROTOCOLS.md

---

## Filosofia de Templates

Templates não são formulários para preencher. São **estruturas cognitivas** que garantem:

1. **Completude** — Nada importante é esquecido
2. **Consistência** — Mesma estrutura, toda vez
3. **Transferibilidade** — Qualquer um entende
4. **Rastreabilidade** — Fácil de referenciar

---

## Template 1: Intent Specification

**Arquivo:** `templates/blueprints/INTENT-SPEC.yaml`
**Usado em:** Protocolo P1 (DECODE)

```yaml
# ╔═══════════════════════════════════════════════════════════════════╗
# ║                    INTENT SPECIFICATION                           ║
# ║                         Template v1.0                             ║
# ╚═══════════════════════════════════════════════════════════════════╝

# ─────────────────────────────────────────────────────────────────────
# METADATA
# ─────────────────────────────────────────────────────────────────────
metadata:
  id: "INT-{YYYY-MM-DD}-{NNN}"
  version: "1.0.0"
  created_at: "{ISO-8601 timestamp}"
  created_by: "{operador}"
  athena_version: "1.0.0"

# ─────────────────────────────────────────────────────────────────────
# SUMÁRIO EXECUTIVO
# ─────────────────────────────────────────────────────────────────────
summary:
  # Uma frase que captura a essência
  one_liner: ""
  
  # Job To Be Done no formato padrão
  jtbd: "Quando [SITUAÇÃO], eu quero [MOTIVAÇÃO], para que [RESULTADO]."
  
  # Classificação de complexidade
  complexity: "LOW | MEDIUM | HIGH | EXTREME"
  
  # Estimativa de esforço
  estimated_effort:
    value: 0
    unit: "hours | days | weeks"
    confidence: "LOW | MEDIUM | HIGH"

# ─────────────────────────────────────────────────────────────────────
# DIMENSÕES EXTRAÍDAS
# ─────────────────────────────────────────────────────────────────────
dimensions:
  # O QUE precisa ser feito
  what:
    explicit: |
      O que foi explicitamente pedido.
      Pode ser múltiplas linhas.
    implicit: |
      O que provavelmente é necessário mas não foi dito.
      Inferências baseadas no contexto.
    out_of_scope: |
      O que definitivamente NÃO está incluído.
      
  # POR QUE precisa ser feito
  why:
    surface_reason: |
      A razão aparente, o que foi dito.
    deep_reason: |
      A motivação real (aplicar 5 Porquês se necessário).
    impact_if_not_done: |
      O que acontece se isso NÃO for feito?
      
  # QUEM está envolvido
  who:
    operator: 
      name: ""
      role: ""
      context: ""
    beneficiary:
      primary: ""
      secondary: []
    stakeholders: []
    
  # ONDE será executado
  where:
    target_project:
      name: ""
      path: ""
      type: ""
    target_location: |
      Onde especificamente no projeto.
      
  # QUANDO precisa estar pronto
  when:
    urgency: "LOW | MEDIUM | HIGH | CRITICAL"
    deadline: "{YYYY-MM-DD ou null}"
    dependencies:
      must_be_ready_before: []
      blocks: []
      
  # COMO deve ser feito
  how:
    constraints:
      technical: []
      resource: []
      time: []
    preferences:
      format: ""
      style: ""
      tools: []
    anti_patterns:
      - "O que definitivamente NÃO fazer"

# ─────────────────────────────────────────────────────────────────────
# CRITÉRIOS DE SUCESSO
# ─────────────────────────────────────────────────────────────────────
success_criteria:
  # Obrigatórios - todos devem ser atendidos
  must_have:
    - criterion: "Descrição do critério"
      measurement: "Como medir (binário)"
      
  # Desejáveis - bom ter, não obrigatório
  should_have:
    - criterion: ""
      measurement: ""
      
  # Proibidos - não podem acontecer
  must_not:
    - "O que não pode acontecer"

# ─────────────────────────────────────────────────────────────────────
# CONTEXTO ADICIONAL
# ─────────────────────────────────────────────────────────────────────
context:
  # Projetos relacionados
  related_projects:
    - name: ""
      relevance: ""
      
  # Materiais de referência
  reference_materials:
    - type: "doc | url | file"
      path: ""
      relevance: ""
      
  # Tentativas anteriores (se houver)
  prior_attempts:
    - description: ""
      result: ""
      learning: ""
      
  # Bloqueadores conhecidos
  known_blockers:
    - blocker: ""
      mitigation: ""

# ─────────────────────────────────────────────────────────────────────
# VALIDAÇÃO (preenchido pelo Gate G1)
# ─────────────────────────────────────────────────────────────────────
validation:
  gate: "G1"
  status: "PENDING | PASSED | FAILED"
  checked_at: ""
  checked_by: ""
  notes: ""
  issues_found: []
```

---

## Template 2: Execution Architecture

**Arquivo:** `templates/blueprints/EXEC-ARCH.yaml`
**Usado em:** Protocolo P2 (ARCHITECT)

```yaml
# ╔═══════════════════════════════════════════════════════════════════╗
# ║                   EXECUTION ARCHITECTURE                          ║
# ║                         Template v1.0                             ║
# ╚═══════════════════════════════════════════════════════════════════╝

# ─────────────────────────────────────────────────────────────────────
# METADATA
# ─────────────────────────────────────────────────────────────────────
metadata:
  id: "ARCH-{YYYY-MM-DD}-{NNN}"
  intent_id: "{referência ao INT-*}"
  version: "1.0.0"
  created_at: "{ISO-8601}"
  athena_version: "1.0.0"

# ─────────────────────────────────────────────────────────────────────
# CLASSIFICAÇÃO
# ─────────────────────────────────────────────────────────────────────
classification:
  complexity: "LOW | MEDIUM | HIGH | EXTREME"
  type: "ANALYSIS | CREATION | TRANSFORMATION | ORCHESTRATION | HYBRID"
  paradigm: "LINEAR | ITERATIVE | EVENT-DRIVEN | HYBRID"
  
  summary:
    total_phases: 0
    total_agents: 0
    total_decision_points: 0
    estimated_duration:
      value: 0
      unit: "hours | days"

# ─────────────────────────────────────────────────────────────────────
# FASES
# ─────────────────────────────────────────────────────────────────────
phases:
  - id: "PH-1"
    name: "Nome da Fase"
    objective: |
      O que esta fase realiza.
      Objetivo claro e mensurável.
    
    inputs:
      - name: "Nome do input"
        source: "De onde vem"
        required: true
        
    outputs:
      - name: "Nome do output"
        format: "md | yaml | json | etc"
        destination: "Para onde vai"
        
    agents_involved: ["AGT-1"]
    
    gate:
      id: "G-PH1"
      question: "Pergunta de validação"
      criteria:
        - "Critério 1"
        - "Critério 2"
      action_if_fail: "O que fazer se falhar"
      
    estimated_duration:
      value: 0
      unit: "minutes | hours"
      
    notes: ""

# ─────────────────────────────────────────────────────────────────────
# AGENTES
# ─────────────────────────────────────────────────────────────────────
agents:
  - id: "AGT-1"
    name: "Nome do Agente"
    type: "THINKER | DOER | VALIDATOR | HYBRID"
    
    role: |
      Papel do agente no sistema.
      
    expertise:
      - "Área de conhecimento 1"
      - "Área de conhecimento 2"
      
    responsibilities:
      - "Responsabilidade 1"
      - "Responsabilidade 2"
      
    invoked_in:
      - phase: "PH-1"
        purpose: "Por que é invocado nesta fase"
        
    prompt_reference: "path/to/prompt.md ou inline"
    
    collaboration:
      receives_from: ["AGT-X"]
      sends_to: ["AGT-Y"]

# ─────────────────────────────────────────────────────────────────────
# WORKFLOW
# ─────────────────────────────────────────────────────────────────────
workflow:
  type: "LINEAR | PARALLEL | CONDITIONAL | ITERATIVE | HYBRID"
  
  # Diagrama Mermaid
  diagram: |
    ```mermaid
    graph TD
      A[PH-1] --> B[PH-2]
      B --> C{Decisão}
      C -->|Sim| D[PH-3A]
      C -->|Não| E[PH-3B]
    ```
  
  # Fluxo detalhado
  flow:
    - step: 1
      phase: "PH-1"
      agents: ["AGT-1"]
      parallel: false
      condition: null
      
    - step: 2
      phase: "PH-2"
      agents: ["AGT-2"]
      parallel: false
      condition: "Após G-PH1 PASS"

# ─────────────────────────────────────────────────────────────────────
# PONTOS DE DECISÃO
# ─────────────────────────────────────────────────────────────────────
decision_points:
  - id: "DP-1"
    after_phase: "PH-X"
    type: "HUMAN | AUTOMATIC | HYBRID"
    
    question: |
      Pergunta que precisa ser respondida.
      
    options:
      - id: "A"
        label: "Opção A"
        leads_to: "PH-Y"
        criteria: "Quando escolher esta opção"
        
      - id: "B"
        label: "Opção B"
        leads_to: "PH-Z"
        criteria: "Quando escolher esta opção"
        
    default: "A"
    timeout_action: "O que fazer se não houver resposta"

# ─────────────────────────────────────────────────────────────────────
# RECURSOS NECESSÁRIOS
# ─────────────────────────────────────────────────────────────────────
resources:
  tools:
    - name: ""
      purpose: ""
      required: true
      
  mcps:
    - name: ""
      purpose: ""
      config: ""
      
  external_apis:
    - name: ""
      purpose: ""
      auth_required: true
      
  knowledge_bases:
    - name: ""
      path: ""
      purpose: ""
      
  files:
    - path: ""
      purpose: ""
      access: "read | write | both"

# ─────────────────────────────────────────────────────────────────────
# RISCOS E MITIGAÇÕES
# ─────────────────────────────────────────────────────────────────────
risks:
  - id: "R-1"
    description: ""
    probability: "LOW | MEDIUM | HIGH"
    impact: "LOW | MEDIUM | HIGH"
    mitigation: ""
    contingency: ""

# ─────────────────────────────────────────────────────────────────────
# VALIDAÇÃO (preenchido pelo Gate G2)
# ─────────────────────────────────────────────────────────────────────
validation:
  gate: "G2"
  status: "PENDING | PASSED | FAILED"
  checked_at: ""
  notes: ""
```

---

## Template 3: Checkpoint Map

**Arquivo:** `templates/checkpoints/CHECKPOINT-MAP.yaml`
**Usado em:** Protocolo P3 (FRAGMENT)

```yaml
# ╔═══════════════════════════════════════════════════════════════════╗
# ║                       CHECKPOINT MAP                              ║
# ║                         Template v1.0                             ║
# ╚═══════════════════════════════════════════════════════════════════╝

# ─────────────────────────────────────────────────────────────────────
# METADATA
# ─────────────────────────────────────────────────────────────────────
metadata:
  id: "CKPT-{YYYY-MM-DD}-{NNN}"
  architecture_id: "{referência ao ARCH-*}"
  intent_id: "{referência ao INT-*}"
  version: "1.0.0"
  created_at: "{ISO-8601}"

# ─────────────────────────────────────────────────────────────────────
# SUMÁRIO
# ─────────────────────────────────────────────────────────────────────
summary:
  total_epics: 0
  total_stories: 0
  total_tasks: 0
  total_checkpoints: 0
  
  completion:
    epics_done: 0
    stories_done: 0
    tasks_done: 0
    percentage: 0
    
  estimated_total_effort:
    value: 0
    unit: "hours"

# ─────────────────────────────────────────────────────────────────────
# ÉPICOS
# ─────────────────────────────────────────────────────────────────────
epics:
  - id: "E-1"
    derived_from: "PH-1"
    title: "Título do Épico"
    
    objective: |
      O que este épico realiza.
      
    acceptance_criteria: |
      Como saber que o épico está completo.
      
    status: "TODO | IN_PROGRESS | DONE | BLOCKED"
    progress: 0  # percentage
    
    estimated_effort:
      value: 0
      unit: "days"
      
    # ─────────────────────────────────────────────────────────────────
    # STORIES DO ÉPICO
    # ─────────────────────────────────────────────────────────────────
    stories:
      - id: "S-1.1"
        title: "Título da Story"
        
        # Formato User Story
        user_story:
          as_a: "Persona/Role"
          i_want: "Ação desejada"
          so_that: "Benefício/Valor"
          
        acceptance_criteria:
          - "Critério 1 - binário"
          - "Critério 2 - binário"
          
        status: "TODO | IN_PROGRESS | DONE | BLOCKED"
        progress: 0
        
        estimated_effort:
          value: 0
          unit: "hours"
          
        # ─────────────────────────────────────────────────────────────
        # TASKS DA STORY
        # ─────────────────────────────────────────────────────────────
        tasks:
          - id: "T-1.1.1"
            title: "Título da Task"
            
            description: |
              O que fazer, em detalhes suficientes para execução.
              
            # ÚNICO critério, BINÁRIO
            acceptance_criterion: "Condição binária de conclusão"
            
            status: "TODO | IN_PROGRESS | DONE | BLOCKED"
            
            estimated_duration:
              value: 30
              unit: "minutes"
              
            # Dependências
            depends_on: []  # IDs de outras tasks
            blocks: []      # IDs de tasks que dependem desta
            
            # Bloqueadores (se houver)
            blockers:
              - description: ""
                type: "TECHNICAL | RESOURCE | DEPENDENCY | EXTERNAL"
                resolution: ""
                
            # Notas de execução
            execution_notes: ""
            completed_at: null

# ─────────────────────────────────────────────────────────────────────
# CHECKPOINTS
# ─────────────────────────────────────────────────────────────────────
checkpoints:
  - id: "CP-1"
    name: "Nome do Checkpoint"
    after_task: "T-X.Y.Z"
    
    validation:
      question: "O que verificar?"
      criteria:
        - "Critério 1"
        - "Critério 2"
        
    action_if_pass: "Prosseguir para próxima task"
    action_if_fail: "O que fazer se falhar"
    
    updates_state: true
    state_updates:
      - field: "path.to.field"
        value: "novo valor"
        
    triggered: false
    triggered_at: null
    result: null

# ─────────────────────────────────────────────────────────────────────
# GRAFO DE DEPENDÊNCIAS
# ─────────────────────────────────────────────────────────────────────
dependency_graph:
  nodes:
    - id: "T-1.1.1"
      type: "task"
      status: "TODO"
      
  edges:
    - from: "T-1.1.1"
      to: "T-1.1.2"
      type: "blocks"

# ─────────────────────────────────────────────────────────────────────
# VALIDAÇÃO (preenchido pelo Gate G3)
# ─────────────────────────────────────────────────────────────────────
validation:
  gate: "G3"
  status: "PENDING | PASSED | FAILED"
  checked_at: ""
  notes: ""
```

---

## Template 4: Blueprint Operacional

**Arquivo:** `templates/blueprints/BLUEPRINT-TEMPLATE.md`
**Usado em:** Protocolo P4 (CRYSTALLIZE)

```markdown
# BLUEPRINT OPERACIONAL
# {TÍTULO DO PROJETO}

---

**ID:** BP-{YYYY-MM-DD}-{NNN}
**Versão:** 1.0.0
**Gerado por:** ATHENA OS v1.0
**Data:** {YYYY-MM-DD HH:MM}
**Projeto-alvo:** {nome do projeto}
**Caminho:** {path do projeto}

---

## 1. SUMÁRIO EXECUTIVO

### 1.1 O Que É
{Descrição clara em 2-3 frases do que este Blueprint realiza}

### 1.2 Por Que Existe
> "Quando {SITUAÇÃO}, eu quero {MOTIVAÇÃO}, para que {RESULTADO}."

### 1.3 Resultado Esperado
Ao final da execução deste Blueprint:
- [ ] {Deliverable 1}
- [ ] {Deliverable 2}
- [ ] {Deliverable 3}

### 1.4 Estimativas
| Métrica | Valor |
|---------|-------|
| Complexidade | {LOW/MEDIUM/HIGH/EXTREME} |
| Esforço estimado | {X horas/dias} |
| Número de épicos | {N} |
| Número de tasks | {N} |

---

## 2. INTENT SPECIFICATION

### 2.1 Dimensões

#### O QUE
**Explícito:**
{O que foi pedido}

**Implícito:**
{O que é necessário mas não foi dito}

**Fora do Escopo:**
{O que NÃO está incluído}

#### POR QUE
**Razão de Superfície:**
{A razão aparente}

**Razão Profunda:**
{A motivação real}

#### QUEM
- **Operador:** {quem executa}
- **Beneficiário:** {quem se beneficia}

#### ONDE
- **Projeto:** {nome}
- **Path:** `{caminho}`

#### QUANDO
- **Urgência:** {nível}
- **Deadline:** {data ou N/A}

#### COMO
**Constraints:**
- {Limitação 1}
- {Limitação 2}

**Anti-Patterns:**
- {O que NÃO fazer}

### 2.2 Critérios de Sucesso

**MUST HAVE:**
- [ ] {Critério obrigatório 1}
- [ ] {Critério obrigatório 2}

**SHOULD HAVE:**
- [ ] {Critério desejável}

**MUST NOT:**
- {O que não pode acontecer}

---

## 3. EXECUTION ARCHITECTURE

### 3.1 Visão Geral

```mermaid
{Diagrama do workflow}
```

### 3.2 Fases

| # | Fase | Objetivo | Output | Gate |
|---|------|----------|--------|------|
| 1 | {Nome} | {Objetivo} | {Output} | {Critério} |
| 2 | {Nome} | {Objetivo} | {Output} | {Critério} |

### 3.3 Detalhamento das Fases

#### Fase 1: {Nome}

**Objetivo:**
{Descrição}

**Inputs:**
- {Input 1}

**Outputs:**
- {Output 1}

**Gate:**
- {Critério de passagem}

{Repetir para cada fase}

### 3.4 Agentes (se aplicável)

| Agente | Role | Invocado em |
|--------|------|-------------|
| {Nome} | {Papel} | {Fases} |

---

## 4. CHECKPOINT MAP

### 4.1 Visão Geral

| Épico | Stories | Tasks | Status |
|-------|---------|-------|--------|
| E-1: {Nome} | {N} | {N} | TODO |

### 4.2 Épicos Detalhados

#### E-1: {Nome do Épico}

**Objetivo:** {Descrição}
**Acceptance Criteria:** {Como saber que terminou}

##### S-1.1: {Nome da Story}

> Como {persona}, eu quero {ação}, para que {benefício}.

**Tasks:**

- [ ] **T-1.1.1:** {Título}
  - Critério: {Condição binária}
  - Duração: {estimativa}
  
- [ ] **T-1.1.2:** {Título}
  - Critério: {Condição binária}
  - Duração: {estimativa}
  - Depende de: T-1.1.1

{Repetir para cada story e task}

### 4.3 Checkpoints

| CP | Após | Validação | Ação se Falhar |
|----|------|-----------|----------------|
| CP-1 | T-X.Y.Z | {O que verificar} | {O que fazer} |

---

## 5. TAXONOMY CONFIG

### 5.1 Estrutura de Outputs

```
{projeto}/
├── {pasta}/
│   ├── {arquivo}.{ext}
│   └── {arquivo}.{ext}
└── STATE.yaml
```

### 5.2 Convenções

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| Arquivos | {padrão} | {exemplo} |
| Pastas | {padrão} | {exemplo} |
| IDs | {padrão} | {exemplo} |

---

## 6. GUIA DE EXECUÇÃO

### 6.1 Pré-requisitos

Antes de iniciar, garantir que:
- [ ] {Pré-requisito 1}
- [ ] {Pré-requisito 2}

### 6.2 Primeiro Passo

```
{Comando ou ação inicial}
```

### 6.3 Fluxo de Execução

1. {Passo 1}
2. {Passo 2}
3. {Passo 3}

### 6.4 Pontos de Atenção

⚠️ **{Ponto 1}:** {Descrição do cuidado necessário}

⚠️ **{Ponto 2}:** {Descrição do cuidado necessário}

---

## 7. CRITÉRIOS DE SUCESSO FINAL

A execução está completa quando TODOS os critérios abaixo forem atendidos:

- [ ] {Critério 1}
- [ ] {Critério 2}
- [ ] {Critério 3}
- [ ] STATE.yaml atualizado com status COMPLETED

---

## ANEXOS

### A. Referências
- {Referência 1}
- {Referência 2}

### B. Glossário
- **{Termo}:** {Definição}

---

*Blueprint gerado por ATHENA OS v1.0*
*Timestamp: {ISO-8601}*
```

---

## Template 5: Activation Prompt

**Arquivo:** `templates/prompts/ACTIVATION-TEMPLATE.md`
**Usado em:** Protocolo P4 (CRYSTALLIZE)

```markdown
# ACTIVATION PROMPT
# {TÍTULO DO PROJETO}

---

## CONTEXTO

Este prompt ativa a execução de um Blueprint gerado pelo ATHENA OS.

| Campo | Valor |
|-------|-------|
| **Operador** | {nome} |
| **Projeto** | {nome do projeto} |
| **Blueprint ID** | {BP-YYYY-MM-DD-NNN} |
| **Gerado em** | {timestamp} |

---

## BLUEPRINT

O Blueprint completo está localizado em:

```
{caminho/completo/para/BLUEPRINT.md}
```

### Ação Obrigatória

**LEIA O BLUEPRINT COMPLETO** antes de executar qualquer coisa.

Seções críticas:
1. Sumário Executivo (entender o objetivo)
2. Checkpoint Map (entender as tasks)
3. Guia de Execução (entender o fluxo)

---

## INSTRUÇÕES DE EXECUÇÃO

### Passo 1: Preparação
```bash
# Verificar estado atual
cat STATE.yaml

# Verificar pré-requisitos (seção 6.1 do Blueprint)
```

### Passo 2: Iniciar Execução
```
# Primeiro comando sugerido:
{comando inicial}
```

### Passo 3: Durante Execução
- Seguir a sequência de tasks do Checkpoint Map
- Marcar cada task como DONE ao completar
- Atualizar STATE.yaml em cada checkpoint

### Passo 4: Finalização
- Verificar todos os critérios de sucesso (seção 7)
- Atualizar STATE.yaml com status COMPLETED
- Reportar conclusão

---

## REGRAS INVIOLÁVEIS

1. ❌ **NÃO** pular etapas
2. ❌ **NÃO** ignorar checkpoints
3. ❌ **NÃO** alterar outputs sem atualizar STATE
4. ✅ **SEMPRE** atualizar STATE após cada task
5. ✅ **SEMPRE** parar e reportar se encontrar bloqueio

---

## PRIMEIRO COMANDO

Execute isto para iniciar:

```
{comando detalhado para iniciar a execução}
```

---

## EM CASO DE BLOQUEIO

1. Documentar o bloqueio no STATE.yaml
2. Identificar a causa raiz
3. Consultar o Blueprint seção relevante
4. Se não resolver: reportar para ATHENA OS

---

## REFERÊNCIAS RÁPIDAS

| Documento | Localização |
|-----------|-------------|
| Blueprint | `{path}` |
| STATE | `{path}` |
| Checkpoint Map | Seção 4 do Blueprint |
| Critérios de Sucesso | Seção 7 do Blueprint |

---

*Activation Prompt gerado por ATHENA OS v1.0*
```

---

## Uso dos Templates

### Regras de Preenchimento

1. **Nunca deixar campos vazios** — Use "N/A" se não aplicável
2. **Manter formatação** — Estrutura é sagrada
3. **Usar IDs consistentes** — Seguir padrão de nomenclatura
4. **Timestamps em ISO-8601** — `2025-01-16T14:30:00-03:00`

### Localização dos Templates

```
athena-os/
└── templates/
    ├── blueprints/
    │   ├── INTENT-SPEC.yaml
    │   ├── EXEC-ARCH.yaml
    │   └── BLUEPRINT-TEMPLATE.md
    ├── prompts/
    │   └── ACTIVATION-TEMPLATE.md
    └── checkpoints/
        └── CHECKPOINT-MAP.yaml
```

---

*"Um template bem projetado é meio caminho andado para um output excelente." — ATHENA*
