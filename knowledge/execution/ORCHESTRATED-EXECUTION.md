# Orchestrated Execution

Multi-terminal execution for high-volume, context-isolated work via campaign manifests and orchestrate.sh.

---

## What It Is

Orchestrated Execution is ATHENA's capability to distribute work across parallel Claude instances via filesystem coordination.

Each worker is an independent `claude -p` instance with:
- **Isolated 200K context window** (no pollution from other tasks)
- **Specific tools** (Read, Write, Edit, Grep, Glob per worker type)
- **Target project access** (via `--add-dir`)
- **Structured QA review** by a separate instance (no self-assessment bias)

---

## When to Use

| Factor | In-Session | Orchestrated |
|--------|-----------|-------------|
| Task Count | <10 | 10+ parallelizable |
| Context Isolation | Shared preferred | Each task needs clean context |
| QA | Manual review | Automated QA gates |
| Autonomy | Operator supervises | Set-and-forget |
| Parallelism | Serial only | 2-4 workers |
| Budget | <$2 | $5-20 campaigns |

---

## Architecture (Four-Unit Model)

| Unit | Component | Role |
|------|-----------|------|
| Planning & Policy | Manifest YAML + validate_manifest() | Goals, constraints, DAG |
| Execution & Control | run_campaign() + parallel.sh + deps.sh | Dispatch, concurrency |
| State & Knowledge | state.sh + events.jsonl + cost.jsonl | Checkpoints, budget |
| Quality & Operations | qa.sh + QA workers + generate_report() | Scoring, rework, learning |

Feedback cycle: Quality → Planning (rework feedback enriches next attempt).

---

## How It Works

```
Campaign Manifest (YAML)
    │
orchestrate.sh
    ├─ validate_manifest() → Check fields, files, DAG, budget
    ├─ init_campaign()     → Create runtime dir, state.json, events.jsonl
    └─ run_campaign()      → Main loop:
        │
        ├─ get_ready_tasks()  → Pending tasks with all deps completed
        ├─ budget_check()     → Pre-spawn budget verification
        ├─ execute_task()     → Ralph Loop per task:
        │   ├─ assemble_context_pack() → 60K token max
        │   ├─ spawn worker (claude -p via stdin)
        │   ├─ verify output (stop gate)
        │   ├─ run_qa() (separate claude -p + --json-schema)
        │   ├─ parse_verdict() + route_verdict()
        │   └─ PASS → done | REWORK → retry | REJECT → cascade_failure
        ├─ reap_finished()    → Collect exit codes
        └─ print_progress()   → Real-time status
```

---

## Context Pack Structure

Every worker receives a context pack via stdin (not CLI args — avoids ARG_MAX):

```
[30%] GOAL       — Task description + acceptance criteria
[25%] CONSTRAINTS — _base.md + worker type prompt
[30%] REFERENCE  — context_files concatenated (truncated if >60K)
[10%] RUBRIC     — QA criteria (worker sees HOW it's judged)
[ 5%] FEEDBACK   — Only LATEST QA feedback (if retry)
```

Worker identity goes via `--append-system-prompt` (~2K chars).

---

## Worker Types

| Worker | Nature | Tools | Role |
|--------|--------|-------|------|
| analyst | DATA/META | Read,Grep,Glob | Pattern recognition, metrics |
| architect | ARCH/META | Read,Grep,Glob | Design, trade-offs |
| writer | COPY/DOCS | Read,Write,Grep,Glob | Content, summaries |
| implementer | CODE | Read,Write,Edit,Grep,Glob | File creation, code |
| qa | ALL | Read,Grep,Glob | Quality review (READ-ONLY) |

Extensible: add `workers/{name}.md` for custom roles.

---

## Task State Machine

```
pending → running → completed (QA PASS)
             │
             ├→ rework → running (retry) → completed | exhausted
             ├→ rejected (score < 60)
             ├→ dep-failed (dependency failed/rejected/exhausted)
             ├→ aborted (budget/timeout/cancel)
             └→ paused (--interactive + critical failure)
```

---

## Observability

| Artifact | Format | Purpose |
|----------|--------|---------|
| state.json | JSON | Campaign state, task statuses, budget |
| events.jsonl | JSONL | Append-only event trace (debugging) |
| cost.jsonl | JSONL | Per-task cost records |
| progress.txt | Text | Human-readable status |
| campaign-report.yaml | YAML | Post-campaign summary (P6 feed) |
| attempts/{task}-attempt-{N}/ | Directory | Full audit trail per attempt |

---

## Integration with ATHENA Pipeline

### P4: CRYSTALLIZE
P4 can output campaign manifests when task count >10, parallelism matters, QA is automatable.

### P5: EXECUTE
For orchestrated campaigns: ATHENA designs manifest (P1-P4), then runs `orchestrate.sh`.

### P6: LEARN
`campaign-report.yaml` follows `execution_log.yaml` schema. P6 appends it to the log.

---

## Patterns

- **PAT-012: Context Pack Assembly** — 6 building blocks, 60K ceiling, truncation safety
- **PAT-013: External QA Loop** — Separate reviewer + --json-schema + calibration anchors
- **PAT-014: Filesystem Coordination** — state.json + mkdir locks + PID-unique temps + atomic mv

---

## Anti-Patterns

- **Using orchestrated for <5 tasks** — overhead not justified
- **Hardcoding QA to haiku for nuanced criteria** — override to sonnet
- **Skipping --dry-run** — always validate first
- **Self-assessment** — worker reviews own output (ANTI-009)
