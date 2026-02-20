# THREAT PLAYBOOKS — ATHENA OS 3.0

> **"Conhecer as ameaças é o primeiro passo para prevení-las."**

---

## VISÃO GERAL

Context Engineering tem failure modes previsíveis. Este documento cataloga as 4 principais ameaças e suas contramedidas.

---

## THREAT 1: CONTEXT POISONING

### Descrição
Dados corrompidos ou incorretos no contexto degradam todo raciocínio subsequente.

### Sintomas
- Respostas factualmente incorretas
- Raciocínio baseado em premissas falsas
- Inconsistências lógicas
- Hallucinations aumentadas

### Causas
- Documentos desatualizados no contexto
- RAG retrieval de fontes não-confiáveis
- Erros em few-shot examples
- Informação conflitante de múltiplas fontes

### Countermeasures

**1. Self-Critique Loop**
```markdown
## Instructions
After completing your analysis:
1. Review your reasoning against the original sources
2. Identify any statements not directly supported by context
3. Flag uncertainties explicitly
```

**2. Source Fidelity Clause**
```markdown
## Constitution
Clause I: You must base answers ONLY on provided <context>.
If information is not in context, state "Not found in provided sources."
```

**3. Freshness Checks**
- Timestamp documents
- Verify sources before including
- Prefer authoritative sources

---

## THREAT 2: CONTEXT DISTRACTION

### Descrição
Informação repetida ou irrelevante causa fixação em padrões errados.

### Sintomas
- Foco em detalhes irrelevantes
- Ignorar informação importante
- Respostas tangenciais
- Repetição de padrões incorretos

### Causas
- Histórico de conversa muito longo
- Documentos RAG não-filtrados
- Exemplos repetitivos sem variação
- Informação redundante

### Countermeasures

**1. Aggressive Context Pruning**
```markdown
## Compaction Strategy
Before continuing, summarize key points from previous turns:
- Main objective: ...
- Decisions made: ...
- Current blockers: ...

Previous detailed history can be ignored.
```

**2. Relevance Filtering**
```python
# RAG retrieval
results = search(query)
filtered = [r for r in results if relevance_score(r) > 0.7]
```

**3. Serialization Variance**
```markdown
# Vary format slightly between examples to prevent pattern lock
Example 1: JSON format
Example 2: YAML format
Example 3: Markdown table
```

---

## THREAT 3: CONTEXT CONFUSION

### Descrição
Muitas ferramentas ou documentos disponíveis levam a escolhas erradas.

### Sintomas
- Uso de ferramenta incorreta
- RAG retrieval de documento errado
- Ações que não fazem sentido para a tarefa
- Confusion entre fontes similares

### Causas
- Muitas ferramentas disponíveis
- Documentos com conteúdo similar
- Descrições de ferramentas ambíguas
- Falta de guidance sobre quando usar o quê

### Countermeasures

**1. Dynamic Sub-Context**
```markdown
## Available Tools for THIS Task
For code implementation:
- Edit: Modify existing files
- Write: Create new files
- Bash: Run tests

Do NOT use: WebSearch, WebFetch (not needed for this task)
```

**2. Tool Selection Guidance**
```markdown
## Tool Selection Rules
- Finding files by name? → Glob
- Searching file contents? → Grep
- Reading a file? → Read
- Complex multi-step? → Task (subagent)
```

**3. Source Attribution**
```markdown
## Constitution
Clause V: EVERY statement must cite its source.
Format: [source: document_name, section]
```

---

## THREAT 4: CONTEXT CLASH

### Descrição
Instruções conflitantes de múltiplas fontes degradam performance.

### Sintomas
- Comportamento inconsistente
- Alternância entre estilos
- Instruções parcialmente seguidas
- Confusion sobre prioridades

### Causas
- CLAUDE.md global vs project conflitam
- Múltiplas fontes de truth
- Instruções implícitas vs explícitas
- Updates parciais em documentos

### Countermeasures

**1. Monolithic Instruction Set**
```markdown
## Single Source of Truth
All instructions for this task are in THIS document.
Ignore any conflicting guidance from other sources.
Priority order:
1. This prompt
2. Project CLAUDE.md
3. Global CLAUDE.md
```

**2. Clear Order of Operations**
```markdown
## Execution Order
1. First, analyze the PDF using file_search
2. Then, search web for updates using web.run
3. Finally, synthesize (do NOT mix facts between sources)

Cite source for EVERY claim: [fonte: pdf] or [fonte: web]
```

**3. Explicit Override Rules**
```markdown
## Override Rules
IF project CLAUDE.md conflicts with global → Project wins
IF this prompt conflicts with CLAUDE.md → This prompt wins
IF uncertain → Ask for clarification
```

---

## DETECTION CHECKLIST

| Threat | Warning Signs | Action |
|--------|---------------|--------|
| Poisoning | Wrong facts, false premises | Verify sources, add self-critique |
| Distraction | Tangential responses, repetition | Prune history, filter relevance |
| Confusion | Wrong tool, wrong doc | Constrain options, add guidance |
| Clash | Inconsistent behavior | Establish hierarchy, single source |

---

## PREVENTION BEST PRACTICES

### 1. Constitution Clauses
Include explicit behavior rules that override implicit tendencies.

### 2. Source Verification
Always verify sources before including in context.

### 3. Minimal Viable Context
Include only what's needed. Less is more.

### 4. Clear Hierarchies
Establish explicit priority when multiple sources exist.

### 5. Continuous Monitoring
Watch for symptoms during execution.

---

## ATHENA APPLICATION

### P5: EXECUTE
- **Anti-Poisoning:** Verification phase validates output
- **Anti-Distraction:** Fresh 200K context per task
- **Anti-Confusion:** Specialized agents with focused tools
- **Anti-Clash:** Blueprint as single source of truth

### Circuit Breaker
Triggers on symptoms:
- 3+ loops with same error (possible confusion)
- Repeated incorrect attempts (possible poisoning)
- Tangential outputs (possible distraction)

---

*ATHENA OS 3.0 — Threat Playbooks*
*"Prevenção é melhor que correção."*
