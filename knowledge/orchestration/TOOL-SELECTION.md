# TOOL SELECTION FRAMEWORK — ATHENA OS 2.0

> **"A ferramenta certa no momento certo faz toda a diferença."**

---

## VISÃO GERAL

Claude Code disponibiliza um conjunto de ferramentas. Este documento guia a seleção consciente de cada uma.

---

## DECISION TREE: LEITURA

```
PRECISO LER ALGO
       │
       ▼
┌─────────────────────────────┐
│ Sei exatamente qual arquivo?│
└─────────────────────────────┘
       │              │
      SIM            NÃO
       │              │
       ▼              ▼
    READ        ┌───────────────────┐
                │ Sei o padrão do   │
                │ nome do arquivo?  │
                └───────────────────┘
                      │         │
                     SIM       NÃO
                      │         │
                      ▼         ▼
                    GLOB   ┌─────────────┐
                           │ Sei conteúdo│
                           │ que busco?  │
                           └─────────────┘
                                │        │
                               SIM      NÃO
                                │        │
                                ▼        ▼
                              GREP    TASK
                                    (Explore)
```

---

## DECISION TREE: ESCRITA

```
PRECISO ESCREVER ALGO
         │
         ▼
┌─────────────────────────────┐
│ Arquivo já existe?          │
└─────────────────────────────┘
         │              │
        SIM            NÃO
         │              │
         ▼              ▼
┌───────────────┐    WRITE
│ Mudança é     │    (criar novo)
│ localizada?   │
└───────────────┘
    │         │
   SIM       NÃO
    │         │
    ▼         ▼
  EDIT      WRITE
(trecho)  (reescrever)
```

---

## FERRAMENTAS: QUANDO USAR

### Read

**Usar quando:**
- Sabe exatamente qual arquivo ler
- Precisa do conteúdo completo ou trecho específico
- Arquivo não é muito grande

**Não usar quando:**
- Precisa buscar em múltiplos arquivos
- Não sabe onde está a informação

**Exemplo:**
```
Read: D:/athena-os/STATE.yaml
```

---

### Glob

**Usar quando:**
- Sabe o padrão do nome do arquivo
- Precisa encontrar arquivos específicos
- Quer listar estrutura de diretório

**Padrões úteis:**
- `**/*.md` — Todos markdown recursivamente
- `src/**/*.ts` — TypeScript em src
- `**/test*.py` — Arquivos de teste Python

**Não usar quando:**
- Precisa buscar por conteúdo, não nome

---

### Grep

**Usar quando:**
- Sabe um padrão de conteúdo a buscar
- Precisa encontrar onde algo é usado
- Quer todas as ocorrências de um termo

**Exemplo:**
```
Grep: "epistemic_state" em D:/athena-os
```

**Não usar quando:**
- Busca é muito ampla/vaga
- Precisa de compreensão, não localização

---

### Write

**Usar quando:**
- Criar arquivo novo
- Substituir conteúdo inteiro
- Conteúdo é completamente novo

**Não usar quando:**
- Arquivo existe e só precisa de ajustes pequenos

---

### Edit

**Usar quando:**
- Modificar trecho específico de arquivo existente
- Manter resto do arquivo intacto
- Mudança é localizada

**Não usar quando:**
- Arquivo não existe
- Mudança afeta arquivo inteiro

---

### Bash

**Usar quando:**
- Operação de sistema necessária
- Comando git
- Execução de scripts
- Criar estruturas de diretório

**Não usar para:**
- Ler arquivos (usar Read)
- Buscar conteúdo (usar Grep)
- Criar arquivos simples (usar Write)

---

### Task

**Usar quando:**
- Trabalho requer foco profundo
- Múltiplas operações coordenadas
- Investigação que pode demorar
- Paralelização de trabalho

**Tipos de agent:**
- `Explore` — Investigação de codebase
- `code-master` — Implementação de código
- `researcher` — Pesquisa profunda

**Não usar quando:**
- Operação é simples e direta
- Precisa de feedback iterativo

---

### WebFetch / WebSearch

**Usar quando:**
- Informação externa necessária
- Documentação online
- Verificação de fatos atuais

**Não usar quando:**
- Informação está no codebase
- Pode deduzir de contexto local

---

## ANTI-PATTERNS

### 1. Over-Reading
**O que é:** Ler muitos arquivos "por precaução"
**Problema:** Gasta contexto desnecessariamente
**Solução:** Ler just-in-time, apenas o necessário

### 2. Bash para Tudo
**O que é:** Usar bash quando ferramenta específica existe
**Problema:** Menos eficiente, menos feedback
**Solução:** Usar ferramenta certa (Read, Write, Edit)

### 3. Agent para Trivialidades
**O que é:** Spawnar agent para task simples
**Problema:** Overhead desnecessário
**Solução:** Fazer direto se é rápido e simples

### 4. Search sem Foco
**O que é:** Grep muito amplo, resultados demais
**Problema:** Noise > signal
**Solução:** Refinar padrão, limitar escopo

---

## COMBINAÇÕES PODEROSAS (SYNERGIES)

### Pattern 1: Glob → Read
```
1. Glob para encontrar arquivos relevantes
2. Read para examinar cada um
```

### Pattern 2: Grep → Read
```
1. Grep para localizar ocorrências
2. Read com offset para ver contexto
```

### Pattern 3: Read → Edit → Validate
```
1. Read para entender estado atual
2. Edit para fazer mudança
3. Read novamente para validar
```

### Pattern 4: Parallel Tasks
```
1. Spawnar múltiplos agents com briefings claros
2. Coletar resultados
3. Sintetizar
```

---

## CHECKLIST PRÉ-SELEÇÃO

Antes de usar uma ferramenta:

- [ ] Esta é a ferramenta mínima suficiente?
- [ ] Tenho os parâmetros corretos?
- [ ] O resultado esperado é claro?
- [ ] Há alternativa mais simples?

---

*ATHENA OS 2.0 — Tool Selection Framework*
*"Simplicidade é sofisticação máxima."*
