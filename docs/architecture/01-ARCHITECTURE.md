# ATHENA OS — ARQUITETURA DO SISTEMA

> Estrutura Técnica Completa do Sistema Operacional Cognitivo

**Versão:** 1.0.0
**Tipo:** COGNITIVE + OPERATIONAL
**Status:** PRODUCTION-READY

---

## Visão Geral da Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                         ATHENA OS v1.0                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    CAMADA 0: CONSCIÊNCIA                    │   │
│  │                                                             │   │
│  │   STATE.yaml ◄──── Fonte única de verdade                  │   │
│  │   CLAUDE.md  ◄──── Identidade e configuração               │   │
│  │                                                             │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   CAMADA 1: PROTOCOLOS                      │   │
│  │                                                             │   │
│  │   ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │   │
│  │   │DECODIFIC.│ │ARQUITET. │ │FRAGMENT. │ │CRISTALIZ.│     │   │
│  │   │    P1    │ │    P2    │ │    P3    │ │    P4    │     │   │
│  │   └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘     │   │
│  │        │            │            │            │            │   │
│  │        └────────────┴─────┬──────┴────────────┘            │   │
│  │                           │                                 │   │
│  └───────────────────────────┼─────────────────────────────────┘   │
│                              ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   CAMADA 2: ARTEFATOS                       │   │
│  │                                                             │   │
│  │   ┌────────────────┐  ┌────────────────┐                   │   │
│  │   │   BLUEPRINT    │  │   ACTIVATION   │                   │   │
│  │   │  OPERACIONAL   │  │     PROMPT     │                   │   │
│  │   └───────┬────────┘  └───────┬────────┘                   │   │
│  │           │                   │                             │   │
│  │   ┌───────┴────────┐  ┌───────┴────────┐                   │   │
│  │   │   CHECKPOINT   │  │    TAXONOMY    │                   │   │
│  │   │      MAP       │  │     CONFIG     │                   │   │
│  │   └────────────────┘  └────────────────┘                   │   │
│  │                                                             │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                  CAMADA 3: INTEGRAÇÃO                       │   │
│  │                                                             │   │
│  │   ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │   │
│  │   │AD ANATOMY│ │  FUNNEL  │ │ GENESIS  │ │  [NOVO]  │     │   │
│  │   │  ENGINE  │ │ARCHITECT │ │          │ │ PROJETO  │     │   │
│  │   └──────────┘ └──────────┘ └──────────┘ └──────────┘     │   │
│  │                                                             │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Estrutura de Diretórios

```
athena-os/
│
├── .claude/
│   ├── CLAUDE.md                    # Identidade do sistema
│   └── commands/
│       └── ATHENA/
│           └── tasks/
│               ├── forge-blueprint.md      # Comando principal
│               ├── decode-intent.md        # P1: Decodificação
│               ├── architect-execution.md  # P2: Arquitetura
│               ├── fragment-work.md        # P3: Fragmentação
│               ├── crystallize-output.md   # P4: Cristalização
│               ├── validate-blueprint.md   # Validação
│               ├── export-to-project.md    # Exportação
│               └── check-state.md          # Status
│
├── docs/
│   ├── 00-MANIFESTO.md              # Princípios fundacionais
│   └── architecture/
│       ├── 01-ARCHITECTURE.md       # Este documento
│       ├── 02-PROTOCOLS.md          # Detalhamento dos protocolos
│       ├── 03-TEMPLATES.md          # Especificação dos templates
│       ├── 04-TAXONOMY.md           # Sistema de nomenclatura
│       └── 05-INTEGRATION.md        # Guia de integração
│
├── protocols/
│   ├── P1-DECODE.md                 # Protocolo de Decodificação
│   ├── P2-ARCHITECT.md              # Protocolo de Arquitetura
│   ├── P3-FRAGMENT.md               # Protocolo de Fragmentação
│   └── P4-CRYSTALLIZE.md            # Protocolo de Cristalização
│
├── templates/
│   ├── blueprints/
│   │   ├── BLUEPRINT-TEMPLATE.md    # Template de Blueprint
│   │   └── BLUEPRINT-MINIMAL.md     # Template simplificado
│   ├── prompts/
│   │   ├── ACTIVATION-TEMPLATE.md   # Template de Prompt de Ativação
│   │   └── CONTEXT-INJECTION.md     # Template de injeção de contexto
│   └── checkpoints/
│       ├── CHECKPOINT-MAP.yaml      # Template de mapa de checkpoints
│       └── EPIC-TEMPLATE.yaml       # Template de épico
│
├── knowledge/
│   ├── patterns/
│   │   ├── orchestration-patterns.yaml
│   │   ├── decomposition-patterns.yaml
│   │   └── documentation-patterns.yaml
│   └── principles/
│       ├── cognitive-load.md
│       ├── context-engineering.md
│       └── state-management.md
│
├── integrations/
│   ├── ad-anatomy-engine.yaml       # Config de integração
│   ├── funnel-architect.yaml
│   ├── genesis.yaml
│   └── _template.yaml               # Template para novos projetos
│
├── outputs/
│   ├── blueprints/                  # Blueprints gerados
│   │   └── {YYYY-MM-DD}/
│   │       └── {slug}/
│   │           ├── BLUEPRINT.md
│   │           ├── ACTIVATION.md
│   │           ├── CHECKPOINTS.yaml
│   │           └── TAXONOMY.yaml
│   └── activations/                 # Prompts exportados
│
├── STATE.yaml                       # Estado atual do sistema
├── CLAUDE.md                        # Symlink para .claude/CLAUDE.md
└── README.md                        # Documentação de entrada
```

---

## Componentes do Sistema

### 1. STATE.yaml — A Consciência

O STATE.yaml é a memória persistente do sistema. Ele rastreia:

```yaml
# STATE.yaml - Estrutura
version: "1.0.0"
last_updated: "2025-01-16T14:30:00-03:00"
updated_by: "ATHENA"

# ═══════════════════════════════════════════════════════════
# SESSÃO ATUAL
# ═══════════════════════════════════════════════════════════
current_session:
  started_at: "2025-01-16T14:00:00-03:00"
  active_blueprint: null | "{blueprint_id}"
  current_phase: "IDLE" | "P1" | "P2" | "P3" | "P4"
  current_gate: null | "G0" | "G1" | "G2" | "G3"

# ═══════════════════════════════════════════════════════════
# BLUEPRINT EM PROGRESSO (se houver)
# ═══════════════════════════════════════════════════════════
active_work:
  blueprint_id: null
  intent_summary: null
  target_project: null
  phases_completed: []
  current_checkpoint: null
  blockers: []
  
# ═══════════════════════════════════════════════════════════
# HISTÓRICO RECENTE
# ═══════════════════════════════════════════════════════════
recent_blueprints:
  - id: "BP-2025-01-15-001"
    title: "Framework de Análise Tally"
    status: "COMPLETED"
    exported_to: "D:/market-intel"
    
# ═══════════════════════════════════════════════════════════
# MÉTRICAS
# ═══════════════════════════════════════════════════════════
metrics:
  total_blueprints_generated: 0
  total_exports: 0
  avg_time_per_blueprint: null
  
# ═══════════════════════════════════════════════════════════
# ALERTAS E PENDÊNCIAS
# ═══════════════════════════════════════════════════════════
alerts:
  - type: "INFO"
    message: "Sistema inicializado"
    timestamp: "2025-01-16T14:00:00-03:00"
```

---

### 2. Os 4 Protocolos Core

| Protocolo | Input | Output | Gate |
|-----------|-------|--------|------|
| **P1: DECODE** | Intenção bruta | Intent Specification | G1: Intent clara? |
| **P2: ARCHITECT** | Intent Spec | Execution Architecture | G2: Arquitetura válida? |
| **P3: FRAGMENT** | Architecture | Checkpoint Map | G3: Fragmentação completa? |
| **P4: CRYSTALLIZE** | Checkpoint Map | Blueprint + Activation | G4: Pronto para exportar? |

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│    P1    │────►│    P2    │────►│    P3    │────►│    P4    │
│  DECODE  │     │ ARCHITECT│     │ FRAGMENT │     │CRYSTALLIZE│
└────┬─────┘     └────┬─────┘     └────┬─────┘     └────┬─────┘
     │                │                │                │
     ▼                ▼                ▼                ▼
   [G1]            [G2]             [G3]             [G4]
  Intent?        Arquit?          Fragment?        Export?
```

---

### 3. Artefatos Gerados

#### 3.1 Blueprint Operacional
O documento mestre que contém toda a especificação para execução.

**Estrutura:**
- Metadata (ID, versão, data, projeto-alvo)
- Intent Specification (o que, por que, para quem)
- Execution Architecture (fases, agents, workflows)
- Checkpoint Map (épicos, stories, tasks)
- Success Criteria (como saber que terminou)
- Taxonomy Config (onde colocar cada output)

#### 3.2 Activation Prompt
O prompt pronto para colar no projeto-alvo, referenciando o Blueprint.

**Estrutura:**
- Context Injection (quem é o operador, qual o projeto)
- Blueprint Reference (caminho para o arquivo)
- Execution Instructions (como usar o Blueprint)
- First Command (comando inicial sugerido)

#### 3.3 Checkpoint Map
Arquivo YAML com a decomposição completa do trabalho.

**Estrutura:**
```yaml
epics:
  - id: E1
    title: "Nome do Épico"
    stories:
      - id: S1.1
        title: "Nome da Story"
        tasks:
          - id: T1.1.1
            title: "Nome da Task"
            status: "TODO" | "IN_PROGRESS" | "DONE"
            acceptance_criteria: "Critério binário"
```

#### 3.4 Taxonomy Config
Configuração de onde cada output deve ser salvo no projeto-alvo.

---

### 4. Sistema de Gates

Cada gate é um checkpoint de qualidade que deve passar antes de avançar:

| Gate | Pergunta | Critério de Passagem |
|------|----------|----------------------|
| **G1** | A intenção está clara? | Intent Spec completa, sem ambiguidades |
| **G2** | A arquitetura faz sentido? | Fases lógicas, agents definidos, workflow claro |
| **G3** | A fragmentação está completa? | Todo trabalho decomposto em tasks atômicas |
| **G4** | O Blueprint está pronto? | Exportável, auto-contido, transferível |

**Regra:** Falha em qualquer gate = retorno à fase anterior para correção.

---

### 5. Fluxo de Integração com Projetos

```
ATHENA OS                           PROJETO-ALVO
    │                                    │
    │  1. Gera Blueprint                 │
    │  2. Gera Activation Prompt         │
    │  3. Define Taxonomy                │
    │                                    │
    └──────── EXPORTA ─────────────────►│
                                         │
                                    4. Recebe Blueprint
                                    5. Lê Activation Prompt
                                    6. Executa conforme
                                    7. Atualiza STATE local
                                         │
    ◄─────── FEEDBACK ──────────────────┘
    │
    8. Registra conclusão
    9. Atualiza métricas
```

---

## Comandos Disponíveis

| Comando | Descrição | Fase |
|---------|-----------|------|
| `/ATHENA:tasks:forge-blueprint` | Pipeline completo P1→P4 | ALL |
| `/ATHENA:tasks:decode-intent` | Apenas decodificação | P1 |
| `/ATHENA:tasks:architect-execution` | Apenas arquitetura | P2 |
| `/ATHENA:tasks:fragment-work` | Apenas fragmentação | P3 |
| `/ATHENA:tasks:crystallize-output` | Apenas cristalização | P4 |
| `/ATHENA:tasks:validate-blueprint` | Validar Blueprint existente | UTIL |
| `/ATHENA:tasks:export-to-project` | Exportar para projeto-alvo | UTIL |
| `/ATHENA:tasks:check-state` | Ver estado atual | UTIL |

---

## Regras de Operação

### Regra 1: Sempre Ler STATE Primeiro
```
ANTES de qualquer operação:
1. cat STATE.yaml
2. Verificar current_session
3. Verificar active_work
4. Só então executar
```

### Regra 2: Sempre Atualizar STATE Depois
```
APÓS qualquer checkpoint:
1. Atualizar current_checkpoint
2. Atualizar phases_completed (se aplicável)
3. Atualizar last_updated
4. Salvar STATE.yaml
```

### Regra 3: Nunca Pular Gates
```
SE gate falhar:
1. Documentar motivo
2. Retornar à fase anterior
3. Corrigir
4. Tentar gate novamente
```

### Regra 4: Outputs Sempre na Taxonomia
```
TODO output deve ir para:
outputs/{tipo}/{YYYY-MM-DD}/{slug}/

NUNCA:
- Jogar na raiz
- Criar pastas ad-hoc
- Ignorar convenção de nomenclatura
```

---

## Próximos Documentos

- **02-PROTOCOLS.md** — Detalhamento completo de cada protocolo
- **03-TEMPLATES.md** — Especificação dos templates
- **04-TAXONOMY.md** — Sistema de nomenclatura completo
- **05-INTEGRATION.md** — Guia de integração com projetos
