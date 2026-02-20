# FORMIGA — Technical Architecture

**Orchestration Engine for ATHENA OS**
**Version:** 1.0.0
**Nature:** Biomimetic, multi-agent, bash-native
**Status:** IMPLEMENTED

---

## Overview

FORMIGA is a bash-orchestrated execution engine that spawns independent `claude -p` workers with isolated contexts, manages them via file-based state, and uses six biomimetic patterns to achieve emergent colony intelligence.

**Core Insight:** The main orchestrator (Opus) acts as **consciousness** — strategic awareness, meta-loop decisions, pattern learning. Workers (Haiku/Sonnet) act as **unconscious processing** — focused execution without blueprint awareness. Colony signals act as **pheromones** — peer-to-peer communication without centralized coordination.

---

## Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FORMIGA v1.0                                │
│                    (1100-line orchestrator)                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  LAYER 2: KNOWLEDGE (ATHENA-native)                                │
│  ├─ lib/athena.sh (243 lines)                                      │
│  │   ├─ load_genius_kit() — nature-specific domain expertise       │
│  │   ├─ get_relevant_patterns() — pattern library integration      │
│  │   ├─ prune_patterns() — synaptic pruning with lifecycle         │
│  │   └─ promote_to_blacklist() — immune promotion                  │
│  │                                                                  │
│  LAYER 1: INTELLIGENCE (orchestration logic)                       │
│  ├─ lib/file_registry.sh (184 lines)                               │
│  │   ├─ build_file_registry() — parse files_read/write per task    │
│  │   ├─ detect_file_conflicts() — detect write_write / RAW         │
│  │   └─ generate_execution_waves() — merge DAG + file conflicts    │
│  ├─ lib/routing.sh (274 lines) — Allometry + Negative Pheromone    │
│  │   ├─ apply_allometry() — scale-dependent colony parameters      │
│  │   ├─ select_model() — budget-aware model routing                │
│  │   └─ apply_negative_pheromone() — blacklist-based repulsion     │
│  ├─ lib/advisory.sh (166 lines)                                    │
│  │   ├─ run_advisory() — spawn advisor worker between waves        │
│  │   └─ apply_advisory() — coherence-based adjustments             │
│  ├─ lib/meta_loop.sh (286 lines) — Quorum Sensing                  │
│  │   ├─ compute_quorum_signal() — multi-source composite decision  │
│  │   ├─ quorum_decide() — DONE|RETRY|RE_EXECUTE|ESCALATE           │
│  │   └─ detect_demand_signals() — trophallaxis aggregation         │
│  │                                                                  │
│  LAYER 0: CORE (execution primitives)                              │
│  ├─ orchestrate.sh (1100 lines) — main blueprint runner             │
│  │   ├─ parse_manifest() → validate_manifest()                     │
│  │   ├─ build_file_registry() → generate_execution_waves()         │
│  │   └─ run_blueprint() → execute_wave() → execute_task()           │
│  ├─ lib/utils.sh — logging, timestamps, portable helpers           │
│  ├─ lib/lock.sh — file-based task locking                          │
│  ├─ lib/parallel.sh — semaphore-based concurrency (--jobs)         │
│  ├─ lib/state.sh — jq-based state.json manipulation                │
│  ├─ lib/deps.sh — dependency resolution + cascade failure          │
│  ├─ lib/cost.sh — budget tracking + cost extraction                │
│  ├─ lib/context.sh (308 lines) — layered context assembly          │
│  │   ├─ assemble_context_pack() — 5-layer composition              │
│  │   └─ _allometry_token_budget() — power-law scaling              │
│  └─ lib/qa.sh (395 lines) — Immune System + Trophallaxis           │
│      ├─ pre_spawn_barriers() — mechanical rejection                │
│      ├─ innate_immune_check() — format + size validation           │
│      ├─ run_qa() → parse_verdict() → route_verdict()               │
│      └─ extract_colony_signal() — QA → colony signaling            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### Blueprint Lifecycle

```
1. INITIALIZATION
   orchestrate.sh --manifest blueprint.yaml
   └─► parse_manifest() — YAML → state.json
   └─► validate_manifest() — check schema
   └─► apply_allometry() — set colony parameters (parallel, advisory, budget)
   └─► build_file_registry() — parse files_read/write per task
   └─► generate_execution_waves() — merge DAG + file conflicts

2. EXECUTION (per wave)
   run_blueprint() loops over waves:
     └─► execute_wave($wave_num)
         ├─ parallel_execute(tasks_in_wave)
         │   └─► execute_task($task_id) × MAX_PARALLEL
         │       ├─ pre_spawn_barriers() — budget, worker DNA, output dir
         │       ├─ assemble_context_pack() — 5-layer composition
         │       ├─ spawn_worker() — claude -p with isolated context
         │       ├─ innate_immune_check() — format, size, immune memory
         │       ├─ check_blacklist_violations() — negative pheromone match
         │       ├─ run_qa() → extract_colony_signal() → parse_verdict()
         │       └─ route_verdict() — PASS/REWORK/REJECT → update state
         │
         └─► run_advisory($wave_num) — coherence review, adjustments
         └─► detect_demand_signals() — aggregate colony warnings

3. META-LOOP (if QUORUM_ENABLED)
   run_meta_loop($max_cycles=2)
   └─► after each blueprint execution:
       ├─ compute_quorum_signal() — 4 sources (QA, advisory, colony, structural)
       ├─ quorum_decide() — sigmoid-based decision
       └─► DONE | TARGETED_RETRY | RE_EXECUTE | RE_FORGE | ESCALATE

4. FINALIZATION
   generate_execution_report()
   ├─► decay_patterns() — synaptic pruning decay (×0.9)
   ├─► prune_patterns() — remove weak patterns (threshold 0.3|1.0)
   ├─► promote_immune_responses() — repeated violations → immune memory
   └─► promote_to_blacklist() — anti-patterns → global blacklist
```

---

## Worker Architecture

### Worker Types

| Worker | Model Default | Purpose | Output Format | Schema |
|--------|---------------|---------|---------------|--------|
| **implementer** | sonnet | Code implementation | .sh, .js, .ts, .py | — |
| **writer** | haiku | Documentation, markdown | .md | — |
| **analyst** | haiku | Data analysis, reports | .md, .json | — |
| **architect** | sonnet | Design artifacts | .md, .yaml | — |
| **qa** | haiku | Quality review | .json | qa-verdict.json |
| **advisor** | sonnet | Strategic coherence | .json | advisory-review.json |
| **forger** | opus | Re-generate blueprint YAML | .yaml | — |

### Worker Execution Pattern

```bash
# Each worker spawned with fresh context, no session persistence
echo "$context_pack" | \
  env -u CLAUDECODE claude -p \
    --append-system-prompt "$worker_dna" \
    --model "$selected_model" \
    --max-budget-usd "$task_budget" \
    --tools "$allowed_tools" \
    --setting-sources "" \  # CRITICAL: 87% cache reduction
    --output-format json \
    --json-schema "$schema" \  # If structured output needed
    --no-session-persistence \
    --dangerously-skip-permissions \
    2>"$log_file" > "$response_file"
```

**Worker Isolation:** Each worker has ZERO knowledge of the blueprint. Context pack contains everything needed for the task. Workers write to specified output path, never to state.json. Orchestrator parses response, updates state, routes to next task.

---

## Biomimetic Patterns

### 1. Negative Pheromone (Pattern 1)

**Source:** `lib/routing.sh::apply_negative_pheromone()`

**Mechanism:** Blacklist-based active repulsion. Two severity classes:
- **Hard constraints (severity 4-5):** Mechanical blocking. Output matched against regex patterns. Violation → auto-reject (no QA).
- **Soft constraints (severity 1-3):** Cognitive warnings. Injected into context pack Layer 1.5.

**TTL decay:** Each entry has `ttl_days` (default 90). Expired entries ignored.

**Files:**
- `global_blacklist.jsonl` — system-wide (e.g., anti-patterns promoted from pattern library)
- `runtime/{blueprint-id}/blacklist.jsonl` — blueprint-specific

**Integration:**
- `check_blacklist_violations()` called post-worker, pre-QA
- `_layer_constraints()` in `context.sh` injects soft constraints

---

### 2. Trophallaxis (Pattern 2)

**Source:** `lib/qa.sh::extract_colony_signal()` + `lib/context.sh::_layer_colony_signals()`

**Mechanism:** Peer-to-peer information exchange without central coordination. QA worker observes output, emits optional `colony_signal` (type, signal, intensity). Signals aggregated in `colony_signals.jsonl`. Top N (intensity ≥ 0.4) injected into future workers' context packs.

**Data Flow:**
```
Worker output
  ↓
QA worker reviews
  ↓
QA emits colony_signal: {type: "warning", signal: "File paths inconsistent", intensity: 0.7}
  ↓
Appended to colony_signals.jsonl
  ↓
Future workers receive signal in Layer 5 of context pack
```

**Demand Detection:** `meta_loop.sh::detect_demand_signals()` groups repeated warnings (≥3 occurrences) → demand signals → influence quorum decision.

---

### 3. Quorum Sensing (Pattern 3)

**Source:** `lib/meta_loop.sh::compute_quorum_signal()`

**Mechanism:** Multi-source composite signal with sigmoid sharpening. Four sources weighted:
1. **QA scores** (weight 0.40) — average task QA scores
2. **Advisory coherence** (weight 0.25) — advisor coherence_score / 10
3. **Colony sentiment** (weight 0.15) — 1 - (warnings / total_signals)
4. **Structural health** (weight 0.20) — (completed - failed*0.5) / total

**Sigmoid sharpening:** `1 / (1 + e^(-12*(x-0.75)))` — makes threshold sharp, not gradual.

**Decision table:**

| Sigmoid | Disagreement | Budget | Cycle | Verdict |
|---------|--------------|--------|-------|---------|
| ≥ 0.90 | — | — | — | DONE |
| 0.70-0.89 | — | — | — | TARGETED_RETRY |
| 0.40-0.69 | — | — | — | RE_EXECUTE |
| < 0.40 | — | — | — | RE_FORGE |
| — | > 0.40 | — | — | ESCALATE |
| — | — | < 20% | — | ESCALATE |
| — | — | — | ≥ max | ESCALATE |

**Max cycles:** 2 (prevents infinite meta-loop).

---

### 4. Allometry (Pattern 4)

**Source:** `lib/routing.sh::apply_allometry()`

**Mechanism:** Scale-dependent colony parameters. Three size classes:

| Size Class | Task Count | Parallel | Retries | Advisory | Quorum | Signal Injection | Token Budget |
|------------|-----------|----------|---------|----------|--------|------------------|--------------|
| **small** | ≤ 8 | 2 | 2 | false | false | 2 | `60000 × (8/n)^0.75` |
| **medium** | 9-25 | 3 | 3 | true | false | 4 | `60000 × (8/n)^0.75` |
| **large** | > 25 | 4 | 3 | true | true | 6 | `60000 × (8/n)^0.75` |

**Power-law token budget:** Biological reality: small organisms have more energy per unit mass. Small colonies get proportionally more context budget per task.

**Between-wave adaptation:**
- Failure rate > 30% → reduce `MAX_PARALLEL`
- Retry rate > 50% → upgrade `DEFAULT_MODEL` (haiku → sonnet)

---

### 5. Synaptic Pruning (Pattern 5)

**Source:** `lib/athena.sh::decay_patterns()`, `::prune_patterns()`

**Mechanism:** Pattern lifecycle with decay + pruning. Inspired by neural synaptic pruning (childhood = gentle, adulthood = aggressive).

**Operations:**
1. **Reinforce:** Task uses pattern + passes QA → `strength += 1.0` (cap 10.0)
2. **Decay:** Every blueprint end → all patterns `strength *= 0.9`
3. **Prune:** Two-phase threshold
   - Blueprints ≤ 10: threshold 0.3 (gentle, preserve exploration)
   - Blueprints > 10: threshold 1.0 (aggressive, remove weak patterns)

**Outcome:** Patterns that aren't reinforced decay to zero over ~10-20 blueprints. Strong patterns (used + successful) persist.

---

### 6. Immune System (Pattern 6)

**Source:** `lib/qa.sh::pre_spawn_barriers()`, `::innate_immune_check()`

**Mechanism:** Three-layer adaptive defense (biological: barriers → innate → adaptive).

**Layer 1: Pre-spawn barriers (mechanical)**
- Budget check
- Worker DNA file exists
- Output directory writable
- **Cost:** Zero tokens spent if barrier fails

**Layer 2: Innate immune check (format validation)**
- File exists, non-empty
- Size sanity (10B - 500KB)
- Format validation (JSON/YAML/shell/markdown)
- Line count sanity (30%-300% of expected)
- **Immune memory matching:** Check against `immune_memory.jsonl` (promoted patterns)

**Layer 3: Adaptive QA (context-aware review)**
- Full QA worker review
- Criterion-based scoring
- **Colony signal emission** (feedback to Layer 2 via trophallaxis)

**Immune Promotion:**
- `promote_immune_responses()`: Repeated violations (≥3 occurrences) → `immune_memory.jsonl` with `response: "flag"` (conservative, not `auto_reject`)
- `promote_to_blacklist()`: Anti-patterns from pruned pattern library → `global_blacklist.jsonl`

---

## Context Pack Assembly

**Source:** `lib/context.sh::assemble_context_pack()`

**Layered Composition:**

```
Layer 1: UNIVERSAL (task definition, criteria, output path)
  - Task description
  - Acceptance criteria
  - Output file path

Layer 1.5: CONSTRAINTS (negative pheromone soft constraints)
  - Blacklist patterns (severity 1-3)
  - "AVOID: {pattern}" warnings

Layer 2: DOMAIN (genius kit, AURUM exports)
  - load_genius_kit(nature_code) — nature-specific expertise
  - get_relevant_patterns(nature_code) — pattern library (top 5 by strength)

Layer 3: DEPENDENCY (outputs from completed deps)
  - Included via context_files array
  - Prior task outputs, source files

Layer 4: PROJECT (reference material)
  - context_files from manifest
  - Wrapped as "--- filename ---" blocks

Layer 5: COLONY SIGNALS (trophallaxis)
  - Top N signals (intensity ≥ 0.4)
  - "Colony signals from peer workers"

Layer 6: QA RUBRIC
  - QA criteria from manifest
  - Minimum passing score

Layer 7: FEEDBACK (rework attempts)
  - Last QA feedback if status=rework
```

**Token Budget Enforcement:**
- `estimate_tokens()` — rough estimate (chars / 4)
- If pack > `CONTEXT_TOKEN_BUDGET`, truncate Layer 4 (reference material)
- Truncation: distribute remaining budget equally across files, head -c

---

## File-Based Orchestration

**State File:** `runtime/{blueprint-id}/state.json`

**Structure:**
```json
{
  "blueprint": {
    "id": "blueprint-{timestamp}",
    "status": "running|paused|completed",
    "nature_code": "ARCH|META|CODE|...",
    "started_at": "2026-02-16T10:00:00Z"
  },
  "tasks": {
    "task-id-1": {
      "status": "pending|running|completed|rework|rejected|exhausted",
      "attempts": 2,
      "score": 85,
      "started_at": "...",
      "completed_at": "...",
      "last_feedback": "...",
      "depends_on": ["task-id-0"]
    }
  },
  "counters": {
    "total": 10,
    "completed": 7,
    "failed": 1
  },
  "budget": {
    "limit_usd": 50.0,
    "used_usd": 12.34
  }
}
```

**Atomic Updates:** All state writes via `state_write()` — jq filter applied to temp file → atomic move.

**Concurrency Safety:** File-based locking via `lib/lock.sh` — `task-{id}.lock` files with 30s timeout.

---

## Advisory + Meta-Loop

### Advisory (Between Waves)

**Trigger:** `ADVISORY_ENABLED=true` (medium/large colonies)

**Process:**
1. After wave completion, `run_advisory($wave_num)`
2. Assemble context: blueprint progress, recent QA feedback, demand signals
3. Spawn **advisor worker** with `advisory-review.json` schema
4. Parse `coherence_score` (0-10), `quality_trend` (improving|stable|degrading)
5. `apply_advisory()`:
   - Coherence < 5 → PAUSE blueprint for operator
   - Coherence < 7 → apply adjustments (upgrade model, increase QA threshold)

### Meta-Loop (Post-Execution)

**Trigger:** `QUORUM_ENABLED=true` (large colonies)

**Process:**
1. Blueprint executes normally
2. `compute_quorum_signal()` — 4 sources → composite → sigmoid
3. `quorum_decide()` → DONE | TARGETED_RETRY | RE_EXECUTE | RE_FORGE | ESCALATE
4. If not DONE, execute decision, increment cycle
5. Max 2 cycles → ESCALATE

---

## Cost Model

| Model | Task (avg) | QA | Advisory | Total (per task) |
|-------|-----------|-----|----------|------------------|
| **haiku** | $0.012 | $0.008 | — | $0.020 |
| **sonnet** | $0.040 | $0.008 | — | $0.048 |
| **opus** | $0.150 | $0.008 | — | $0.158 |

**Budget tracking:** `lib/cost.sh::record_cost()` extracts cost from `claude` response metadata, appends to `costs.jsonl`, updates `state.json::budget.used_usd`.

---

## Key Design Decisions

### ADR-001: Evolution > Rewrite
FORMIGA evolved from Orchestrator v0.1.0-alpha. Biomimetic patterns permeated existing architecture, not separate epics.

### ADR-002: Advisory Between Waves
Advisory runs between waves (not post-execution) for real-time course correction.

### ADR-003: File Registry Pre-Execution
File conflicts detected during planning (pre-execution), not reactively. Prevents race conditions.

### ADR-004: Meta-Loop Max 2 Cycles
Prevents infinite refinement. 2 cycles = initial + 1 retry + 1 targeted fix. After that, escalate.

### ADR-005: Adversarial QA
QA worker DNA explicitly adversarial ("you did NOT produce this work"). Prevents lenient self-review.

### ADR-006: Stigmergy (Not Direct Communication)
Workers never communicate directly. All coordination via state.json + colony_signals.jsonl (stigmergy).

### ADR-007: --setting-sources ""
Critical optimization. Reduces cache from 87K → 11K tokens (85% savings). Workers don't need project settings.

### ADR-008: Structured Output in .structured_output
`--json-schema` puts data in `.structured_output`, NOT `.result`. Legacy field `.result` is free-form text.

---

## Integration with ATHENA OS

**ATHENA-native Layer (Layer 2):**
- `lib/athena.sh` is **optional**. If file doesn't exist, FORMIGA runs without ATHENA knowledge.
- `ATHENA_ROOT=${ATHENA_ROOT:-D:/athena-os}` — configurable
- Genius kits loaded via `load_genius_kit(nature_code)` → injected into context Layer 2
- Pattern library read via `get_relevant_patterns(nature_code)` → top 5 by strength
- Pattern lifecycle: reinforce → decay → prune → promote to blacklist

**P6 Learning Integration:**
- ATHENA P6 protocol calls `orchestrate.sh` → post-execution:
  - `decay_patterns()` — synaptic pruning
  - `prune_patterns(blueprint_count)` — threshold-based removal
  - `promote_immune_responses()` — repeated violations → immune memory
  - Pattern feedback appended to `pattern_library.yaml`

---

## File Reference

```
.orchestrator/
├── orchestrate.sh (1100 lines) — main entry point
├── lib/
│   ├── utils.sh — logging, timestamps, helpers
│   ├── lock.sh — file-based locking
│   ├── parallel.sh — semaphore-based concurrency
│   ├── state.sh — jq-based state manipulation
│   ├── deps.sh — dependency resolution
│   ├── cost.sh — budget tracking
│   ├── context.sh (308 lines) — layered context assembly
│   ├── qa.sh (395 lines) — immune system + QA + trophallaxis
│   ├── file_registry.sh (184 lines) — file conflict detection
│   ├── routing.sh (274 lines) — allometry + model selection + neg pheromone
│   ├── advisory.sh (166 lines) — strategic coherence review
│   ├── meta_loop.sh (286 lines) — quorum sensing + meta-loop
│   └── athena.sh (243 lines) — genius + AURUM + pattern lifecycle
├── workers/
│   ├── _base.md — universal worker DNA
│   ├── implementer.md, writer.md, analyst.md, architect.md
│   ├── qa.md — adversarial QA reviewer
│   ├── advisor.md — strategic coherence advisor
│   └── forger.md — blueprint YAML re-generator
├── schemas/
│   ├── qa-verdict.json — QA structured output
│   └── advisory-review.json — advisor structured output
└── blueprints/
    └── _template.yaml — blueprint YAML template
```

---

## Performance Characteristics

**Small blueprints (≤8 tasks):**
- Parallelism: 2
- Advisory: disabled
- Quorum: disabled
- Cost: ~$0.20-0.50 (haiku)

**Medium blueprints (9-25 tasks):**
- Parallelism: 3
- Advisory: enabled (every wave)
- Quorum: disabled
- Cost: ~$1.00-3.00 (sonnet)

**Large blueprints (>25 tasks):**
- Parallelism: 4
- Advisory: enabled
- Quorum: enabled (meta-loop up to 2 cycles)
- Cost: ~$5.00-15.00 (sonnet + meta-loop)

**Throughput:** With 4 parallel workers, ~15-30 tasks/hour (depending on task complexity).

---

## Evolution Path

**Current:** v1.0.0 (FORMIGA biomimetic engine)
**Next:**
- W4: Documentation (operator guide, worker guide, troubleshooting)
- W5: Adversarial testing (chaos injection, edge cases)
- Post-v1: Cross-blueprint pattern transfer (global pattern library)

---

*FORMIGA Architecture v1.0.0*
*"From forge to execution — emergent colony intelligence."*
