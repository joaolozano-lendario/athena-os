---
type: skill
id: SKILL-WRK-hooks-automation-20260205-001
title: "Claude Code Hooks Automation"
skill_type: workflow
domain: claude-code
source: "MTH-20260205-005"
confidence: 0.9
created: 2026-02-05
tags:
  - "#type/skill"
  - "#skill/workflow"
  - "#domain/claude-code"
related:
  - "[[MTH-20260205-005]]"
status: active
---

# Claude Code Hooks Automation

> **One-liner:** Automate repetitive Claude Code workflows with event-driven hooks

## Pre-condicoes

- [ ] Claude Code installed
- [ ] Repetitive task identified (formatting, testing, validation, logging)
- [ ] settings.json accessible (.claude/settings.json or ~/.claude/settings.json)
- [ ] Shell script or command available for automation

## Passos de Execucao

### Step 1: Identify automation opportunity

Categories: Validation (block dangerous ops), Formatting (auto-lint), Testing (run after changes), Logging (audit trail), Context Injection (add knowledge at session start)

**Decision Point:**
- Validation: Use PreToolUse to block before execution
- Formatting/Testing: Use PostToolUse to run after completion
- Setup: Use SessionStart for environment configuration
- Cleanup: Use SessionEnd for reports and cleanup

### Step 2: Select appropriate hook event

PreToolUse (before execution), PostToolUse (after completion), SessionStart (session begins), SessionEnd (session ends), Stop (Claude finishes), SubagentStart/Stop (subagent lifecycle)

### Step 3: Choose configuration location

Priority: --hooks CLI flag > .claude/settings.local.json > .claude/settings.json > ~/.claude/settings.json

**Decision Point:**
- Personal (git-ignored): .claude/settings.local.json
- Project-shared: .claude/settings.json
- Global: ~/.claude/settings.json
- Session-only: --hooks CLI flag

### Step 4: Configure hook with matcher and command

Write JSON: {hooks: {EventName: [{matcher: 'Tool1|Tool2', hooks: [{type: 'command', command: 'script.sh'}]}]}}

### Step 5: Handle exit codes appropriately

Exit 0: success, continue. Exit 2: block operation (PreToolUse only). Other: warning, continue.

**Decision Point:**
- Exit 0: operation completes normally
- Exit 2: operation blocked (use for validation failures)
- Other codes: warning logged, operation continues

### Step 6: Test hook with explicit tool invocation

Trigger the tool that should fire the hook. Verify hook executes and exit code handled correctly.

## Pos-condicoes

- [ ] Hook configured in appropriate settings.json
- [ ] Automation fires automatically on target events
- [ ] Exit codes handled correctly (block with 2, warn with others)
- [ ] Repetitive task no longer requires manual reminders

## Rollback

Remove or comment out hook configuration in settings.json. Restart Claude Code session.

## Essencia

Claude Code Hooks eliminate the manual reminder problem by automating repetitive tasks at specific lifecycle points. Instead of constantly telling Claude "format after editing" or "run tests before committing", hooks enforce these automatically.

The power comes from event-driven architecture: PreToolUse can block dangerous operations before execution (exit code 2), PostToolUse can auto-format/test after completion, and Session hooks can inject context or generate reports.

Hooks use JSON-RPC communication (input via stdin, output via stdout), support regex matchers for tool filtering, and respect 10-minute timeouts for safety.

## Exemplos

**Example 1: Auto-format TypeScript files after every edit**

**Execution:** Add PostToolUse hook with matcher 'Edit|Write', command: jq -r '.tool_input.file_path' | { read f; if echo "$f" | grep -q '\\.ts$'; then npx prettier --write "$f"; fi; }. Every time Claude edits .ts file, Prettier runs automatically.

**Result:** All TypeScript files formatted consistently without manual reminders. Developer experience improved.

**Example 2: Block dangerous bash commands before execution**

**Execution:** Add PreToolUse hook with matcher 'Bash', command: ./scripts/validate-command.sh (checks for rm -rf, dd, etc.). Script exits with 2 if dangerous. Claude blocked from executing dangerous commands.

**Result:** Prevented accidental 'rm -rf /' command. Hook blocked with clear error message.

**Example 3: Inject project context at every session start**

**Execution:** Add SessionStart hook with command: cat .claude/project-context.md. Hook runs when session begins, Claude receives project-specific knowledge automatically.

**Result:** No need to manually paste context. Claude starts every session with full project knowledge.

**Example 4: Run tests after code changes**

**Execution:** Add PostToolUse hook with matcher 'Edit|Write', command: npm test (or equivalent). After Claude edits code, tests run automatically. Exit code determines if changes acceptable.

**Result:** Immediate feedback on code changes. Bugs caught before moving to next task.

## Anti-Patterns

- Blocking too aggressively (frustrates workflow, kills productivity)
- Heavy operations in PreToolUse (adds latency to every tool call)
- Ignoring hook timeouts (10 minutes max, design for speed)
- Not testing hooks before deployment (broken hook blocks entire workflow)
- Circular dependencies between hooks (hook A triggers hook B triggers A)
- Writing to stdout in STDIO hooks (corrupts JSON-RPC communication)

## Variantes

- Formatter hook: PostToolUse on Edit|Write → prettier/black/rustfmt
- Validator hook: PreToolUse on Bash → check dangerous commands, exit 2 to block
- Test runner: PostToolUse on Edit|Write → npm test/pytest/cargo test
- Context injector: SessionStart → cat project-docs.md
- Logger/Auditor: PostToolUse on all tools → log to audit.jsonl

---
*Knowledge Skill | SKILL-WRK-hooks-automation-20260205-001 | Confidence: 0.9*
*Packaged by AURUM Cognitive Refinery | format-renderer | 2026-02-05*
