# /ATHENA:tasks:forge-blueprint

> Pipeline completo para forjar um Blueprint Operacional do zero

---

## Descrição

Este comando executa o pipeline completo P1→P4, guiando o operador através de todas as fases para criar um Blueprint Operacional completo e pronto para exportação.

---

## Pré-requisitos

Antes de executar:

```bash
cat STATE.yaml  # Verificar estado atual
```

**Condições:**
- [ ] Sistema em estado IDLE (sem trabalho ativo)
- [ ] Operador tem clareza sobre a intenção (mesmo que vaga)

---

## Fluxo de Execução

```
┌─────────────────────────────────────────────────────────────────────┐
│                     FORGE BLUEPRINT PIPELINE                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. INICIALIZAÇÃO                                                   │
│     ├── Ler STATE.yaml                                             │
│     ├── Verificar se IDLE                                          │
│     ├── Gerar ID do Blueprint (BP-YYYY-MM-DD-NNN)                  │
│     └── Atualizar STATE (current_phase: P1)                        │
│                                                                     │
│  2. P1: DECODE                                                      │
│     ├── Solicitar intenção do operador                             │
│     ├── Extrair dimensões (WHAT, WHY, WHO, WHERE, WHEN, HOW)       │
│     ├── Formular JTBD                                              │
│     ├── Definir critérios de sucesso                               │
│     ├── Gerar intent-spec.yaml                                     │
│     └── Gate G1: Intent clara?                                     │
│         ├── SE PASS: Avançar para P2                               │
│         └── SE FAIL: Solicitar clarificação                        │
│                                                                     │
│  3. P2: ARCHITECT                                                   │
│     ├── Analisar complexidade                                      │
│     ├── Projetar fases                                             │
│     ├── Definir agentes (se aplicável)                             │
│     ├── Desenhar workflow                                          │
│     ├── Mapear pontos de decisão                                   │
│     ├── Gerar exec-arch.yaml                                       │
│     └── Gate G2: Arquitetura válida?                               │
│         ├── SE PASS: Avançar para P3                               │
│         └── SE FAIL: Revisar arquitetura                           │
│                                                                     │
│  4. P3: FRAGMENT                                                    │
│     ├── Derivar épicos das fases                                   │
│     ├── Decompor em stories                                        │
│     ├── Atomizar em tasks                                          │
│     ├── Mapear dependências                                        │
│     ├── Definir checkpoints                                        │
│     ├── Gerar checkpoint-map.yaml                                  │
│     └── Gate G3: Fragmentação completa?                            │
│         ├── SE PASS: Avançar para P4                               │
│         └── SE FAIL: Decompor mais                                 │
│                                                                     │
│  5. P4: CRYSTALLIZE                                                 │
│     ├── Consolidar todos os artefatos                              │
│     ├── Gerar BLUEPRINT.md                                         │
│     ├── Gerar ACTIVATION.md                                        │
│     ├── Gerar taxonomy-config.yaml                                 │
│     ├── Gerar _metadata.yaml                                       │
│     └── Gate G4: Pronto para exportar?                             │
│         ├── SE PASS: Finalizar                                     │
│         └── SE FAIL: Refinar artefatos                             │
│                                                                     │
│  6. FINALIZAÇÃO                                                     │
│     ├── Salvar todos os arquivos em outputs/blueprints/            │
│     ├── Atualizar STATE (current_phase: IDLE)                      │
│     ├── Atualizar métricas                                         │
│     └── Mostrar resumo e próximos passos                           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Instruções para ATHENA

### Ao iniciar este comando:

1. **Ler STATE.yaml**
   ```bash
   cat STATE.yaml
   ```

2. **Verificar estado**
   - Se `current_phase` não for "IDLE": Informar operador e perguntar se quer abortar trabalho anterior
   - Se IDLE: Prosseguir

3. **Gerar ID do Blueprint**
   - Formato: `BP-{YYYY-MM-DD}-{NNN}`
   - NNN = próximo número sequencial do dia

4. **Atualizar STATE**
   ```yaml
   current_session:
     started_at: "{timestamp}"
     active_blueprint: "{BP-ID}"
     current_phase: "P1"
   
   active_work:
     blueprint_id: "{BP-ID}"
     phases_status:
       P1_DECODE:
         status: "IN_PROGRESS"
         started_at: "{timestamp}"
   ```

5. **Executar P1: DECODE**
   
   Solicitar ao operador:
   > "Descreva o que você quer fazer. Pode ser uma ideia vaga, um problema, uma necessidade — eu vou extrair a estrutura."
   
   Após receber input, executar extração conforme `protocols/P1-DECODE.md`:
   - Extrair dimensões
   - Formular JTBD
   - Definir critérios de sucesso
   - Gerar `intent-spec.yaml`
   
   Apresentar resumo ao operador e solicitar validação (Gate G1).

6. **Executar P2: ARCHITECT**
   
   Com base na Intent Specification:
   - Analisar complexidade
   - Propor fases
   - Sugerir agentes (se necessário)
   - Desenhar workflow
   
   Gerar `exec-arch.yaml`.
   
   Apresentar arquitetura ao operador e solicitar validação (Gate G2).

7. **Executar P3: FRAGMENT**
   
   Com base na Architecture:
   - Derivar épicos
   - Decompor stories
   - Atomizar tasks
   - Mapear dependências
   - Definir checkpoints
   
   Gerar `checkpoint-map.yaml`.
   
   Apresentar fragmentação ao operador e solicitar validação (Gate G3).

8. **Executar P4: CRYSTALLIZE**
   
   Consolidar tudo:
   - Gerar `BLUEPRINT.md` completo
   - Gerar `ACTIVATION.md` pronto para uso
   - Gerar `taxonomy-config.yaml`
   - Gerar `_metadata.yaml`
   
   Apresentar artefatos ao operador e solicitar validação final (Gate G4).

9. **Finalizar**
   
   - Salvar arquivos em `outputs/blueprints/{date}/{slug}/`
   - Atualizar STATE para IDLE
   - Atualizar métricas
   - Mostrar:
     - Resumo do Blueprint criado
     - Path dos arquivos
     - Comando para exportar: `/ATHENA:tasks:export-to-project {path}`

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

*Comando do ATHENA OS v1.0.0*
