# MULTI-AGENT PATTERNS — ATHENA OS 2.0

> **"Orquestração multi-agent é a arte de coordenar múltiplas inteligências para criar emergência maior que a soma das partes."**

---

## PATTERN 1: FAN-OUT (Paralelo Independente)

### Quando Usar
- Tasks independentes através de um epic
- Nenhuma task depende do output de outra
- Todas podem ser especificadas upfront
- Velocidade é prioritária

### Estrutura

```
                    ┌─────────────┐
                    │ ORCHESTRATOR│
                    │  (ATHENA)   │
                    └──────┬──────┘
                           │ split work
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
      ┌─────────┐    ┌─────────┐    ┌─────────┐
      │ Agent A │    │ Agent B │    │ Agent C │
      │  Epic 1 │    │  Epic 2 │    │  Epic 3 │
      └────┬────┘    └────┬────┘    └────┬────┘
           │               │               │
           └───────────────┼───────────────┘
                           │ collect results
                    ┌──────▼──────┐
                    │   RESULT    │
                    │  SYNTHESIS  │
                    └─────────────┘
```

### Exemplo Prático

**Caso:** Implementar 4 épicos independentes de um Blueprint

```yaml
Agents:
  - agent_id: "E1"
    type: "executor"
    epic: "Epic 1: Design System Setup"
    briefing: "Create design system files per specifications"

  - agent_id: "E2"
    type: "executor"
    epic: "Epic 2: Core Components"
    briefing: "Implement UI components library"

  - agent_id: "E3"
    type: "executor"
    epic: "Epic 3: Page Templates"
    briefing: "Create page templates"

  - agent_id: "E4"
    type: "executor"
    epic: "Epic 4: Hooks & Utils"
    briefing: "Implement custom hooks and utilities"

Execution: PARALLEL
Merge: Collect outputs + verify integration points
```

### Benefícios
- 4x velocidade (4 agents vs 1)
- Isolamento de falhas
- Foco profundo por agent

### Riscos
- Conflitos de merge se não planejado
- Comunicação inter-agent necessária
- Overhead de coordenação

### Mitigação
- Definir interfaces claramente antes
- Dividir em modules/directories independentes
- Briefing completo para cada agent

---

## PATTERN 2: PIPELINE (Sequencial com Handoff)

### Quando Usar
- Output de uma fase é input da próxima
- Cada fase requer expertise diferente
- Progressão linear é natural
- Não pode paralelizar

### Estrutura

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ Agent A │───►│ Agent B │───►│ Agent C │───►│ Agent D │
│ RESEARCH│    │  PLAN   │    │ EXECUTE │    │ REVIEW  │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
     │              │              │              │
     ▼              ▼              ▼              ▼
  Findings      Blueprint      Code/Docs     Validation
```

### Exemplo Prático

**Caso:** Criar feature complexa com pesquisa necessária

```yaml
Phase 1 - Research:
  agent: "researcher"
  input: "Investigate existing approaches"
  output: "findings.md"

Phase 2 - Architecture:
  agent: "architect"
  input: "findings.md"
  output: "architecture-decision.md"

Phase 3 - Implementation:
  agent: "executor"
  input: "architecture-decision.md"
  output: "code + tests"

Phase 4 - Review:
  agent: "reviewer"
  input: "code + tests"
  output: "approval or corrections"
```

### Benefícios
- Especialização por fase
- Handoff explícito e rastreável
- Qualidade aumenta a cada fase

### Riscos
- Mais lento que paralelo
- Bloqueio se fase anterior falha
- Perda de contexto nos handoffs

### Mitigação
- Documentar handoffs completamente
- Critérios de aceite claros por fase
- Checkpoints entre fases

---

## PATTERN 3: MAP-REDUCE (Processamento em Escala)

### Quando Usar
- Grande volume de dados/tasks similares
- Processamento idêntico em múltiplos items
- Agregação final necessária
- Escalabilidade é crítica

### Estrutura

```
                    ┌─────────────┐
                    │   DATASET   │
                    │ (100 items) │
                    └──────┬──────┘
                           │ split
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
      ┌─────────┐    ┌─────────┐    ┌─────────┐
      │ Agent A │    │ Agent B │    │ Agent C │
      │ Items   │    │ Items   │    │ Items   │
      │ 1-33    │    │ 34-66   │    │ 67-100  │
      └────┬────┘    └────┬────┘    └────┬────┘
           │               │               │
           │ process       │ process       │ process
           │               │               │
           └───────────────┼───────────────┘
                           │ reduce
                    ┌──────▼──────┐
                    │  AGGREGATE  │
                    │   RESULTS   │
                    └─────────────┘
```

### Exemplo Prático

**Caso:** Criar 30 personas para Genius Layer

```yaml
Map Phase:
  total_personas: 30
  batch_size: 10

  agents:
    - agent_id: "P1"
      personas: ["persona_01" through "persona_10"]

    - agent_id: "P2"
      personas: ["persona_11" through "persona_20"]

    - agent_id: "P3"
      personas: ["persona_21" through "persona_30"]

Reduce Phase:
  action: "Aggregate all personas"
  validation: "Ensure all 30 personas created"
  output: "personas library complete"
```

### Benefícios
- Escala linear com número de agents
- Ideal para trabalho repetitivo
- Alta velocidade de throughput

### Riscos
- Overhead de split/merge
- Consistência entre batches
- Duplicação de trabalho se mal dividido

### Mitigação
- Batch size apropriado
- Template claro para todos agents
- Validação final agregada

---

## PATTERN 4: REVIEW CHAIN (Criação + Validação)

### Quando Usar
- Qualidade é crítica
- Dois olhares melhor que um
- Implementação + review necessários
- Risk de erros é alto

### Estrutura

```
┌─────────────┐
│  CREATOR    │
│  Agent      │
└──────┬──────┘
       │ creates
       ▼
┌─────────────┐
│   ARTIFACT  │
│  (draft)    │
└──────┬──────┘
       │ review
       ▼
┌─────────────┐
│  REVIEWER   │
│   Agent     │
└──────┬──────┘
       │
       ├─────► APPROVED ──────► DONE
       │
       ├─────► CORRECTIONS ───► Back to CREATOR
       │
       └─────► REJECTED ───────► Escalate
```

### Exemplo Prático

**Caso:** Implementar código crítico com review

```yaml
Phase 1 - Creation:
  agent: "executor"
  task: "Implement authentication system"
  output: "auth code + tests"

Phase 2 - Review:
  agent: "reviewer"
  input: "auth code + tests"
  checks:
    - "Security vulnerabilities"
    - "Test coverage > 80%"
    - "Error handling comprehensive"

  outcomes:
    - APPROVED: Ship
    - CORRECTIONS: List issues → executor fixes
    - REJECTED: Architecture flaw → escalate
```

### Benefícios
- Catch de erros antes de ship
- Qualidade dupla
- Learning para creator

### Riscos
- Mais lento que single-agent
- Conflito entre creator/reviewer
- Over-engineering se reviewer é perfeccionista

### Mitigação
- Critérios de review objetivos
- Timeboxing de review
- Escalation path definido

---

## PATTERN 5: COORDINATOR (Multi-Agent Sync)

### Quando Usar
- Multiple agents precisam coordenar
- Estado compartilhado crítico
- Conflitos precisam ser resolvidos
- Orquestração complexa necessária

### Estrutura

```
                    ┌─────────────┐
                    │ COORDINATOR │
                    │   Agent     │
                    └──────┬──────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
      ┌─────────┐    ┌─────────┐    ┌─────────┐
      │ Worker A│◄──►│ Worker B│◄──►│ Worker C│
      └─────────┘    └─────────┘    └─────────┘
           │               │               │
           └───────────────┼───────────────┘
                           │
                    ┌──────▼──────┐
                    │  SHARED     │
                    │  STATE      │
                    └─────────────┘
```

### Exemplo Prático

**Caso:** Implementação com dependências cruzadas

```yaml
Coordinator:
  agent_id: "coordinator"
  responsibilities:
    - "Track completion status"
    - "Resolve conflicts"
    - "Manage shared state"
    - "Sync between workers"

Workers:
  - agent_id: "W1"
    task: "API layer"
    dependencies: ["shared types"]

  - agent_id: "W2"
    task: "UI components"
    dependencies: ["shared types", "API contracts"]

  - agent_id: "W3"
    task: "Shared types"
    dependencies: []

Execution Flow:
  1. Coordinator identifies W3 must go first
  2. W3 creates shared types
  3. Coordinator notifies W1 and W2
  4. W1 and W2 run in parallel
  5. Coordinator verifies integration
```

### Benefícios
- Gerencia dependências complexas
- Sincronização explícita
- Resolução de conflitos centralizada

### Riscos
- Coordinator é bottleneck
- Overhead de coordenação
- Complexidade aumenta

### Mitigação
- Minimizar dependências cruzadas
- Coordinator focado em sync, não execução
- Documentar estado compartilhado

---

## SELECTION MATRIX

| Cenário | Pattern | Por quê |
|---------|---------|---------|
| 4 epics independentes | FAN-OUT | Paralelo, sem dependências |
| Research → Plan → Build | PIPELINE | Sequencial, handoff necessário |
| Criar 50 personas | MAP-REDUCE | Volume, tarefas similares |
| Implementar feature crítica | REVIEW CHAIN | Qualidade crítica |
| Sistema com dependências cruzadas | COORDINATOR | Estado compartilhado, sync necessário |

---

## ANTI-PATTERNS

### 1. Over-coordination
**Problema:** Criar coordinator quando não necessário
**Solução:** Usar FAN-OUT se tasks são realmente independentes

### 2. Under-specification
**Problema:** Lançar agents sem briefing completo
**Solução:** Template de briefing completo sempre

### 3. Serial when Parallel
**Problema:** Rodar sequencial quando podia ser paralelo
**Solução:** Sempre questionar se pode paralelizar

### 4. No Merge Strategy
**Problema:** Rodar paralelo sem plano de merge
**Solução:** Definir merge antes de split

### 5. Agent Sprawl
**Problema:** Muitos agents sem coordenação
**Solução:** Máximo de 4-5 agents paralelos, usar coordinator se mais

---

## IMPLEMENTATION CHECKLIST

Antes de implementar multi-agent:

- [ ] Pattern selecionado é o correto?
- [ ] Briefing completo para cada agent?
- [ ] Dependências mapeadas?
- [ ] Merge strategy definida?
- [ ] Exit criteria para cada agent?
- [ ] Fallback se agent falha?
- [ ] Contexto compartilhado documentado?

---

*ATHENA OS 2.0 — Multi-Agent Patterns*
*"Orquestração é transformar N em N²."*
