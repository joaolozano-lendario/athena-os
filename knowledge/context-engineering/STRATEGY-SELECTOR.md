# STRATEGY SELECTOR — ATHENA OS 3.0

> **"A estratégia certa para a tarefa certa."**

---

## VISÃO GERAL

Diferentes tarefas requerem diferentes estratégias de contexto. Selecionar a estratégia correta maximiza eficácia e eficiência.

---

## AS 7 ESTRATÉGIAS

### 1. ZERO-SHOT DIRECT

**Best For:** Tarefas simples, claras, baixa ambiguidade

**Mecanismo:** Confia na capacidade pré-treinada do modelo para seguir instruções diretas.

**Quando usar:**
- Reformatação de texto
- Sumarização simples
- Perguntas diretas
- Conversões de formato

**Template:**
```
[Instrução clara e direta]
[Input]
[Formato de output esperado]
```

**Exemplo:**
```
Convert this JSON to YAML:
{input}
```

---

### 2. FEW-SHOT EXEMPLARS

**Best For:** Formatos específicos, estilos não-padrão, padrões customizados

**Mecanismo:** In-context learning através de 1-5 exemplos de alta qualidade.

**Quando usar:**
- Geração JSON customizada
- Estilo de código específico
- Mimicking voz/estilo de escrita
- Padrões de naming

**Template:**
```
[Instrução]

Example 1:
Input: {input1}
Output: {output1}

Example 2:
Input: {input2}
Output: {output2}

Now process:
Input: {actual_input}
Output:
```

**Dicas:**
- 2-5 exemplos é ideal
- Exemplos devem ser diversos
- Cobrir edge cases

---

### 3. CHAIN-OF-THOUGHT (CoT)

**Best For:** Raciocínio complexo, multi-step, matemático, lógico

**Mecanismo:** Externaliza o processo de raciocínio em passos explícitos.

**Quando usar:**
- Problemas matemáticos
- Análise lógica
- Debugging complexo
- Planejamento estratégico

**Template:**
```
[Problema]

Let's think step by step:
1. First, I need to understand...
2. Then, I should consider...
3. Based on this, I can conclude...

Final answer:
```

**Variantes:**
- Zero-Shot CoT: "Let's think step by step"
- Few-Shot CoT: Exemplos com reasoning
- Self-Consistency: Múltiplos paths, majority vote

---

### 4. RAG (Retrieval-Augmented Generation)

**Best For:** Knowledge-intensive, informação proprietária, verificável

**Mecanismo:** Grounding através de retrieval dinâmico de documentos.

**Quando usar:**
- Perguntas sobre documentação
- Análise de arquivos específicos
- Informação up-to-date
- Respostas verificáveis

**Tools:** `file_search`, `Read`, `Grep`

**Template:**
```
Based on the following document:
<document>
{retrieved_content}
</document>

[Pergunta]

Important: Base your answer ONLY on the document above.
```

**Dicas:**
- Chunk documents appropriately
- Retrieve more, filter later
- Always cite sources

---

### 5. ReAct (Reasoning + Acting)

**Best For:** Interação com sistemas externos, APIs, web, código

**Mecanismo:** Loop iterativo Reason → Act → Observe.

**Quando usar:**
- Web search + análise
- Execução de código
- API interactions
- Debugging interativo

**Tools:** `web.run`, `Bash`, `python`

**Template:**
```
Thought: I need to...
Action: [tool_name]
Action Input: [parameters]
Observation: [result]

Thought: Based on this, I should...
Action: ...
...

Final Answer: ...
```

**Dicas:**
- Clear action boundaries
- Handle errors gracefully
- Limit iteration count

---

### 6. MULTI-AGENT ORCHESTRATION

**Best For:** Tarefas parallelizáveis, perspectivas múltiplas

**Mecanismo:** Orchestrator delega para specialists que trabalham em paralelo.

**Quando usar:**
- Research amplo
- Análise multi-perspectiva
- Tasks independentes
- Review de código

**Pattern:**
```
Orchestrator
    ├── Agent A (perspective 1)
    ├── Agent B (perspective 2)
    └── Agent C (perspective 3)
          ↓
      Merge results
```

**Tools:** `Task` (subagents)

**Dicas:**
- Tasks devem ser independentes
- Clear merge strategy
- Fresh context per agent

---

### 7. SINGLE-AGENT DECOMPOSITION

**Best For:** Tarefas sequenciais com dependências, memória unificada crítica

**Mecanismo:** Um agente mantém estado coerente, decompondo em sub-tasks.

**Quando usar:**
- Coding + debugging (precisa ver código anterior)
- Planejamento multi-step
- Refactoring gradual
- Documentação interconectada

**Pattern:**
```
Agent
    ├── Sub-task 1 → result 1
    ├── Sub-task 2 (uses result 1) → result 2
    └── Sub-task 3 (uses result 2) → final
```

**Dicas:**
- Summarize between phases
- Use /compact when needed
- Clear state tracking

---

## COMPOSITION RULES

### RAG + ReAct
Para tarefas que precisam de knowledge (RAG) E ação (ReAct):
1. Retrieve documents first
2. Reason about what to search/do
3. Execute actions
4. Synthesize with retrieved knowledge

### CoT + Tools
Para raciocínio que precisa de computação:
1. Reason about approach
2. Call tool for computation
3. Continue reasoning with result

### Multi-Agent vs Single-Agent

| Critério | Multi-Agent | Single-Agent |
|----------|-------------|--------------|
| Dependencies | Independent | Dependent |
| Memory | Separate | Shared |
| Parallelism | Yes | No |
| Context | Fresh each | Accumulated |

---

## DECISION TREE

```
Task chegou
    │
    ├── Simples, clara? → ZERO-SHOT
    │
    ├── Precisa formato específico? → FEW-SHOT
    │
    ├── Requer raciocínio complexo? → CoT
    │
    ├── Precisa de documentos? → RAG
    │
    ├── Precisa interagir com sistemas? → ReAct
    │
    ├── Parallelizável? → MULTI-AGENT
    │
    └── Sequencial com estado? → SINGLE-AGENT
```

---

## APLICAÇÃO EM ATHENA

### /athena:compile-context
Usa este framework para selecionar estratégia automaticamente.

### P5: EXECUTE
Combina estratégias:
- Multi-Agent para épicos paralelos
- Single-Agent para tasks sequenciais
- ReAct para execução de código

---

*ATHENA OS 3.0 — Strategy Selector*
*"Estratégia certa, resultado certo."*
