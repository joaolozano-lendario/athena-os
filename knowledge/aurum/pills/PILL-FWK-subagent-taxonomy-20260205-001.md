---
type: pill
id: PILL-FWK-subagent-taxonomy-20260205-001
title: "Claude Code Subagent Taxonomy"
pill_type: framework
domain: claude-code
source: "Anthropic Claude Code Docs"
confidence: 0.95
created: 2026-02-05
tags:
  - "#type/pill"
  - "#pill/framework"
  - "#domain/claude-code"
related:
  - "[[FWK-20260205-001]]"
status: active
---

# Claude Code Subagent Taxonomy

> **One-liner:** 3 built-in + custom subagents: Explore (Haiku), Plan, General-Purpose

## Essencia

Claude Code has 3 built-in subagent types + custom agents:

1. **EXPLORE (Haiku Fast)**
   - Model: Haiku 3.5
   - Tools: Read-only (Read, Grep, Glob)
   - Use: Fast search, scan, exploration
   - 5x cheaper, 2x faster than main

2. **PLAN**
   - Model: Inherits from main
   - Tools: Read-only (Read, Grep, Glob)
   - Use: Analysis, planning, design
   - Same quality as main, but read-only

3. **GENERAL-PURPOSE**
   - Model: Inherits from main
   - Tools: ALL (Read, Write, Edit, Bash, etc.)
   - Use: Full execution, complex tasks
   - Full capability, like main agent

4. **CUSTOM (.claude/agents/)**
   - Model: You configure
   - Tools: You configure
   - Use: Specialized domain tasks
   - Loads custom context + knowledge

## Passos

1. Identify task type (explore? plan? execute?)
2. If scan/search → use Explore (Haiku, fast, cheap)
3. If design/analyze → use Plan (quality, read-only)
4. If need Write/Edit/Bash → use General-Purpose (full tools)
5. If specialized domain → use Custom (.claude/agents/)

## Exemplos

**Example 1:**
- **Input:** "Search codebase for all async functions"
- **Output:** Use Explore subagent (Haiku, read-only, fast). Returns summary to main.

**Example 2:**
- **Input:** "Design architecture for new feature"
- **Output:** Use Plan subagent (quality model, read-only). Returns design doc to main.

**Example 3:**
- **Input:** "Implement feature with file changes"
- **Output:** Use General-Purpose (full tools). Writes/edits files.

**Example 4:**
- **Input:** "Extract knowledge using AURUM methodology"
- **Output:** Use Custom subagent (.claude/agents/methodology-distiller.md). Loads specialized context.

## Anti-Patterns

- Using General-Purpose for simple search (waste of tokens)
- Using Explore for tasks that need Write tool (won't work)
- Using Plan when Explore would be faster (Haiku vs main model)
- Not using Custom agents for specialized domains (miss specialized context)
- Using main agent when subagent would be better (context pollution)

## Transformacao

**WRONG tool choice:**
Task: "Search for async functions"
Use: General-Purpose (slow, expensive, full tools not needed)

**RIGHT tool choice:**
Task: "Search for async functions"
Use: Explore (fast, cheap, read-only is enough)

## Checklist de Validacao

- [ ] Did you use Explore for search/scan tasks?
- [ ] Did you use Plan for design/analysis tasks?
- [ ] Did you use General-Purpose only when Write/Edit/Bash needed?
- [ ] Did you use Custom agents for specialized domains?
- [ ] Did you avoid using main agent when subagent would work?

---
*Knowledge Pill | PILL-FWK-subagent-taxonomy-20260205-001 | Confidence: 0.95 | Source: Anthropic Claude Code Documentation*
*Packaged by AURUM Cognitive Refinery | format-renderer | 2026-02-05*
