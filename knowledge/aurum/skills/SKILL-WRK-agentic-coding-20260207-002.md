---
type: knowledge-skill
id: SKILL-WRK-agentic-coding-20260207-002
source: MTH-20260207-016
domain: agentic-coding
skill_type: workflow
confidence: 0.9
---

# Agentic Engineering Workflow - 4 Phases

> Structured 4-phase process for professionals using AI agents: Architect → Orchestrate → Test → Review

## Pre-condicoes

- [ ] Agentic tool configured (Claude Code, Cursor, Copilot Agent Mode, Cline)
- [ ] Project with clear documentation (CLAUDE.md or equivalent)
- [ ] Type definitions and interfaces defined
- [ ] Comprehensive test suite exists

## Passos

### Passo 1: Architect the solution (HUMAN)

**Acao:** Architect the solution (HUMAN)

Engineer personally defines: data models and API contracts, component hierarchies and boundaries, error handling patterns, security requirements. Critical rule: Do not give vague prompts to agent. Give precise specifications. Quality of agent output is directly proportional to specification precision.

⚡ **Decision Point:** Decide delegation granularity: tasks too large = loss of control, too small = loss of efficiency

### Passo 2: Orchestrate implementation (AGENT)

**Acao:** Orchestrate implementation (AGENT)

Agent executes: multi-file refactors, type-safe migrations, test coverage expansion, documentation updates. Agent handles mechanical work while maintaining consistency with defined architecture. Human monitors progress and provides course corrections when necessary.

⚡ **Decision Point:** When to intervene vs when to let agent iterate: intervene too early loses throughput, too late accumulates drift

### Passo 3: Test and validate (HUMAN)

**Acao:** Test and validate (HUMAN)

Engineer personally verifies: edge cases agent didn't consider, performance under realistic load, security implications, user experience flows. Act as QA, providing specific feedback on what needs adjustment. Do not accept 'compiled, ship it' -- compilation tests are not correctness tests.

⚡ **Decision Point:** Decide test depth: shallow tests pass fast but hide deep bugs

### Passo 4: Review and approve (HUMAN)

**Acao:** Review and approve (HUMAN)

Engineer verifies: code patterns against project standards, architectural consistency, security vulnerabilities, long-term maintainability. Final gate: Engineer is the final approval gate. Never skip this step. Develop pattern recognition for agent-generated code -- common failure modes, security vulnerabilities, architectural drift.

⚡ **Decision Point:** If review reveals architectural problems, return to Step 1 and re-specify before re-delegating

## Resultado Esperado

- Implementation matches architecture specification
- All tests passing including edge cases
- Code reviewed and approved by human engineer
- Documentation updated to reflect changes

## Se Algo Der Errado

If architectural drift detected in Step 4, revert to last architecturally sound state and return to Step 1 with refined specifications. Do not attempt to fix drift by iterating with agent.

---
> Fonte: [[MTH-20260207-016]] | Confianca: 0.9
