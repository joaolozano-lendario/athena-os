# /ATHENA:tasks:forge-blueprint

> Pipeline completo para forjar um Blueprint Operacional do zero

---

## Descrição

Este comando executa o pipeline de forja **P0→P1→P2→P3→P4**, guiando o operador desde a reflexão até a cristalização do Blueprint Operacional.

Execução (P5) e aprendizado (P6) são invocados separadamente via `/athena:execute` e `/ATHENA:tasks:learn`.

---

## Pré-requisitos

Antes de executar:

```
Read STATE.yaml  # ~36 lines, verificar estado atual
```

**Condições:**
- [ ] Sistema em estado IDLE (sem trabalho ativo)
- [ ] Operador tem clareza sobre a intenção (mesmo que vaga)

---

## Fluxo de Execução

```
┌─────────────────────────────────────────────────────────────────────┐
│                 FORGE BLUEPRINT PIPELINE v3.1                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  0. INICIALIZAÇÃO                                                   │
│     ├── Read STATE.yaml (~36 lines)                                │
│     ├── Verificar se IDLE                                          │
│     ├── Gerar ID do Blueprint (BP-YYYY-MM-DD-NNN)                  │
│     └── Atualizar STATE (status: FORGING)                          │
│                                                                     │
│  1. P0: REFLECT                                                     │
│     ├── Read: observability/execution_log.yaml (last 5)            │
│     ├── Read: observability/pattern_library.yaml                   │
│     ├── IF AURUM: Read knowledge/aurum/{domain}/                   │
│     ├── Detectar nature code                                       │
│     ├── Carregar cognitive kit + dream team                        │
│     ├── Antecipar riscos                                           │
│     └── Gate G0                                                    │
│                                                                     │
│  2. P1: DECODE                                                      │
│     ├── Solicitar intencao do operador                             │
│     ├── Extrair dimensoes, JTBD, criterios                         │
│     └── Gate G1                                                    │
│                                                                     │
│  3. P2: ARCHITECT                                                   │
│     ├── Analisar complexidade, projetar fases                      │
│     ├── Desenhar workflow                                          │
│     └── Gate G2                                                    │
│                                                                     │
│  4. P3: FRAGMENT                                                    │
│     ├── Derivar epicos, stories, tasks                             │
│     ├── Mapear dependencias e checkpoints                          │
│     └── Gate G3                                                    │
│                                                                     │
│  5. P4: CRYSTALLIZE                                                 │
│     ├── Consolidar: BLUEPRINT.md, ACTIVATION.md, configs           │
│     ├── Write: outputs/blueprints/{date}/{slug}/                   │
│     └── Gate G4                                                    │
│                                                                     │
│  6. FINALIZAÇÃO                                                     │
│     ├── Update STATE → IDLE                                        │
│     ├── Append to blueprints-archive.yaml                          │
│     └── Suggest: /athena:execute or /ATHENA:tasks:learn            │
│                                                                     │
│  (P5: EXECUTE e P6: LEARN sao comandos separados)                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Instruções para ATHENA

### Ao iniciar este comando:

1. **Ler STATE.yaml** (~36 lines)
   - Se `current_phase` != "IDLE": Informar operador, perguntar se quer abortar anterior
   - Se IDLE: Prosseguir

2. **Gerar ID do Blueprint**
   - Formato: `BP-{YYYY-MM-DD}-{NNN}`

3. **Atualizar STATE** (minimal)
   ```yaml
   current_session:
     active_blueprint: "{BP-ID}"
     current_phase: "P0_REFLECT"
   active_work:
     status: "FORGING"
   ```

4. **P0: REFLECT**
   - Read: `observability/execution_log.yaml` (last 5 entries from `executions[]`)
   - Read: `observability/pattern_library.yaml` (validated patterns)
   - IF AURUM available: Read `knowledge/aurum/{domain}/` matching nature
   - Detect nature code, load cognitive kit, assemble dream team
   - Gate G0: Reflexao completa?
   - Write: Nothing (P0 is read-only)

5. **P1: DECODE**
   - Read: `protocols/P1-DECODE.md`
   - Solicitar ao operador: "Descreva o que quer fazer."
   - Extrair dimensoes, formular JTBD, definir criterios
   - Gate G1: Intent clara?
   - Write: `intent-spec.yaml` (in memory, saved at P4)

6. **P2: ARCHITECT**
   - Read: `protocols/P2-ARCHITECT.md`
   - Analisar complexidade, projetar fases, desenhar workflow
   - Gate G2: Arquitetura valida?
   - Write: `exec-arch.yaml` (in memory)

7. **P3: FRAGMENT**
   - Read: `protocols/P3-FRAGMENT.md`
   - Derivar epicos, decompor stories, atomizar tasks
   - Gate G3: Fragmentacao completa?
   - Write: `checkpoint-map.yaml` (in memory)

8. **P4: CRYSTALLIZE**
   - Read: `protocols/P4-CRYSTALLIZE.md`
   - Consolidar: BLUEPRINT.md, ACTIVATION.md, taxonomy-config.yaml, _metadata.yaml
   - Gate G4: Pronto para exportar?
   - Write: All files to `outputs/blueprints/{date}/{slug}/`

9. **Finalizar**
   - Update STATE: `current_phase: IDLE`, `active_work.status: IDLE`
   - Increment `blueprints.total_generated` in STATE
   - Append to `observability/blueprints-archive.yaml`
   - Show: resumo, paths, comando para executar ou exportar
   - Suggest: `/athena:execute` or `/ATHENA:tasks:learn`

---

## Outputs

```
outputs/blueprints/{YYYY-MM-DD}/{slug}/
├── BLUEPRINT.md
├── ACTIVATION.md
├── intent-spec.yaml
├── exec-arch.yaml
├── checkpoint-map.yaml
├── taxonomy-config.yaml
└── _metadata.yaml
```

---

## Regras

- **NUNCA** pular gates
- **SEMPRE** atualizar STATE em cada transição de fase
- **SEMPRE** pedir confirmação do operador antes de avançar fase
- **SE** gate falhar, **ENTÃO** voltar para a fase e corrigir

---

## Exemplo de Uso

```
Operador: /ATHENA:tasks:forge-blueprint

ATHENA: Vou iniciar o pipeline de criação de Blueprint.
        
        [Lendo STATE.yaml...]
        Status: IDLE ✓
        
        Blueprint ID: BP-2025-01-16-001
        
        ═══════════════════════════════════════════════
        FASE P1: DECODIFICAÇÃO
        ═══════════════════════════════════════════════
        
        Descreva o que você quer fazer. Pode ser uma 
        ideia vaga, um problema, uma necessidade — eu 
        vou extrair a estrutura.

Operador: Quero criar um framework para analisar os 
          dados de pesquisa do Tally, orquestrando 
          agents para extrair insights quantitativos 
          e qualitativos.

ATHENA: [Processando...]
        
        Extrai dimensões, formula JTBD, define critérios.
        
        ───────────────────────────────────────────────
        GATE G1: VALIDAÇÃO DE INTENT
        ───────────────────────────────────────────────
        
        JTBD: "Quando recebo dados de pesquisas do 
        Tally, quero um framework que orquestre a 
        análise, para extrair insights acionáveis 
        sem reexplicar contexto a cada sessão."
        
        Complexidade: HIGH
        Projeto-alvo: Novo ou existente?
        
        Isso captura sua intenção? [S/N]

[Pipeline continua...]
```

---

*Comando do ATHENA OS v3.1.0*
