# Principio: State Management

> Se nao esta no STATE, nao aconteceu

**Versao:** 1.0.0
**Principio ATHENA:** P3 (STATE como Consciencia)

---

## Conceito Central

**State Management** e a disciplina de manter uma fonte unica de verdade sobre o que foi feito, o que esta em progresso, e o que falta fazer.

Em ATHENA OS, o `STATE.yaml` e a **consciencia persistente** do sistema.

---

## Por Que State Importa

### 1. Continuidade Entre Sessoes

Claude nao tem memoria entre sessoes. O STATE e a memoria.

```
Sessao 1: Completa Fase 1, atualiza STATE
[sessao termina]
Sessao 2: Le STATE, sabe exatamente onde continuar
```

### 2. Transferibilidade Entre Executores

Qualquer instancia de Claude pode assumir o trabalho.

```
Claude A: Trabalha ate T-2.3.4, atualiza STATE
Claude B: Le STATE, continua de T-2.3.4
```

### 3. Auditabilidade

Historico de o que foi feito e quando.

```yaml
history:
  - action: "Completou T-1.1.1"
    timestamp: "2025-01-16T14:30:00"
  - action: "Gate G1 PASSED"
    timestamp: "2025-01-16T15:00:00"
```

### 4. Recuperacao de Falhas

Se algo der errado, sabe-se exatamente o estado antes da falha.

```yaml
before_failure:
  last_good_state: "T-2.3.3 completa"
  in_progress: "T-2.3.4"
  rollback_to: "T-2.3.3"
```

---

## Anatomia do STATE.yaml

### Secao 1: Metadata do Sistema

```yaml
system:
  name: "ATHENA OS"
  version: "1.0.0"
  status: "OPERATIONAL"
  initialized_at: "2025-01-16T00:00:00-03:00"
  last_updated: "2025-01-16T14:30:00-03:00"
  updated_by: "ATHENA"
```

### Secao 2: Sessao Atual

```yaml
current_session:
  started_at: "2025-01-16T14:00:00-03:00"
  active_blueprint: "BP-2025-01-16-001"
  current_phase: "P2"  # IDLE | P1 | P2 | P3 | P4
  current_gate: "G2"   # null | G1 | G2 | G3 | G4
```

### Secao 3: Trabalho Ativo

```yaml
active_work:
  blueprint_id: "BP-2025-01-16-001"
  intent_summary: "Framework de analise Tally"
  target_project: "D:/ad-anatomy-engine"

  phases_status:
    P1_DECODE:
      status: "COMPLETED"
      started_at: "2025-01-16T14:00:00"
      completed_at: "2025-01-16T14:30:00"
      gate_status: "PASSED"

    P2_ARCHITECT:
      status: "IN_PROGRESS"
      started_at: "2025-01-16T14:35:00"
      completed_at: null
      gate_status: "PENDING"

  current_checkpoint: "Gate G2"
  blockers: []
  notes: []
```

### Secao 4: Historico

```yaml
blueprints:
  total_generated: 5
  total_exported: 3

  recent:
    - id: "BP-2025-01-15-001"
      title: "Analise de Competitors"
      status: "EXPORTED"
      created_at: "2025-01-15T10:00:00"
      exported_at: "2025-01-15T12:00:00"
      exported_to: "D:/market-intel"
```

### Secao 5: Metricas

```yaml
metrics:
  blueprints:
    total: 5
    by_status:
      completed: 3
      exported: 3
      failed: 0
      in_progress: 1

  performance:
    avg_time_per_blueprint: "45 min"
    gates_passed_first_try: 8
    gates_required_retry: 2
```

### Secao 6: Alertas

```yaml
alerts:
  - type: "WARNING"
    message: "Blueprint BP-2025-01-14-001 nao exportado ha 2 dias"
    timestamp: "2025-01-16T14:00:00"
    acknowledged: false

pending_actions:
  - action: "Exportar BP-2025-01-14-001"
    priority: "MEDIUM"
```

---

## Regras de State Management

### Regra 1: Ler Primeiro

**SEMPRE** ler STATE.yaml antes de qualquer operacao.

```
INICIO DE SESSAO:
1. cat STATE.yaml
2. Verificar current_session
3. Verificar active_work
4. So entao executar
```

### Regra 2: Atualizar Imediatamente

Atualizar STATE.yaml **imediatamente** apos cada checkpoint.

```
APOS CADA CHECKPOINT:
1. Atualizar current_checkpoint
2. Atualizar phases_status (se aplicavel)
3. Atualizar last_updated
4. Salvar STATE.yaml
```

### Regra 3: Nunca Confiar na Memoria

Se nao esta no STATE, agir como se nao tivesse acontecido.

```
NAO:
"Acho que ja fiz a Fase 1..."

SIM:
"STATE.yaml mostra P1_DECODE: COMPLETED, Gate G1: PASSED"
```

### Regra 4: Granularidade Apropriada

Atualizar em momentos significativos, nao a cada linha.

```
ATUALIZAR QUANDO:
- Task completa
- Gate passa/falha
- Fase inicia/termina
- Bloqueador surge/resolve
- Decisao importante tomada

NAO ATUALIZAR:
- A cada comando executado
- A cada arquivo lido
- Durante processamento intermediario
```

### Regra 5: Atomicidade

Uma atualizacao de STATE deve ser atomica e consistente.

```
ERRADO:
1. Atualizar status da task
2. [erro acontece]
3. Atualizar checkpoint (nunca executado)
-> STATE inconsistente

CERTO:
1. Preparar todas as atualizacoes
2. Validar consistencia
3. Escrever STATE de uma vez
```

---

## Operacoes Comuns

### Iniciar Trabalho

```yaml
# Transicao de IDLE para WORKING
current_session:
  active_blueprint: "BP-2025-01-16-001"  # novo
  current_phase: "P1"                     # de IDLE

active_work:
  blueprint_id: "BP-2025-01-16-001"       # novo
  phases_status:
    P1_DECODE:
      status: "IN_PROGRESS"               # novo
      started_at: "2025-01-16T14:00:00"   # novo
```

### Completar Fase

```yaml
# P1 completa, iniciar P2
phases_status:
  P1_DECODE:
    status: "COMPLETED"                   # de IN_PROGRESS
    completed_at: "2025-01-16T14:30:00"   # novo
    gate_status: "PASSED"                 # novo

  P2_ARCHITECT:
    status: "IN_PROGRESS"                 # novo
    started_at: "2025-01-16T14:35:00"     # novo

current_phase: "P2"                       # de P1
current_gate: null                        # de G1
```

### Registrar Bloqueador

```yaml
active_work:
  blockers:
    - id: "BLK-001"
      description: "API indisponivel"
      since: "2025-01-16T15:00:00"
      impact: "Task T-2.3.4 bloqueada"
      resolution: null

alerts:
  - type: "BLOCKER"
    message: "Task T-2.3.4 bloqueada - API indisponivel"
    timestamp: "2025-01-16T15:00:00"
```

### Finalizar Trabalho

```yaml
# Blueprint completo
current_session:
  active_blueprint: null
  current_phase: "IDLE"
  current_gate: null

active_work:
  blueprint_id: null
  phases_status:
    P4_CRYSTALLIZE:
      status: "COMPLETED"
      gate_status: "PASSED"

blueprints:
  total_generated: 6                      # incrementa
  recent:
    - id: "BP-2025-01-16-001"             # adiciona
      status: "COMPLETED"
```

---

## Anti-Patterns

| Anti-Pattern | Problema | Solucao |
|--------------|----------|---------|
| STATE Stale | Nao atualizado | Atualizar em cada checkpoint |
| Memory Trust | Confiar na memoria | Sempre ler STATE |
| Partial Update | STATE inconsistente | Atualizacoes atomicas |
| Granularity Overload | Update a cada segundo | Apenas em checkpoints |
| STATE Neglect | Ignorar STATE | Boot sequence obrigatorio |

---

## Conclusao

O STATE.yaml e mais do que um arquivo - e a **consciencia** do sistema.

Ele permite:

- **Continuidade** entre sessoes
- **Transferibilidade** entre executores
- **Auditabilidade** de acoes
- **Recuperacao** de falhas

> "Se nao esta no STATE, nao aconteceu.
> Se esta no STATE, pode ser continuado."

---

*"A memoria e a base da consciencia." - Filosofia*
*"STATE.yaml e a memoria de ATHENA." - ATHENA*
