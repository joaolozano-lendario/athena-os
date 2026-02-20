---
type: pill
id: PILL-FWK-hook-lifecycle-20260205-001
title: "7 Hook Events in Claude Code"
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
  - "[[FWK-20260205-005]]"
status: active
---

# 7 Hook Events in Claude Code

> **One-liner:** 7 hook events: SessionStart, UserPromptSubmit, Pre/PostToolUse, Stop, Subagent Start/Stop

## Essencia

7 lifecycle events where hooks can run:

1. **SESSION_START**
   - Runs when Claude Code starts
   - Use: Setup, load state, initialize

2. **USER_PROMPT_SUBMIT**
   - Runs after user sends message
   - Use: Context injection, prompt enhancement

3. **PRE_TOOL_USE**
   - Runs before tool execution
   - Use: Validation, blocking, transformation
   - Exit code 2 = BLOCK tool execution

4. **POST_TOOL_USE**
   - Runs after tool execution
   - Use: Automation, state updates, logging

5. **STOP**
   - Runs when session ends
   - Use: Validation, cleanup, reporting

6. **SUBAGENT_START**
   - Runs when subagent spawned
   - Use: Subagent setup, context injection

7. **SUBAGENT_STOP**
   - Runs when subagent returns
   - Use: Result processing, validation

Configure in .claude/settings.json

## Passos

1. Identify what you need to automate or validate
2. Choose the right lifecycle event
3. Write hook script (exit 0 = continue, exit 2 = block)
4. Add hook to .claude/settings.json
5. Test hook by triggering the event

## Exemplos

**Example 1:**
- **Input:** "Prevent commits without tests"
- **Output:** PRE_TOOL_USE hook: detect git commit → check for tests → exit 2 if no tests (blocks commit)

**Example 2:**
- **Input:** "Auto-update STATE.yaml after extraction"
- **Output:** POST_TOOL_USE hook: detect extraction done → update STATE.yaml → exit 0

**Example 3:**
- **Input:** "Load AURUM state on session start"
- **Output:** SESSION_START hook: read STATE.yaml → display summary → exit 0

## Anti-Patterns

- Using wrong event (e.g., POST_TOOL_USE when need PRE_TOOL_USE blocking)
- Not returning correct exit code (exit 2 for blocking)
- Putting complex logic in hooks (should be fast)
- Not testing hooks before relying on them
- Using SESSION_START for heavy operations (slows startup)

## Transformacao

**NO HOOKS (manual):**
User: "Remember to run tests after changes"
*Depends on Claude remembering*

**WITH HOOKS (automated):**
POST_TOOL_USE hook: Edit detected → runs tests automatically
*No manual reminder needed*

## Checklist de Validacao

- [ ] Did you choose the right lifecycle event?
- [ ] Does hook return correct exit code (0 or 2)?
- [ ] Is hook fast (< 1 second ideally)?
- [ ] Did you test the hook?
- [ ] Is hook configured in settings.json?

---
*Knowledge Pill | PILL-FWK-hook-lifecycle-20260205-001 | Confidence: 0.95 | Source: Anthropic Claude Code Documentation*
*Packaged by AURUM Cognitive Refinery | format-renderer | 2026-02-05*
