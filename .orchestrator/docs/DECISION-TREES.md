# FORMIGA — Decision Trees

**Version:** 1.0.0
**Blueprint:** BP-2026-02-16-002
**Date:** 2026-02-16

---

## Overview

FORMIGA's intelligence emerges from 8 interconnected decision trees. Each tree makes focused decisions based on runtime state, feeding into other trees to create emergent adaptive behavior.

**Key Insight:** No tree is intelligent alone. Intelligence emerges from their interaction.

---

## 1. Model Routing Decision Tree

**Function:** `routing.sh::select_model()`

**Purpose:** Select the right model for each task based on constraints and retry state.

```
START: Task needs model selection
  │
  ├─► [Per-task override specified?] ──YES──► Use override model → END
  │                     │
  │                    NO
  │                     ▼
  ├─► [Budget remaining < 30%?] ──YES──► Force HAIKU (cost emergency) → END
  │                     │
  │                    NO
  │                     ▼
  ├─► [Retry count >= 2?] ──YES──► Upgrade model:
  │                     │              haiku → sonnet
  │                     │              sonnet → (stay sonnet, don't auto-upgrade to opus)
  │                     │              → END
  │                    NO
  │                     ▼
  └─► Use DEFAULT_MODEL (set by config or allometry) → END
```

**Implementation:**
- Line 129-159 in `routing.sh`
- Called per task before worker spawn
- Priority: override > budget constraint > retry upgrade > default

**Cost Impact:**
- Haiku: $0.012/task
- Sonnet: $0.04/task
- Upgrade triggered on 2nd retry to avoid retry loops

---

## 2. Parallelization + File Safety Decision Tree

**Function:** `file_registry.sh::generate_execution_waves()`

**Purpose:** Generate safe parallel execution waves by merging DAG dependencies with file conflict detection.

```
START: Blueprint manifest loaded
  │
  ├─► Build file registry (files_read/files_write per task)
  │     │
  │     └─► For each task pair (A, B):
  │           │
  │           ├─► [A.writes ∩ B.writes ≠ ∅?] ──YES──► CONFLICT: write-write
  │           │                                          Add dependency: B depends on A
  │           │
  │           ├─► [A.writes ∩ B.reads ≠ ∅?] ──YES──► CONFLICT: read-after-write
  │           │                                         Add dependency: B depends on A
  │           │
  │           └─► [A.reads ∩ B.reads ≠ ∅?] ──YES──► NO CONFLICT (reads are safe)
  │                                              └─► [No overlap?] ──YES──► NO CONFLICT
  │
  ├─► Merge file conflicts with DAG dependencies (from task.depends_on)
  │     │
  │     └─► Build dependency graph:
  │           - Edges = explicit deps + file conflict deps
  │           - In-degree[task] = count of dependencies
  │
  ├─► Topological sort (Kahn's algorithm):
  │     │
  │     ├─► Initialize queue with tasks where in_degree = 0
  │     │
  │     ├─► WHILE queue not empty:
  │     │     ├─► Pop all tasks from queue → WAVE N
  │     │     ├─► For each task in wave:
  │     │     │     └─► Decrement in_degree of dependent tasks
  │     │     └─► Add tasks with in_degree = 0 to queue
  │     │
  │     └─► [Any task with in_degree > 0?] ──YES──► ERROR: circular dependency
  │                                              └─► NO → waves generated
  │
  └─► Output: execution_waves.json
        { "waves": [{"wave": 1, "tasks": ["t1","t2"]}, ...], "conflicts": [...] }
```

**Implementation:**
- Lines 111-184 in `file_registry.sh`
- Called once during blueprint initialization
- Zero runtime conflicts by construction

**Example:**
```
Task A: writes "output.txt"
Task B: reads "output.txt"
→ B depends on A (read-after-write)
→ Wave 1: [A], Wave 2: [B]
```

---

## 3. Retry Strategy Decision Tree

**Function:** `orchestrate.sh::execute_task()` (Ralph Loop)

**Purpose:** Handle task execution with adversarial QA and retry logic.

```
START: Execute task
  │
  ├─► Attempt 1:
  │     ├─► Assemble context pack
  │     ├─► Select model
  │     ├─► Spawn worker
  │     ├─► Run QA (adversarial scoring)
  │     │
  │     └─► [QA verdict?]
  │           │
  │           ├─► PASS (score >= threshold) ──► Mark complete → END
  │           │
  │           ├─► REWORK (60 <= score < threshold) ──► Go to Attempt 2
  │           │
  │           └─► REJECT (score < 60) ──► Go to Attempt 2
  │
  ├─► Attempt 2:
  │     ├─► Include QA feedback in context
  │     ├─► Upgrade model (haiku → sonnet via Tree 1)
  │     ├─► Spawn worker
  │     ├─► Run QA
  │     │
  │     └─► [QA verdict?]
  │           │
  │           ├─► PASS ──► Mark complete → END
  │           │
  │           └─► REWORK/REJECT ──► Go to Attempt 3
  │
  ├─► Attempt 3 (final):
  │     ├─► Include all prior QA feedback
  │     ├─► Model already upgraded
  │     ├─► Spawn worker
  │     ├─► Run QA
  │     │
  │     └─► [QA verdict?]
  │           │
  │           ├─► PASS ──► Mark complete → END
  │           │
  │           └─► REWORK/REJECT ──► CIRCUIT BREAKER
  │
  └─► CIRCUIT BREAKER (max retries exhausted):
        │
        ├─► [Score >= 60?] ──YES──► Mark as PARTIAL SUCCESS → Continue blueprint
        │
        ├─► [Task can be decomposed?] ──YES──► Create sub-tasks → Continue
        │
        ├─► [Task is optional?] ──YES──► Mark SKIPPED → Continue
        │
        └─► [Critical task failed] ──► PAUSE blueprint → Operator review
```

**Implementation:**
- Core retry logic in `orchestrate.sh` (lines vary, main execution loop)
- QA scoring in `qa.sh`
- Model upgrade via Tree 1

**Max Cost per Task:**
- 3 attempts × model cost
- Worst case: haiku + sonnet + sonnet = $0.012 + $0.04 + $0.04 = $0.092

---

## 4. Meta-Loop Decision Tree

**Function:** `meta_loop.sh::quorum_decide()`

**Purpose:** After blueprint execution, decide whether to stop or iterate.

```
START: Blueprint execution complete
  │
  ├─► Compute quorum signal (Tree 8)
  │     ├─► QA signal: avg(task scores) / 100
  │     ├─► Advisory signal: last coherence / 10
  │     ├─► Colony signal: 1 - (warnings / total_signals)
  │     ├─► Structural signal: (completed - failed*0.5) / total
  │     │
  │     └─► Weighted composite:
  │           - Advisory ON:  0.40*QA + 0.25*Adv + 0.15*Col + 0.20*Str
  │           - Advisory OFF: 0.50*QA + 0.00*Adv + 0.20*Col + 0.30*Str
  │
  ├─► Apply sigmoid sharpening: 1/(1+e^(-12*(x-0.75)))
  │
  ├─► Check overrides:
  │     │
  │     ├─► [Disagreement > 0.40?] ──YES──► ESCALATE (sources conflict) → END
  │     │
  │     ├─► [Budget < 20%?] ──YES──► ESCALATE (budget exhausted) → END
  │     │
  │     └─► [Cycle >= max_cycles?] ──YES──► ESCALATE (max iterations) → END
  │
  ├─► Sigmoid-based decision:
  │     │
  │     ├─► [Sigmoid >= 0.90?] ──YES──► DONE → P6 LEARN → END
  │     │
  │     ├─► [Sigmoid >= 0.70?] ──YES──► TARGETED_RETRY
  │     │                                  ├─► Reset tasks with score < 80
  │     │                                  ├─► Increment cycle
  │     │                                  └─► Re-execute (go to START)
  │     │
  │     ├─► [Sigmoid >= 0.40?] ──YES──► RE_EXECUTE
  │     │                                  ├─► Reset all non-completed tasks
  │     │                                  ├─► Apply advisory adjustments
  │     │                                  ├─► Increment cycle
  │     │                                  └─► Re-execute (go to START)
  │     │
  │     └─► [Sigmoid < 0.40?] ──YES──► RE_FORGE
  │                                       ├─► [Forger worker available?] ──YES──► Generate new YAML
  │                                       │                                          └─► Validate → Re-init (go to START)
  │                                       │
  │                                       └─► NO → ESCALATE (forger unavailable)
  │
  └─► ESCALATE → Pause, await operator input
```

**Implementation:**
- Lines 88-146 in `meta_loop.sh`
- Called after `generate_execution_report()`
- Max auto cycles: 2 (configurable)

**Thresholds (sigmoid-sharpened):**
- DONE: >= 0.90 (excellence)
- TARGETED_RETRY: 0.70-0.89 (minor fixes)
- RE_EXECUTE: 0.40-0.69 (moderate issues)
- RE_FORGE: < 0.40 (fundamental problems)

---

## 5. Advisory Action Decision Tree

**Function:** `advisory.sh::apply_advisory()`

**Purpose:** Between waves, advisor reviews blueprint state and recommends adjustments.

```
START: Wave N complete
  │
  ├─► [Advisory enabled?] ──NO──► Skip advisory → Continue to next wave
  │                   │
  │                  YES
  │                   ▼
  ├─► Run advisory review:
  │     ├─► Assemble context (~5-8K tokens):
  │     │     - Blueprint state (all task scores, statuses)
  │     │     - Recent outputs (last 5 tasks)
  │     │     - Demand signals (colony warnings)
  │     │     - Pattern library (domain-filtered)
  │     │
  │     ├─► Spawn advisor worker (sonnet, ~$0.15)
  │     │
  │     └─► Parse structured output:
  │           - coherence_score: 0-10
  │           - quality_trend: improving|stable|degrading
  │           - recommendations: continue|adjust|pause|escalate
  │           - adjustments: { upgrade_model, increase_qa_threshold }
  │
  ├─► [Coherence < 5?] ──YES──► PAUSE blueprint → Operator review → END
  │                   │
  │                  NO
  │                   ▼
  ├─► [Coherence < 7?] ──YES──► Apply adjustments:
  │                   │            ├─► [upgrade_model=true?] ──YES──► haiku → sonnet
  │                   │            └─► [increase_qa_threshold=true?] ──YES──► QA += 5
  │                   │
  │                  NO (coherence >= 7)
  │                   ▼
  └─► Continue to next wave (no adjustments needed)
```

**Implementation:**
- Lines 72-109 in `advisory.sh`
- Called after each wave in `run_blueprint()`
- Cost: ~$0.15 per review

**Coherence Rubric:**
- 9-10: Excellent cross-task consistency
- 7-8: Good, minor inconsistencies
- 5-6: Noticeable drift, adjustments needed
- 3-4: Major conflicts emerging
- 0-2: Blueprint incoherent, PAUSE required

---

## 6. Allometry Decision Tree

**Function:** `routing.sh::apply_allometry()`

**Purpose:** Scale system parameters based on blueprint size (colony allometry).

```
START: Blueprint loaded, count tasks
  │
  ├─► [Task count <= 8?] ──YES──► SMALL COLONY
  │                                  ├─► MAX_PARALLEL = 2
  │                                  ├─► MAX_RETRIES = 2
  │                                  ├─► ADVISORY_ENABLED = false
  │                                  ├─► QUORUM_ENABLED = false
  │                                  ├─► SIGNAL_INJECTION_MAX = 2
  │                                  └─► CONTEXT_BUDGET = 60000 * (8/n)^0.75 (min 3000)
  │
  ├─► [Task count <= 25?] ──YES──► MEDIUM COLONY
  │                                   ├─► MAX_PARALLEL = 3
  │                                   ├─► MAX_RETRIES = 3
  │                                   ├─► ADVISORY_ENABLED = true
  │                                   ├─► QUORUM_ENABLED = false
  │                                   ├─► SIGNAL_INJECTION_MAX = 4
  │                                   └─► CONTEXT_BUDGET = 60000 * (8/n)^0.75 (min 3000)
  │
  └─► [Task count > 25?] ──YES──► LARGE COLONY
                                     ├─► MAX_PARALLEL = 4
                                     ├─► MAX_RETRIES = 3
                                     ├─► ADVISORY_ENABLED = true
                                     ├─► QUORUM_ENABLED = true
                                     ├─► SIGNAL_INJECTION_MAX = 6
                                     └─► CONTEXT_BUDGET = 60000 * (8/n)^0.75 (min 3000)

ADAPTIVE BRANCH (between waves):
  │
  ├─► [Failure rate > 30%?] ──YES──► MAX_PARALLEL = MAX_PARALLEL - 1 (min 1)
  │
  └─► [Retry rate > 50%?] ──YES──► [DEFAULT_MODEL = haiku?] ──YES──► Upgrade to sonnet
```

**Implementation:**
- Lines 25-120 in `routing.sh`
- Called once at blueprint init
- Between-wave adaptation via `adapt_allometry()`

**Token Budget Formula:**
```
tokens = 60000 * (8 / n)^0.75
floor = 3000

Examples:
  n=4:   60000 * (8/4)^0.75  = 60000 * 1.68 = ~100K (capped at 60K)
  n=8:   60000 * (8/8)^0.75  = 60000 * 1.00 = 60K
  n=16:  60000 * (8/16)^0.75 = 60000 * 0.59 = 35K
  n=32:  60000 * (8/32)^0.75 = 60000 * 0.35 = 21K
  n=64:  60000 * (8/64)^0.75 = 60000 * 0.21 = 12K
  n=128: 60000 * (8/128)^0.75 = 60000 * 0.12 = 7K
  n=256: 60000 * (8/256)^0.75 = 60000 * 0.07 = 4K
  n=512: 60000 * (8/512)^0.75 = 60000 * 0.04 = 2.4K → floored to 3K
```

**Biological Parallel:** Real ant colonies scale coordination mechanisms based on size. Small colonies (< 10 ants) don't use pheromone trails. Large colonies (1000+) have sophisticated signaling.

---

## 7. Context Budget Decision Tree

**Function:** `context.sh::assemble_context_pack()`

**Purpose:** Compose multi-layer context packs within token budget.

```
START: Assemble context for task
  │
  ├─► Get token budget from allometry (Tree 6)
  │     Default: 60000 tokens
  │     Scaled: based on colony size
  │
  ├─► Layer 1: UNIVERSAL (always included, ~2K tokens)
  │     ├─► Task definition
  │     ├─► Acceptance criteria
  │     ├─► Output path
  │     └─► Cost: ~2K tokens
  │
  ├─► Layer 1.5: CONSTRAINTS (negative pheromone, ~0.5K tokens)
  │     ├─► Soft blacklist entries (severity 1-3)
  │     ├─► Pattern warnings from past failures
  │     └─► Cost: ~0.5K tokens
  │
  ├─► Layer 2: DOMAIN (if nature_code set AND ATHENA available, ~2K tokens)
  │     ├─► Genius kit summary
  │     ├─► AURUM exports (top 3 for domain)
  │     ├─► Domain lens
  │     └─► Cost: ~2K tokens
  │
  ├─► Layer 3: DEPENDENCY (if task.depends_on non-empty, ~3-8K tokens)
  │     ├─► Outputs from completed dependency tasks
  │     ├─► QA feedback from dependencies
  │     ├─► Partial work (if this is retry)
  │     └─► Cost: ~3-8K tokens (adaptive)
  │
  ├─► Layer 4: PROJECT (if files_read specified, ~2-10K tokens)
  │     ├─► Project structure (tree)
  │     ├─► Source files from files_read
  │     ├─► Test files (if specified)
  │     └─► Cost: ~2-10K tokens (adaptive)
  │
  ├─► Layer 5: COLONY SIGNALS (trophallaxis demand signals, ~1K tokens)
  │     ├─► Repeated warnings from colony
  │     ├─► Demand patterns (warning count >= 3)
  │     └─► Cost: ~1K tokens
  │
  ├─► Layer 6: QA RUBRIC (~0.5K tokens)
  │     ├─► Scoring criteria
  │     ├─► QA threshold
  │     └─► Cost: ~0.5K tokens
  │
  ├─► Layer 7: FEEDBACK (if retry, ~1-3K tokens)
  │     ├─► Prior attempt QA feedback
  │     ├─► Reasons for rejection
  │     └─► Cost: ~1-3K tokens
  │
  ├─► Estimate total tokens
  │
  ├─► [Total > budget?] ──YES──► Truncate layers:
  │                                  Priority: Universal > Constraints > Domain > Project > Signals
  │                                  Truncate Project layer proportionally
  │                                  └─► Re-estimate
  │
  └─► Write context pack to file → Worker receives this
```

**Implementation:**
- Lines 9-64 in `context.sh`
- Layer functions: `_layer_universal()`, `_layer_constraints()`, etc.
- Called per task before worker spawn

**Layer Priority (if truncation needed):**
1. Universal (never truncate)
2. Constraints (never truncate)
3. Domain (never truncate if < 2K)
4. Dependency (truncate after 5K)
5. Project (truncate first — large source files)
6. Signals (truncate after 1K)

**Typical Sizes:**
- Minimal worker (no deps, no files): ~5K tokens
- Standard worker (deps + 2-3 files): ~12K tokens
- Heavy worker (many deps + large files): ~25K tokens (pre-truncation)
- Advisor (full blueprint state): ~8K tokens

---

## 8. Quorum Sensing Decision Tree

**Function:** `meta_loop.sh::compute_quorum_signal()`

**Purpose:** Synthesize multi-source quality signals into a single meta-loop decision.

```
START: Blueprint execution complete, compute quorum
  │
  ├─► Source 1: QA Signal (weight 0.40 if advisory ON, 0.50 if OFF)
  │     ├─► avg_score = mean(task.score for all tasks)
  │     └─► qa_signal = avg_score / 100  (normalize to 0-1)
  │
  ├─► Source 2: Advisory Signal (weight 0.25 if advisory ON, 0.00 if OFF)
  │     ├─► [advisory_reviews.jsonl exists?] ──YES──► last_coherence = tail entry
  │     │                                      └─► NO  → default = 0.7
  │     └─► advisory_signal = last_coherence / 10  (normalize to 0-1)
  │
  ├─► Source 3: Colony Signal (weight 0.15 if advisory ON, 0.20 if OFF)
  │     ├─► [colony_signals.jsonl exists?] ──YES──► count warnings
  │     │                                     └─► NO  → default = 0.7
  │     └─► colony_signal = 1 - (warning_count / total_signals)
  │
  ├─► Source 4: Structural Signal (weight 0.20 if advisory ON, 0.30 if OFF)
  │     └─► structural_signal = (completed - failed*0.5) / total_tasks
  │
  ├─► Compute weighted composite:
  │     composite = qa*w_qa + adv*w_adv + col*w_col + str*w_str
  │
  ├─► Apply sigmoid sharpening:
  │     sigmoid = 1 / (1 + e^(-12 * (composite - 0.75)))
  │
  │     Effect: Soft threshold at 0.75
  │       - 0.60 → 0.001 (strongly below)
  │       - 0.70 → 0.12  (below)
  │       - 0.75 → 0.50  (threshold)
  │       - 0.80 → 0.88  (above)
  │       - 0.90 → 0.999 (strongly above)
  │
  ├─► Compute disagreement (max deviation between any two sources):
  │     disagreement = max(|source_i - source_j|) for all i,j pairs
  │
  └─► Output: "sigmoid|qa|adv|col|str|disagreement"
        Example: "0.8234|0.82|0.75|0.70|0.88|0.18"

DECISION ROUTING (used by Tree 4):
  │
  ├─► [Disagreement > 0.40?] ──YES──► ESCALATE (sources fundamentally disagree)
  │
  ├─► [Budget < 20%?] ──YES──► ESCALATE (resource exhaustion)
  │
  ├─► [Cycle >= max?] ──YES──► ESCALATE (iteration limit)
  │
  ├─► [Sigmoid >= 0.90?] ──YES──► DONE
  │
  ├─► [Sigmoid >= 0.70?] ──YES──► TARGETED_RETRY
  │
  ├─► [Sigmoid >= 0.40?] ──YES──► RE_EXECUTE
  │
  └─► [Sigmoid < 0.40?] ──YES──► RE_FORGE
```

**Implementation:**
- Lines 15-146 in `meta_loop.sh`
- Called by `run_meta_loop()` after blueprint execution
- Feeds into Tree 4 (Meta-Loop Decision)

**Why Sigmoid Sharpening?**

Biological quorum sensing uses SHARP thresholds, not linear. Example: bacteria don't gradually increase bioluminescence — they flip a switch when density > threshold.

Raw composite (linear):
- 0.74 vs 0.76 feels barely different
- Decisions feel arbitrary

Sigmoid-sharpened:
- 0.74 → 0.43 (clearly below threshold)
- 0.76 → 0.57 (clearly above threshold)
- Clear separation around 0.75

**Disagreement Override:**

If sources disagree > 0.40, something is fundamentally wrong:
- Example: QA=0.90 (excellent), Advisory=0.40 (incoherent)
- System cannot self-correct → Escalate to operator

---

## Decision Tree Interaction Map

How trees feed into each other:

```
┌─────────────────────────────────────────────────────────────────┐
│                     BLUEPRINT EXECUTION                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ [6] ALLOMETRY                                                    │
│ Task count → Colony size → Parallelism, Advisory, Budget        │
└─────────────────────────────────────────────────────────────────┘
          │                    │                    │
          ▼                    ▼                    ▼
   MAX_PARALLEL         ADVISORY_ENABLED    CONTEXT_TOKEN_BUDGET
          │                    │                    │
          ▼                    ▼                    ▼
┌───────────────────┐  ┌───────────────────┐  ┌──────────────────┐
│ [2] FILE SAFETY   │  │ [5] ADVISORY      │  │ [7] CONTEXT      │
│ DAG + conflicts   │  │ Between waves     │  │ Layered packs    │
│ → Execution waves │  │ → Coherence check │  │ → Worker context │
└───────────────────┘  └───────────────────┘  └──────────────────┘
          │                    │                    │
          └────────────────────┴────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ [1] MODEL ROUTING│
                    │ Task type +      │
                    │ retry → Model    │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ [3] RETRY (Ralph)│
                    │ 3 attempts max   │
                    │ → Pass/Fail      │
                    └──────────────────┘
                              │
                              ▼
                    All tasks complete
                              │
                              ▼
                    ┌──────────────────┐
                    │ [8] QUORUM       │
                    │ 4 signals →      │
                    │ Composite score  │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ [4] META-LOOP    │
                    │ Quorum → Action  │
                    │ → Iterate/Done   │
                    └──────────────────┘
```

**Feedback Loops:**

1. **Retry Upgrade Loop:** Tree 3 (retry) → Tree 1 (upgrade model) → Tree 3 (retry with better model)
2. **Advisory Adjustment Loop:** Tree 5 (advisory) → Adjust DEFAULT_MODEL/QA_THRESHOLD → Tree 1 (uses new defaults)
3. **Meta-Loop Iteration:** Tree 4 (TARGETED_RETRY decision) → Reset failed tasks → Tree 2 (re-generate waves) → Tree 3 (execute)
4. **Allometry Adaptation:** Tree 6 (detect high failure rate) → Reduce parallelism → Tree 2 (fewer tasks per wave)

---

## Pattern: Emergent Intelligence

None of these trees are "smart" individually. Intelligence emerges from:

1. **Stigmergy:** Trees coordinate via shared state (state.json, events.jsonl), not direct communication
2. **Feedback Loops:** Decisions propagate through system, creating self-correction
3. **Multi-Scale:** Allometry adjusts behavior based on blueprint size (small → simple, large → sophisticated)
4. **Consensus:** Quorum sensing synthesizes multiple independent signals (QA, advisory, colony, structural)
5. **Escalation Ladder:** System tries cheaper fixes first (retry → targeted → re-execute → re-forge → escalate)

**Biological Parallel:** Ant colonies exhibit complex behavior (building bridges, sorting food) without any ant knowing the master plan. FORMIGA mirrors this: trees make local decisions, global behavior emerges.

---

## Usage Notes

### For Operators

When reading logs, you'll see decision tree outputs:

```
[INFO] Allometry: medium colony (15 tasks) — parallel=3, advisory=true, quorum=false, budget=42000tok
[INFO] File conflicts detected: 2 — adding implicit dependencies
[INFO] Model selection: task-003 → sonnet (retry_count=2, upgrade triggered)
[INFO] QA verdict: task-007 → REWORK (score 72/80)
[INFO] Advisory: coherence=6, trend=degrading
[INFO] Advisory adjustment: upgraded default model to sonnet
[INFO] Quorum signal: 0.7342|0.78|0.60|0.65|0.82|0.22
[INFO] Quorum: TARGETED_RETRY — sigmoid=0.7342 (0.70-0.89)
```

Each line corresponds to a decision tree.

### For Developers

When extending FORMIGA, ask:

1. **Is this a new decision tree?** If yes, document it here.
2. **Does this tree interact with existing trees?** Update interaction map.
3. **What state does this tree read/write?** Document in tree flowchart.

**Anti-pattern:** Adding "smart" logic that tries to make multiple decisions at once. Keep trees focused, let intelligence emerge from interaction.

---

## References

**Implementation:**
- `lib/routing.sh` — Trees 1, 6
- `lib/file_registry.sh` — Tree 2
- `orchestrate.sh` — Tree 3
- `lib/meta_loop.sh` — Trees 4, 8
- `lib/advisory.sh` — Tree 5
- `lib/context.sh` — Tree 7

**Architecture:**
- `/docs/ARCHITECTURE.md` — Component descriptions
- `/docs/DECISIONS.md` — Design rationale (ADR-002: Stigmergy, ADR-007: Quorum)

**Patterns:**
- Biomimetic patterns integrated into Trees 1, 6, 8 (allometry, pheromone, quorum)
- Ralph Loop (Tree 3) — Retry with QA feedback
- Fresh Context (Tree 7) — Minimal context packs via `--setting-sources ""`

---

*FORMIGA v1.0.0 — Decision Trees*
*"Intelligence is not in the trees, but in their interaction."*
