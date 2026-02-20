# AGENT DEPLOYMENT PROTOCOL — ATHENA OS 2.0

> **"Delegar bem é multiplicar capacidade. Delegar mal é multiplicar problemas."**

---

## QUANDO SPAWNAR UM AGENT

### Indicadores POSITIVOS (deve spawnar):

1. **Foco profundo necessário** — Task requer concentração sem interrupção
2. **Escopo bem definido** — Pode especificar completamente upfront
3. **Resultado mensurável** — Sabe como verificar sucesso
4. **Independência** — Não precisa de input durante execução
5. **Paralelizável** — Pode rodar junto com outras tasks

### Indicadores NEGATIVOS (não spawnar):

1. **Feedback iterativo** — Precisa ajustar durante execução
2. **Escopo vago** — "Faça algo interessante"
3. **Contexto compartilhado crítico** — Depende de estado em evolução
4. **Decisões não delegáveis** — Requer julgamento do operador
5. **Task trivial** — Mais rápido fazer direto

---

## DECISION TREE

```
CONSIDERAR AGENT?
        │
        ▼
┌───────────────────────────┐
│ Task pode ser especificada│
│ completamente upfront?    │
└───────────────────────────┘
        │            │
       SIM          NÃO
        │            │
        ▼            ▼
┌─────────────────┐  FAZER DIRETO
│ Task beneficia  │
│ de foco profundo│
│ sem interrupção?│
└─────────────────┘
        │         │
       SIM       NÃO
        │         │
        ▼         ▼
┌──────────────┐  FAZER DIRETO
│ Resultado é  │
│ claramente   │
│ verificável? │
└──────────────┘
       │        │
      SIM      NÃO
       │        │
       ▼        ▼
   SPAWNAR   FAZER DIRETO
    AGENT    (mais controle)
```

---

## TAXONOMIA DE AGENT TYPES

### code-master
**Quando usar:** Implementação de código com TDD e boas práticas
**Strengths:** Escrita de código, testes, refatoração
**Briefing ideal:** Templates, exemplos, critérios de aceite

### architect
**Quando usar:** Design de sistemas, planejamento estratégico
**Strengths:** Arquitetura, trade-offs, visão sistêmica
**Briefing ideal:** Constraints, requisitos, contexto existente

### researcher
**Quando usar:** Pesquisa profunda, síntese de informações
**Strengths:** Busca, análise, síntese multi-fonte
**Briefing ideal:** Perguntas específicas, fontes a considerar

### Explore
**Quando usar:** Entender codebase, encontrar informação
**Strengths:** Navegação, descoberta, mapeamento
**Briefing ideal:** O que buscar, onde começar

### reviewer
**Quando usar:** Revisão de código, validação de qualidade
**Strengths:** Análise crítica, bugs, boas práticas
**Briefing ideal:** O que revisar, critérios de qualidade

---

## PATTERNS MULTI-AGENT

### 1. FAN-OUT (Paralelo Independente)

```
                    ┌─────────────┐
                    │   MAIN      │
                    └──────┬──────┘
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
      ┌─────────┐    ┌─────────┐    ┌─────────┐
      │ Agent A │    │ Agent B │    │ Agent C │
      │  E1     │    │  E2     │    │  E3     │
      └────┬────┘    └────┬────┘    └────┬────┘
           │               │               │
           └───────────────┼───────────────┘
                           ▼
                    ┌─────────────┐
                    │  COLLECT    │
                    │  RESULTS    │
                    └─────────────┘
```

**Quando usar:** Tasks independentes que podem rodar em paralelo
**Exemplo:** Implementar 4 épicos simultaneamente

---

### 2. PIPELINE (Sequencial)

```
┌─────────┐    ┌─────────┐    ┌─────────┐
│ Agent A │───►│ Agent B │───►│ Agent C │
│ Pesquisa│    │ Análise │    │ Síntese │
└─────────┘    └─────────┘    └─────────┘
```

**Quando usar:** Output de um é input do próximo
**Exemplo:** Research → Architecture → Implementation

---

### 3. SPECIALIST (Um faz tudo profundo)

```
┌─────────────────────────────┐
│        MAIN                 │
├─────────────────────────────┤
│ Task complexa               │
│ Spawn 1 agent specialist    │
│ Briefing completo           │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│      SPECIALIST AGENT       │
│  Faz todo o trabalho        │
│  profundo                   │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│     RESULTADO COMPLETO      │
└─────────────────────────────┘
```

**Quando usar:** Task requer expertise focada
**Exemplo:** Implementar um epic complexo inteiro

---

### 4. REVIEW (Um faz, outro valida)

```
┌─────────┐         ┌─────────┐
│ Agent A │────────►│ Agent B │
│  CRIA   │         │ VALIDA  │
└─────────┘         └────┬────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
       APROVADO     CORREÇÕES     REJEITAR
          │              │         (raro)
          ▼              ▼
       DONE         AGENT A
                    CORRIGE
```

**Quando usar:** Qualidade é crítica, dois olhares melhor que um
**Exemplo:** Code review, validação de Blueprint

---

## TEMPLATE DE BRIEFING

```markdown
# AGENT BRIEFING: {NOME_DA_TASK}

## CONTEXTO
{2-3 sentenças sobre o background necessário}

## OBJETIVO
{Uma frase clara e específica do que fazer}

## DELIVERABLES
- [ ] Deliverable 1 com critério de aceite
- [ ] Deliverable 2 com critério de aceite
- [ ] Deliverable 3 com critério de aceite

## CONSTRAINTS
- NÃO fazer: {lista de coisas a evitar}
- MANTER: {o que preservar}
- SEGUIR: {padrões ou templates}

## REFERÊNCIAS
- Template a usar: {path}
- Exemplo de output: {path}
- Documentação relevante: {path}

## CRITÉRIO DE SUCESSO
{Como saber que está completo e correto}

## OUTPUT ESPERADO
{Formato e localização do output}
```

---

## ANTI-PATTERNS DE DELEGAÇÃO

### 1. Briefing Vago
**Problema:** "Faça algo com os arquivos"
**Solução:** Especificar exatamente o que, como, e onde

### 2. Micro-management
**Problema:** Briefing com cada micro-passo
**Solução:** Definir objetivo e constraints, deixar agent decidir como

### 3. No Exit Criteria
**Problema:** Agent não sabe quando está pronto
**Solução:** Critério de sucesso claro e verificável

### 4. Context Starvation
**Problema:** Não dar contexto suficiente
**Solução:** Incluir referências, exemplos, padrões

### 5. Over-delegation
**Problema:** Spawnar agent para task de 2 minutos
**Solução:** Fazer direto se é rápido e simples

---

## CHECKLIST PRÉ-SPAWN

Antes de spawnar agent:

- [ ] Task está claramente definida?
- [ ] Resultado é verificável?
- [ ] Briefing inclui contexto necessário?
- [ ] Constraints estão especificadas?
- [ ] Referências incluídas?
- [ ] Critério de sucesso definido?
- [ ] É mesmo melhor delegar que fazer direto?

---

*ATHENA OS 2.0 — Agent Deployment Protocol*
*"Delegação efetiva é multiplicação de capacidade."*
