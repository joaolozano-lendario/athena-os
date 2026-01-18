# P3: PROTOCOLO DE FRAGMENTACAO

> Quebrar a arquitetura em unidades atomicas rastreaveis

**Versao:** 1.0.0
**Gate de Saida:** G3 - Toda a execucao esta mapeada em tasks atomicas?
**Referencia:** docs/architecture/02-PROTOCOLS.md

---

## Objetivo

Transformar a Execution Architecture em um **Checkpoint Map** - uma decomposicao completa do trabalho em unidades atomicas rastreaveis: Epicos -> Stories -> Tasks.

---

## Entrada

- Execution Architecture validada (G2 PASSED)
- `exec-arch.yaml`

---

## Saida

- `checkpoint-map.yaml` completo e validado
- Grafo de dependencias
- Gate G3 PASSED

---

## Hierarquia de Fragmentacao

```
BLUEPRINT
    |
    +-- EPIC (E)
    |   |   Objetivo macro, 1-2 semanas de trabalho
    |   |
    |   +-- STORY (S)
    |   |   |   Entrega de valor, 1-3 dias de trabalho
    |   |   |
    |   |   +-- TASK (T)
    |   |   |       Unidade atomica, 15min-2h de trabalho
    |   |   |       Criterio de conclusao BINARIO
    |   |   |
    |   |   +-- TASK (T)
    |   |
    |   +-- STORY (S)
    |
    +-- EPIC (E)
```

---

## Processo de Execucao

### Passo 3.1: Derivacao de Epicos

Cada **fase** da arquitetura se torna um **epico**:

```yaml
epic:
  id: "E-{N}"
  derived_from: "PH-{N}"
  title: "Titulo do Epico"
  objective: |
    O que este epico realiza.
  acceptance_criteria: |
    Como saber que terminou.
  estimated_effort:
    value: 0
    unit: "days"
  status: "TODO"
```

**Regra:** 1 Fase = 1 Epico (em geral)

### Passo 3.2: Decomposicao em Stories

Cada epico e decomposto em **stories**:

```yaml
story:
  id: "S-{epic}.{N}"
  parent_epic: "E-{N}"
  title: "Titulo da Story"

  user_story:
    as_a: "Persona/Role"
    i_want: "Acao desejada"
    so_that: "Beneficio/Valor"

  acceptance_criteria:
    - "Criterio 1 - binario"
    - "Criterio 2 - binario"

  estimated_effort:
    value: 0
    unit: "hours"

  status: "TODO"
```

**Regras de Story:**
- Entrega valor isoladamente
- 1-3 dias de trabalho
- Multiplas tasks

### Passo 3.3: Atomizacao em Tasks

Cada story e atomizada em **tasks**:

```yaml
task:
  id: "T-{epic}.{story}.{N}"
  parent_story: "S-{epic}.{story}"
  title: "Titulo da Task"

  description: |
    O que fazer, em detalhes suficientes para execucao.

  # UNICO criterio, BINARIO
  acceptance_criterion: "Condicao binaria de conclusao"

  estimated_duration:
    value: 30
    unit: "minutes"

  status: "TODO"
  depends_on: []
  blocks: []
```

**Regras de Atomizacao:**
- Uma task = uma acao
- Criterio de conclusao binario (feito/nao feito)
- Maximo 2 horas de trabalho
- Se maior, decompor mais

### Passo 3.4: Mapeamento de Dependencias

```yaml
dependencies:
  - task: "T-1.1.1"
    depends_on: []
    blocks: ["T-1.1.2"]

  - task: "T-1.1.2"
    depends_on: ["T-1.1.1"]
    blocks: ["T-1.2.1"]
```

Criar grafo de dependencias:

```yaml
dependency_graph:
  nodes:
    - id: "T-1.1.1"
      type: "task"
      status: "TODO"

  edges:
    - from: "T-1.1.1"
      to: "T-1.1.2"
      type: "blocks"
```

### Passo 3.5: Definicao de Checkpoints

Checkpoints sao pontos de validacao durante a execucao:

```yaml
checkpoints:
  - id: "CP-1"
    name: "Nome do Checkpoint"
    after_task: "T-1.1.3"

    validation:
      question: "O que verificar?"
      criteria:
        - "Criterio 1"
        - "Criterio 2"

    action_if_pass: "Prosseguir para proxima task"
    action_if_fail: "O que fazer se falhar"

    updates_state: true
```

**Regras de Checkpoint:**
- Apos tasks criticas
- Apos mudancas de fase
- Antes de pontos de decisao
- Quando STATE precisa ser atualizado

### Passo 3.6: Calculo de Sumario

```yaml
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
```

---

## Gate G3: Validacao de Fragmentacao

**Pergunta Central:** Toda a execucao esta mapeada em tasks atomicas?

### Checklist de Validacao

| Criterio | Peso | Verificacao |
|----------|------|-------------|
| Toda fase virou epico? | CRITICO | Nenhuma fase orfa? |
| Tasks sao atomicas? | CRITICO | Todas < 2h, criterio binario? |
| Dependencias mapeadas? | ALTO | Grafo esta completo? |
| Checkpoints definidos? | ALTO | Pontos de validacao existem? |
| Sumario calculado? | MEDIO | Totais estao corretos? |

### Regra de Passagem

- Todos os criterios CRITICO e ALTO devem ser atendidos

### Se Falhar

1. Identificar quais criterios falharam
2. Decompor mais se tasks > 2h
3. Adicionar dependencias faltantes
4. Definir checkpoints faltantes
5. Re-executar Gate G3

---

## Testes de Atomicidade

### Teste 1: Duracao

```
SE task > 2 horas ENTAO
   DECOMPOR em tasks menores
```

### Teste 2: Criterio Binario

```
SE criterio nao for sim/nao ENTAO
   REFORMULAR criterio
```

### Teste 3: Acao Unica

```
SE task tem "e" ou "," ENTAO
   PROVAVELMENTE sao 2+ tasks
```

### Teste 4: Dependencia Clara

```
SE "posso comecar sem X estar pronto?" = NAO ENTAO
   X e dependencia
```

---

## Output Template

Ver: `templates/checkpoints/CHECKPOINT-MAP.yaml`

---

## Padroes de Fragmentacao

### Padrao: Preparar-Executar-Validar

Para cada fase:
```
EPIC: [Fase X]
  STORY: Preparacao
    TASK: Verificar pre-requisitos
    TASK: Coletar inputs
  STORY: Execucao
    TASK: Executar passo 1
    TASK: Executar passo 2
  STORY: Validacao
    TASK: Verificar outputs
    TASK: Documentar resultado
```

### Padrao: CRUD

Para operacoes de dados:
```
STORY: Criar [Recurso]
  TASK: Definir schema
  TASK: Implementar criacao
  TASK: Testar criacao

STORY: Ler [Recurso]
  ...
```

### Padrao: Research-Design-Build

Para criacao de features:
```
EPIC: [Feature]
  STORY: Pesquisa
  STORY: Design
  STORY: Implementacao
  STORY: Testes
  STORY: Documentacao
```

---

## Checklist Final

Antes de passar para P4:

- [ ] Todos os epicos derivados das fases
- [ ] Todas as stories com user story format
- [ ] Todas as tasks atomicas (< 2h, binarias)
- [ ] Dependencias mapeadas
- [ ] Checkpoints definidos
- [ ] Sumario calculado
- [ ] Grafo de dependencias criado
- [ ] Gate G3 PASSED
- [ ] STATE.yaml atualizado

---

*"Uma task nao decomposta e uma task que vai se perder no meio do caminho." - ATHENA*
