# FORMICA Evolution Matrix — Knowledge-Driven System Evolution

> **Source:** AURUM Deep Mine DM-20260218-001 (55 artifacts, 19 sources, 9 agents)
> **Generated:** 2026-02-18
> **Purpose:** Mapeamento central de conhecimento minerado para evolucao do orquestrador
> **Usage:** Referencia para blueprints de evolucao, PRDs, e decisoes arquiteturais

---

## Como Usar Este Documento

1. **Antes de implementar feature:** Consultar a secao de Component Mapping para ver quais artifacts informam a decisao
2. **Ao planejar sprint:** Usar a Recommendation Matrix para priorizar por impacto/esforco
3. **Ao debuggar:** Consultar Failure Modes importados dos artifacts de referencia
4. **Ao questionar decisao arquitetural:** Consultar Validation Matrix para evidencia empirica

---

## 1. ARCHITECTURAL VALIDATION MATRIX

> 7 decisoes de design do FORMIGA validadas por convergencia independente de 5+ projetos.

| Decisao FORMIGA | Validacao Externa | Evidencia | Status |
|-----------------|-------------------|-----------|--------|
| **Filesystem como canal de coordenacao** | Ralph, Zerg, Agent Farm, OpenClaw — 5 projetos independentes | PAT-1 em SYN-DM-20260218-001 | VALIDADA (convergencia universal) |
| **Bash-native sem dependencias** | Dex Horthy preferiu 5 linhas de bash ao plugin oficial Anthropic | INS-20260218-009, CTI-20260218-002 | VALIDADA (Lindy Effect) |
| **Workers stateless com context fresh** | Ralph Loop, Zerg stateless workers, Nolan Lawson IndexedDB | PAT-2, INS-20260218-001, MTH-20260218-003 | VALIDADA (context rot como feature) |
| **Tiered model routing (haiku/sonnet/opus)** | Zerg, AURUM Deep Mine, Nolan Lawson ($7 projeto inteiro) | PAT-5, MTH-20260218-012, FWK-20260218-007 | VALIDADA (economia 60-70%) |
| **Biomimetica como principio (nao metafora)** | AWS Enterprise Swarm Intelligence confirma resiliencia | FWK-20260218-006, INS-20260218-007 | VALIDADA (AWS production-ready) |
| **DAG + wave execution** | Zerg task-graph.json, Agent Farm wave model | MTH-20260218-005, FWK-20260218-005 | VALIDADA (padrao convergente) |
| **QA como immune system** | 3-layer defense (pre-spawn, innate, adaptive) em todos projetos | INS-20260218-006, MTH-20260218-013 | VALIDADA (modelo biologico preciso) |

---

## 2. COMPONENT-TO-ARTIFACT MAPPING

> Cada arquivo .sh do FORMIGA mapeado para artifacts que informam sua evolucao.

### Layer 0: CORE (Execution Primitives)

| Componente | Path | Artifacts Relevantes | Acao Sugerida |
|------------|------|---------------------|---------------|
| **orchestrate.sh** | `orchestrate.sh` | MTH-001 (Ralph Loop), MTH-005 (Task Graph), FWK-001 (4 elementos), INS-001 (context rot) | Integrar Ralph-style fresh context per wave; adicionar stagnation detection |
| **state.sh** | `lib/state.sh` | INS-002 (filesystem truth), FWK-004 (stateless workers), INS-010 (stigmergy) | Adicionar pheromone decay (GAP-1); manter atomicidade |
| **context.sh** | `lib/context.sh` | MTH-003 (Context Fresh Start), INS-001 (context rot feature), PAT-2 | Garantir context pack < threshold; fresh start per iteration |
| **qa.sh** | `lib/qa.sh` | INS-006 (immune system), MTH-013 (guardrails), INS-008 (overbaking), INS-015 (proxy gaming) | Adicionar gates MAXIMOS (REC-3); metricas ortogonais (REC-5) |
| **deps.sh** | `lib/deps.sh` | MTH-005 (task graph), FWK-005 (conflict prevention), INS-017 (eliminacao topologica) | Evoluir para file ownership exclusivo (REC-2, CRITICA) |
| **cost.sh** | `lib/cost.sh` | MTH-012 (cost-optimized selection), FWK-007 (routing framework), INS-005 (allometry) | Formalizar dashboard de custo por modelo/tarefa (REC-4) |
| **parallel.sh** | `lib/parallel.sh` | MTH-008 (stagger launch), MTH-006 (lock coordination), MTH-007 (tmux farm) | Implementar stagger com backoff adaptativo (REC-1) |
| **lock.sh** | `lib/lock.sh` | MTH-006 (lock-based coordination), INS-010 (stigmergy), INS-017 (structural prevention) | Evoluir de locks probabilisticos para ownership exclusivo |
| **utils.sh** | `lib/utils.sh` | — | Sem evolucao necessaria (infraestrutura estavel) |

### Layer 1: INTELLIGENCE (Orchestration Logic)

| Componente | Path | Artifacts Relevantes | Acao Sugerida |
|------------|------|---------------------|---------------|
| **routing.sh** | `lib/routing.sh` | MTH-012 (model selection), FWK-007 (cost-capacity), INS-005 (allometry), PAT-5 | Formalizar 3-tier routing com fallback dinamico (REC-4) |
| **advisory.sh** | `lib/advisory.sh` | FWK-008 (autonomy spectrum), INS-011 (governance vacuum), MTH-013 (guardrails) | Adicionar anti-overbaking check; metricas ortogonais |
| **meta_loop.sh** | `lib/meta_loop.sh` | FWK-001 (loop agentico), MTH-010 (swarm optimization), INS-003 (deterministic badness) | Integrar stagnation detection (REC-8); swarm mode exploratorio (GAP-7) |
| **file_registry.sh** | `lib/file_registry.sh` | MTH-005 (task graph), FWK-005 (conflict matrix), INS-017 (structural elimination) | Central para REC-2: construir task graph com ownership exclusivo |
| **modes.sh** | `lib/modes.sh` | FWK-008 (5 niveis autonomia), FWK-003 (topologia spectrum), INS-014 (limiar centralizado) | Adicionar modo dual centralizado/descentralizado (REC-7) |
| **friction.sh** | `lib/friction.sh` | INS-003 (deterministic badness), INS-012 (falhas como dados), FWK-001 (feedback loop) | Classificar falhas para Ralph-style re-prompting |
| **epigenetics.sh** | `lib/epigenetics.sh` | MTH-011 (stigmergy), INS-010 (stigmergy digital), FWK-006 (4 loops bio) | Implementar pheromone decay formal (GAP-1) |
| **pheromone.sh** | `lib/pheromone.sh` | MTH-011 (stigmergy), FWK-006 (swarm loops), INS-007 (emergencia) | Adicionar evaporacao temporal de sinais (relevance * 0.9^age) |

### Layer 2: KNOWLEDGE (ATHENA-native)

| Componente | Path | Artifacts Relevantes | Acao Sugerida |
|------------|------|---------------------|---------------|
| **athena.sh** | `lib/athena.sh` | MTH-009 (skills system), FWK-002 (gateway-agent-skills), INS-013 (spec como executavel) | Investigar extensibilidade via skills (REC-9, OpenClaw-inspired) |

### Workers

| Worker | Path | Artifacts Relevantes | Acao Sugerida |
|--------|------|---------------------|---------------|
| **_base.md** | `workers/_base.md` | FWK-004 (stateless), INS-004 (ignorancia produtiva), MTH-003 (fresh start) | Reforcar isolamento; workers NUNCA devem saber de outros workers |
| **analyst.md** | `workers/analyst.md` | INS-004, FWK-007 (haiku tier) | Manter em haiku; adicionar rubrica ortogonal |
| **implementer.md** | `workers/implementer.md` | INS-008 (overbaking), INS-015 (proxy gaming), MTH-013 (guardrails) | Adicionar constraint: "NAO implementar o que NAO esta na spec" |
| **writer.md** | `workers/writer.md` | INS-004, FWK-007 | Manter em haiku; low-risk worker |
| **architect.md** | `workers/architect.md` | FWK-003 (topologias), FWK-007 (sonnet tier), INS-014 (limiar) | Manter em sonnet; adicionar mapping de padroes classicos |
| **advisor.md** | `workers/advisor.md` | FWK-008 (governanca), INS-011 (governance vacuum), INS-015 (proxy gaming) | Adicionar check de metricas ortogonais; anti-overbaking |
| **forger.md** | `workers/forger.md` | MTH-002 (PRD Factory), INS-013 (spec executavel), INS-018 (codigo descartavel) | Reforcar: spec > codigo; re-gerar > manter |

---

## 3. RECOMMENDATION MATRIX (Priorizada por Impacto/Esforco)

```
                    IMPACTO
              Baixo    Medio     Alto     Critico
         ┌─────────┬─────────┬─────────┬─────────┐
  Baixo  │         │ REC-6   │ REC-1   │         │
         │         │ REC-10  │ REC-8   │         │
Esforco  ├─────────┼─────────┼─────────┼─────────┤
  Medio  │         │         │ REC-3   │ REC-2   │
         │         │         │ REC-4   │         │
         │         │         │ REC-5   │         │
         ├─────────┼─────────┼─────────┼─────────┤
  Alto   │         │ REC-9   │ REC-7   │         │
         │         │         │         │         │
         └─────────┴─────────┴─────────┴─────────┘

  LEGENDA: Implementar primeiro → canto superior direito
```

### Quick Wins (Baixo esforco, Alto impacto)

| # | Recomendacao | Arquivo(s) | Linhas est. | Artifacts |
|---|-------------|------------|-------------|-----------|
| REC-1 | Stagger Launch + Backoff Adaptativo | `lib/parallel.sh` | ~25 linhas | MTH-008, MTH-007 |
| REC-8 | Deteccao de Estagnacao + Reset | `lib/meta_loop.sh`, `lib/friction.sh` | ~30 linhas | MTH-001, FWK-001, INS-003 |
| REC-6 | Mapear Padroes Classicos (doc) | `docs/DISTRIBUTED-PATTERNS.md` | Documentacao | INS-016, FWK-003 |
| REC-10 | Modo Cron Ralph | `campaigns/cron-normalize.yaml` | Blueprint | MTH-014 |

### Core Evolutions (Medio esforco, Alto-Critico impacto)

| # | Recomendacao | Arquivo(s) | Complexidade | Artifacts |
|---|-------------|------------|--------------|-----------|
| REC-2 | Task Graph + File Ownership | `lib/deps.sh`, `lib/file_registry.sh` | Redesign dispatch | MTH-005, FWK-005, INS-017 |
| REC-3 | Gates de Qualidade MAXIMA | `lib/qa.sh`, `lib/advisory.sh` | Nova logica em gates | INS-008, INS-015, MTH-013 |
| REC-4 | Roteamento Formal de Modelos | `lib/routing.sh`, `lib/cost.sh` | Formalizar 3-tier | MTH-012, FWK-007, INS-005 |
| REC-5 | Metricas Ortogonais nos Gates | `lib/qa.sh` | Multi-dimensional check | INS-015, INS-006, MTH-013 |

### Strategic Investments (Alto esforco, Alto impacto)

| # | Recomendacao | Arquivo(s) | Complexidade | Artifacts |
|---|-------------|------------|--------------|-----------|
| REC-7 | Modo Dual (Central/Decentral) | `lib/modes.sh`, `lib/parallel.sh` | 2 modos operacao | INS-014, FWK-003, FWK-009 |
| REC-9 | Skills Extensiveis (OpenClaw) | `lib/athena.sh`, novo subsistema | Novo modulo | MTH-009, FWK-002 |

---

## 4. MEGA-PATTERN → FORMIGA IMPLEMENTATION MAP

| Mega-Pattern | Principio | FORMIGA Atual | Evolucao Sugerida |
|-------------|-----------|---------------|-------------------|
| **PAT-1: Filesystem como Canal** | Coordenacao via arquivos, nao APIs | state.json + events.jsonl + locks | Manter e PROTEGER. Nao migrar para Redis/Kafka. |
| **PAT-2: Context Rot como Feature** | Matar conversa = limpar degradacao | Workers isolados via `claude -p` | Formalizar max_context_tokens per worker. Auto-kill apos threshold. |
| **PAT-3: Simplicidade Radical** | Complexidade no output, nao no agente | 22 libs bash, 5127 lines | Teste de simplicidade: "posso fazer com bash puro?" Se sim, nao adicionar lib. |
| **PAT-4: Prevencao Estrutural** | Eliminar conflitos por design, nao por lock | file_registry.json (probabilistico) | Evoluir para ownership exclusivo por nivel (REC-2). |
| **PAT-5: Allometry de Modelos** | Custo proporcional a complexidade | routing.sh com escalation | Formalizar classificacao automatica Low/Med/High (REC-4). |
| **PAT-6: Spec como Executavel** | PRD/prompt E o programa | campaigns/*.yaml (blueprints) | Blueprints JA sao spec executavel. Adicionar acceptance_criteria verificavel. |
| **PAT-7: Autonomia Governada** | Guardrails proporcionais ao nivel | qa.sh + advisory.sh | Adicionar gates MAXIMOS + metricas ortogonais (REC-3, REC-5). |

---

## 5. GAP ANALYSIS — O QUE FALTA

| # | Gap | Impacto | Arquivo(s) Afetado(s) | Artifact de Referencia | Prioridade |
|---|-----|---------|----------------------|----------------------|------------|
| GAP-1 | Sem evaporacao de sinais (pheromone decay) | Acumulo de ruido no estado | `lib/pheromone.sh`, `lib/epigenetics.sh` | MTH-011, FWK-006 | MEDIA |
| GAP-2 | Sem stagger no lancamento | Thundering herd em 20+ workers | `lib/parallel.sh` | MTH-008 | ALTA |
| GAP-3 | Sem deteccao de overbaking | Workers excedem escopo | `lib/qa.sh` | INS-008, INS-015 | ALTA |
| GAP-4 | Sem mapping de padroes classicos | Nao importa failure modes conhecidos | `docs/` | INS-016 | MEDIA |
| GAP-5 | Sem metricas ortogonais | Proxy gaming possivel | `lib/qa.sh` | INS-015, INS-006 | ALTA |
| GAP-6 | Sem skills extensiveis | Nao permite extensao comunitaria | `lib/athena.sh` | MTH-009, FWK-002 | MEDIA |
| GAP-7 | Sem modo swarm exploratorio | Tarefas ambiguas nao otimizadas | `lib/meta_loop.sh` | FWK-006, INS-007 | MEDIA |

---

## 6. FAILURE MODES IMPORTADOS

> Modos de falha documentados nos projetos analisados que FORMIGA deve prevenir.

| Failure Mode | Fonte | Descricao | Prevencao em FORMIGA |
|-------------|-------|-----------|---------------------|
| **Overbaking** | Ralph Loop (INS-008) | Worker adiciona features nao solicitadas (criptografia pos-quantica em TODO app) | Gate de qualidade MAXIMA: diff spec vs impl |
| **Proxy Gaming** | Swarm Patterns (INS-015) | Worker deleta testes para "melhorar" cobertura | Metricas ortogonais: testes passam E testes nao foram modificados |
| **Context Rot** | Ralph/Zerg (INS-001) | Qualidade degrada com conversa longa | Fresh context per iteration (ja implementado) |
| **Sycophancy Loop** | Ralph (INS-008) | Worker tenta agradar em vez de resolver | Token COMPLETE como unico mecanismo de avancar; stop conditions verificaveis |
| **Mode Collapse** | Swarm (FWK-001) | Repete mesma estrategia falhada N vezes | Deteccao de estagnacao: 2 falhas identicas = escalar (REC-8) |
| **Thundering Herd** | Agent Farm (MTH-008) | 20+ workers lancados simultaneamente | Stagger launch com backoff adaptativo (REC-1) |
| **Governance Vacuum** | Ralph (INS-011) | Entre spec e stop condition, nao ha lei | Whitelist de permissoes (so pode o que e explicitamente permitido) |
| **Oscillation** | Ralph (FWK-001) | Diff ciclico A->B->A->B sem convergir | Detectar diffs similares ciclicos; parar e re-especificar |
| **Metric Gaming** | Swarm (INS-015) | Otimiza metrica observavel, nao objetivo real | Metricas ortogonais multiplas (exponencialmente mais dificil de gamear) |

---

## 7. DISTRIBUTED SYSTEMS ANCESTRY MAP

> Cada componente FORMIGA mapeado para seu ancestral em sistemas distribuidos.
> Referencia: INS-20260218-016 (Patrick Koss: "AI Agents — New Patterns or Old Tricks?")

| Componente FORMIGA | Padrao Classico | Failure Modes Conhecidos | Best Practice a Importar |
|-------------------|----------------|------------------------|-------------------------|
| Pipeline (waves) | **Pipes-and-Filters** | Stage starvation, backpressure | Bounded buffers, flow control |
| orchestrate.sh | **Mediator** | Single point of failure, bottleneck | Health checks, failover |
| P2 (parallel lenses) | **MapReduce / Scatter-Gather** | Straggler problem, partial failure | Timeout + partial results, speculative execution |
| file locks | **Distributed Locks** | Deadlocks, lock contention | Lock ordering, timeouts, ownership tracking |
| Workers stateless | **Stateless Servers** | Cold start overhead | Context pre-warming, caching hints |
| QA workers | **Circuit Breaker** | Cascading failures | Trip after N failures, half-open state |
| Advisory | **Saga Pattern** | Compensation complexity | Forward recovery preferred over backward |
| Meta-loop quorum | **Consensus (Paxos/Raft)** | Split brain, liveness | Majority quorum, leader election |
| Pheromone trails | **Event Sourcing** | Event store growth, replay cost | Snapshotting, compaction |
| Epigenetics | **CQRS** | Eventual consistency lag | Read-after-write guarantees |

---

## 8. COMPETITIVE LANDSCAPE

> Posicao do FORMIGA vs concorrentes analisados.

| Feature | FORMIGA | Zerg | Agent Farm | OpenClaw | Ralph (puro) |
|---------|---------|------|-----------|----------|-------------|
| **Runtime** | Bash | Python+Claude | Node+tmux | TypeScript | Bash (5 linhas) |
| **Workers** | `claude -p` isolados | Claude subagents | Claude Code sessions | Anthropic API | Bash loop |
| **State** | state.json (jq atomic) | task-graph.json | lock files + logs | Workspace .md files | Filesystem only |
| **Conflict prevention** | file_registry (probabilistic) | Exclusive ownership | Lock-based | N/A (single agent) | N/A |
| **QA/Immune** | 3-layer (pre-spawn, innate, adaptive) | Level-boundary gates | Post-execution review | N/A | Stop conditions |
| **Meta-learning** | Quorum sensing + epigenetics | N/A | N/A | Heartbeat learning | N/A |
| **Biomimetica** | ACO, stigmergy, allometry, trophallaxis | N/A | N/A | N/A | N/A |
| **Cost routing** | haiku/sonnet/opus escalation | haiku/sonnet/opus | Single model | Configurable | Single model |
| **Extensibility** | Workers + Athena layer | Config-based | Config-based | Skills system (3 tiers) | Prompt only |
| **Cognitive depth** | 7-layer agents (~120k words) | Scripts | Vanilla Claude | AGENTS.md generic | PROMPT.md |

**FORMIGA Moats (proteger):**
1. Unico bash-native multi-agent orchestrator
2. Unico com biomimetica como principio (nao metafora)
3. Unico com 7-layer cognitive agents
4. Unico com meta-learning (quorum + epigenetics)

**Vulnerabilidades (mitigar):**
1. Sem skills extensiveis (OpenClaw advantage)
2. Conflict prevention probabilistica vs estrutural (Zerg advantage)
3. Sem modo swarm exploratorio (swarm frameworks advantage)

---

## 9. ARTIFACT PATH INDEX

> Todos os 55 artifacts da mine DM-20260218-001, organizados por relevancia para evolucao.

### Tier 1: CRITICAL (implementacao imediata)

| ID | Path (AURUM Vault) | Relevancia FORMIGA |
|----|---------------------|-------------------|
| MTH-20260218-001 | `D:\cognitive-refinery\20-methodologies\MTH-20260218-001.md` | Ralph Loop completo — padrao de referencia |
| MTH-20260218-005 | `D:\cognitive-refinery\20-methodologies\MTH-20260218-005.md` | Task Graph com ownership exclusivo (REC-2) |
| MTH-20260218-008 | `D:\cognitive-refinery\20-methodologies\MTH-20260218-008.md` | Stagger Launch + Backoff (REC-1) |
| MTH-20260218-013 | `D:\cognitive-refinery\20-methodologies\MTH-20260218-013.md` | Guardrail Engineering completo (REC-3, REC-5) |
| FWK-20260218-005 | `D:\cognitive-refinery\21-frameworks\FWK-20260218-005.md` | Matriz de prevencao de conflitos |
| FWK-20260218-007 | `D:\cognitive-refinery\21-frameworks\FWK-20260218-007.md` | Framework de routing custo-capacidade (REC-4) |
| INS-20260218-001 | `D:\cognitive-refinery\22-insights\INS-20260218-001.md` | Context rot como feature (validacao arquitetural) |
| INS-20260218-008 | `D:\cognitive-refinery\22-insights\INS-20260218-008.md` | Overbaking risk (REC-3) |
| INS-20260218-015 | `D:\cognitive-refinery\22-insights\INS-20260218-015.md` | Proxy gaming (REC-5) |
| INS-20260218-017 | `D:\cognitive-refinery\22-insights\INS-20260218-017.md` | Eliminacao topologica de conflitos (REC-2) |
| SYN-DM-20260218-001 | `D:\cognitive-refinery\24-connections\SYN-DM-20260218-001.md` | Sintese completa com 7 mega-patterns |

### Tier 2: HIGH (proximo ciclo)

| ID | Path | Relevancia |
|----|------|-----------|
| MTH-20260218-002 | `D:\cognitive-refinery\20-methodologies\MTH-20260218-002.md` | PRD Factory para spec executavel |
| MTH-20260218-003 | `D:\cognitive-refinery\20-methodologies\MTH-20260218-003.md` | Context Fresh Start methodology |
| MTH-20260218-004 | `D:\cognitive-refinery\20-methodologies\MTH-20260218-004.md` | OpenClaw Heartbeat lifecycle |
| MTH-20260218-006 | `D:\cognitive-refinery\20-methodologies\MTH-20260218-006.md` | Lock-Based Coordination patterns |
| MTH-20260218-012 | `D:\cognitive-refinery\20-methodologies\MTH-20260218-012.md` | Cost-Optimized Model Selection |
| FWK-20260218-001 | `D:\cognitive-refinery\21-frameworks\FWK-20260218-001.md` | 4 elementos do loop agentico |
| FWK-20260218-003 | `D:\cognitive-refinery\21-frameworks\FWK-20260218-003.md` | Espectro de topologias (REC-7) |
| FWK-20260218-006 | `D:\cognitive-refinery\21-frameworks\FWK-20260218-006.md` | 4 loops bio-mimeticos |
| FWK-20260218-008 | `D:\cognitive-refinery\21-frameworks\FWK-20260218-008.md` | Espectro de governanca (5 niveis) |
| INS-20260218-002 | `D:\cognitive-refinery\22-insights\INS-20260218-002.md` | Filesystem como canal (validacao) |
| INS-20260218-003 | `D:\cognitive-refinery\22-insights\INS-20260218-003.md` | Deterministic badness paradox |
| INS-20260218-005 | `D:\cognitive-refinery\22-insights\INS-20260218-005.md` | Allometry de modelos |
| INS-20260218-006 | `D:\cognitive-refinery\22-insights\INS-20260218-006.md` | QA como sistema imunologico |
| INS-20260218-009 | `D:\cognitive-refinery\22-insights\INS-20260218-009.md` | Bash como linguagem superior |
| INS-20260218-011 | `D:\cognitive-refinery\22-insights\INS-20260218-011.md` | Governance vacuum |
| INS-20260218-016 | `D:\cognitive-refinery\22-insights\INS-20260218-016.md` | Padroes classicos remix |

### Tier 3: REFERENCE (consulta sob demanda)

| ID | Path | Relevancia |
|----|------|-----------|
| MTH-20260218-007 | `D:\cognitive-refinery\20-methodologies\MTH-20260218-007.md` | Tmux Agent Farm patterns |
| MTH-20260218-009 | `D:\cognitive-refinery\20-methodologies\MTH-20260218-009.md` | Skill-Based Extension (REC-9) |
| MTH-20260218-010 | `D:\cognitive-refinery\20-methodologies\MTH-20260218-010.md` | Swarm Optimization Loop |
| MTH-20260218-011 | `D:\cognitive-refinery\20-methodologies\MTH-20260218-011.md` | Coordenacao Stigmergica |
| MTH-20260218-014 | `D:\cognitive-refinery\20-methodologies\MTH-20260218-014.md` | Cron Ralph (REC-10) |
| FWK-20260218-002 | `D:\cognitive-refinery\21-frameworks\FWK-20260218-002.md` | Gateway-Agent-Skills (OpenClaw) |
| FWK-20260218-004 | `D:\cognitive-refinery\21-frameworks\FWK-20260218-004.md` | Resiliencia por stateless |
| FWK-20260218-009 | `D:\cognitive-refinery\21-frameworks\FWK-20260218-009.md` | 4 canais de comunicacao |
| INS-20260218-004 | `D:\cognitive-refinery\22-insights\INS-20260218-004.md` | Ignorancia produtiva |
| INS-20260218-007 | `D:\cognitive-refinery\22-insights\INS-20260218-007.md` | Emergencia agentica |
| INS-20260218-010 | `D:\cognitive-refinery\22-insights\INS-20260218-010.md` | Stigmergy digital |
| INS-20260218-012 | `D:\cognitive-refinery\22-insights\INS-20260218-012.md` | Falhas como dados |
| INS-20260218-013 | `D:\cognitive-refinery\22-insights\INS-20260218-013.md` | Spec como executavel |
| INS-20260218-014 | `D:\cognitive-refinery\22-insights\INS-20260218-014.md` | Limiar centralizado/descentralizado |
| INS-20260218-018 | `D:\cognitive-refinery\22-insights\INS-20260218-018.md` | Codigo descartavel |
| CTI-20260218-001..013 | `D:\cognitive-refinery\23-content-ideas\CTI-20260218-*.md` | 13 ideias de conteudo para Joao |

### Raw Harvest Data

| Cluster | Path | Conteudo |
|---------|------|---------|
| Cluster 1 (Ralph) | `D:\cognitive-refinery\00-inbox\deep-mine\DM-20260218-001\raw\cluster-1.md` | 6 fontes originais completas |
| Cluster 2 (OpenClaw) | `D:\cognitive-refinery\00-inbox\deep-mine\DM-20260218-001\raw\cluster-2.md` | 4 fontes originais completas |
| Cluster 3 (Bash Orch) | `D:\cognitive-refinery\00-inbox\deep-mine\DM-20260218-001\raw\cluster-3.md` | 5 fontes originais completas |
| Cluster 4 (Arch Intel) | `D:\cognitive-refinery\00-inbox\deep-mine\DM-20260218-001\raw\cluster-4.md` | 4 fontes originais completas |

### Reports & Synthesis

| Documento | Path |
|-----------|------|
| Mining Report | `D:\cognitive-refinery\40-meta\mining-reports\MINE-DM-20260218-001-REPORT.md` |
| Synthesis | `D:\cognitive-refinery\24-connections\SYN-DM-20260218-001.md` |
| Manifest | `D:\cognitive-refinery\00-inbox\deep-mine\DM-20260218-001\manifest.yaml` |
| Mining Log | `D:\cognitive-refinery\40-meta\mining-log.md` |

---

## 10. EVOLUTION ROADMAP SUGERIDO

### Wave 1: Quick Wins (1-2 dias)
- [ ] **REC-1:** Stagger Launch em `lib/parallel.sh` (~25 linhas)
- [ ] **REC-8:** Stagnation Detection em `lib/meta_loop.sh` (~30 linhas)
- [ ] **REC-6:** Criar `docs/DISTRIBUTED-PATTERNS.md` (documentacao)
- [ ] **REC-10:** Criar `campaigns/cron-normalize.yaml` (blueprint)

### Wave 2: Core Evolution (3-5 dias)
- [ ] **REC-2:** Task Graph + File Ownership em `lib/deps.sh` + `lib/file_registry.sh`
- [ ] **REC-3:** Gates MAXIMOS em `lib/qa.sh`
- [ ] **REC-5:** Metricas Ortogonais em `lib/qa.sh`
- [ ] **REC-4:** Routing Formal em `lib/routing.sh` + `lib/cost.sh`

### Wave 3: Strategic (1-2 semanas)
- [ ] **REC-7:** Modo Dual em `lib/modes.sh` + `lib/parallel.sh`
- [ ] **REC-9:** Skills System investigacao + design
- [ ] **GAP-1:** Pheromone Decay em `lib/pheromone.sh` + `lib/epigenetics.sh`
- [ ] **GAP-7:** Swarm Mode exploratorio em `lib/meta_loop.sh`

---

*FORMICA Evolution Matrix v1.0.0*
*Source: AURUM DM-20260218-001 (55 artifacts, 19 sources)*
*"Every evolution decision traceable to empirical evidence."*
