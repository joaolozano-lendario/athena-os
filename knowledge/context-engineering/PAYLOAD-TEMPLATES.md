# PAYLOAD TEMPLATES — ATHENA OS 3.0

> **"O template certo para a tarefa certa."**

---

## VISÃO GERAL

Payloads são pacotes de contexto estruturados para tipos específicos de tarefas. Este documento define os 3 templates principais.

---

## QUICK-SCOPE PAYLOAD

### Quando Usar
- Tarefas atômicas e factuais
- Perguntas diretas
- Operações simples
- Modo "chill"

### Estrutura

```markdown
# PERSONA
{role_brief}

# OBJECTIVE
{single_clear_objective}

# CONSTRAINTS
- {constraint_1}
- {constraint_2}

# OUTPUT FORMAT
{expected_format}
```

### Exemplo

```markdown
# PERSONA
You are a code formatter specialist.

# OBJECTIVE
Convert the provided JSON to YAML format.

# CONSTRAINTS
- Preserve all data
- Use standard YAML syntax
- No comments needed

# OUTPUT FORMAT
```yaml
{converted_content}
```
```

### Características
- Mínimo de tokens
- Instruções diretas
- Sem reasoning extenso
- Output claro e definido

---

## DEEP-CONTEXT PAYLOAD

### Quando Usar
- Análises multi-step
- Tarefas que requerem raciocínio
- Modo "balanced" ou "reliability"
- Outputs que precisam ser verificáveis

### Estrutura

```markdown
# PERSONA
{expert_role_with_background}

# CONSTITUTION
- **Clause I: {fidelity_rule}**
- **Clause II: {quality_rule}**
- **Clause III: {safety_rule}**

# OBJECTIVE
{detailed_objective}

# CONTEXT
{rich_background_information}

# AVAILABLE TOOLS
- {tool_1}: {description}
- {tool_2}: {description}

# INSTRUCTIONS
1. {step_1}
2. {step_2}
3. {step_3}

# EVALUATION CRITERIA
- {criterion_1}
- {criterion_2}
```

### Exemplo

```markdown
# PERSONA
You are a senior security analyst with 15 years of experience in application security. You are meticulous, skeptical, and always ground conclusions in evidence.

# CONSTITUTION
- **Clause I: Source Fidelity:** Base answers ONLY on provided code and documentation.
- **Clause II: Precision:** Every vulnerability must include file, line, and severity.
- **Clause III: No False Positives:** Only report confirmed issues, not theoretical.

# OBJECTIVE
Analyze the provided codebase for security vulnerabilities, focusing on OWASP Top 10.

# CONTEXT
This is a Node.js Express API handling user authentication and payment processing.
Tech stack: Express 4.x, MongoDB, JWT auth.
Previous audit found 3 SQL injection issues (now fixed).

# AVAILABLE TOOLS
- file_search: Search code files
- grep: Pattern matching in code

# INSTRUCTIONS
1. Scan authentication flows for issues
2. Check input validation patterns
3. Review session management
4. Analyze data exposure risks
5. Generate prioritized findings

# EVALUATION CRITERIA
- All OWASP Top 10 categories checked
- Each finding has reproduction steps
- Severity ratings follow CVSS
```

### Características
- Persona detalhada com expertise
- Constitution clauses para guardrails
- Instruções step-by-step
- Critérios de avaliação explícitos

---

## CREATIVE-CONTEXT PAYLOAD

### Quando Usar
- Ideação e brainstorming
- Tarefas abertas
- Modo "creative"
- Exploração de possibilidades

### Estrutura

```markdown
# PERSONA
{creative_role}

# INSPIRATION
- {reference_1}
- {reference_2}
- {style_guide}

# OBJECTIVE
{open_ended_goal}

# EXPLORATION SPACE
{what_to_explore}
{what_to_avoid}

# CONSTRAINTS
- {minimal_constraint_1}

# OUTPUT STYLE
{style_preferences}
```

### Exemplo

```markdown
# PERSONA
You are an innovative product designer who thinks in systems and loves challenging conventions. You draw inspiration from diverse fields.

# INSPIRATION
- Apple's focus on simplicity
- Notion's flexibility
- Linear's speed and keyboard-first design
- Figma's collaboration model

# OBJECTIVE
Design a new approach to project management for solo developers working with AI assistants.

# EXPLORATION SPACE
Explore:
- Novel interaction patterns
- AI-native workflows
- Unconventional metaphors
- Cross-domain inspiration

Avoid:
- Copying existing tools directly
- Enterprise-only features
- Complex permission systems

# CONSTRAINTS
- Must work in CLI environment
- Should leverage AI capabilities

# OUTPUT STYLE
Think out loud, explore multiple directions, use sketches/diagrams where helpful. Prioritize novel ideas over safe choices.
```

### Características
- Persona criativa e exploradora
- Referências para inspiração
- Espaço de exploração definido
- Constraints mínimos
- Encorajamento de divergência

---

## SELECTION GUIDE

| Task Type | Payload | Reasoning |
|-----------|---------|-----------|
| Format conversion | Quick-Scope | Simple, deterministic |
| Code review | Deep-Context | Multi-step, needs rigor |
| Bug fix | Deep-Context | Needs analysis |
| Brainstorming | Creative-Context | Open exploration |
| Documentation | Deep-Context | Needs structure |
| Naming ideas | Creative-Context | Needs creativity |
| API query | Quick-Scope | Simple retrieval |
| Architecture design | Creative → Deep | Explore then refine |

---

## COMPOSITION PATTERNS

### Quick → Deep
Start quick for exploration, then deep for implementation.

```
Phase 1: Quick-Scope for initial ideas
Phase 2: Deep-Context for detailed implementation
```

### Creative → Deep
Start creative for ideation, then deep for execution.

```
Phase 1: Creative-Context for brainstorming
Phase 2: Deep-Context for building
```

### Deep with RAG
Deep-Context + document retrieval.

```markdown
# CONTEXT
<documents>
{retrieved_documents}
</documents>

Based on the documents above...
```

### Deep with ReAct
Deep-Context + tool loop.

```markdown
# INSTRUCTIONS
For each finding:
1. Search codebase with grep
2. Read relevant files
3. Analyze and document
4. Repeat until complete
```

---

## ATHENA INTEGRATION

### /athena:compile-context
```bash
/athena:compile-context quick   # Quick-Scope
/athena:compile-context deep    # Deep-Context
/athena:compile-context creative # Creative-Context
```

### Automatic Selection
Based on task analysis:
- Simple + clear → Quick
- Complex + verification → Deep
- Open + exploration → Creative

---

*ATHENA OS 3.0 — Payload Templates*
*"Estrutura certa, resultado certo."*
