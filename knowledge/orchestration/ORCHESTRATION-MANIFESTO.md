# ORCHESTRATION MANIFESTO — ATHENA OS 2.0

> **"Orquestração consciente não é sobre fazer mais — é sobre fazer certo, na hora certa, com os recursos certos."**

---

## FILOSOFIA

ATHENA opera dentro do Claude Code, que disponibiliza um arsenal de ferramentas e capacidades. A orquestração consciente é a arte de selecionar e coordenar esses recursos para máxima eficácia.

### Princípio Fundacional

> **O operador humano é o arquiteto. Claude é o executor. ATHENA é a ponte que transforma arquitetura em execução impecável.**

---

## OS 7 PRINCÍPIOS DE ORQUESTRAÇÃO

### 1. PARALELIZAÇÃO AGRESSIVA

**"Se tasks são independentes → paralelo"**

Quando identificar tasks que:
- Não dependem uma da outra
- Não competem por recursos
- Podem falhar independentemente

**→ Execute em paralelo usando múltiplos agents.**

```
BOM:  4 agents fazendo E1, E2, E3, E4 simultaneamente
RUIM: Fazer E1, depois E2, depois E3, depois E4 sequencialmente
```

**Exceção:** Quando contexto compartilhado é crítico, sequenciar para manter coerência.

---

### 2. DELEGAÇÃO CONSCIENTE

**"Foco profundo → spawn agent"**

Delegar para um agent quando:
- Task requer foco profundo sem interrupção
- Task pode ser completamente especificada upfront
- Resultado é claramente definível
- Não precisa de feedback iterativo durante execução

**Não delegar quando:**
- Task requer múltiplas decisões interativas
- Contexto muda frequentemente
- Output precisa ser refinado com operador

```
BOM:  "Crie os 8 cognitive kits conforme templates"
RUIM: "Faça algo interessante com os kits"
```

---

### 3. TOOL RIGHT-SIZING

**"Usar ferramenta mínima suficiente"**

| Necessidade | Ferramenta Mínima |
|-------------|-------------------|
| Ler arquivo específico | Read |
| Buscar padrão em arquivos | Grep |
| Encontrar arquivos por nome | Glob |
| Criar arquivo novo | Write |
| Modificar trecho específico | Edit |
| Operação complexa de sistema | Bash |
| Investigação profunda multi-arquivo | Task (Explore) |

**Regra:** Se pode fazer com ferramenta simples, não use complexa.

---

### 4. CONTEXT AS CURRENCY

**"Contexto é finito, gastar com sabedoria"**

O contexto da sessão é um recurso limitado. Cada leitura, cada output, cada decisão consome esse recurso.

**Estratégias de economia:**
- Carregar apenas o necessário, just-in-time
- Resumir antes de prosseguir
- Delegar trabalho focado para agents
- Estruturar outputs de forma compacta

**Anti-pattern:** Carregar 10 arquivos "por precaução" no início.

---

### 5. DEPTH-FIRST WHEN UNCERTAIN

**"Na dúvida, ir fundo primeiro"**

Quando o caminho não está claro:
1. Escolha uma direção
2. Vá fundo nela
3. Avalie se é o caminho certo
4. Se não, volte e tente outra

**Melhor que:** Ficar na superfície de múltiplas opções sem progredir em nenhuma.

---

### 6. FAIL FAST, ADAPT FASTER

**"2 tentativas → pivotar"**

Se uma abordagem não funciona após 2 tentativas honestas:
1. Não insista
2. Documente o que aprendeu
3. Pivote para abordagem alternativa

**Regra:** Falha rápida é feature, não bug.

---

### 7. HANDOFF WITH FULL CONTEXT

**"Nunca delegar sem contexto completo"**

Ao delegar para agent ou próxima sessão:

**Incluir SEMPRE:**
- O que precisa ser feito (objetivo claro)
- Por que precisa ser feito (contexto)
- Como saber se está feito (critérios de sucesso)
- O que NÃO fazer (constraints)
- Onde encontrar mais informação (referências)

**Template de briefing:**
```markdown
## OBJETIVO
{Uma frase clara}

## CONTEXTO
{2-3 sentenças de background}

## DELIVERABLES
- [ ] Deliverable 1
- [ ] Deliverable 2

## CONSTRAINTS
- Não fazer X
- Manter compatibilidade com Y

## REFERÊNCIAS
- Arquivo A: {path}
- Padrão a seguir: {referência}

## CRITÉRIO DE SUCESSO
{Como saber que está completo}
```

---

## DECISION FRAMEWORK

### Quando usar cada estratégia:

```
┌─────────────────────────────────────────────────────────────┐
│                    TASK CHEGOU                               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
            ┌───────────────────────────────┐
            │  É uma task ou múltiplas?     │
            └───────────────────────────────┘
                     │              │
              UMA TASK        MÚLTIPLAS
                     │              │
                     ▼              ▼
    ┌────────────────────┐    ┌────────────────────┐
    │ Precisa de foco    │    │ São independentes? │
    │ profundo?          │    └────────────────────┘
    └────────────────────┘         │         │
         │         │             SIM        NÃO
        SIM       NÃO             │         │
         │         │              ▼         ▼
         ▼         ▼         PARALELO  SEQUENCIAL
    DELEGATE   FAZER DIRETO
    (agent)    (tool simples)
```

---

## APLICAÇÃO NO PIPELINE ATHENA

| Fase | Orquestração Típica |
|------|---------------------|
| P0: REFLECT | Direto, contexto é crítico |
| P1: DECODE | Direto, interação com operador |
| P2: ARCHITECT | Direto, decisões arquiteturais |
| P3: FRAGMENT | Direto ou agent se Blueprint grande |
| P4: CRYSTALLIZE | Paralelo se múltiplos artifacts |
| P5: LEARN | Direto, síntese é crucial |
| EXECUÇÃO | Paralelo agressivo por épicos |

---

## MÉTRICAS DE ORQUESTRAÇÃO

Após cada execução, avaliar:

1. **Paralelização aproveitada?** — Quantas tasks rodaram em paralelo
2. **Delegação efetiva?** — Agents completaram sem re-briefing
3. **Contexto bem gerido?** — Sessão não sobrecarregou
4. **Falhas rápidas?** — Pivotamos quando necessário
5. **Handoffs completos?** — Nenhuma informação perdida

---

*ATHENA OS 2.0 — Orchestration Manifesto*
*"Orquestração é multiplicação de capacidade, não soma."*
