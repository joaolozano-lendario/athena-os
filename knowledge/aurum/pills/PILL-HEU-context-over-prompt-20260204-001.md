---
id: PILL-HEU-context-engineering-paradigm-20260204-001
title: "Context Engineering > Prompt Engineering"
type: pill
pill_type: heuristic
domain: context-engineering
source_artifact: INS-20260204-019
source_author: Cole Medin
confidence: 0.9
created: 2026-02-04
---

# Context Engineering > Prompt Engineering

> **"Context engineering is 10x better than prompt engineering, 100x better than vibe coding"**

---

## The Paradigm Shift

**Most agent failures aren't model failures—they're CONTEXT failures.**

| Prompt Engineering | Context Engineering |
|-------------------|---------------------|
| Clever wording and phrasing | Complete system for comprehensive context |
| How you phrase the task | Everything the model needs to know |
| Like a sticky note | Like a full screenplay |

---

## The Heuristic

**When agents fail, audit context BEFORE blaming the model.**

The discipline of engineering complete context (documentation, examples, rules, patterns, validation) outperforms clever prompt wording by an **order of magnitude**.

---

## How to Apply

1. **Identify** the failure mode (what went wrong)
2. **Audit** context completeness (what was missing)
3. **Build** context infrastructure:
   - Documentation (CLAUDE.md, AGENTS.md)
   - Examples folder with correct patterns
   - Rules and conventions
   - Validation gates
4. **Test** with comprehensive context BEFORE tweaking prompts
5. **Optimize** prompts only AFTER context is complete

---

## Examples

| Problem | Wrong Approach | Right Approach |
|---------|----------------|----------------|
| Agent generates wrong code patterns | Rewrite prompt with clearer instructions | Add `examples/` folder with correct patterns |
| Agent doesn't follow conventions | Longer, more detailed prompt | Create AGENTS.md with coding standards |
| Multi-step task fails halfway | Cleverer prompt structure | Build PRP with validation loops |

---

## Validation Checklist

- [ ] Did I provide examples, not just instructions?
- [ ] Are project conventions documented, not assumed?
- [ ] Do I have validation loops for self-correction?
- [ ] Is the context complete enough that a new human could do the task?
- [ ] Have I treated context as infrastructure, not afterthought?

---

## Anti-Patterns

- Iterating on prompt wording when context is incomplete
- Blaming the model before auditing context
- Writing longer prompts instead of providing examples
- Treating prompt optimization as the primary lever
- "Vibe coding" — hoping the model figures it out

---

## The Transformation

**BEFORE (prompt engineering mindset):**
> "My prompt isn't clear enough. Let me rewrite it with better wording."

**AFTER (context engineering mindset):**
> "What context is the model missing? Let me add examples, rules, validation, and documentation. Then test again before touching the prompt."

---

*Source: [[INS-20260204-019]] | Cole Medin (coleam00/context-engineering-intro)*
*Related: [[LENS-AFW-ace-framework-20260204-001]], [[SKILL-WRK-context-compression-trilogy-20260204-001]]*
