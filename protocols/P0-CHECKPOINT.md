# P0: CHECKPOINT — Protocolo de Persistência Cognitiva

> Garantir continuidade de contexto entre sessões

---

## Propósito

O contexto de uma sessão Claude é volátil. Este protocolo garante que:
- Nenhum trabalho seja perdido se a sessão morrer
- Qualquer instância de Claude possa continuar de onde parou
- O raciocínio e decisões sejam preservados, não apenas metadados

---

## Princípio Central

```
STATE.yaml = O QUE está acontecendo (metadados)
_checkpoint.yaml = COMO estava o pensamento (contexto cognitivo)
```

**STATE** é o índice. **CHECKPOINT** é a memória.

---

## Regra de Ouro

> **APÓS CADA GATE PASSAR:**
> 1. Salvar artefato da fase imediatamente
> 2. Atualizar `_checkpoint.yaml` com contexto cognitivo
> 3. Atualizar `STATE.yaml` com metadados
>
> **NUNCA** esperar P4 para salvar. **SEMPRE** persistir incrementalmente.

---

## Estrutura do Checkpoint

```yaml
# _checkpoint.yaml
checkpoint:
  blueprint_id: "BP-YYYY-MM-DD-NNN"
  last_updated: "ISO-8601 timestamp"
  current_phase: "P1|P2|P3|P4"
  current_gate: "G1|G2|G3|G4|null"

  # Contexto cognitivo por fase
  phases:
    P1_DECODE:
      status: "NOT_STARTED|IN_PROGRESS|COMPLETED"
      gate_status: "PENDING|PASSED|FAILED"
      artifacts_saved:
        - "intent-spec.yaml"
      cognitive_context:
        jtbd: "Job To Be Done extraído"
        key_decisions:
          - "Decisão 1 tomada e porquê"
        open_questions: []
        notes: "Notas relevantes"

    P2_ARCHITECT:
      status: "NOT_STARTED|IN_PROGRESS|COMPLETED"
      gate_status: "PENDING|PASSED|FAILED"
      artifacts_saved:
        - "exec-arch.yaml"
      cognitive_context:
        complexity: "LOW|MEDIUM|HIGH"
        architecture_approach: "Descrição da abordagem"
        key_decisions: []
        trade_offs_considered: []

    P3_FRAGMENT:
      status: "NOT_STARTED|IN_PROGRESS|COMPLETED"
      gate_status: "PENDING|PASSED|FAILED"
      artifacts_saved:
        - "checkpoint-map.yaml"
      cognitive_context:
        total_epics: 0
        total_stories: 0
        total_tasks: 0
        decomposition_notes: ""

    P4_CRYSTALLIZE:
      status: "NOT_STARTED|IN_PROGRESS|COMPLETED"
      gate_status: "PENDING|PASSED|FAILED"
      artifacts_saved:
        - "BLUEPRINT.md"
        - "ACTIVATION.md"
        - "taxonomy-config.yaml"
        - "_metadata.yaml"
      cognitive_context:
        consolidation_notes: ""

  # Resumo para recuperação rápida
  recovery_summary:
    what_was_done: "Resumo do que foi completado"
    what_comes_next: "Próximos passos explícitos"
    blockers: []
    operator_decisions_pending: []
```

---

## Localização

```
outputs/blueprints/{YYYY-MM-DD}/{slug}/
├── _checkpoint.yaml      ← Sempre presente durante trabalho ativo
├── intent-spec.yaml      ← Salvo após G1
├── exec-arch.yaml        ← Salvo após G2
├── checkpoint-map.yaml   ← Salvo após G3
├── BLUEPRINT.md          ← Salvo após G4
├── ACTIVATION.md         ← Salvo após G4
├── taxonomy-config.yaml  ← Salvo após G4
└── _metadata.yaml        ← Salvo após G4
```

---

## Boot Sequence Atualizado

```yaml
1. LER: STATE.yaml

2. VERIFICAR: current_session.active_blueprint

3. SE active_blueprint != null:
   3.1 LER: outputs/blueprints/{date}/{slug}/_checkpoint.yaml
   3.2 RESTAURAR: contexto cognitivo da fase atual
   3.3 INFORMAR: operador sobre estado recuperado
   3.4 PERGUNTAR: "Continuar de onde paramos?"

4. SE active_blueprint == null (IDLE):
   4.1 Aguardar comando do operador
```

---

## Comandos de Checkpoint

### Automático
- Checkpoint é salvo automaticamente após cada gate passar
- Não requer ação do operador

### Manual (se necessário)
```
/ATHENA:tasks:save-checkpoint   # Forçar salvamento
/ATHENA:tasks:load-checkpoint   # Forçar carregamento
```

---

## Protocolo de Recuperação

Quando uma nova sessão detecta trabalho ativo:

```
ATHENA: Detectei trabalho em progresso.

        Blueprint: BP-2026-01-18-002
        Título: "Análise e Evolução do Dispatch Framework"
        Fase atual: P2 (ARCHITECT)
        Último gate: G1 PASSED

        Contexto recuperado:
        - JTBD: "Rotear tasks para Haiku/Sonnet/Opus..."
        - Próximo passo: Projetar arquitetura de execução

        Continuar de onde paramos? [S/N]
```

---

## Regras de Implementação

### SEMPRE
- [ ] Criar pasta do Blueprint no início de P1, não em P4
- [ ] Salvar artefato imediatamente após gate passar
- [ ] Atualizar `_checkpoint.yaml` após cada mudança de estado
- [ ] Incluir `recovery_summary` com próximos passos claros

### NUNCA
- [ ] Esperar P4 para salvar artefatos
- [ ] Salvar apenas STATE sem salvar checkpoint
- [ ] Deixar `what_comes_next` vazio
- [ ] Assumir que contexto será preservado entre sessões

---

## Exemplo de Checkpoint Real

```yaml
checkpoint:
  blueprint_id: "BP-2026-01-18-002"
  last_updated: "2026-01-18T14:30:00-03:00"
  current_phase: "P2"
  current_gate: "G1"

  phases:
    P1_DECODE:
      status: "COMPLETED"
      gate_status: "PASSED"
      artifacts_saved:
        - "intent-spec.yaml"
      cognitive_context:
        jtbd: "Quando preciso usar Claude Code em projetos, quero um framework de roteamento inteligente que direcione cada task para Haiku/Sonnet/Opus conforme complexidade, para reduzir custos sem sacrificar qualidade."
        key_decisions:
          - "Escopo inclui análise + plano de evolução, não implementação direta"
          - "Projeto-alvo é dispatch-framework existente"
          - "Deve suportar agentes especializados (copywriter, dev, análise)"
        open_questions: []
        notes: "Operador identificou gap no ATHENA OS: falta persistência cognitiva. Resolvido com P0-CHECKPOINT."

    P2_ARCHITECT:
      status: "IN_PROGRESS"
      gate_status: "PENDING"
      artifacts_saved: []
      cognitive_context:
        complexity: "HIGH"
        architecture_approach: null
        key_decisions: []
        trade_offs_considered: []

  recovery_summary:
    what_was_done: "P1 completo. Intent extraída e validada. JTBD formulado. Critérios de sucesso definidos."
    what_comes_next: "Iniciar P2: Analisar Dispatch Framework, projetar arquitetura de execução para o Blueprint."
    blockers: []
    operator_decisions_pending: []
```

---

## Integração com Outros Protocolos

| Protocolo | Integração |
|-----------|------------|
| P1-DECODE | Após G1 PASS → Salvar intent-spec.yaml + checkpoint |
| P2-ARCHITECT | Após G2 PASS → Salvar exec-arch.yaml + checkpoint |
| P3-FRAGMENT | Após G3 PASS → Salvar checkpoint-map.yaml + checkpoint |
| P4-CRYSTALLIZE | Após G4 PASS → Salvar todos artefatos finais + checkpoint final |

---

## Métricas de Sucesso

O protocolo é bem-sucedido quando:

> **Uma nova instância de Claude consegue continuar o trabalho em menos de 1 minuto de leitura, sem perguntar ao operador "onde paramos?"**

---

*Protocolo P0-CHECKPOINT v1.0.0*
*ATHENA OS*
