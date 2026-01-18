# /ATHENA:tasks:fragment-work

> Fase P3: Fragmentação do Trabalho (execução isolada)

---

## Descrição

Executa apenas a Fase P3 do pipeline, decompondo uma Execution Architecture em unidades atômicas rastreáveis: Épicos → Stories → Tasks.

---

## Pré-requisitos

- Execution Architecture existente (output de P2)

---

## Fluxo

```
INPUT: Execution Architecture
   │
   ▼
DERIVAÇÃO DE ÉPICOS
   └── Cada fase → 1 épico
   │
   ▼
DECOMPOSIÇÃO EM STORIES
   └── Cada épico → N stories
       (entregas de valor)
   │
   ▼
ATOMIZAÇÃO EM TASKS
   └── Cada story → N tasks
       (unidades atômicas, <2h)
   │
   ▼
MAPEAMENTO DE DEPENDÊNCIAS
   └── Grafo de dependências
   │
   ▼
DEFINIÇÃO DE CHECKPOINTS
   └── Pontos de validação
   │
   ▼
GATE G3: Fragmentação completa?
   │
   ├── PASS ──► checkpoint-map.yaml gerado
   └── FAIL ──► Decompor mais
```

---

## Regras de Fragmentação

### Task Atômica
- UMA ação
- Critério BINÁRIO (feito/não feito)
- Máximo 2 horas
- Se maior → decompor mais

### Story
- Entrega valor isoladamente
- 1-3 dias de trabalho
- Múltiplas tasks

### Épico
- Objetivo macro
- 1-2 semanas de trabalho
- Múltiplas stories

---

## Instruções para ATHENA

1. Carregar Execution Architecture
2. Processar usando protocolo `protocols/P3-FRAGMENT.md`
3. Para cada fase:
   - Criar épico
   - Decompor em stories
   - Atomizar em tasks
4. Mapear dependências
5. Definir checkpoints
6. Gerar `checkpoint-map.yaml`
7. Apresentar visão geral + detalhes
8. Solicitar validação (Gate G3)

---

## Output

```yaml
# checkpoint-map.yaml
metadata:
  id: "CKPT-{YYYY-MM-DD}-{NNN}"
  architecture_id: "{ARCH-*}"

summary:
  total_epics: 0
  total_stories: 0
  total_tasks: 0
  total_checkpoints: 0

epics:
  - id: "E-1"
    title: ""
    stories:
      - id: "S-1.1"
        title: ""
        tasks:
          - id: "T-1.1.1"
            title: ""
            acceptance_criterion: ""
            estimated_duration: ""
            status: "TODO"

checkpoints:
  - id: "CP-1"
    after_task: ""
    validation: ""

dependency_graph:
  nodes: []
  edges: []

validation:
  gate: "G3"
  status: "PASSED | FAILED"
```

---

*Comando do ATHENA OS v1.0.0*
