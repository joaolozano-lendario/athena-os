# ATHENA OS — PROTOCOLOS DE OPERAÇÃO

> Os 4 Protocolos Core que Governam a Forja de Blueprints

**Versão:** 1.0.0
**Dependências:** 00-MANIFESTO.md, 01-ARCHITECTURE.md

---

## Visão Geral do Pipeline

```
INTENÇÃO BRUTA
     │
     ▼
┌─────────────────────────────────────────────────────────────────┐
│  P1: DECODE                                                     │
│  "Extrair a intenção real por trás das palavras"               │
│                                                                 │
│  Input:  Descrição livre do que você quer fazer                │
│  Output: Intent Specification estruturada                       │
│  Gate:   G1 — A intenção está inequivocamente clara?           │
└─────────────────────────────────────────────────────────────────┘
     │
     ▼ [G1 PASS]
┌─────────────────────────────────────────────────────────────────┐
│  P2: ARCHITECT                                                  │
│  "Desenhar a máquina que vai executar a intenção"              │
│                                                                 │
│  Input:  Intent Specification                                   │
│  Output: Execution Architecture (fases, agents, workflows)      │
│  Gate:   G2 — A arquitetura é lógica e executável?             │
└─────────────────────────────────────────────────────────────────┘
     │
     ▼ [G2 PASS]
┌─────────────────────────────────────────────────────────────────┐
│  P3: FRAGMENT                                                   │
│  "Quebrar a arquitetura em unidades atômicas rastreáveis"      │
│                                                                 │
│  Input:  Execution Architecture                                 │
│  Output: Checkpoint Map (Épicos → Stories → Tasks)              │
│  Gate:   G3 — Toda a execução está mapeada em tasks?           │
└─────────────────────────────────────────────────────────────────┘
     │
     ▼ [G3 PASS]
┌─────────────────────────────────────────────────────────────────┐
│  P4: CRYSTALLIZE                                                │
│  "Transformar em artefatos prontos para exportar"              │
│                                                                 │
│  Input:  Checkpoint Map + todos os outputs anteriores          │
│  Output: Blueprint + Activation Prompt + Taxonomy Config        │
│  Gate:   G4 — O Blueprint é auto-contido e transferível?       │
└─────────────────────────────────────────────────────────────────┘
     │
     ▼ [G4 PASS]
BLUEPRINT OPERACIONAL COMPLETO
```

---

# P1: PROTOCOLO DE DECODIFICAÇÃO

> "A maioria dos projetos falha porque ninguém entendeu o que realmente precisava ser feito."

## Objetivo

Transformar uma intenção bruta (texto livre, ideia vaga, pedido confuso) em uma **Intent Specification** — um documento estruturado que elimina toda ambiguidade sobre o que deve ser feito.

## Processo de Execução

### Passo 1.1: Captura Bruta

Receber a intenção do operador exatamente como ela vier:
- Texto livre
- Bullet points
- Conversa informal
- Referência a outros projetos

**Regra:** Não interpretar ainda. Apenas capturar.

### Passo 1.2: Extração de Dimensões

Extrair sistematicamente as seguintes dimensões:

```yaml
dimensions:
  WHAT:
    explicit: "O que foi pedido literalmente"
    implicit: "O que provavelmente é necessário mas não foi dito"
    
  WHY:
    surface: "A razão aparente"
    deep: "A motivação real por trás (5 Porquês)"
    
  WHO:
    operator: "Quem vai executar (humano, Claude, sistema)"
    beneficiary: "Quem se beneficia do resultado"
    stakeholders: "Quem mais é afetado"
    
  WHERE:
    target_project: "Em qual projeto/sistema isso será executado"
    target_path: "Onde especificamente no projeto"
    
  WHEN:
    urgency: "low | medium | high | critical"
    deadline: "Se houver"
    dependencies: "O que precisa estar pronto antes"
    
  HOW:
    constraints: "Limitações técnicas, de tempo, de recursos"
    preferences: "Preferências do operador (formato, estilo, etc.)"
    anti_patterns: "O que definitivamente NÃO fazer"
```

### Passo 1.3: Identificação do JTBD (Job To Be Done)

Formular o "trabalho a ser feito" no formato:

```
"Quando [SITUAÇÃO], eu quero [MOTIVAÇÃO], para que [RESULTADO ESPERADO]."
```

**Exemplo:**
```
"Quando recebo dados brutos de pesquisas do Tally, eu quero um framework 
que orquestre a análise completa, para que eu extraia insights acionáveis 
sem ter que reexplicar o contexto a cada sessão."
```

### Passo 1.4: Definição de Sucesso

Estabelecer critérios binários de sucesso:

```yaml
success_criteria:
  must_have:
    - "Critério 1 que DEVE ser atendido"
    - "Critério 2 que DEVE ser atendido"
  should_have:
    - "Critério desejável mas não obrigatório"
  must_not:
    - "Isso NÃO pode acontecer"
```

### Passo 1.5: Compilação da Intent Specification

Consolidar tudo em um documento estruturado.

## Output: Intent Specification

```yaml
# INTENT SPECIFICATION
# ====================

id: "INT-{YYYY-MM-DD}-{NNN}"
created_at: "{timestamp}"
created_by: "{operator}"

# ─────────────────────────────────────────────────────────
# SUMÁRIO EXECUTIVO
# ─────────────────────────────────────────────────────────
summary:
  one_liner: "Frase única que captura a essência"
  jtbd: "Quando [X], eu quero [Y], para que [Z]"
  complexity: "LOW | MEDIUM | HIGH | EXTREME"
  estimated_effort: "Estimativa em horas/dias"

# ─────────────────────────────────────────────────────────
# DIMENSÕES EXTRAÍDAS
# ─────────────────────────────────────────────────────────
dimensions:
  what:
    explicit: ""
    implicit: ""
  why:
    surface: ""
    deep: ""
  who:
    operator: ""
    beneficiary: ""
  where:
    target_project: ""
    target_path: ""
  when:
    urgency: ""
    deadline: ""
  how:
    constraints: []
    preferences: []
    anti_patterns: []

# ─────────────────────────────────────────────────────────
# CRITÉRIOS DE SUCESSO
# ─────────────────────────────────────────────────────────
success_criteria:
  must_have: []
  should_have: []
  must_not: []

# ─────────────────────────────────────────────────────────
# CONTEXTO ADICIONAL
# ─────────────────────────────────────────────────────────
context:
  related_projects: []
  reference_materials: []
  prior_attempts: []
  known_blockers: []

# ─────────────────────────────────────────────────────────
# VALIDAÇÃO
# ─────────────────────────────────────────────────────────
validation:
  gate_status: "PENDING | PASSED | FAILED"
  gate_notes: ""
  reviewed_by: ""
  reviewed_at: ""
```

## Gate G1: Validação de Intent

**Pergunta Central:** A intenção está inequivocamente clara?

**Checklist de Validação:**

| Critério | Peso | Verificação |
|----------|------|-------------|
| JTBD está formulado? | CRÍTICO | O Job To Be Done está claro e específico? |
| Sucesso é mensurável? | CRÍTICO | Os critérios de sucesso são binários (sim/não)? |
| Escopo está fechado? | ALTO | Está claro o que está FORA do escopo? |
| Projeto-alvo definido? | ALTO | Sabemos onde isso será executado? |
| Anti-patterns listados? | MÉDIO | Sabemos o que NÃO fazer? |

**Regra de Passagem:** Todos os critérios CRÍTICO e ALTO devem ser atendidos.

**Se falhar:** Voltar ao operador com perguntas específicas para clarificar.

---

# P2: PROTOCOLO DE ARQUITETURA

> "Uma boa arquitetura torna a execução óbvia. Uma má arquitetura torna a execução impossível."

## Objetivo

Transformar a Intent Specification em uma **Execution Architecture** — um design completo de como o trabalho será executado, incluindo fases, agentes, workflows e pontos de decisão.

## Processo de Execução

### Passo 2.1: Análise de Complexidade

Classificar a complexidade para determinar o nível de arquitetura necessário:

| Complexidade | Características | Arquitetura |
|--------------|-----------------|-------------|
| **LOW** | Tarefa única, linear, sem dependências | Simples: 1-2 fases |
| **MEDIUM** | Múltiplas etapas, algumas dependências | Moderada: 3-4 fases |
| **HIGH** | Multi-agente, dependências cruzadas | Elaborada: 5-7 fases |
| **EXTREME** | Sistema completo, múltiplos workflows | Complexa: Framework próprio |

### Passo 2.2: Design de Fases

Definir as fases de execução:

```yaml
phases:
  - id: "PH-1"
    name: "Nome da Fase"
    objective: "O que esta fase realiza"
    inputs: 
      - "O que entra"
    outputs:
      - "O que sai"
    gate: "Critério para avançar"
```

**Regras de Design:**
- Cada fase tem um objetivo único e claro
- Inputs e outputs são explícitos
- Toda fase termina com um gate

### Passo 2.3: Definição de Agentes

Se a execução requer múltiplos "agentes cognitivos":

```yaml
agents:
  - id: "AGT-1"
    name: "Nome do Agente"
    role: "Papel do agente"
    expertise: "Área de conhecimento"
    invoked_in: ["PH-1", "PH-2"]
    prompt_file: "path/to/prompt.md"
```

**Regras de Design:**
- Cada agente tem uma especialidade única
- Agentes não competem, colaboram
- Sempre definir quando o agente é invocado

### Passo 2.4: Design de Workflow

Mapear o fluxo de execução:

```yaml
workflow:
  type: "LINEAR | PARALLEL | CONDITIONAL | ITERATIVE"
  
  flow:
    - step: 1
      phase: "PH-1"
      agents: ["AGT-1"]
      parallel: false
      
    - step: 2
      phase: "PH-2"
      agents: ["AGT-2", "AGT-3"]
      parallel: true
      
    - step: 3
      phase: "PH-3"
      condition: "Se output de PH-2 atender critério X"
      if_true: "PH-4"
      if_false: "PH-5"
```

### Passo 2.5: Identificação de Pontos de Decisão

Mapear onde decisões humanas são necessárias:

```yaml
decision_points:
  - id: "DP-1"
    after_phase: "PH-2"
    question: "Pergunta que o operador deve responder"
    options:
      - option: "A"
        leads_to: "PH-3A"
      - option: "B"
        leads_to: "PH-3B"
    default: "A"
```

## Output: Execution Architecture

```yaml
# EXECUTION ARCHITECTURE
# ======================

id: "ARCH-{YYYY-MM-DD}-{NNN}"
intent_id: "{referência à Intent Specification}"
created_at: "{timestamp}"

# ─────────────────────────────────────────────────────────
# CLASSIFICAÇÃO
# ─────────────────────────────────────────────────────────
classification:
  complexity: "LOW | MEDIUM | HIGH | EXTREME"
  type: "ANALYSIS | CREATION | TRANSFORMATION | ORCHESTRATION"
  estimated_phases: 0
  estimated_agents: 0

# ─────────────────────────────────────────────────────────
# FASES
# ─────────────────────────────────────────────────────────
phases:
  - id: "PH-1"
    name: ""
    objective: ""
    inputs: []
    outputs: []
    gate: ""
    estimated_duration: ""

# ─────────────────────────────────────────────────────────
# AGENTES (se aplicável)
# ─────────────────────────────────────────────────────────
agents:
  - id: "AGT-1"
    name: ""
    role: ""
    expertise: ""
    invoked_in: []

# ─────────────────────────────────────────────────────────
# WORKFLOW
# ─────────────────────────────────────────────────────────
workflow:
  type: ""
  flow: []

# ─────────────────────────────────────────────────────────
# PONTOS DE DECISÃO
# ─────────────────────────────────────────────────────────
decision_points: []

# ─────────────────────────────────────────────────────────
# RECURSOS NECESSÁRIOS
# ─────────────────────────────────────────────────────────
resources:
  tools: []
  mcps: []
  external_apis: []
  knowledge_bases: []

# ─────────────────────────────────────────────────────────
# VALIDAÇÃO
# ─────────────────────────────────────────────────────────
validation:
  gate_status: "PENDING | PASSED | FAILED"
  gate_notes: ""
```

## Gate G2: Validação de Arquitetura

**Pergunta Central:** A arquitetura é lógica e executável?

**Checklist de Validação:**

| Critério | Peso | Verificação |
|----------|------|-------------|
| Fases são sequenciáveis? | CRÍTICO | Não há dependências circulares? |
| Outputs alimentam inputs? | CRÍTICO | Cada fase recebe o que precisa? |
| Agentes estão definidos? | ALTO | Cada agente tem papel claro? |
| Pontos de decisão mapeados? | ALTO | Sabemos onde o operador intervém? |
| Recursos estão disponíveis? | MÉDIO | Temos acesso a tudo necessário? |

---

# P3: PROTOCOLO DE FRAGMENTAÇÃO

> "Uma tarefa não decomposta é uma tarefa que vai se perder no meio do caminho."

## Objetivo

Transformar a Execution Architecture em um **Checkpoint Map** — uma decomposição completa do trabalho em unidades atômicas rastreáveis: Épicos → Stories → Tasks.

## Hierarquia de Fragmentação

```
BLUEPRINT
    │
    ├── EPIC (E)
    │   │   Objetivo macro, 1-2 semanas de trabalho
    │   │
    │   ├── STORY (S)
    │   │   │   Entrega de valor, 1-3 dias de trabalho
    │   │   │
    │   │   ├── TASK (T)
    │   │   │       Unidade atômica, 15min-2h de trabalho
    │   │   │       Critério de conclusão BINÁRIO
    │   │   │
    │   │   └── TASK (T)
    │   │
    │   └── STORY (S)
    │
    └── EPIC (E)
```

## Processo de Execução

### Passo 3.1: Derivação de Épicos

Cada **fase** da arquitetura se torna um **épico**:

```yaml
epic:
  id: "E-{N}"
  derived_from: "PH-{N}"
  title: "Título do Épico"
  objective: "O que este épico realiza"
  acceptance_criteria: "Como saber que terminou"
  estimated_effort: "Em dias"
```

### Passo 3.2: Decomposição em Stories

Cada épico é decomposto em **stories**:

```yaml
story:
  id: "S-{epic}.{N}"
  parent_epic: "E-{N}"
  title: "Título da Story"
  as_a: "Persona"
  i_want: "Ação"
  so_that: "Benefício"
  acceptance_criteria:
    - "Critério 1"
    - "Critério 2"
```

### Passo 3.3: Atomização em Tasks

Cada story é atomizada em **tasks**:

```yaml
task:
  id: "T-{epic}.{story}.{N}"
  parent_story: "S-{epic}.{story}"
  title: "Título da Task"
  description: "O que fazer"
  acceptance_criteria: "ÚNICO critério binário"
  estimated_duration: "15min | 30min | 1h | 2h"
  status: "TODO | IN_PROGRESS | DONE | BLOCKED"
  blockers: []
```

**Regra de Atomização:**
- Uma task = uma ação
- Critério de conclusão binário (feito/não feito)
- Máximo 2 horas de trabalho
- Se maior, decompor mais

### Passo 3.4: Mapeamento de Dependências

```yaml
dependencies:
  - task: "T-1.1.1"
    depends_on: []
    blocks: ["T-1.1.2"]
    
  - task: "T-1.1.2"
    depends_on: ["T-1.1.1"]
    blocks: ["T-1.2.1"]
```

### Passo 3.5: Definição de Checkpoints

Checkpoints são pontos de validação durante a execução:

```yaml
checkpoints:
  - id: "CP-1"
    after_task: "T-1.1.3"
    validation: "O que verificar"
    action_if_fail: "O que fazer se falhar"
    updates_state: true
```

## Output: Checkpoint Map

```yaml
# CHECKPOINT MAP
# ==============

id: "CKPT-{YYYY-MM-DD}-{NNN}"
architecture_id: "{referência à Architecture}"
created_at: "{timestamp}"

# ─────────────────────────────────────────────────────────
# SUMÁRIO
# ─────────────────────────────────────────────────────────
summary:
  total_epics: 0
  total_stories: 0
  total_tasks: 0
  total_checkpoints: 0
  estimated_total_effort: ""

# ─────────────────────────────────────────────────────────
# ÉPICOS
# ─────────────────────────────────────────────────────────
epics:
  - id: "E-1"
    title: ""
    objective: ""
    acceptance_criteria: ""
    status: "TODO"
    
    stories:
      - id: "S-1.1"
        title: ""
        acceptance_criteria: []
        status: "TODO"
        
        tasks:
          - id: "T-1.1.1"
            title: ""
            acceptance_criteria: ""
            estimated_duration: ""
            status: "TODO"
            depends_on: []

# ─────────────────────────────────────────────────────────
# CHECKPOINTS
# ─────────────────────────────────────────────────────────
checkpoints:
  - id: "CP-1"
    after_task: ""
    validation: ""
    action_if_fail: ""

# ─────────────────────────────────────────────────────────
# DEPENDÊNCIAS (GRAFO)
# ─────────────────────────────────────────────────────────
dependency_graph:
  nodes: []
  edges: []
```

## Gate G3: Validação de Fragmentação

**Pergunta Central:** Toda a execução está mapeada em tasks atômicas?

**Checklist:**

| Critério | Peso | Verificação |
|----------|------|-------------|
| Toda fase virou épico? | CRÍTICO | Nenhuma fase órfã? |
| Tasks são atômicas? | CRÍTICO | Todas < 2h, critério binário? |
| Dependências mapeadas? | ALTO | Grafo está completo? |
| Checkpoints definidos? | ALTO | Pontos de validação existem? |

---

# P4: PROTOCOLO DE CRISTALIZAÇÃO

> "Um Blueprint que não pode ser executado por outro é um Blueprint que falhou."

## Objetivo

Consolidar todos os outputs anteriores em artefatos finais, prontos para exportação e execução no projeto-alvo.

## Artefatos Gerados

### 4.1 Blueprint Operacional

O documento mestre que contém **tudo** necessário para execução:

```markdown
# BLUEPRINT OPERACIONAL
# {Título do Projeto}

**ID:** BP-{YYYY-MM-DD}-{NNN}
**Versão:** 1.0.0
**Gerado por:** ATHENA OS
**Data:** {timestamp}
**Projeto-alvo:** {nome do projeto}

---

## 1. SUMÁRIO EXECUTIVO

### 1.1 O Que É
{Descrição em 2-3 frases}

### 1.2 Por Que Existe
{JTBD formatado}

### 1.3 Resultado Esperado
{Lista de deliverables}

---

## 2. INTENT SPECIFICATION

{Conteúdo completo do P1}

---

## 3. EXECUTION ARCHITECTURE

{Conteúdo completo do P2}

### 3.1 Diagrama de Fluxo
{Mermaid diagram}

### 3.2 Fases Detalhadas
{Tabela de fases}

### 3.3 Agentes
{Descrição de cada agente}

---

## 4. CHECKPOINT MAP

{Conteúdo completo do P3}

### 4.1 Visão Geral
{Tabela resumo}

### 4.2 Épicos Detalhados
{Cada épico com suas stories e tasks}

---

## 5. TAXONOMY CONFIG

### 5.1 Estrutura de Outputs
{Onde cada coisa vai}

### 5.2 Convenções de Nomenclatura
{Padrões a seguir}

---

## 6. GUIA DE EXECUÇÃO

### 6.1 Pré-requisitos
{O que precisa estar pronto}

### 6.2 Primeiro Passo
{Como começar}

### 6.3 Pontos de Atenção
{Onde cuidado é necessário}

---

## 7. CRITÉRIOS DE SUCESSO

{Lista de critérios binários}

---

## ANEXOS

- A: Prompts de Agentes
- B: Templates de Output
- C: Referências
```

### 4.2 Activation Prompt

O prompt pronto para colar no projeto-alvo:

```markdown
# ACTIVATION PROMPT
# {Título do Projeto}

---

## CONTEXTO

Você está prestes a executar um Blueprint gerado pelo ATHENA OS.

**Operador:** {nome}
**Projeto:** {nome do projeto}
**Data:** {timestamp}

---

## BLUEPRINT

O Blueprint completo está em:
`{caminho/para/BLUEPRINT.md}`

**IMPORTANTE:** Leia o Blueprint COMPLETO antes de executar qualquer coisa.

---

## INSTRUÇÕES DE EXECUÇÃO

1. **LER** o Blueprint (seções 1-4)
2. **VERIFICAR** pré-requisitos (seção 6.1)
3. **INICIAR** pelo primeiro épico (seção 4.2)
4. **ATUALIZAR** o STATE a cada checkpoint
5. **VALIDAR** critérios de sucesso ao final (seção 7)

---

## PRIMEIRO COMANDO

```
{comando sugerido para iniciar}
```

---

## REGRAS

- NÃO pular etapas
- NÃO ignorar checkpoints
- ATUALIZAR STATE após cada task concluída
- PARAR e reportar se encontrar bloqueio

---

## EM CASO DE DÚVIDA

Consultar:
- Blueprint seção relevante
- ATHENA OS para clarificação
```

### 4.3 Taxonomy Config

```yaml
# TAXONOMY CONFIG
# ===============

project_root: "{caminho/do/projeto}"

output_structure:
  primary_output:
    path: "{onde vai o output principal}"
    format: "{md | yaml | json}"
    naming: "{convenção}"
    
  secondary_outputs:
    - type: "{tipo}"
      path: "{caminho}"
      format: "{formato}"
      
  logs:
    path: "{caminho/logs}"
    
  temp:
    path: "{caminho/temp}"
    cleanup: true

naming_conventions:
  files: "{padrão}"
  folders: "{padrão}"
  timestamps: "YYYY-MM-DD"
  
state_file:
  path: "{caminho/STATE.yaml}"
  update_frequency: "on_checkpoint"
```

## Gate G4: Validação Final

**Pergunta Central:** O Blueprint é auto-contido e transferível?

**Teste de Transferibilidade:**
> Se alguém que nunca viu este projeto ler apenas o Blueprint, consegue executar?

**Checklist:**

| Critério | Peso | Verificação |
|----------|------|-------------|
| Blueprint completo? | CRÍTICO | Todas as seções preenchidas? |
| Activation Prompt funciona? | CRÍTICO | Instruções são executáveis? |
| Taxonomy definida? | CRÍTICO | Outputs têm destino? |
| Sem referências quebradas? | ALTO | Todos os links funcionam? |
| Linguagem clara? | ALTO | Sem jargão inexplicado? |

---

## Resumo dos Protocolos

| Protocolo | Input | Output | Gate |
|-----------|-------|--------|------|
| **P1: DECODE** | Intenção bruta | Intent Specification | G1 |
| **P2: ARCHITECT** | Intent Spec | Execution Architecture | G2 |
| **P3: FRAGMENT** | Architecture | Checkpoint Map | G3 |
| **P4: CRYSTALLIZE** | Tudo anterior | Blueprint + Activation + Taxonomy | G4 |

---

*"Processo é liberdade disfarçada de restrição." — ATHENA*
