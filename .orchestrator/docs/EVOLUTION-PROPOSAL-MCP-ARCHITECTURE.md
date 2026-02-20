# FORMICA Evolution Proposal: MCP Architecture & Cognitive Infrastructure

> **Status:** PROPOSAL | **Version:** 1.0 | **Date:** 2026-02-18
> **Author:** AURUM Cognitive Refinery (cross-project analysis)
> **Target:** ATHENA OS / FORMICA Orchestrator v3.5+
> **Companion docs:**
> - `AURUM-KNOWLEDGE-PACK.md` (13 curated knowledge exports)
> - `cognitive-refinery/40-meta/MATRIX-FORMICA-AURUM.md` (full cross-reference matrix)

---

## 1. EXECUTIVE SUMMARY

This document proposes 4 evolution axes for FORMICA, derived from cross-referencing FORMICA's architecture with 504 knowledge artifacts from the AURUM Cognitive Refinery vault. The central thesis:

**FORMICA's greatest leverage point is not smarter workers or better QA — it's the ENVIRONMENT in which workers operate.** Improving context assembly, persistent memory, and communication protocol yields compounding returns across every component.

The proposal explores 4 paths for MCP integration (from minimal to transformative), 3 concrete context engine improvements, a persistent memory architecture, and a phased roadmap that delivers value at each step without requiring a full rewrite.

**Key numbers:**
- 13 directly applicable knowledge exports identified
- 6-8 reverse-flow artifacts (FORMICA knowledge → AURUM vault)
- 4 MCP integration paths analyzed (A through D)
- 5 phases in the evolution roadmap
- Estimated: each phase is independently valuable and deployable

---

## 2. CURRENT STATE: FORMICA v3.5

### 2.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    FORMICA v3.5 ARCHITECTURE                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  LAYER 2: KNOWLEDGE (optional, ATHENA-native)                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ athena.sh — Genius kits, AURUM exports, pattern lifecycle │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  LAYER 1: INTELLIGENCE (orchestration logic)                    │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ routing.sh    — Allometry + model selection                │  │
│  │ advisory.sh   — Inter-wave coherence review                │  │
│  │ meta_loop.sh  — Quorum sensing + self-improvement          │  │
│  │ pheromone.sh  — Evidence-based model routing (v3.5)        │  │
│  │ epigenetics.sh — Runtime parameter adaptation              │  │
│  │ friction.sh   — Friction event logging                     │  │
│  │ file_registry.sh — Write-conflict detection                │  │
│  │ modes.sh      — Execution modes (quality/speed/budget)     │  │
│  │ wizard.sh     — Pre-execution cost estimation              │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  LAYER 0: CORE (standalone)                                     │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ orchestrate.sh — Main loop, Ralph Loop, task dispatch      │  │
│  │ qa.sh          — 3-layer immune system                     │  │
│  │ context.sh     — 7-layer context pack assembly             │  │
│  │ deps.sh        — DAG validation + topological sort         │  │
│  │ state.sh       — Atomic JSON state management              │  │
│  │ cost.sh        — Token tracking + budget enforcement       │  │
│  │ lock.sh        — File-based locking                        │  │
│  │ parallel.sh    — Semaphore concurrency                     │  │
│  │ ingest.sh      — Blueprint ingestion                       │  │
│  │ report.sh      — Execution reports                         │  │
│  │ meta_report.sh — 3-layer meta-report                       │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  WORKERS: Stateless claude -p instances                         │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ analyst.md | writer.md | qa.md | architect.md | ...        │  │
│  │ Each: receives context pack → produces output → dies       │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  STATE: Filesystem-based stigmergy                              │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ state.json | events.jsonl | colony_signals.jsonl           │  │
│  │ attempts/*/output.md | pheromone_table.jsonl               │  │
│  │ global_blacklist.jsonl | campaign reports                  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Communication Model (Current)

```
┌──────────────┐     filesystem      ┌──────────────┐
│ orchestrate  │ ──── write ────────►│  state.json   │
│    .sh       │ ◄─── read ─────────│  events.jsonl │
└──────┬───────┘                     │  colony_*.jsonl│
       │                             └──────────────┘
       │ pipe stdin                         ▲
       ▼                                    │ read
┌──────────────┐                     ┌──────────────┐
│  Worker      │ ──── stdout ──────►│  output.md    │
│  (claude -p) │                     └──────────────┘
└──────────────┘                            ▲
       │                                    │ read
       │ (no direct communication)          │
       ▼                                    │
┌──────────────┐                     ┌──────┴───────┐
│  QA Worker   │ ──── verdict ─────►│  qa-*.json    │
│  (claude -p) │     + signal       │  colony_*.jsonl│
└──────────────┘                     └──────────────┘
```

**Properties:**
- Unidirectional: orchestrator → worker (via context pack pipe)
- Asynchronous: workers cannot query state mid-execution
- Batch: intelligence transfers happen at wave boundaries, not continuously
- Broadcast: colony signals go to ALL workers, not targeted
- Ephemeral: most intelligence dies with the campaign

### 2.3 Strengths (preserve these)

| Strength | Why it works | Evidence |
|---|---|---|
| Zero-dependency core | Layer 0 works with bash + jq + claude only | ADR-001 |
| Stateless workers | Fresh context per task, no contamination | AURUM PILL-HEU-context-isolation validates |
| Biomimetic patterns | Allometry, stigmergy, trophallaxis are genuinely novel | No equivalent in AURUM vault (unique IP) |
| File-based coordination | Simple, debuggable, version-controllable | Works for batch execution model |
| 3-layer immune system | Pre-spawn + innate + adaptive QA | AURUM confirms this is industry convergent pattern |
| Self-modification protection | chmod -w during execution | AURUM PILL-HEU-sandbox-84 validates (84% reduction) |

### 2.4 Gaps (address these)

| Gap | Current Impact | AURUM Evidence |
|---|---|---|
| No persistent cross-campaign memory | Each campaign starts from zero; patterns evaporate | PILL-FWK-memory-hierarchy: Layer 4 (Persistent) underutilized |
| No role-based worker permissions | All workers have identical access | LENS-AFW-bounded-autonomy: 2/5 on this dimension |
| No end-to-end value metric | cost.sh measures tokens, not value delivered | LENS-AFW-measurement-paradox: proxy optimization risk |
| Colony signals are broadcast, not routed | Workers receive ALL signals, most irrelevant | PILL-FWK-orchestration-20260207-009: routing pattern underused |
| No human escalation in QA | Binary pass/fail, no "ask human for ambiguous case" | PILL-FWK-trust-funnel: Layer 4 (Ask Rules) missing |
| No wave checkpointing | Cannot fork, recover to point-in-time, or experiment | PILL-FWK-memory-hierarchy: Layer 3 (Session) missing |
| No external API/interface | Other systems interact via bash exec only | Limits composability and ATHENA integration |
| Context pack not validated pre-spawn | Missing blocks not detected until bad output | PILL-FWK-context-engineering-6-blocks: audit checklist |

---

## 3. KNOWLEDGE FOUNDATION

### 3.1 From AURUM (13 exports — see AURUM-KNOWLEDGE-PACK.md)

**Tier 1 Fundamental:**
- F1: 5 Composable Agentic Patterns (FORMICA implements all 5)
- F2: Trust Funnel 7 Layers (FORMICA has 3/7)
- F3: 4 Multi-Agent Topologies (FORMICA = Coordinator-Subagent + Platform hybrid)
- F4: Context Engineering 6 Building Blocks (context.sh covers 5/6, missing validation)
- F5: Subagent Pattern: Isolate, Parallelize, Summarize (validates FORMICA's design)

**Tier 2 Technical:**
- T1: Memory Hierarchy 4 Layers (FORMICA strong on L4, weak on L3)
- T2: Bounded Autonomy 5 Dimensions (FORMICA 4/5, weak on role-based permissions)
- T3: QA-as-Subagent (VS Code convergent validation)
- T4: Measurement Paradox 55% vs 19% (proxy optimization warning)
- T5: Delegation Paradox 60% vs 20% (human evaluation is the ceiling)

**Tier 3 Strategic:**
- S1: Cognitive Debt Model (generated artifacts without understanding = debt)
- S2: Sandbox 84% (restrict environment > monitor agent)
- S3: DevEx = AgentEx (environment quality = agent quality)

### 3.2 From FORMICA (6-8 unique artifacts → AURUM vault)

| Pattern | Type | Novelty | Extraction Priority |
|---|---|---|---|
| Allometry (scale-dependent colony sizing) | FWK + PILL | No equivalent in literature | HIGH |
| Stigmergy (filesystem as coordination protocol) | FWK | Exists in biology, novel in AI orchestration | HIGH |
| Trophallaxis (colony signals for cross-worker intelligence) | MTH + PILL | Novel mechanism for asynchronous knowledge transfer | HIGH |
| Negative Pheromone (severity-graded blacklist with evaporation) | MTH | Operational anti-pattern enforcement | MEDIUM |
| Quorum Sensing (multi-source composite decision + sigmoid) | FWK + SKILL | Novel autonomous decision mechanism | HIGH |
| Synaptic Pruning (pattern lifecycle with maturity-adjusted thresholds) | MTH | Pattern lifecycle management | MEDIUM |

### 3.3 Meta-Principle

From analyzing all 13 exports against FORMICA's architecture, one principle emerges:

> **The environment shapes the agent more than the agent's internal capability.**

This means: invest in context quality, state structure, communication protocol, and audit design BEFORE investing in smarter models or more sophisticated QA prompts. The environment is the multiplier.

---

## 4. EVOLUTION AXIS 1: CONTEXT ENGINE

**Target:** context.sh → Context Engine v2.0
**Priority:** HIGHEST (single point through which ALL information flows to ALL workers)
**Effort:** LOW-MEDIUM
**Dependencies:** None (can be done first)

### 4.1 Current: 7-Layer Assembly

```
L1: Universal       → System identity, global rules
L2: Constraints     → Budget, blacklist, limitations
L3: Domain          → Domain-specific knowledge files
L4: Project         → Prior outputs, file context
L5: Colony Signals  → Trophallaxis (broadcast, unfiltered)
L6: QA Rubric       → Scoring criteria for this task type
L7: Feedback        → Retry context from prior failed attempts
```

### 4.2 Evolution: Validated + Routed + Enriched

**Change 1: Pre-Spawn Validation (6 Building Blocks audit)**

Before every worker spawn, validate context pack completeness:

```bash
# context.sh addition
validate_context_pack() {
    local task_id="$1"
    local pack_file="$2"
    local warnings=()

    # Map 6 Building Blocks to FORMICA layers
    local goal=$(extract_block "$pack_file" "goal")        # From blueprint task description
    local constraints=$(extract_block "$pack_file" "L2")    # Budget, blacklist, rules
    local references=$(extract_block "$pack_file" "L3")     # Domain knowledge
    local examples=$(extract_block "$pack_file" "L4")       # Prior outputs, exemplars
    local procedures=$(extract_block "$pack_file" "worker")  # Worker prompt (.md)
    local rubric=$(extract_block "$pack_file" "L6")         # QA scoring criteria

    [[ -z "$goal" ]]        && warnings+=("GOAL: task has no clear objective description")
    [[ -z "$constraints" ]] && warnings+=("CONSTRAINTS: no budget/blacklist/rules injected")
    [[ -z "$references" ]]  && warnings+=("REFERENCES: no domain knowledge loaded")
    [[ -z "$rubric" ]]      && warnings+=("RUBRIC: no QA criteria — QA will score generically")
    # examples and procedures are DESIRABLE but not always available
    [[ -z "$examples" ]]    && warnings+=("EXAMPLES: no prior outputs for few-shot (acceptable)")

    if (( ${#warnings[@]} > 2 )); then
        log_event "CONTEXT_THIN" "$task_id" "Missing ${#warnings[@]}/6 blocks: ${warnings[*]}"
        # Option: abort spawn, degrade to simpler model, or warn and proceed
    fi

    echo "${warnings[@]}"
}
```

**Impact:** Catches "thin context" before it produces bad output. Most common failure mode in multi-agent systems is agents receiving Goal-only context (1/6 blocks).

**Change 2: Colony Signal Routing (targeted, not broadcast)**

Current: ALL colony signals injected into L5 for EVERY worker.
Evolution: Route signals by domain/relevance to the specific task.

```bash
# context.sh addition
route_colony_signals() {
    local task_id="$1"
    local task_domain="$2"  # From blueprint task metadata
    local max_signals=${3:-5}  # Prevent context bloat

    # Filter by domain relevance
    local relevant_signals=$(jq -c "
        [.[] | select(
            (.type == \"warning\" and .intensity >= 7) or  # Always include high-intensity warnings
            (.domain == \"$task_domain\") or               # Domain match
            (.target_task == \"$task_id\")                  # Explicitly targeted
        )] | sort_by(-.intensity) | .[:$max_signals]
    " "$COLONY_SIGNALS_FILE")

    echo "$relevant_signals"
}
```

**Impact:** Workers receive RELEVANT intelligence instead of noise. Reduces context waste. Makes trophallaxis precision-targeted.

**Change 3: Context Enrichment from Persistent Memory (requires Axis 3)**

If a persistent memory layer exists (MCP or file-based), context.sh can query it:

```bash
# context.sh addition (Phase 3+)
enrich_from_memory() {
    local task_type="$1"
    local domain="$2"

    # Query persistent memory for relevant patterns
    local patterns=$(formica_recall --domain "$domain" --task-type "$task_type" --min-confidence 0.7 --limit 3)

    # Query historical performance for model recommendation
    local model_hint=$(formica_get_performance --worker-type "$task_type" --domain "$domain" --metric qa_score --top 1)

    echo "LEARNED_PATTERNS: $patterns"
    echo "MODEL_HINT: $model_hint"
}
```

**Impact:** Context packs include intelligence from past campaigns. Workers benefit from organizational memory.

---

## 5. EVOLUTION AXIS 2: MCP SERVER

### 5.1 Path A: MCP as Orchestrator API

**Concept:** MCP server wraps FORMICA's state layer. Orchestrator (bash) uses it via CLI wrapper. External systems (ATHENA, other Claude sessions) use it as native MCP.

**Architecture:**

```
┌──────────────────────────────────────────────────────────────┐
│                    MCP Server: formica-mcp                    │
│                                                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │   STATE     │  │  SIGNALS   │  │  OUTPUTS   │             │
│  │  Tools      │  │  Tools     │  │  Tools     │             │
│  ├────────────┤  ├────────────┤  ├────────────┤             │
│  │ get_state   │  │ get_signals│  │ query_     │             │
│  │ update_task │  │ emit_signal│  │  outputs   │             │
│  │ get_status  │  │ get_black- │  │ get_report │             │
│  │             │  │  list      │  │            │             │
│  └────────────┘  └────────────┘  └────────────┘             │
│                                                              │
│  ┌────────────┐  ┌────────────┐                              │
│  │ BLUEPRINT  │  │  CONTROL   │                              │
│  │  Tools      │  │  Tools     │                              │
│  ├────────────┤  ├────────────┤                              │
│  │ submit_    │  │ pause      │                              │
│  │  blueprint │  │ resume     │                              │
│  │ validate_  │  │ cancel     │                              │
│  │  blueprint │  │ get_logs   │                              │
│  └────────────┘  └────────────┘                              │
│                                                              │
│  Storage: runtime/{blueprint}/state.json (same files)        │
│  Transport: stdio (for Claude) or HTTP (for bash/external)   │
└──────────────────────────────────────────────────────────────┘
         ▲              ▲              ▲
         │              │              │
    Claude Code    orchestrate.sh   CI/CD / External
    (native MCP)   (curl/cli)      (HTTP API)
```

**Implementation sketch:**

```typescript
// formica-mcp/src/server.ts (Node.js MCP server)
import { McpServer } from "@anthropic-ai/mcp";

const server = new McpServer({
  name: "formica",
  version: "1.0.0",
});

// === STATE TOOLS ===
server.tool("formica_get_state", {
  description: "Read current blueprint execution state",
  parameters: {
    blueprint_id: { type: "string", description: "Blueprint identifier" },
    task_id: { type: "string", optional: true, description: "Specific task (omit for full state)" },
  },
  handler: async ({ blueprint_id, task_id }) => {
    const statePath = `runtime/${blueprint_id}/state.json`;
    const state = JSON.parse(await fs.readFile(statePath, "utf-8"));
    if (task_id) return state.tasks.find(t => t.id === task_id);
    return state;
  },
});

server.tool("formica_get_status", {
  description: "High-level campaign status: progress, wave, cost, scores",
  parameters: {
    blueprint_id: { type: "string" },
  },
  handler: async ({ blueprint_id }) => {
    const state = await readState(blueprint_id);
    return {
      progress: `${state.tasks.filter(t => t.status === "done").length}/${state.tasks.length}`,
      current_wave: state.current_wave,
      total_cost: state.total_cost,
      avg_qa_score: state.avg_qa_score,
      mode: state.mode,
      started_at: state.started_at,
    };
  },
});

// === COLONY INTELLIGENCE ===
server.tool("formica_emit_signal", {
  description: "Emit a colony signal for cross-worker intelligence",
  parameters: {
    type: { type: "string", enum: ["insight", "warning", "pattern", "dependency", "suggestion"] },
    signal: { type: "string", description: "The signal content" },
    intensity: { type: "number", minimum: 1, maximum: 10 },
    source_task: { type: "string" },
    domain: { type: "string", optional: true, description: "Domain tag for routing" },
    target_task: { type: "string", optional: true, description: "Specific target task" },
  },
  handler: async (params) => {
    const signalPath = `runtime/${params.blueprint_id}/colony_signals.jsonl`;
    const entry = { ...params, timestamp: new Date().toISOString() };
    await fs.appendFile(signalPath, JSON.stringify(entry) + "\n");
    return { status: "emitted", id: entry.timestamp };
  },
});

server.tool("formica_get_signals", {
  description: "Read colony signals, optionally filtered by domain/intensity",
  parameters: {
    blueprint_id: { type: "string" },
    domain: { type: "string", optional: true },
    min_intensity: { type: "number", optional: true, default: 1 },
    type: { type: "string", optional: true },
    limit: { type: "number", optional: true, default: 20 },
  },
  handler: async ({ blueprint_id, domain, min_intensity, type, limit }) => {
    const signals = await readJsonl(`runtime/${blueprint_id}/colony_signals.jsonl`);
    return signals
      .filter(s => (!domain || s.domain === domain))
      .filter(s => s.intensity >= (min_intensity || 1))
      .filter(s => (!type || s.type === type))
      .sort((a, b) => b.intensity - a.intensity)
      .slice(0, limit);
  },
});

// === HANDOFF ===
server.tool("formica_handoff", {
  description: "Create a structured handoff between tasks with typed payload",
  parameters: {
    from_task: { type: "string" },
    to_task: { type: "string" },
    payload: { type: "object", description: "Structured data to pass" },
    priority: { type: "string", enum: ["critical", "normal", "fyi"], default: "normal" },
    summary: { type: "string", description: "Human-readable summary of the handoff" },
  },
  handler: async (params) => {
    const handoffPath = `runtime/${params.blueprint_id}/handoffs/`;
    await fs.mkdir(handoffPath, { recursive: true });
    const handoff = {
      ...params,
      id: `HO-${params.from_task}-${params.to_task}-${Date.now()}`,
      timestamp: new Date().toISOString(),
    };
    await fs.writeFile(
      `${handoffPath}/${handoff.id}.json`,
      JSON.stringify(handoff, null, 2)
    );
    return handoff;
  },
});

server.tool("formica_get_handoffs", {
  description: "Read pending handoffs for a specific task",
  parameters: {
    blueprint_id: { type: "string" },
    task_id: { type: "string" },
  },
  handler: async ({ blueprint_id, task_id }) => {
    const handoffs = await readHandoffs(blueprint_id);
    return handoffs.filter(h => h.to_task === task_id);
  },
});

// === BLUEPRINT MANAGEMENT ===
server.tool("formica_submit_blueprint", {
  description: "Submit a YAML blueprint for execution",
  parameters: {
    yaml_content: { type: "string", description: "Full YAML blueprint content" },
    mode: { type: "string", enum: ["quality", "speed", "budget"], default: "quality" },
    dry_run: { type: "boolean", default: false, description: "Validate without executing" },
  },
  handler: async ({ yaml_content, mode, dry_run }) => {
    // Write blueprint to temp file, run validation
    const tmpPath = await writeTempBlueprint(yaml_content);
    const validation = await validateBlueprint(tmpPath);
    if (!validation.valid) return { error: validation.errors };
    if (dry_run) return { valid: true, tasks: validation.task_count, est_cost: validation.estimated_cost };

    // Execute via orchestrate.sh
    const blueprintId = await executeBlueprint(tmpPath, mode);
    return { blueprint_id: blueprintId, status: "started", mode };
  },
});

// === QUERY ===
server.tool("formica_query_outputs", {
  description: "Query completed task outputs from a campaign",
  parameters: {
    blueprint_id: { type: "string" },
    task_filter: { type: "string", optional: true, description: "Filter by task name pattern" },
    status_filter: { type: "string", optional: true, enum: ["done", "failed", "pending"] },
  },
  handler: async ({ blueprint_id, task_filter, status_filter }) => {
    const state = await readState(blueprint_id);
    let tasks = state.tasks;
    if (task_filter) tasks = tasks.filter(t => t.id.includes(task_filter));
    if (status_filter) tasks = tasks.filter(t => t.status === status_filter);
    return tasks.map(t => ({
      id: t.id,
      status: t.status,
      output_path: t.output_path,
      qa_score: t.qa_score,
      model: t.model,
      tokens: t.tokens,
    }));
  },
});

// === CONTROL ===
server.tool("formica_pause", {
  description: "Pause a running blueprint execution after current wave completes",
  parameters: { blueprint_id: { type: "string" } },
  handler: async ({ blueprint_id }) => {
    await writeControlSignal(blueprint_id, "PAUSE");
    return { status: "pause_requested" };
  },
});

server.tool("formica_resume", {
  description: "Resume a paused blueprint execution",
  parameters: { blueprint_id: { type: "string" } },
  handler: async ({ blueprint_id }) => {
    await writeControlSignal(blueprint_id, "RESUME");
    return { status: "resume_requested" };
  },
});

server.tool("formica_cancel", {
  description: "Cancel a running blueprint execution",
  parameters: { blueprint_id: { type: "string" } },
  handler: async ({ blueprint_id }) => {
    await writeControlSignal(blueprint_id, "CANCEL");
    return { status: "cancel_requested" };
  },
});
```

**Bash CLI wrapper (for orchestrate.sh):**

```bash
# lib/mcp_client.sh — Thin wrapper for bash to call MCP server
formica_mcp() {
    local tool="$1"; shift
    local params="$*"
    # Call MCP server via HTTP (if running as HTTP) or via CLI bridge
    curl -s "http://localhost:${FORMICA_MCP_PORT:-7433}/tool/${tool}" \
        -H "Content-Type: application/json" \
        -d "$params"
}

# Example usage in orchestrate.sh:
formica_mcp "formica_emit_signal" '{"type":"pattern","signal":"Writer tasks score higher with sonnet","intensity":7,"source_task":"task-3"}'
```

**Effort:** Medium (Node.js MCP server ~500 lines, bash wrapper ~100 lines)
**Preserves bash-native:** Yes (workers unchanged, orchestrator gains CLI bridge)
**Risk:** Adds Node.js runtime dependency for MCP server

---

### 5.2 Path B: Workers Migrate to Agent SDK

**Concept:** Workers transition from `claude -p` (stateless pipe) to Agent SDK instances (TypeScript/Python) with native MCP client, tool use, and structured output.

**Architecture:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    FORMICA v4.0 (Agent SDK)                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  orchestrate.sh (bash, unchanged)                               │
│       │                                                         │
│       │ spawn                                                   │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Worker Runner (TypeScript)                              │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │    │
│  │  │ Agent SDK │  │ MCP      │  │ Tool Definitions     │  │    │
│  │  │ Client   │  │ Client   │  │ (per worker role)     │  │    │
│  │  └──────────┘  └──────────┘  └──────────────────────┘  │    │
│  │       │              │                                   │    │
│  │       │  MCP calls   │                                   │    │
│  │       ▼              ▼                                   │    │
│  │  ┌──────────────────────────────────────────────────┐   │    │
│  │  │  formica-mcp server                               │   │    │
│  │  │  (state, signals, handoffs, blacklist, outputs)   │   │    │
│  │  └──────────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**What changes:**
- Workers go from `echo $context | claude -p $prompt` to Agent SDK API calls
- Workers can USE TOOLS during execution (read files, query MCP, emit signals)
- Workers can REQUEST more context mid-execution (not just receive a static pack)
- Workers produce STRUCTURED output (JSON schema-validated, not raw markdown)
- Model selection per worker is programmatic (API parameter, not CLI flag)

**Worker definition evolution:**

```typescript
// workers/analyst.ts (Agent SDK worker)
import { Agent } from "@anthropic-ai/agent-sdk";

const analyst = new Agent({
  model: "claude-haiku-4-5",
  systemPrompt: await readFile("workers/analyst.md"),
  tools: [
    // Formica MCP tools (query state, emit signals)
    "formica_get_signals",
    "formica_emit_signal",
    "formica_get_handoffs",
    // Task-specific tools
    "read_file",
    "search_codebase",
  ],
  // Role-based permissions (Path B enables this)
  permissions: {
    write: ["runtime/*/attempts/*/"],  // Only write to own attempt directory
    read: ["**/*"],                     // Read anything
    mcp: ["formica_get_*", "formica_emit_signal"],  // Can query and emit, not control
  },
  outputSchema: analystOutputSchema,  // Enforced structured output
});

// Execute
const result = await analyst.run(contextPack);
```

**What this unlocks:**
- Workers can check colony signals MID-EXECUTION and adjust behavior
- Workers can request handoff data from specific upstream tasks
- Workers can emit targeted signals to specific downstream tasks
- Role-based permissions become enforceable (analyst: read-only, writer: scoped write, QA: read-all)
- Structured output eliminates output parsing errors

**Effort:** HIGH (rewrite worker dispatch from bash to TypeScript/Python)
**Preserves bash-native:** Partially (orchestrate.sh stays bash, workers become SDK)
**Risk:** Major architectural shift. Increases complexity. Introduces TypeScript/Python runtime.

**When to choose:** When workers need to be INTERACTIVE (query during execution, not just receive-and-produce). When role-based permissions are critical. When structured output validation is needed.

---

### 5.3 Path C: Hybrid (MCP for Orchestrator + Enhanced Workers)

**Concept:** MCP server for orchestrator and external interface (Path A). Workers stay `claude -p` but get a "mini-client" that pre-fetches MCP data and injects it into the context pack before spawn.

**Architecture:**

```
┌──────────────────────────────────────────────────────────────┐
│  orchestrate.sh                                              │
│       │                                                      │
│       │  ┌─────────────────────────────────────┐             │
│       ├──│ Pre-spawn MCP enrichment:            │             │
│       │  │  1. formica_get_signals (filtered)   │             │
│       │  │  2. formica_get_handoffs (for task)  │             │
│       │  │  3. formica_recall (persistent mem)  │             │
│       │  │  4. formica_get_performance (model)  │             │
│       │  └─────────────┬───────────────────────┘             │
│       │                │ inject into context pack             │
│       │                ▼                                      │
│       │  ┌─────────────────────────────────────┐             │
│       ├──│ Enhanced Context Pack:                │             │
│       │  │  L1-L4: (unchanged)                  │             │
│       │  │  L5: Routed colony signals (not all) │             │
│       │  │  L5b: Relevant handoffs (NEW)        │             │
│       │  │  L5c: Learned patterns (NEW)         │             │
│       │  │  L6: QA Rubric (unchanged)           │             │
│       │  │  L7: Feedback (unchanged)            │             │
│       │  │  L8: Model recommendation (NEW)      │             │
│       │  └─────────────┬───────────────────────┘             │
│       │                │ pipe                                │
│       ▼                ▼                                      │
│  Worker (claude -p, unchanged)                               │
│       │                                                      │
│       │ output                                               │
│       ▼                                                      │
│  Post-output MCP update:                                     │
│    1. formica_update_task (status, tokens)                   │
│    2. formica_handoff (if structured output has handoff)     │
│    3. Parse colony_signal from output → formica_emit_signal  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**Key insight:** Workers don't need to CALL MCP tools. The orchestrator calls MCP BEFORE spawning each worker and AFTER collecting output. Workers are still stateless — they just receive richer context.

**New context layers:**

```bash
# context.sh v2.0 (hybrid)
assemble_context_pack() {
    local task_id="$1"
    local task_domain="$2"

    # L1-L4: unchanged
    assemble_L1_universal
    assemble_L2_constraints
    assemble_L3_domain "$task_domain"
    assemble_L4_project "$task_id"

    # L5: ROUTED colony signals (not broadcast)
    local signals=$(formica_mcp "formica_get_signals" \
        "{\"blueprint_id\":\"$BLUEPRINT_ID\",\"domain\":\"$task_domain\",\"min_intensity\":5,\"limit\":5}")
    echo "## Colony Intelligence (Relevant Signals)" >> "$PACK"
    echo "$signals" | jq -r '.[] | "- [\(.type)] \(.signal) (intensity: \(.intensity))"' >> "$PACK"

    # L5b: HANDOFFS from upstream tasks (NEW)
    local handoffs=$(formica_mcp "formica_get_handoffs" \
        "{\"blueprint_id\":\"$BLUEPRINT_ID\",\"task_id\":\"$task_id\"}")
    if [[ "$handoffs" != "[]" ]]; then
        echo "## Handoffs from Upstream Tasks" >> "$PACK"
        echo "$handoffs" | jq -r '.[] | "### From \(.from_task) [\(.priority)]\n\(.summary)\n\(.payload | tostring)"' >> "$PACK"
    fi

    # L5c: LEARNED PATTERNS from persistent memory (NEW, Phase 3+)
    if command -v formica_recall &>/dev/null; then
        local patterns=$(formica_mcp "formica_recall" \
            "{\"domain\":\"$task_domain\",\"task_type\":\"$WORKER_TYPE\",\"min_confidence\":0.7,\"limit\":3}")
        if [[ "$patterns" != "[]" ]]; then
            echo "## Learned Patterns (from prior campaigns)" >> "$PACK"
            echo "$patterns" | jq -r '.[] | "- \(.signal) (confidence: \(.confidence), evidence: \(.evidence))"' >> "$PACK"
        fi
    fi

    # L6-L7: unchanged
    assemble_L6_rubric
    assemble_L7_feedback "$task_id"

    # Validate completeness (6 Building Blocks audit)
    validate_context_pack "$task_id" "$PACK"
}
```

**Effort:** MEDIUM (MCP server from Path A + context.sh enrichment + post-output parsing)
**Preserves bash-native:** YES (workers are still claude -p)
**Risk:** Moderate — adds MCP dependency but workers are unchanged

**Best of both worlds:** External API + enriched workers without rewriting the worker model.

---

### 5.4 Path D: MCP as Persistent Memory (Cognitive Infrastructure)

**Concept:** MCP server focused on LONG-TERM intelligence that persists across campaigns. Not just state access — active learning, pattern consolidation, performance tracking.

**Architecture:**

```
┌──────────────────────────────────────────────────────────────┐
│                FORMICA Cognitive MCP Server                   │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  MEMORY LAYER (persistent, cross-campaign)            │    │
│  │                                                       │    │
│  │  formica_learn      — Record pattern from execution   │    │
│  │  formica_recall     — Query patterns by domain/type   │    │
│  │  formica_reinforce  — Strengthen pattern (evidence+1) │    │
│  │  formica_decay      — Weaken pattern (time-based)     │    │
│  │  formica_prune      — Remove below-threshold patterns │    │
│  │  formica_get_memory_stats — Memory health metrics     │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  PERFORMANCE LAYER (analytics)                        │    │
│  │                                                       │    │
│  │  formica_record_performance — Log task result metrics  │    │
│  │  formica_get_performance    — Query historical data    │    │
│  │  formica_get_model_ranking  — Best model per domain    │    │
│  │  formica_get_worker_ranking — Best worker per task     │    │
│  │  formica_get_friction_trends — Friction over time      │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  EVOLUTION LAYER (self-improvement)                   │    │
│  │                                                       │    │
│  │  formica_suggest_improvement — AI-generated proposals │    │
│  │  formica_get_anti_patterns   — Detected anti-patterns │    │
│  │  formica_compare_campaigns   — Before/after analysis  │    │
│  │  formica_export_knowledge    — Generate AURUM artifact│    │
│  └──────────────────────────────────────────────────────┘    │
│                                                              │
│  Storage: .orchestrator/memory/                              │
│  ├── patterns.jsonl      (learned patterns with lifecycle)   │
│  ├── performance.jsonl   (per-task metrics history)          │
│  ├── model_scores.jsonl  (pheromone table v2, persistent)    │
│  ├── anti_patterns.jsonl (detected failure modes)            │
│  └── knowledge_exports/  (generated AURUM-format artifacts)  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**Memory tool specifications:**

```typescript
// Memory Layer
server.tool("formica_learn", {
  description: "Record a pattern learned from campaign execution. Patterns accumulate evidence over time.",
  parameters: {
    pattern_type: { type: "string", enum: ["routing", "context", "qa", "model", "structural", "friction"] },
    signal: { type: "string", description: "The pattern description" },
    evidence: { type: "string", description: "What campaign/task demonstrated this" },
    domain: { type: "string" },
    confidence: { type: "number", minimum: 0, maximum: 1 },
    source_campaign: { type: "string" },
  },
  handler: async (params) => {
    // Check if pattern already exists (fuzzy match on signal)
    const existing = await findSimilarPattern(params.signal, params.domain);
    if (existing) {
      // Reinforce existing pattern
      existing.observations++;
      existing.confidence = Math.min(1.0, existing.confidence + 0.05);
      existing.last_evidence = params.evidence;
      existing.last_seen = new Date().toISOString();
      await updatePattern(existing);
      return { action: "reinforced", pattern_id: existing.id, observations: existing.observations };
    }
    // Create new pattern
    const pattern = {
      id: `PAT-${Date.now()}`,
      ...params,
      observations: 1,
      created_at: new Date().toISOString(),
      last_seen: new Date().toISOString(),
    };
    await appendPattern(pattern);
    return { action: "created", pattern_id: pattern.id };
  },
});

server.tool("formica_recall", {
  description: "Query learned patterns relevant to a domain/task type. Returns highest-confidence matches.",
  parameters: {
    domain: { type: "string", optional: true },
    task_type: { type: "string", optional: true },
    pattern_type: { type: "string", optional: true },
    min_confidence: { type: "number", default: 0.5 },
    limit: { type: "number", default: 5 },
  },
  handler: async (params) => {
    const patterns = await readPatterns();
    return patterns
      .filter(p => (!params.domain || p.domain === params.domain))
      .filter(p => (!params.task_type || p.task_type === params.task_type))
      .filter(p => (!params.pattern_type || p.pattern_type === params.pattern_type))
      .filter(p => p.confidence >= params.min_confidence)
      .sort((a, b) => b.confidence - a.confidence || b.observations - a.observations)
      .slice(0, params.limit);
  },
});

// Performance Layer
server.tool("formica_record_performance", {
  description: "Record task execution metrics for historical analysis",
  parameters: {
    campaign_id: { type: "string" },
    task_id: { type: "string" },
    worker_type: { type: "string" },
    model: { type: "string" },
    domain: { type: "string" },
    qa_score: { type: "number" },
    tokens_used: { type: "number" },
    cost: { type: "number" },
    attempt_number: { type: "number" },
    first_pass: { type: "boolean" },
    friction_events: { type: "number", default: 0 },
  },
  handler: async (params) => {
    await appendPerformance({ ...params, timestamp: new Date().toISOString() });
    // Auto-update model ranking
    await updateModelRanking(params.worker_type, params.domain, params.model, params.qa_score);
    return { recorded: true };
  },
});

server.tool("formica_get_model_ranking", {
  description: "Get best-performing model for a worker type and domain, based on historical QA scores",
  parameters: {
    worker_type: { type: "string" },
    domain: { type: "string", optional: true },
    min_samples: { type: "number", default: 3 },
  },
  handler: async ({ worker_type, domain, min_samples }) => {
    const history = await readPerformance();
    const filtered = history
      .filter(h => h.worker_type === worker_type)
      .filter(h => (!domain || h.domain === domain));

    // Group by model, calculate running average
    const byModel = groupBy(filtered, "model");
    return Object.entries(byModel)
      .map(([model, records]) => ({
        model,
        avg_qa_score: avg(records.map(r => r.qa_score)),
        avg_cost: avg(records.map(r => r.cost)),
        first_pass_rate: records.filter(r => r.first_pass).length / records.length,
        sample_count: records.length,
      }))
      .filter(m => m.sample_count >= min_samples)
      .sort((a, b) => b.avg_qa_score - a.avg_qa_score);
  },
});

// Evolution Layer
server.tool("formica_export_knowledge", {
  description: "Generate an AURUM-compatible artifact from accumulated FORMICA patterns",
  parameters: {
    pattern_ids: { type: "array", items: { type: "string" } },
    artifact_type: { type: "string", enum: ["methodology", "framework", "insight"] },
    title: { type: "string" },
  },
  handler: async ({ pattern_ids, artifact_type, title }) => {
    const patterns = await Promise.all(pattern_ids.map(id => getPattern(id)));
    // Generate AURUM-format artifact
    const artifact = formatAsAurumArtifact(patterns, artifact_type, title);
    const path = `memory/knowledge_exports/${artifact.id}.md`;
    await fs.writeFile(path, artifact.content);
    return { artifact_id: artifact.id, path, type: artifact_type };
  },
});
```

**Lifecycle management (synaptic pruning via MCP):**

```typescript
// Scheduled maintenance (run after each campaign)
server.tool("formica_maintenance", {
  description: "Run pattern lifecycle maintenance: decay old patterns, prune weak ones",
  parameters: {
    campaign_count: { type: "number", description: "Total campaigns executed (for maturity calculation)" },
  },
  handler: async ({ campaign_count }) => {
    const patterns = await readPatterns();
    const maturity = campaign_count <= 10 ? "young" : campaign_count <= 50 ? "adolescent" : "mature";
    const pruneThreshold = maturity === "young" ? 0.3 : maturity === "adolescent" ? 0.5 : 0.7;
    const decayFactor = 0.95;

    let decayed = 0, pruned = 0;
    const surviving = [];

    for (const p of patterns) {
      p.confidence *= decayFactor;
      decayed++;
      if (p.confidence < pruneThreshold && p.observations < 3) {
        pruned++;
        continue; // Remove
      }
      surviving.push(p);
    }

    await writePatterns(surviving);
    return { total: patterns.length, decayed, pruned, surviving: surviving.length, maturity };
  },
});
```

**Effort:** MEDIUM-HIGH (more tools, persistence layer, lifecycle management)
**Preserves bash-native:** YES (memory is a service, not a worker change)
**Risk:** Data quality — garbage patterns poison future campaigns

**Key advantage:** Transforms FORMICA from stateless executor to learning organism.

---

## 6. EVOLUTION AXIS 3: WAVE CHECKPOINTING

**Target:** state.sh → State Engine v2.0
**Priority:** HIGH (enables experimentation and recovery)
**Effort:** LOW
**Dependencies:** None

### 6.1 Implementation

```bash
# state.sh addition
checkpoint_wave() {
    local blueprint_id="$1"
    local wave_num="$2"
    local state_path="runtime/${blueprint_id}/state.json"
    local checkpoint_dir="runtime/${blueprint_id}/checkpoints"

    mkdir -p "$checkpoint_dir"

    # Atomic snapshot
    cp "$state_path" "${checkpoint_dir}/state.wave-${wave_num}.json"

    # Also snapshot colony signals and events at this point
    cp "runtime/${blueprint_id}/colony_signals.jsonl" \
       "${checkpoint_dir}/colony_signals.wave-${wave_num}.jsonl" 2>/dev/null || true
    cp "runtime/${blueprint_id}/events.jsonl" \
       "${checkpoint_dir}/events.wave-${wave_num}.jsonl" 2>/dev/null || true

    log_event "CHECKPOINT" "wave-${wave_num}" "State snapshot created"
}

restore_checkpoint() {
    local blueprint_id="$1"
    local wave_num="$2"
    local checkpoint_dir="runtime/${blueprint_id}/checkpoints"

    if [[ ! -f "${checkpoint_dir}/state.wave-${wave_num}.json" ]]; then
        log_error "No checkpoint found for wave ${wave_num}"
        return 1
    fi

    cp "${checkpoint_dir}/state.wave-${wave_num}.json" \
       "runtime/${blueprint_id}/state.json"

    log_event "RESTORE" "wave-${wave_num}" "State restored to wave ${wave_num} checkpoint"
}

fork_experiment() {
    local blueprint_id="$1"
    local wave_num="$2"
    local experiment_name="$3"
    local fork_dir="runtime/${blueprint_id}/forks/${experiment_name}"

    mkdir -p "$fork_dir"

    # Copy checkpoint state to fork
    cp "runtime/${blueprint_id}/checkpoints/state.wave-${wave_num}.json" \
       "${fork_dir}/state.json"

    # Fork can be executed independently
    log_event "FORK" "${experiment_name}" "Forked from wave ${wave_num} for experiment"
    echo "$fork_dir"
}
```

### 6.2 Use Cases

1. **Recovery:** Wave 4 fails → restore to wave 3 → retry with different model/parameters
2. **Experimentation:** Fork at wave 2 → run wave 3 with haiku AND sonnet → compare QA scores
3. **Debugging:** Inspect state at any wave boundary to find where quality degraded
4. **A/B testing:** Fork same blueprint with different modes (quality vs speed) from same checkpoint

---

## 7. EVOLUTION AXIS 4: WORKER MODEL ENHANCEMENT

**Target:** Workers → Enhanced Workers (optional, per-role)
**Priority:** MEDIUM (unlock when needed, not urgent)
**Effort:** VARIES (per path)

### 7.1 Current: Stateless One-Shot

```
orchestrate.sh → pipe context → claude -p worker.md → capture stdout → done
```

**Properties:** Zero state, zero side effects, zero tool use, pure function.

### 7.2 Option A: Structured Output Workers (minimal change)

```bash
# Add JSON schema enforcement to claude -p
invoke_worker() {
    local prompt="$1"
    local context="$2"
    local schema="$3"  # NEW: JSON schema for output validation

    local output=$(echo "$context" | claude -p "$prompt" --output-format json)

    # Validate against schema
    if [[ -n "$schema" ]]; then
        echo "$output" | jq --argjson schema "$(cat "$schema")" \
            'if . | [type] | inside(["object"]) then . else error("Invalid output format") end'
    fi

    echo "$output"
}
```

**Impact:** Workers produce validated structured output. QA parsing becomes trivial.

### 7.3 Option B: Tool-Using Workers (Agent SDK)

As described in Path B (Section 5.2). Workers gain tool use, MCP access, and mid-execution queries.

### 7.4 Option C: Hybrid Role-Based Workers

Different worker roles get different capabilities:

| Role | Model | Tools | Permissions | Rationale |
|---|---|---|---|---|
| analyst | haiku | read-only file access | Read project files | Needs to understand, not change |
| writer | sonnet | scoped file write | Write to task output dir only | Produces artifacts |
| architect | opus | full file access | Read all, write plans only | Needs full context for decisions |
| qa | sonnet | read-only + signal emit | Read outputs, emit colony signals | Must not modify what it reviews |
| synthesizer | opus | read all outputs | Read-only, write summary | Needs all context for synthesis |

**This is where role-based permissions (Gap #1 from bounded autonomy audit) get resolved.**

---

## 8. PHASED ROADMAP

Each phase delivers independent value. No phase requires all previous phases.

```
PHASE 1: Context Engine v2.0                    [Effort: LOW, Value: HIGH]
├── Pre-spawn validation (6 Building Blocks)
├── Colony signal routing (targeted, not broadcast)
└── Context pack completeness logging

PHASE 2: Wave Checkpointing                     [Effort: LOW, Value: MEDIUM]
├── State snapshot at wave boundaries
├── Restore from checkpoint
└── Fork for experimentation

PHASE 3: MCP Server (Core)                      [Effort: MEDIUM, Value: HIGH]
├── State tools (get_state, get_status, update_task)
├── Colony tools (emit_signal, get_signals with filtering)
├── Handoff tools (structured cross-task communication)
├── Blueprint tools (submit, validate, control)
└── Bash CLI wrapper for orchestrate.sh

PHASE 4: Persistent Memory                      [Effort: MEDIUM, Value: VERY HIGH]
├── Memory tools (learn, recall, reinforce, decay, prune)
├── Performance tools (record, get_ranking, get_trends)
├── Lifecycle management (synaptic pruning via maintenance)
├── Context enrichment from memory (L5c in context packs)
└── Pheromone table migration to persistent store

PHASE 5: Evolution & Knowledge Export            [Effort: LOW-MEDIUM, Value: HIGH]
├── Anti-pattern detection from performance history
├── AURUM-format knowledge export
├── Cross-campaign comparison analytics
├── Self-improvement suggestions
└── Reverse flow: FORMICA biomimetic patterns → AURUM vault
```

### Phase Dependencies

```
Phase 1 ──────────────────────────────► standalone
Phase 2 ──────────────────────────────► standalone
Phase 3 ──────────────────────────────► standalone (but enriches Phase 1)
Phase 4 ─── requires Phase 3 ────────► builds on MCP infrastructure
Phase 5 ─── requires Phase 4 ────────► builds on memory layer
```

### Estimated Effort

| Phase | New Files | Modified Files | Lines (est.) | Runtime Dependencies |
|---|---|---|---|---|
| 1 | 0 | context.sh | ~100 | None |
| 2 | 0 | state.sh, orchestrate.sh | ~80 | None |
| 3 | ~5 (MCP server + bash wrapper) | orchestrate.sh, context.sh | ~600-800 | Node.js (for MCP) |
| 4 | ~3 (memory tools, maintenance) | MCP server, context.sh | ~400-500 | Phase 3 |
| 5 | ~2 (export, analytics) | MCP server | ~300 | Phase 4 |

---

## 9. RISK ANALYSIS

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| MCP server adds Node.js dependency | Certain | Medium | Layer 0 must remain standalone; MCP is Layer 1+ only |
| Persistent memory poisoned by bad patterns | Medium | High | Minimum observation count (3+) before using patterns; decay aggressive for young system |
| Context pack over-enrichment (too much context) | Medium | Medium | Hard limit on injected signals/patterns (5 each); measure context pack size vs. output quality |
| Worker output parsing breaks with structured output | Low | Low | Graceful fallback to raw output; validate schema but don't crash on failure |
| MCP server port conflicts / daemon management | Medium | Low | Use unix socket instead of TCP; systemd/launchd service file for daemon lifecycle |
| Checkpoint storage grows indefinitely | Medium | Low | Prune checkpoints older than N campaigns; configurable retention policy |
| Over-engineering: complexity exceeds value | Medium | High | Phase 1-2 are zero-dependency. Stop there if they solve 80% of the problem. |

---

## 10. DECISION FRAMEWORK

Use this to decide WHICH phases to implement:

```
Q1: Do workers produce inconsistent output quality?
    YES → Phase 1 (Context Engine v2.0) — validate and enrich inputs
    NO  → Skip to Q2

Q2: Do you need to debug or experiment with campaign execution?
    YES → Phase 2 (Wave Checkpointing) — enable recovery and forking
    NO  → Skip to Q3

Q3: Does ATHENA or other systems need to interact with FORMICA programmatically?
    YES → Phase 3 (MCP Core) — expose FORMICA as a service
    NO  → Skip to Q4

Q4: Do you see the same mistakes repeated across campaigns?
    YES → Phase 4 (Persistent Memory) — learn from history
    NO  → Skip to Q5

Q5: Do you want FORMICA to improve itself and export knowledge?
    YES → Phase 5 (Evolution) — self-improvement + AURUM integration
    NO  → System is good as-is. Monitor.
```

---

## 11. INTEGRATION WITH ATHENA OS

### 11.1 Current: Shell Execution

```
ATHENA (Claude Code) → /execute blueprint → orchestrate.sh → results
```

### 11.2 With MCP (Phase 3+):

```yaml
# .claude/settings.json (ATHENA configuration)
{
  "mcpServers": {
    "formica": {
      "command": "node",
      "args": [".orchestrator/formica-mcp/dist/server.js"],
      "env": {
        "FORMICA_ROOT": ".orchestrator",
        "FORMICA_MEMORY": ".orchestrator/memory"
      }
    }
  }
}
```

ATHENA gains native access to FORMICA:

```
User: "Execute this plan with quality mode"
ATHENA: [uses formica_submit_blueprint tool]

User: "How's the campaign going?"
ATHENA: [uses formica_get_status tool]

User: "What did we learn from the last 5 campaigns?"
ATHENA: [uses formica_recall tool with min_confidence 0.7]

User: "Compare this campaign with the previous one"
ATHENA: [uses formica_compare_campaigns tool]
```

### 11.3 AURUM Integration (Phase 5)

```
FORMICA learns pattern → formica_export_knowledge → AURUM-format artifact
                                                         │
                                                         ▼
                                              cognitive-refinery/00-inbox/
                                                         │
                                                    /AURUM:tasks:refine
                                                         │
                                                         ▼
                                              Pills, Lenses, Skills
```

The loop closes: AURUM knowledge improves FORMICA → FORMICA execution generates new knowledge → new knowledge flows back to AURUM → refined knowledge further improves FORMICA.

---

## 12. REFERENCES

### AURUM Knowledge Exports (see AURUM-KNOWLEDGE-PACK.md for full content)

| ID | Title | Tier |
|---|---|---|
| PILL-FWK-five-agentic-patterns-20260207-009 | 5 Composable Agentic Patterns | F1 |
| PILL-FWK-trust-funnel-7-layers-20260215-013 | Trust Funnel 7 Layers | F2 |
| LENS-AFW-multi-agent-topologies-20260215-009 | 4 Coordination Topologies | F3 |
| PILL-FWK-context-engineering-6-blocks-20260215-015 | 6 Building Blocks + 4 Layers | F4 |
| SKILL-WRK-subagent-pattern-20260215-004 | Isolate, Parallelize, Summarize | F5 |
| PILL-FWK-memory-hierarchy-4-layers-20260215-017 | 4-Layer Memory Hierarchy | T1 |
| LENS-AFW-bounded-autonomy-20260215-005 | Bounded Autonomy 5 Dimensions | T2 |
| SKILL-WRK-multi-agent-qa-20260215-006 | Coordinator + QA Backstop | T3 |
| LENS-AFW-measurement-paradox-20260215-003 | 55% vs 19% Measurement Paradox | T4 |
| PILL-HEU-delegation-paradox-20260215-005 | 60% Use vs 20% Delegation | T5 |
| LENS-MDL-cognitive-debt-20260215-001 | Cognitive Debt > Technical Debt | S1 |
| PILL-HEU-sandbox-84-percent-20260215-006 | Sandbox 84% Permission Reduction | S2 |
| PILL-HEU-devex-equals-agentex-20260215-004 | DevEx = AgentEx | S3 |

### Cross-Reference Matrix

Full mapping: `cognitive-refinery/40-meta/MATRIX-FORMICA-AURUM.md`

### FORMICA Architecture Docs

- `.orchestrator/docs/ARCHITECTURE.md`
- `.orchestrator/docs/DECISIONS.md` (ADR-001 through ADR-010)
- `.orchestrator/docs/BLUEPRINT-REFERENCE.md`
- `.orchestrator/docs/DECISION-TREES.md`

---

## APPENDIX A: FORMICA → AURUM REVERSE FLOW SPECIFICATION

Detailed artifact specifications for extracting FORMICA's unique knowledge into the AURUM vault.

### A.1 Allometry — Scale-Dependent Colony Parameters

```yaml
# Proposed AURUM artifact
type: framework
id: FWK-FORMICA-ALLOMETRY
title: "Allometry: Scale-Dependent Agent Colony Sizing"
domain: multi-agent-systems
confidence: high
source: "FORMICA Orchestrator v3.5 (athena-os/.orchestrator/lib/routing.sh)"

# Core model
description: |
  Colony parameters follow biological allometry — they scale non-linearly
  with colony size. Small colonies (<=8 tasks) need minimal coordination
  overhead. Large colonies (>25) need advisory review, quorum sensing, and
  conservative parallelism.

  Power law for token budget per task:
    budget = BASE_TOKENS * (REFERENCE_SIZE / actual_size) ^ SCALING_EXPONENT
    budget = 60000 * (8/n)^0.75

  This produces:
    4 tasks:  ~100k tokens/task (generous, complex tasks)
    8 tasks:  60k tokens/task (baseline)
    16 tasks: ~36k tokens/task (efficient, focused tasks)
    32 tasks: ~21k tokens/task (minimal, specialized tasks)

# Configuration table
allometry_table:
  small:    { max_tasks: 8,  parallel: 2, advisory: false, quorum: false }
  medium:   { max_tasks: 16, parallel: 3, advisory: true,  quorum: false }
  large:    { max_tasks: 25, parallel: 4, advisory: true,  quorum: true  }
  colony:   { max_tasks: 99, parallel: 4, advisory: true,  quorum: true  }
```

### A.2 Trophallaxis — Cross-Worker Intelligence via Colony Signals

```yaml
type: methodology
id: MTH-FORMICA-TROPHALLAXIS
title: "Trophallaxis: Asynchronous Intelligence Transfer Between Stateless Agents"
domain: multi-agent-systems
confidence: high
source: "FORMICA Orchestrator v3.5 (lib/qa.sh + lib/context.sh)"

# The pattern
steps:
  1: "QA worker evaluates task output"
  2: "QA emits optional colony_signal: { type, signal, intensity, domain }"
  3: "Signal appended to colony_signals.jsonl (persistent)"
  4: "Context engine reads signals for NEXT worker"
  5: "Relevant signals injected into L5 of context pack"
  6: "Next worker benefits from prior QA intelligence WITHOUT direct communication"

# Key properties
properties:
  - "Asynchronous: emitter and receiver never interact directly"
  - "Persistent: signals survive beyond the emitting worker's lifecycle"
  - "Typed: signals have type (insight/warning/pattern/dependency) and intensity (1-10)"
  - "Emergent: colony behavior emerges from individual worker signals, not central planning"
  - "Biological analog: ant trophallaxis (food/information sharing via regurgitation)"
```

### A.3 Quorum Sensing — Multi-Source Composite Decision

```yaml
type: framework
id: FWK-FORMICA-QUORUM
title: "Quorum Sensing: Autonomous Decision via Multi-Source Signal Composition"
domain: multi-agent-systems
confidence: high
source: "FORMICA Orchestrator v3.5 (lib/meta_loop.sh)"

# The model
components:
  qa_scores:       { weight: 0.40, source: "QA immune system verdicts" }
  advisory:        { weight: 0.25, source: "Inter-wave coherence review" }
  colony_sentiment: { weight: 0.15, source: "Aggregate colony signal polarity" }
  structural_health: { weight: 0.20, source: "File registry, dependency completeness" }

# Decision function
decision: |
  composite = sum(component.value * component.weight)
  sharpened = sigmoid(composite, threshold=0.6, steepness=10)

  if sharpened > 0.8:  DONE
  elif sharpened > 0.5: TARGETED_RETRY (re-run failed tasks only)
  elif sharpened > 0.3: RE_EXECUTE (full re-run with adjusted parameters)
  elif sharpened > 0.1: RE_FORGE (generate new blueprint, different approach)
  else:                 ESCALATE (human intervention required)

# Key innovation
insight: |
  Sigmoid sharpening converts a fuzzy composite signal into a crisp decision.
  Without sharpening, signals in the 0.4-0.6 range produce ambiguous behavior.
  The sigmoid creates a sharp transition zone where the system either commits
  to a decision or escalates — no waffling.
```

---

*FORMICA Evolution Proposal v1.0 | 2026-02-18*
*Cross-project analysis: AURUM Cognitive Refinery v4.3.1 x FORMICA v3.5*
*4 Evolution Axes | 4 MCP Paths | 5-Phase Roadmap | 13 Knowledge Exports | 6 Reverse Flow Artifacts*
