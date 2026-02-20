---
type: knowledge-skill
id: SKILL-WRK-context-engineering-20260207-007
source: MTH-20260207-021
domain: context-engineering
skill_type: workflow
confidence: 0.85
---

# Prompt to Context Engineering Transition

> 7-step transition from prompt engineering to context engineering with GraphRAG and Minimum Viable Context pyramid

## Pre-condicoes

- [ ] Existing AI system hitting prompt-only limitations (inconsistency, hallucinations, context loss)
- [ ] Familiarity with basic RAG
- [ ] Access to structurable domain data (documents, APIs, databases)
- [ ] Understanding that problem is not 'how to phrase better' but 'what information to provide'

## Passos

### Passo 1: Diagnose prompt engineering failures

**Acao:** Diagnose prompt engineering failures

Identify if problems are context failures, not prompting: model lacks necessary information for next step (prompt too generic), prompt grows enormous trying to compensate for missing context, model forgets earlier details during long workflows, tool use becomes unreliable because instructions buried in noise, inconsistent results (optimal one minute, nonsensical next). Key indicator: if you keep refining prompts and still get inconsistent results, model probably never received the right context.

⚡ **Decision Point:** If tasks are self-contained (summarization, simple classification), prompt engineering may suffice. Context engineering needed when: long tasks exceed context window, enterprise workflows with governance, multi-agent with shared memory, agents needing planning/action/review.

### Passo 2: Change fundamental question

**Acao:** Change fundamental question

Transition from 'How do I phrase this prompt?' to 'What information does model need to succeed and how do I provide that information clearly?' Context engineering manages: retrieval (search relevant information), memory (persistence between interactions), tool definitions (what model can do), task state (in-progress task state), policies (constraints and rules), reasoning history, observations (action results), output constraints (format and content restrictions).

### Passo 3: Implement Context Pyramid

**Acao:** Implement Context Pyramid

Structure context in three layers: Base (Persistent): permanent knowledge and policies. Changes rarely. Includes business rules, compliance, system identity. Middle (Dynamic): dynamic memory and examples. Includes retrieved documents, recent history, user profile. Changes per interaction. Top (Transient): immediate user query and tool outputs. Changes each turn. Objective: send smallest set of high-signal tokens most relevant to context window.

### Passo 4: Apply Minimum Viable Context (MVC)

**Acao:** Apply Minimum Viable Context (MVC)

Ensure model sees exactly what it needs -- neither more nor less: user objective, only most relevant retrieved information, tool definitions IF needed for next step, relevant policies, compacted memory summary. When something is missing: errors. When something is extra: confusion, irrelevant information occupying context window, reduced attention on what matters, token cost without accuracy improvement.

⚡ **Decision Point:** How much information is 'minimum viable'? Requires iteration -- start with more and reduce, or start with less and add as errors reveal gaps.

### Passo 5: Build Knowledge Graph as foundation

**Acao:** Build Knowledge Graph as foundation

Replace unstructured RAG (isolated document chunks) with GraphRAG. Unstructured RAG limitations: vector search retrieves text that seems relevant but lacks deep meaning, multi-hop questions fail because relationships not encoded, long-text retrieval introduces noise and context poisoning, limited explainability (embedding similarity is opaque). GraphRAG models: entities (customers, services, products, teams), relationships (DEPENDS_ON, OWNED_BY), metadata (timestamps, owners, sources). GraphRAG enables: retrieve only relevant slice, traverse multi-hop relationships, apply policy-aware filtering in retrieval, produce explainable grounded outputs.

⚡ **Decision Point:** Knowledge graph vs unstructured RAG? If use cases require multi-step reasoning, situational awareness or compliance, connected knowledge is necessary.

### Passo 6: Evaluate retrieval pipeline

**Acao:** Evaluate retrieval pipeline

Continuously test if delivering MVC: monitor context rot signals (performance degradation with long context), detect hallucinations (indicator of context gaps), verify missing details (information that should be present but wasn't retrieved), adjust chunking, thresholds and ranking based on observations.

### Passo 7: Develop new competencies

**Acao:** Develop new competencies

Expand skillset beyond prompt engineering: graph modeling (model domains as graphs of entities and relationships), retrieval and indexing (optimize search and information recovery), context orchestration (orchestrate real-time context assembly), agent design and tool-use frameworks (design agents and tool frameworks).

## Resultado Esperado

- Context failures diagnosed and documented
- Context pyramid implemented with three layers
- MVC calibrated for use case
- Retrieval pipeline functional (RAG or GraphRAG)
- Team competencies expanded to context engineering

## Se Algo Der Errado

If context engineering proves too complex for current needs, return to improved prompt engineering with better documentation. Context engineering is overkill for simple self-contained tasks. Invest when limitations are measurable.

---
> Fonte: [[MTH-20260207-021]] | Confianca: 0.85
