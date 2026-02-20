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

---

## FORMICA-Compatible Task Fields

Para garantir que tasks sejam executaveis por FORMICA (FORMIGA v3.0 execution engine), cada task DEVE incluir estes 11 campos obrigatorios:

### Campos Obrigatorios

```yaml
task:
  # 1. Identidade
  id: "T-1.1.1"                          # Format: T-{epic}.{story}.{task_num}
  title: "Implementar validacao de entrada"
  description: |
    Implementar funcao que valida entrada do usuario.
    Deve rejeitar valores negativos e strings vazias.

  # 2. Contexto de Execucao
  worker: "implementer"                  # analyst|architect|implementer|writer
  model: "haiku"                         # haiku|sonnet|opus

  # 3. Saida Esperada
  output: "src/validators.py"            # Caminho do arquivo a ser criado/modificado
  context_files:                         # Arquivos de referencia (leitura)
    - "docs/architecture/validation.md"
    - "src/existing_validators.py"
  expected_format: "py"                  # md|yaml|json|sh|py|ts|js
  expected_lines: 45                     # Aproximacao (±20 linhas aceitavel)

  # 4. Criterios de Aceitacao
  acceptance_criteria:
    - "Funcao valida rejeita valores negativos"
    - "Funcao valida rejeita strings vazias"
    - "Funcao lida com None sem crash"

  # 5. Dependencias
  depends_on: ["T-1.1.0"]                # List de task IDs (vazio se nenhuma)

  # 6. Metadados de Planejamento
  estimated_duration:
    value: 45
    unit: "minutes"
  status: "TODO"
```

### Exemplo Completo (FORMICA v3.0 ready)

```yaml
- id: "T-2.3.5"
  title: "Gerar relatorio de execucao"
  description: |
    Criar arquivo execution-report.md com:
    - Resumo de tarefas executadas
    - Custos totais
    - Tempo decorrido
    - Problemas encontrados

  worker: "writer"
  model: "haiku"
  output: "outputs/execution-report.md"
  context_files:
    - ".planning/execution-log.jsonl"
    - "protocols/P5-EXECUTE.md"
  expected_format: "md"
  expected_lines: 120

  acceptance_criteria:
    - "Arquivo gerado com todos os 4 secoes"
    - "Numeros de tarefas coincidem com execution-log.jsonl"
    - "Arquivo é markdown valido"

  depends_on: ["T-2.3.4"]

  estimated_duration:
    value: 60
    unit: "minutes"
  status: "TODO"
```

### Campo-a-Campo Explicacao

| Campo | Tipo | Exemplo | Validacao |
|-------|------|---------|-----------|
| id | string | T-1.1.3 | Deve ser unico no blueprint |
| title | string | Implementar parser | Nao vazio, <80 chars |
| description | string | Criar... | Detalhado o suficiente para executor cego |
| worker | enum | implementer | Must be: analyst, architect, implementer, writer |
| model | enum | haiku | Must be: haiku, sonnet, opus |
| output | string | src/main.py | Caminho absoluto ou relativo claro |
| context_files | list | [src/lib.py] | Arquivos de entrada (nao incluir output aqui) |
| expected_format | enum | py | Extensao do arquivo ou tipo semantico |
| expected_lines | int | 45 | Aproximacao (tolerancia ±20 linhas) |
| acceptance_criteria | list | [Task generates valid JSON] | Minimo 2 criterios, cada um testavel |
| depends_on | list | [T-1.1.2] | IDs das tasks predecessoras (vazio = paralelo) |
| estimated_duration | object | {value: 45, unit: minutes} | Para planejamento de throughput |

---

## Worker Type Selection Guide

Escolher o worker correto melhora significativamente a qualidade do output. Cada tipo tem foco cognitivo distinto:

### Analyst (Research, Audit, Analysis)

**Quando usar:**
- Investigar problema complexo
- Fazer audit de codigo/sistema
- Comparar opcoes/alternativas
- Extrair padroes de dados
- Produzir relatorios/summaries

**Caracteristicas:**
- Profundo, cuidadoso, critico
- Produz: `.md` (analise), `.json` (dados estruturados), `.yaml` (inventarios)
- Modelo preferido: haiku (custo-beneficio) → sonnet se complexo
- Output tipico: 200-800 linhas
- Tempo: 30-90 minutos

**Exemplo task:**
```yaml
- id: "T-1.1.1"
  title: "Auditar uso de globals no codebase"
  worker: "analyst"
  model: "sonnet"
  output: "reports/globals-audit.md"
  context_files:
    - "src/**/*.py"
    - "docs/code-standards.md"
  expected_format: "md"
  expected_lines: 250
  acceptance_criteria:
    - "Identifica TODAS as globals (grep verificacao)"
    - "Relatorio tem sessoes por arquivo"
    - "Cada global tem uso-case e risco documentados"
  depends_on: []
```

### Architect (Design, Planning, Structure)

**Quando usar:**
- Desenhar solucao/feature
- Definir API/interface
- Planejar fluxo de dados
- Criar estrutura de diretorio
- Fazer design review

**Caracteristicas:**
- Foco em structure, interfaces, constraints
- Produz: `.yaml` (configs), `.md` (ADRs), diagrams
- Modelo preferido: sonnet (precisa raciocinio)
- Output tipico: 300-600 linhas
- Tempo: 45-120 minutos

**Exemplo task:**
```yaml
- id: "T-1.2.1"
  title: "Desenhar API de workers"
  worker: "architect"
  model: "sonnet"
  output: "docs/worker-api.yaml"
  context_files:
    - "docs/architecture/execution.md"
    - "protocols/P5-EXECUTE.md"
  expected_format: "yaml"
  expected_lines: 180
  acceptance_criteria:
    - "API define inputs/outputs para cada worker type"
    - "Exemplo JSON valido para cada endpoint"
    - "Constraints documentadas (max file size, timeout, etc)"
  depends_on: []
```

### Implementer (Code, Config, Building)

**Quando usar:**
- Escrever codigo/scripts
- Criar configuracoes
- Implementar features
- Fazer refactoring
- Integrar componentes

**Caracteristicas:**
- Foco em funcionalidade, coesao, testabilidade
- Produz: `.py`, `.sh`, `.json`, `.yaml`, `.ts`
- Modelo preferido: haiku (tarefas claras) → sonnet (designs complexos)
- Output tipico: 50-300 linhas
- Tempo: 20-90 minutos

**Exemplo task:**
```yaml
- id: "T-2.1.3"
  title: "Implementar worker pool"
  worker: "implementer"
  model: "sonnet"
  output: "src/worker_pool.py"
  context_files:
    - "docs/worker-api.yaml"
    - "src/base_worker.py"
  expected_format: "py"
  expected_lines: 120
  acceptance_criteria:
    - "WorkerPool.spawn() cria novo worker"
    - "Suporta up to 10 workers paralelos"
    - "Todas funcoes tem type hints"
  depends_on: ["T-2.1.1", "T-2.1.2"]
```

### Writer (Documentation, Content, Communication)

**Quando usar:**
- Documentar feature/sistema
- Escrever guias/tutoriais
- Criar READMEs
- Fazer relatorios para humanos
- Estruturar conhecimento

**Caracteristicas:**
- Foco em clareza, estrutura, navegabilidade
- Produz: `.md` (documentacao, guias), `.txt` (relatorios)
- Modelo preferido: haiku (formatacao simples) → sonnet (conteudo rico)
- Output tipico: 200-1000 linhas
- Tempo: 30-120 minutos

**Exemplo task:**
```yaml
- id: "T-3.2.1"
  title: "Escrever guia de deployment"
  worker: "writer"
  model: "haiku"
  output: "docs/DEPLOYMENT.md"
  context_files:
    - ".planning/deployment-plan.yaml"
    - "src/deployment.sh"
    - "docs/architecture.md"
  expected_format: "md"
  expected_lines: 350
  acceptance_criteria:
    - "Secoes: Prerequisitos, Passos, Troubleshooting, Rollback"
    - "Cada passo pode ser executado verbatim"
    - "Inclui exemplos de output esperado"
  depends_on: ["T-3.1.5"]
```

---

## Model Selection Guide

Escolher o modelo correto equilibra custo, qualidade e velocidade:

### Haiku (Fast, Cost-Effective)

**Quando usar:**
- Tasks bem-definidas com entradas claras
- Refactoring/reformatacao
- Documentacao estruturada
- Analise rotineira
- Implementacao simples

**Caracteristicas:**
- Custo: ~$0.003 por task típica (execucao completa)
- Latencia: ~30 segundos
- Output quality: A- (excelente para tarefas focadas)
- Limite de contexto: 200K tokens
- Best for: 5-30 min tasks

**Exemplo tasks para haiku:**
- Refactor função de 50 linhas
- Gerar documentação de API simples
- Validar JSON contra schema
- Criar arquivo de configuracao
- Escrever docstrings/comentarios

```yaml
- id: "T-1.1.1"
  title: "Converter YAML para JSON"
  worker: "implementer"
  model: "haiku"          # ← haiku é suficiente
  output: "config.json"
```

### Sonnet (Balanced - Recommended Default)

**Quando usar:**
- Tasks que requerem raciocinio
- Design/arquitetura
- Code review / audit
- Integration de multiplos componentes
- Problemas sem solucao obvia
- Refactoring profundo (>100 linhas)

**Caracteristicas:**
- Custo: ~$0.01 per task típica (execucao completa)
- Latencia: ~40-60 segundos
- Output quality: A+ (excelente para tudo)
- Limite de contexto: 200K tokens
- Best for: 30-120 min tasks (default para problemas)

**Exemplo tasks para sonnet:**
```yaml
- id: "T-2.1.2"
  title: "Desenhar arquitetura de cache"
  worker: "architect"
  model: "sonnet"          # ← sonnet para design
  output: "docs/cache-architecture.md"

- id: "T-2.2.5"
  title: "Implementar parser YAML complexo"
  worker: "implementer"
  model: "sonnet"          # ← sonnet para logica complexa
  output: "src/yaml_parser.py"
```

### Opus (Critical Path, Complex Reasoning)

**Quando usar:**
- Decisoes arquiteturais criticas
- Debugging de bugs complexos
- Refactoring de sistema monolitico (>1K linhas)
- Tasks que afetam multiplos sistemas
- Rara (use sonnet por default)

**Caracteristicas:**
- Custo: ~$0.03 per task típica (execucao completa)
- Latencia: ~60-90 segundos
- Output quality: A++ (maxima confiabilidade)
- Limite de contexto: 200K tokens
- Best for: critical path, maximum confidence needed

**Exemplo tasks para opus:**
```yaml
- id: "T-3.0.1"
  title: "Redesenhar sistema de eventos"
  worker: "architect"
  model: "opus"            # ← opus para arquitetura critica
  output: "docs/event-system-v2.md"
  context_files:
    - "src/events/**/*.py"
    - "docs/requirements.md"
    - "reports/performance-bottlenecks.md"
```

### Cost vs. Quality Trade-off

```
Task Complexity    |  Haiku   |  Sonnet  |  Opus
-------------------|----------|----------|----------
Simple (5-15 min)  |   ★★★★★  |   ★★★★☆  |   -
Medium (30-60 min) |   ★★★★☆  |   ★★★★★  |   ★★★★☆
Complex (60+ min)  |   ★★★☆☆  |   ★★★★★  |   ★★★★★
Critical path      |   ★★★☆☆  |   ★★★★☆  |   ★★★★★
```

**Rule of Thumb:**
- Default: **sonnet**
- Save cost: haiku para tarefas simples/claras
- Maximize quality: opus para criticos/complexos
- Never: use opus para refactoring de 30 linhas

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
