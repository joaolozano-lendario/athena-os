# Principio: Context Engineering

> Projetar contexto para garantir compreensao e acao corretas

**Versao:** 1.0.0
**Principio ATHENA:** P1 (Contexto e Rei), P7 (Transferibilidade Total)

---

## Conceito Central

**Context Engineering** e a disciplina de projetar, estruturar e entregar contexto de forma que o receptor (humano ou IA) possa compreender e agir corretamente sem informacao adicional.

Em ATHENA OS, isso significa: **Todo Blueprint deve ser auto-contido.**

---

## Os 4 Cs do Contexto

### 1. Completude (Completeness)

Toda informacao necessaria esta presente.

**Teste:** O executor precisa perguntar algo para comecar?

```yaml
checklist_completude:
  - "[ ] Objetivo esta claro"
  - "[ ] Pre-requisitos listados"
  - "[ ] Inputs definidos"
  - "[ ] Outputs esperados descritos"
  - "[ ] Primeiro passo e acionavel"
```

### 2. Coerencia (Coherence)

As partes se conectam logicamente.

**Teste:** Ha contradicoes entre secoes?

```yaml
checklist_coerencia:
  - "[ ] Fases seguem ordem logica"
  - "[ ] Outputs de fase N sao inputs de fase N+1"
  - "[ ] IDs sao consistentes"
  - "[ ] Referencias resolvem"
```

### 3. Clareza (Clarity)

A informacao e facil de entender.

**Teste:** Alguem sem conhecimento previo entenderia?

```yaml
checklist_clareza:
  - "[ ] Sem jargao inexplicado"
  - "[ ] Frases curtas e diretas"
  - "[ ] Estrutura visual clara"
  - "[ ] Exemplos concretos presentes"
```

### 4. Concisao (Conciseness)

Sem informacao desnecessaria.

**Teste:** Posso remover algo sem perder significado?

```yaml
checklist_concisao:
  - "[ ] Sem repeticoes"
  - "[ ] Sem tangentes"
  - "[ ] Cada palavra serve proposito"
  - "[ ] Nivel de detalhe apropriado"
```

---

## Layers de Contexto

### Layer 1: Meta-Contexto

"O que isso e e por que existe"

```markdown
## SOBRE ESTE DOCUMENTO
Este Blueprint guia a implementacao de [X] para [projeto Y].
Gerado por ATHENA OS em [data].
```

### Layer 2: Contexto do Dominio

"O problema e o espaco da solucao"

```markdown
## CONTEXTO DO PROBLEMA
- Situacao atual: [descricao]
- Desafio: [o que precisa mudar]
- Restricoes: [limitacoes]
```

### Layer 3: Contexto Operacional

"Como executar"

```markdown
## COMO USAR
1. Ler secoes 1-3 para entender
2. Seguir Checkpoint Map (secao 4)
3. Atualizar STATE a cada conclusao
```

### Layer 4: Contexto de Execucao

"Onde estamos agora"

```markdown
## STATUS ATUAL
- Fase: P2 (ARCHITECT)
- Ultima task: T-1.2.3
- Proximo: Gate G2
```

---

## Tecnicas de Context Engineering

### 1. Context Injection

Injetar contexto relevante no inicio de cada sessao/secao.

```markdown
# FASE 2: ARQUITETURA

> Esta fase transforma a Intent Specification (P1) em um design executavel.
> Pre-requisito: Gate G1 PASSED
> Output: exec-arch.yaml

[conteudo da fase]
```

### 2. Context Bridging

Conectar partes relacionadas explicitamente.

```markdown
Os dados coletados na **Fase 1** (ver T-1.1.1 a T-1.1.5) serao
processados nesta fase usando o schema definido em `schemas/data.yaml`.
```

### 3. Context Scoping

Delimitar claramente o escopo.

```markdown
## ESCOPO DESTE BLUEPRINT

**INCLUI:**
- Analise quantitativa
- Geracao de relatorio

**NAO INCLUI:**
- Coleta de dados (assumidos prontos)
- Implementacao de melhorias (proxima fase)
```

### 4. Context Refreshing

Relembrar contexto em pontos-chave.

```markdown
## CHECKPOINT CP-3

**Onde estamos:**
- Fases 1-2 completas
- Dados analisados
- Insights extraidos

**Proximo:**
- Gerar relatorio final
- Validar com stakeholders
```

---

## Context Handoff

Transferir contexto entre sessoes/executores.

### Estrutura de Handoff

```yaml
handoff:
  from:
    session: "2025-01-16-001"
    executor: "Claude A"
    stopped_at: "T-2.3.4"

  status:
    completed:
      - "E-1: Completo"
      - "E-2: Stories 1-3 completas"
    in_progress:
      - "T-2.3.4: Schema em 80%"
    blocked:
      - "T-2.4.1: Aguardando input"

  context_for_next:
    decisions_made:
      - "Decidido usar formato JSON (ver DP-1)"
    assumptions:
      - "API disponivel 24/7"
    warnings:
      - "Cuidado com rate limit na API"

  first_action: "Completar T-2.3.4 (faltam campos X, Y)"
```

---

## Anti-Patterns de Contexto

| Anti-Pattern | Problema | Solucao |
|--------------|----------|---------|
| Context Starvation | Informacao insuficiente | Verificar 4 Cs |
| Context Overload | Informacao demais | Filtrar o essencial |
| Context Pollution | Informacao irrelevante | Escopo claro |
| Context Fragmentation | Contexto espalhado | Centralizar referencias |
| Context Staleness | Contexto desatualizado | STATE como fonte de verdade |
| Implicit Context | Assumir conhecimento | Explicitar tudo |

---

## Teste de Transferibilidade

O teste final de context engineering:

> **Se alguem que nunca viu este projeto ler apenas o Blueprint,
> consegue executar sem perguntas adicionais?**

### Checklist do Teste

```yaml
transferability_test:
  tester: "Alguem sem contexto previo"

  questions:
    - "Entendi o que precisa ser feito?"
    - "Sei por onde comecar?"
    - "Tenho tudo que preciso?"
    - "Sei como verificar se terminei?"
    - "Sei o que fazer se algo falhar?"

  if_any_no: "Blueprint precisa de mais contexto"
```

---

## Aplicacao Pratica

### Ao Escrever

1. Comece pelo meta-contexto
2. Adicione contexto de dominio
3. Detalhe contexto operacional
4. Mantenha contexto de execucao atualizado

### Ao Revisar

1. Leia como se fosse a primeira vez
2. Marque pontos de confusao
3. Adicione contexto faltante
4. Remova contexto desnecessario

### Ao Transferir

1. Capture decisoes e premissas
2. Documente estado atual
3. Defina proximo passo
4. Sinalize cuidados

---

## Conclusao

Context Engineering nao e sobre documentar mais - e sobre documentar **certo**.

O contexto bem engenheirado:

- **Elimina** perguntas do executor
- **Acelera** onboarding
- **Preserva** conhecimento entre sessoes
- **Garante** execucao consistente

> "Contexto nao e o que voce sabe. E o que o outro precisa saber."

---

*"O maior desperdicio em desenvolvimento e a transferencia de conhecimento que nao acontece." - Desconhecido*
*"ATHENA existe para garantir que essa transferencia aconteca." - ATHENA*
