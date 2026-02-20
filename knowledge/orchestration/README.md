# ORCHESTRATION INTELLIGENCE — ATHENA OS 2.0

> **"The right agent, with the right tools, for the right task, at the right time."**

---

## OVERVIEW

This directory contains the complete Orchestration Intelligence system for ATHENA OS 2.0 — the knowledge base and agent definitions that enable intelligent multi-agent coordination and execution.

---

## KNOWLEDGE BASE

### Core Documents

| Document | Purpose | Key Content |
|----------|---------|-------------|
| **ORCHESTRATION-MANIFESTO.md** | Foundational philosophy | 7 Principles of Orchestration |
| **MULTI-AGENT-PATTERNS.md** | Coordination patterns | 5 multi-agent patterns with examples |
| **AGENT-DEFINITIONS.md** | Agent taxonomy | Complete specs for 5 agent types |
| **AGENT-DEPLOYMENT.md** | When/how to spawn agents | Decision trees + briefing templates |
| **CODEBASE-INTELLIGENCE.md** | Pre-execution analysis | 3 pillars of codebase understanding |
| **TOOL-SELECTION.md** | Tool usage framework | When to use each tool |
| **CONTEXT-OPTIMIZATION.md** | Context management | Strategies for token efficiency |
| **SYNERGIES.md** | Cross-layer integration | How orchestration works with other layers |

---

## THE 7 PRINCIPLES OF ORCHESTRATION

### 1. PARALELIZAÇÃO AGRESSIVA
**"Se tasks são independentes → paralelo"**

Execute multiple agents simultaneously when tasks don't depend on each other.

**Example:** 4 independent epics → 4 parallel agents → 4x speedup

### 2. DELEGAÇÃO CONSCIENTE
**"Foco profundo → spawn agent"**

Delegate to agents when tasks need deep focus and can be fully specified upfront.

**When to delegate:**
- Task requires uninterrupted focus
- Fully specifiable upfront
- Result is clearly verifiable
- No iterative feedback needed

### 3. TOOL RIGHT-SIZING
**"Usar ferramenta mínima suficiente"**

Use the simplest tool that gets the job done.

| Need | Tool |
|------|------|
| Read specific file | `Read` |
| Search content | `Grep` |
| Find files | `Glob` |
| Create file | `Write` |
| Modify file | `Edit` |
| Complex operation | `Bash` |
| Deep exploration | `Task (Explore)` |

### 4. CONTEXT AS CURRENCY
**"Contexto é finito, gastar com sabedoria"**

Context window is limited. Load just-in-time, delegate heavy work to agents, summarize before proceeding.

### 5. DEPTH-FIRST WHEN UNCERTAIN
**"Na dúvida, ir fundo primeiro"**

When path is unclear: pick one direction, go deep, evaluate, pivot if needed.

### 6. FAIL FAST, ADAPT FASTER
**"2 tentativas → pivotar"**

If approach doesn't work after 2 honest attempts → document learning → try different approach.

### 7. HANDOFF WITH FULL CONTEXT
**"Nunca delegar sem contexto completo"**

Every agent briefing must include:
- WHAT to do (objective)
- WHY to do it (context)
- HOW to verify (success criteria)
- WHAT NOT to do (constraints)
- WHERE to learn more (references)

---

## MULTI-AGENT PATTERNS

### Pattern 1: FAN-OUT (Paralelo Independente)
```
     Orchestrator
    /    |    \
  A1    A2    A3
    \    |    /
      Merge
```
**Use:** Independent tasks across epic

### Pattern 2: PIPELINE (Sequencial)
```
Research → Plan → Execute → Review
```
**Use:** Output of one is input of next

### Pattern 3: MAP-REDUCE (Escala)
```
Dataset → [A1, A2, A3] → Aggregate
```
**Use:** Large volume of similar tasks

### Pattern 4: REVIEW CHAIN (Qualidade)
```
Creator → Reviewer → [Approved | Corrections | Rejected]
```
**Use:** Quality is critical

### Pattern 5: COORDINATOR (Sync)
```
       Coordinator
      /    |    \
    W1 ←→ W2 ←→ W3
      \    |    /
     Shared State
```
**Use:** Complex dependencies, shared state

---

## AGENT DEFINITIONS

### Overview

ATHENA OS defines 5 specialized agent types:

```
┌─────────────┬─────────┬─────────────┬───────────────────────────┐
│ Agent       │ Model   │ Tools       │ Purpose                   │
├─────────────┼─────────┼─────────────┼───────────────────────────┤
│ EXECUTOR    │ Sonnet  │ R/W/E/B/Gl/Gr│ Implementation            │
│ REVIEWER    │ Opus    │ R/Gl/Gr     │ Quality validation        │
│ RESEARCHER  │ Opus    │ R/Gl/Gr/Web │ Deep exploration          │
│ DEBUGGER    │ Opus    │ R/Gr/B/Gl   │ Bug diagnosis             │
│ COORDINATOR │ Sonnet  │ R/W/Gl      │ Multi-agent sync          │
└─────────────┴─────────┴─────────────┴───────────────────────────┘

Legend:
R=Read, W=Write, E=Edit, B=Bash, Gl=Glob, Gr=Grep, Web=WebSearch/Fetch
```

### Agent 1: EXECUTOR
**File:** `.claude/agents/executor.md`
**Model:** Sonnet (speed + cost-effectiveness)
**Purpose:** Implement code/content based on specs

**When to use:**
- Feature implementation with clear acceptance criteria
- Code generation from Blueprint
- Content creation from template

**Key principles:**
- KISS, DRY, YAGNI, Single Responsibility
- TDD when appropriate
- Follow existing patterns
- Atomic commits
- EXIT_SIGNAL when complete

### Agent 2: REVIEWER
**File:** `.claude/agents/reviewer.md`
**Model:** Opus (deep analysis)
**Purpose:** Validate quality, find bugs

**When to use:**
- Code review before merge
- Blueprint validation
- Quality gates
- Critical features

**Review checklist:**
- Code quality
- Correctness & edge cases
- Testing coverage
- TypeScript strictness
- Security
- Performance
- Documentation

**Verdicts:**
- APPROVED ✓
- CORRECTIONS_NEEDED ⚠️
- REJECTED ❌ (rare)

### Agent 3: RESEARCHER
**File:** `.claude/agents/researcher.md`
**Model:** Opus (deep reasoning + synthesis)
**Purpose:** Investigate, discover, synthesize

**When to use:**
- Understand unknown codebase
- Research approaches for problem
- Root cause investigation
- Best practices discovery

**Techniques:**
- Breadth-first scan (overview)
- Depth-first dive (deep understanding)
- Pattern mining (conventions)
- Frequency analysis (common practices)
- Dependency tracing (relationships)

**Confidence levels:**
- HIGH (90%+): Multiple sources confirm
- MEDIUM (60-90%): Some evidence, minor contradictions
- LOW (<60%): Limited evidence, inference

### Agent 4: DEBUGGER
**File:** `.claude/agents/debugger.md`
**Model:** Opus (systematic diagnosis)
**Purpose:** Find bugs, identify root causes

**When to use:**
- Tests failing
- Complex bug
- Unexpected behavior
- Performance degradation

**Workflow:**
1. Reproduce bug
2. Isolate minimal case
3. Hypothesize causes
4. Investigate systematically
5. Identify root cause
6. Propose fix
7. Verify fix works

**Common bug categories:**
- Logic errors (off-by-one, reversed conditions)
- Null/undefined errors
- Async/timing issues
- Type errors
- Side effects (mutations)

### Agent 5: COORDINATOR
**File:** `.claude/agents/coordinator.md`
**Model:** Sonnet (adequate reasoning + cost-effective)
**Purpose:** Synchronize multiple agents

**When to use:**
- Multiple agents with dependencies
- Shared state/resources
- Conflicts need resolution
- Complex orchestration

**Responsibilities:**
- Map dependencies
- Launch agents in order
- Monitor progress
- Resolve conflicts
- Aggregate results

**Conflict types:**
- File collision (same file modified)
- API contract mismatch (interface incompatibility)
- Resource contention (same resource needed)

---

## CODEBASE INTELLIGENCE SYSTEM

Before orchestrating agents, gather intelligence about the target codebase.

### The 3 Pillars

**1. STRUCTURAL MAPPING**
Map physical and logical structure:
- Folder hierarchy
- Module boundaries
- Entry points
- Technology stack

**2. PATTERN DISCOVERY**
Discover conventions and idioms:
- Component patterns
- Naming conventions
- Import organization
- TypeScript style
- Error handling

**3. DEPENDENCY GRAPH**
Map relationships:
- Import analysis
- Shared resources
- Coupling analysis
- Integration points

### Intelligence Output

```
{project}/.athena/intelligence/
├── structural-map.md
├── pattern-library.md
├── dependency-map.md
└── last-updated.yaml
```

### Confidence Scoring

**Minimum confidence to proceed:** 0.7

```yaml
Structural Map:
  - All key files read: +0.3
  - Package.json analyzed: +0.2
  - Folder structure mapped: +0.2
  - Entry points identified: +0.3

Pattern Library:
  - 5+ exemplars analyzed: +0.3
  - Config files read: +0.2
  - Frequency analysis done: +0.3

Dependency Map:
  - Import analysis complete: +0.3
  - Circular deps checked: +0.2
  - Coupling scored: +0.3
```

---

## AGENT BRIEFING TEMPLATE

Every agent spawn must use this template:

```markdown
# AGENT BRIEFING: {TASK_NAME}

## AGENT TYPE
{executor | reviewer | researcher | debugger | coordinator}

## OBJECTIVE
{Clear one-sentence statement of what to do}

## CONTEXT
{2-3 sentences of necessary background}

## DELIVERABLES
- [ ] Deliverable 1 (specific, verifiable)
- [ ] Deliverable 2 (specific, verifiable)
- [ ] Deliverable 3 (specific, verifiable)

## CONSTRAINTS
- DON'T: {what to avoid}
- MUST: {what is required}
- FOLLOW: {patterns/templates to follow}

## REFERENCES
- Template: {path}
- Example: {path}
- Documentation: {path or URL}

## SUCCESS CRITERIA
{How to know when task is complete and correct}

## OUTPUT EXPECTED
{Format and location of output}
```

---

## SELECTION DECISION TREE

```
TASK ARRIVES
    │
    ▼
┌────────────────┐
│ Need research? │
└────────────────┘
    │       │
   YES     NO
    │       │
    ▼       ▼
RESEARCHER  ┌────────────────┐
            │ Has bug/issue? │
            └────────────────┘
                │       │
               YES     NO
                │       │
                ▼       ▼
            DEBUGGER  ┌────────────────┐
                      │ Needs review?  │
                      └────────────────┘
                          │       │
                         YES     NO
                          │       │
                          ▼       ▼
                      REVIEWER  ┌────────────────────┐
                                │ Multiple agents?   │
                                └────────────────────┘
                                    │           │
                                   YES         NO
                                    │           │
                                    ▼           ▼
                              COORDINATOR  EXECUTOR
```

---

## INTEGRATION WITH ATHENA PIPELINE

| Phase | Orchestration Strategy |
|-------|------------------------|
| P0: REFLECT | Direct (context critical) |
| P1: DECODE | Direct (interactive with operator) |
| P2: ARCHITECT | Direct (architectural decisions) |
| P3: FRAGMENT | Direct or agent if Blueprint is large |
| P4: CRYSTALLIZE | Parallel if multiple artifacts |
| P5: LEARN | Direct (synthesis crucial) |
| **EXECUTION** | **Parallel aggressive by epics** |

---

## METRICS & OBSERVABILITY

Track orchestration effectiveness:

```yaml
Metrics:
  - Parallelization ratio (parallel vs sequential tasks)
  - Agent success rate (completed without re-briefing)
  - Context efficiency (tokens used vs work done)
  - Time saved (parallel vs would-be sequential)
  - Conflicts resolved (auto vs escalated)

Targets:
  - Parallelization: >60% for independent tasks
  - Agent success: >90% first-try completion
  - Context efficiency: <20% token overhead for coordination
  - Time saved: >3x for 4+ parallel agents
  - Conflicts auto-resolved: >80%
```

---

## QUICK REFERENCE

### When to Use Each Agent

| Situation | Agent |
|-----------|-------|
| Implement well-defined feature | EXECUTOR |
| Review critical code | REVIEWER |
| Understand unknown codebase | RESEARCHER |
| Fix complex bug | DEBUGGER |
| Coordinate 3+ agents | COORDINATOR |
| Create 50 similar files | EXECUTOR (MAP-REDUCE) |
| Research → implement → review | Pipeline (RESEARCHER → EXECUTOR → REVIEWER) |

### When to Use Each Pattern

| Situation | Pattern |
|-----------|---------|
| 4 independent epics | FAN-OUT |
| Research then build | PIPELINE |
| Create 50 personas | MAP-REDUCE |
| Critical feature | REVIEW CHAIN |
| Complex dependencies | COORDINATOR |

---

## ANTI-PATTERNS TO AVOID

### 1. Serial When Parallel
**Problem:** Running sequential when could be parallel
**Solution:** Always ask "can these run in parallel?"

### 2. Over-delegation
**Problem:** Spawning agent for 2-minute task
**Solution:** If < 5 min, do it directly

### 3. Under-specification
**Problem:** Vague briefing ("do something with files")
**Solution:** Complete briefing template always

### 4. No Conflict Plan
**Problem:** Parallel agents, no merge strategy
**Solution:** Define merge/conflict resolution before launch

### 5. Context Starvation
**Problem:** Agent lacks context to succeed
**Solution:** Full briefing with references, examples, constraints

---

## FILES IN THIS DIRECTORY

```
knowledge/orchestration/
├── README.md (this file)
├── ORCHESTRATION-MANIFESTO.md (7 principles)
├── MULTI-AGENT-PATTERNS.md (5 patterns)
├── AGENT-DEFINITIONS.md (5 agent types)
├── AGENT-DEPLOYMENT.md (when/how to spawn)
├── CODEBASE-INTELLIGENCE.md (pre-execution analysis)
├── TOOL-SELECTION.md (tool usage framework)
├── CONTEXT-OPTIMIZATION.md (token efficiency)
└── SYNERGIES.md (cross-layer integration)
```

---

## AGENT FILES

```
.claude/agents/
├── executor.md (implementation specialist)
├── reviewer.md (quality gate specialist)
├── researcher.md (exploration specialist)
├── debugger.md (diagnostic specialist)
└── coordinator.md (orchestration specialist)
```

---

## GETTING STARTED

### For ATHENA Operators

1. **Read:** ORCHESTRATION-MANIFESTO.md (foundational philosophy)
2. **Study:** MULTI-AGENT-PATTERNS.md (coordination patterns)
3. **Reference:** AGENT-DEFINITIONS.md (agent capabilities)
4. **Apply:** Use decision tree to select agents
5. **Brief:** Use briefing template for all spawns

### For Agents Being Spawned

1. **Read:** Your agent definition file (.claude/agents/{type}.md)
2. **Understand:** Your role, constraints, tools
3. **Execute:** Follow your workflow
4. **Report:** Use your agent's output format
5. **Signal:** EXIT_SIGNAL or ESCALATION when done

### For New Agent Types

To add a new agent type:

1. Create `.claude/agents/{type}.md` following existing format
2. Add to AGENT-DEFINITIONS.md
3. Update selection decision tree
4. Document integration points
5. Add metrics tracking

---

## CHANGELOG

### v2.0.0 (2026-01-20)
- Created comprehensive orchestration knowledge base
- Defined 5 specialized agent types
- Documented multi-agent patterns
- Established codebase intelligence system
- Created agent definition files in .claude/agents/

### v1.0.0 (2026-01-18)
- Initial orchestration manifesto
- 7 principles established
- Basic agent deployment protocol
- Tool selection framework

---

*ATHENA OS 2.0 — Orchestration Intelligence*
*"Intelligence precedes effective action. Understanding precedes orchestration."*
