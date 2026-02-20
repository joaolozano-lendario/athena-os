# FORMIGA — Architecture Decision Records

**Project:** FORMIGA (FORge-execute-IMprove-Go-Again)
**Version:** v1.0.0-beta
**Last Updated:** 2026-02-16

---

## ADR-001: Evolution Over Rewrite

**Status:** IMPLEMENTED
**Date:** 2026-02-16

### Context

Orchestrator v0.1.0-alpha existed (25 files, 2267 lines) with working core:
- Blueprint execution: blueprint → tasks → workers
- Cost tracking, retry logic, basic QA
- 9/10 tests passing

Decision point: Rewrite from scratch vs. evolve existing architecture?

### Decision

**Evolve, don't rewrite.**

- Keep working core: `orchestrate.sh` (includes worker execution functions)
- Add new intelligence layers: `advisory.sh`, `meta_loop.sh`, `routing.sh`
- Enhance existing: `context.sh`, `qa.sh`, stigmergy via `colony_signals.jsonl`
- Result: 31 files, 5127 lines (127% growth, not 500%+ rewrite)

### Consequences

**Positive:**
- Preserved working patterns (file registry, DAG generation, atomic state)
- Faster implementation (W1-W3 vs. ground-up rebuild)
- Lower risk (core execution never broken)

**Negative:**
- Some debt inherited (shell script brittleness, error handling inconsistencies)
- Architectural constraints from v0.1.0 design

---

## ADR-002: Three-Layer Modularity

**Status:** IMPLEMENTED
**Date:** 2026-02-16

### Context

FORMIGA serves two audiences:
1. Generic users: Want bash-native DAG executor
2. ATHENA users: Want intelligence integration (pattern library, memory, learning)

Tension: Feature richness vs. standalone simplicity.

### Decision

**Three-layer architecture:**

**Layer 0 (Core):**
- `orchestrate.sh` (blueprint coordinator + task execution functions)
- Standalone, zero ATHENA dependencies
- Works with any YAML blueprint

**Layer 1 (Intelligence):**
- `advisory.sh` (advisory reviews between waves)
- `meta_loop.sh` (quorum sensing + meta-loop decisions)
- `routing.sh` (model selection + allometry)
- Generic AI capabilities (coherence analysis, adaptive retry)
- Enhances Layer 0, doesn't replace it

**Layer 2 (Knowledge):**
- `athena.sh` (learning integration + pattern library)
- ATHENA-native: reads/writes `D:/athena-os/observability/`
- Optional: Layer 0+1 work without it

### Consequences

**Positive:**
- Core remains portable (can fork without ATHENA)
- Intelligence is optional enhancement
- Clear separation of concerns

**Negative:**
- Coordination overhead (3 layers must stay aligned)
- Testing complexity (test each layer + integration)

---

## ADR-003: Advisory Between Waves

**Status:** IMPLEMENTED
**Date:** 2026-02-16

### Context

Blueprints span 5-50 tasks across multiple waves. Drift accumulates:
- Workers deviate from original intent
- Early decisions cascade into later failures
- No correction until final QA (too late)

Cost: ~$0.15 per advisory review (sonnet, 2K context).

### Decision

**Spawn advisory agent between execution waves.**

`advisory.sh` analyzes:
- Completed wave outputs vs. original intent
- Cross-wave coherence
- Pattern violations

Returns:
- `coherence_score` (0-10)
- `continue` / `pause` / `adjust_params`
- Concrete recommendations

`orchestrate.sh` integration:
- Coherence < 5 → pause blueprint, escalate
- Coherence 5-7 → adjust worker params (context, model)
- Coherence 8+ → continue execution

### Consequences

**Positive:**
- Early drift detection (wave 2/5 vs. final QA at wave 5/5)
- Cost-effective ($0.15 vs. $2-5 to re-execute failed wave)
- Adaptive course correction

**Negative:**
- Adds 30-60s latency per wave
- Advisory itself can be wrong (false positive pause)

---

## ADR-004: File Registry Pre-Execution

**Status:** IMPLEMENTED
**Date:** 2026-02-16

### Context

Parallel task execution risks file conflicts:
- Task A edits `config.yaml` lines 1-10
- Task B edits `config.yaml` lines 50-60
- Both spawn simultaneously → merge conflict

Alpha v0.1.0 had naive parallelization: "if no task deps → parallel."

### Decision

**Build file registry before blueprint execution.**

`file_registry.sh` scans all tasks:
- Extract `files_modified` from task YAML
- Build registry: `{ "path/to/file": ["T001", "T005", "T012"] }`

`generate_execution_waves()` modified:
- Tasks modifying same file → forced into sequential waves
- Tasks with no file conflicts → eligible for parallelization
- DAG dependencies still respected

### Consequences

**Positive:**
- Zero merge conflicts during execution
- Safe aggressive parallelization (8-12 tasks/wave vs. 2-3)

**Negative:**
- Conservative: False positives (tasks editing different sections)
- Registry build overhead (~2-5s for 50-task blueprint)

---

## ADR-005: Meta-Loop Max 2 Auto Cycles

**Status:** IMPLEMENTED
**Date:** 2026-02-16

### Context

Post-execution, system must decide next action:
- All passed → DONE
- 2 tasks failed → Retry? Re-forge? Escalate?

Quorum sensing (in `meta_loop.sh`) analyzes signals, decides action.

Risk: Infinite loop if system keeps choosing RE_EXECUTE without progress.

### Decision

**Meta-loop max 2 automatic cycles.**

`meta_loop.sh` tracks `meta_loop_count` in `state.json`:
- Cycle 1: Quorum decides → auto-execute
- Cycle 2: Quorum decides → auto-execute
- Cycle 3+: Escalate to human (write `escalation_report.md`)

Actions:
- `DONE`: Exit loop
- `TARGETED_RETRY`: Retry failed tasks only
- `RE_EXECUTE`: Re-run entire blueprint
- `RE_FORGE`: Return to blueprint phase (ATHENA-native)
- `ESCALATE`: Immediate human intervention

### Consequences

**Positive:**
- Prevents runaway costs (max 2 auto retries)
- Forces human decision on persistent failure

**Negative:**
- Conservative: Some blueprints might succeed on cycle 3
- Escalation friction (human must re-engage)

---

## ADR-006: Context Pack Layers

**Status:** IMPLEMENTED
**Date:** 2026-02-16

### Context

Worker context is finite (~30K tokens budget). Must balance:
- Universal guidance (task format, tools available)
- Constraints (budget, patterns, anti-patterns)
- Domain knowledge (COPY vs. CODE vs. ARCH)
- Project specifics (codebase structure)
- Colony signals (peer task outcomes)
- QA rubric (quality criteria)
- Historical feedback (prior failures)

Order matters: Most critical → Least critical.

### Decision

**7-layer context pack architecture** (`context.sh`):

1. **Universal** (~1000 tokens): Task format, tool usage, completion signal
2. **Constraints** (~800 tokens): Budget, time limits, prohibited actions
3. **Domain** (~1500 tokens): Nature-specific knowledge (from Genius Layer)
4. **Project** (~2500 tokens): Codebase intelligence, integration points
5. **Colony Signals** (~1200 tokens): Peer task outcomes, warnings
6. **QA Rubric** (~600 tokens): Acceptance criteria, quality gates
7. **Feedback** (~400 tokens): Historical failures, corrections

Token budget per layer scales via allometry:
```bash
tokens = base_tokens × (8 / wave_size)^0.75
```

Power law: Larger waves → more aggressive compression.

### Consequences

**Positive:**
- Structured prioritization (critical info first)
- Dynamic scaling (adapt to wave size)
- Modular: Easy to add/remove layers

**Negative:**
- Complexity: 7 layers to maintain
- Compression loss: Larger waves get truncated context

---

## ADR-007: Adversarial QA

**Status:** IMPLEMENTED
**Date:** 2026-02-16

### Context

Alpha v0.1.0 QA was cooperative:
- Worker produces output
- QA reviews against acceptance criteria
- Bias: QA assumes worker tried to succeed

Real-world: Workers hallucinate, skip steps, misinterpret specs.

### Decision

**Adversarial QA architecture.**

`qa.sh` spawns independent reviewer:
- Reads task spec + worker output
- Does NOT read worker's internal reasoning
- Structured output via `--json-schema`:
  - `verdict`: PASS / REWORK / REJECT
  - `score`: 0-100
  - `feedback`: detailed review
  - `criteria_scores`: per-criterion breakdown
  - `colony_signal`: structured signal for peer tasks

QA workers emit **colony signals** to `colony_signals.jsonl`:
```json
{
  "type": "qa_warning",
  "task_id": "T005",
  "message": "Missing error handling",
  "severity": 2
}
```

Signals appended to `colony_signals.jsonl` → future workers read in context pack.

### Consequences

**Positive:**
- Independent verification (no worker bias)
- Colony learning (warnings propagate to peers)
- Structured output (parseable by meta-loop)

**Negative:**
- Cost: +$0.008 per task (haiku QA)
- False negatives: QA might miss subtle issues

---

## ADR-008: Model Upgrade on Retry

**Status:** IMPLEMENTED
**Date:** 2026-02-16

### Context

Tasks fail for two reasons:
1. Spec ambiguity / high complexity → needs smarter model
2. Worker carelessness → retry same model works

Cost difference:
- haiku: $0.012/task
- sonnet: $0.040/task

Challenge: Don't waste money upgrading when retry would work, but don't burn retries when complexity is real.

### Decision

**Adaptive model selection in `routing.sh`:**

```bash
select_model() {
  retry_count=$1
  budget_remaining_pct=$2
  complexity=$3  # from task.yaml

  if [[ $budget_remaining_pct -lt 30 ]]; then
    echo "haiku"  # Force cost savings
  elif [[ $retry_count -eq 0 ]]; then
    [[ $complexity == "high" ]] && echo "sonnet" || echo "haiku"
  else
    echo "sonnet"  # Retry 2+ always upgrades
  fi
}
```

Logic:
- First attempt: haiku unless `complexity: high`
- Retry 2+: Upgrade to sonnet
- Budget < 30%: Force haiku (emergency cost control)

### Consequences

**Positive:**
- Cost-efficient: Don't over-provision on first attempt
- Smart escalation: Retries get more capable model

**Negative:**
- Sometimes wastes retry: Complex task fails on haiku, would've passed on sonnet first try
- Budget override can cause failure: Force haiku when sonnet needed

---

## ADR-009: Bash-Native, Zero Dependencies

**Status:** IMPLEMENTED
**Date:** 2026-02-16

### Context

Surveyed 12 orchestration frameworks:
- Airflow, Prefect, Temporal: Python, heavy runtime
- n8n, Windmill: Node.js, GUI-first
- Argo, Tekton: Kubernetes-native

FORMIGA requirements:
- Works in Claude Code environment (bash shell)
- No installation beyond `claude` CLI
- Human-editable config (YAML, not JSON/code)

### Decision

**Bash-native implementation, zero external dependencies.**

Required tools (already in Claude Code):
- `bash` 4.0+
- `jq` (JSON processing)
- `yq` (YAML processing)
- `claude` CLI (Anthropic official)

All logic in bash scripts:
- `orchestrate.sh`: Blueprint coordinator (includes task execution functions)
- `advisory.sh`, `meta_loop.sh`, `routing.sh`, etc.: Intelligence layers

State persistence:
- JSON (`state.json`, `events.jsonl`, `colony_signals.jsonl`)
- YAML (blueprints, blueprint configs)

### Consequences

**Positive:**
- Zero installation friction
- Human-readable, editable state files
- Portable (works anywhere bash + claude CLI exist)

**Negative:**
- Shell script limitations (error handling, async coordination)
- Performance: bash slower than compiled languages
- Maintainability: Large bash codebases get brittle

---

## ADR-010: Stigmergy (Filesystem Coordination)

**Status:** IMPLEMENTED
**Date:** 2026-02-16

### Context

Parallel workers across multiple `claude` CLI invocations need coordination:
- Shared state (blueprint status, completed tasks)
- Event log (audit trail)
- Colony signals (peer-to-peer warnings)

Options:
1. Database (SQLite): Requires installation
2. Redis/memcached: Requires server
3. Filesystem: Built-in, atomic writes

Biology inspiration: Ant stigmergy (coordinate via environment, not direct communication).

### Decision

**Filesystem-based stigmergy.**

Three coordination files:

1. **`state.json`**: Blueprint state (atomic writes)
   ```json
   {
     "blueprint_id": "C-20260216-143022",
     "status": "executing_wave_2",
     "completed_tasks": ["T001", "T002"],
     "budget_spent_usd": 0.15
   }
   ```

2. **`events.jsonl`**: Event log (append-only)
   ```json
   {"timestamp":"2026-02-16T14:30:45Z","type":"task_completed","task_id":"T001"}
   {"timestamp":"2026-02-16T14:31:12Z","type":"task_failed","task_id":"T003"}
   ```

3. **`colony_signals.jsonl`**: Colony intelligence (append-only)
   ```json
   {"type":"warning","task_id":"T005","message":"Config validation failed"}
   {"type":"success_pattern","task_id":"T007","pattern":"Use explicit types"}
   ```

Locking:
```bash
acquire_lock() {
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    sleep 0.1
  done
}
```

### Consequences

**Positive:**
- Zero external dependencies
- Atomic operations (`mkdir` is atomic in POSIX)
- Human-readable (can inspect state with `cat`)

**Negative:**
- Filesystem latency (slower than in-memory)
- Lock contention risk (many parallel workers)
- No transactions (multi-file updates not atomic)

---

## Summary

| ADR | Decision | Status | Cost Impact |
|-----|----------|--------|-------------|
| 001 | Evolution over rewrite | IMPLEMENTED | -70% dev time |
| 002 | Three-layer modularity | IMPLEMENTED | +20% complexity |
| 003 | Advisory between waves | IMPLEMENTED | +$0.15/blueprint |
| 004 | File registry pre-exec | IMPLEMENTED | +2-5s overhead |
| 005 | Meta-loop max 2 cycles | IMPLEMENTED | Prevents runaway |
| 006 | Context pack layers | IMPLEMENTED | Optimizes token usage |
| 007 | Adversarial QA | IMPLEMENTED | +$0.008/task |
| 008 | Model upgrade on retry | IMPLEMENTED | Smart cost scaling |
| 009 | Bash-native zero deps | IMPLEMENTED | Zero install friction |
| 010 | Stigmergy coordination | IMPLEMENTED | No external services |

---

**Total Architecture:** 10 ADRs, 5127 lines across 31 files, $0.02-0.05 per task depending on model selection and retry count.

---

*FORMIGA v1.0.0-beta — Architecture Decision Records*
*"Decisions are the DNA of systems."*
