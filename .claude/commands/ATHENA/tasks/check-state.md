# /ATHENA:tasks:check-state

> Verificar estado atual do sistema ATHENA OS

---

## Descrição

Exibe o estado atual do sistema de forma clara e acionável, incluindo:
- Status geral
- Trabalho em progresso (se houver)
- Blueprints recentes
- Alertas pendentes

---

## Uso

```bash
/ATHENA:tasks:check-state
```

---

## Output Esperado

```
╔═══════════════════════════════════════════════════════════════════╗
║                      ATHENA OS - STATUS                           ║
╚═══════════════════════════════════════════════════════════════════╝

Sistema: ATHENA OS v1.0.0
Status:  OPERATIONAL ✓
Última atualização: 2025-01-16T14:30:00-03:00

─────────────────────────────────────────────────────────────────────
SESSÃO ATUAL
─────────────────────────────────────────────────────────────────────

Estado: IDLE | WORKING

[SE IDLE]
Nenhum trabalho em progresso.
→ Use /ATHENA:tasks:forge-blueprint para criar um Blueprint

[SE WORKING]
Blueprint Ativo: BP-2025-01-16-001
Intent: "Framework de análise de dados Tally"
Fase Atual: P2 (ARCHITECT)
Gate Pendente: G2

Progresso:
  P1 DECODE     [████████████] COMPLETED ✓
  P2 ARCHITECT  [██████░░░░░░] IN PROGRESS (Gate G2 pendente)
  P3 FRAGMENT   [░░░░░░░░░░░░] NOT STARTED
  P4 CRYSTALLIZE[░░░░░░░░░░░░] NOT STARTED

→ Continue com: Validar arquitetura (Gate G2)

─────────────────────────────────────────────────────────────────────
BLUEPRINTS RECENTES
─────────────────────────────────────────────────────────────────────

| ID                  | Título                  | Status    | Data       |
|---------------------|-------------------------|-----------|------------|
| BP-2025-01-15-002   | Análise de Competitors  | EXPORTED  | 2025-01-15 |
| BP-2025-01-15-001   | Refactor do AD Anatomy  | COMPLETED | 2025-01-15 |

─────────────────────────────────────────────────────────────────────
MÉTRICAS
─────────────────────────────────────────────────────────────────────

Total de Blueprints: 5
Exportados: 3
Tempo médio por Blueprint: 45 min

─────────────────────────────────────────────────────────────────────
ALERTAS
─────────────────────────────────────────────────────────────────────

[SE HOUVER ALERTAS]
⚠️ [WARNING] Blueprint BP-2025-01-14-001 não foi exportado há 2 dias

[SE NÃO HOUVER]
✓ Nenhum alerta pendente

─────────────────────────────────────────────────────────────────────
COMANDOS DISPONÍVEIS
─────────────────────────────────────────────────────────────────────

/ATHENA:tasks:forge-blueprint    - Criar novo Blueprint
/ATHENA:tasks:validate-blueprint - Validar Blueprint
/ATHENA:tasks:export-to-project  - Exportar para projeto

═══════════════════════════════════════════════════════════════════
```

---

## Instruções para ATHENA

1. **Ler STATE.yaml**
   ```bash
   cat STATE.yaml
   ```

2. **Extrair informações relevantes**
   - system.status
   - current_session
   - active_work (se houver)
   - blueprints.recent (últimos 5)
   - metrics
   - alerts

3. **Formatar output**
   - Usar tabelas para listas
   - Usar cores/símbolos para status
   - Sugerir próxima ação relevante

4. **Mostrar ao operador**
   - Output limpo e escaneável
   - Foco no que é acionável

---

## Casos Especiais

### Sistema Nunca Usado
```
Status: IDLE
Nenhum Blueprint ainda.
→ Comece com /ATHENA:tasks:forge-blueprint
```

### Trabalho Abandonado
```
⚠️ Blueprint BP-... está IN_PROGRESS há mais de 24h
→ Continue ou use /ATHENA:tasks:abort-work para limpar
```

### Muitos Blueprints Não Exportados
```
⚠️ 3 Blueprints concluídos mas não exportados
→ Use /ATHENA:tasks:export-to-project para exportar
```

---

*Comando do ATHENA OS v1.0.0*
