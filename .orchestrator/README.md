# FORMIGA — Autonomous Cognitive Execution Engine

> **F**ORge → **E**xecute → **IM**prove → **G**o **A**gain

Bash orchestrator that spawns independent `claude -p` instances as specialized workers with isolated context, external QA, DAG scheduling, retry loops, cost tracking, and real-time observability.

**v1.0.0-formiga** builds on v0.1.0-alpha with: biomimetic intelligence (allometry, immune system, colony signaling, quorum sensing), strategic advisory, meta-loop self-improvement, ATHENA knowledge integration, and three-layer modular architecture.

## Quick Start

```bash
# 1. Validate blueprint (dry run)
.orchestrator/orchestrate.sh blueprints/test-single-e2e.yaml --dry-run

# 2. Execute blueprint
.orchestrator/orchestrate.sh blueprints/test-single-e2e.yaml

# 3. Check status during execution
.orchestrator/orchestrate.sh blueprints/test-single-e2e.yaml --status

# 4. Resume after interrupt
.orchestrator/orchestrate.sh blueprints/test-single-e2e.yaml --resume
```

## Prerequisites

| Tool | Install |
|------|---------|
| jq | `choco install jq` or `brew install jq` |
| yq | `choco install yq` or `brew install yq` |
| claude | `npm install -g @anthropic-ai/claude-code` |
| bc | Usually pre-installed. Windows: comes with Git Bash. |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FORMIGA v1.0                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Layer 2: KNOWLEDGE (optional)                               │
│  └── athena.sh — Genius kits, AURUM, patterns, pruning      │
│                                                              │
│  Layer 1: INTELLIGENCE                                       │
│  ├── routing.sh   — Allometry + model selection + blacklist  │
│  ├── advisory.sh  — Coherence review between waves           │
│  ├── meta_loop.sh — Quorum sensing + self-improvement        │
│  └── file_registry.sh — Conflict detection + safe waves      │
│                                                              │
│  Layer 0: CORE (standalone)                                  │
│  ├── orchestrate.sh — Main loop, Ralph Loop, task execution  │
│  ├── qa.sh    — QA + immune system + colony signals          │
│  ├── context.sh — Layered context assembly                   │
│  ├── deps.sh  — DAG validation + topological sort            │
│  ├── state.sh — Atomic JSON state management                 │
│  ├── cost.sh  — Token tracking + budget enforcement          │
│  └── (utils, lock, parallel)                                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## How It Works

1. **Blueprint YAML** defines tasks, workers, dependencies, QA criteria
2. **Allometry** sizes the colony: small (≤8 tasks), medium (9-25), large (26+)
3. **File registry** detects write conflicts and merges with DAG for safe waves
4. **Workers** are independent `claude -p` instances with layered context packs
5. **Immune system**: pre-spawn barriers → innate format check → adaptive QA
6. **Colony signals**: QA workers emit insights, injected into peer context
7. **Advisory**: coherence review between waves (medium/large blueprints)
8. **Meta-loop**: execute → evaluate (quorum) → retry/re-forge/done
9. **P6 Learn**: pattern decay, pruning, immune promotion at blueprint end

## Biomimetic Patterns

| Pattern | What | Where |
|---------|------|-------|
| **Allometry** | Scale-dependent colony parameters | `routing.sh` |
| **Immune System** | Three-layer defense (barriers → innate → QA) | `qa.sh` |
| **Trophallaxis** | Colony signaling via QA workers | `qa.sh` → `context.sh` |
| **Negative Pheromone** | Blacklist-based active repulsion | `routing.sh` |
| **Quorum Sensing** | Multi-source sigmoid meta-loop decision | `meta_loop.sh` |
| **Synaptic Pruning** | Pattern lifecycle with decay + prune | `athena.sh` |

## Blueprint YAML

See `docs/BLUEPRINT-REFERENCE.md` for full reference, or use a blueprint package directory with `checkpoint-map.yaml`.

```yaml
blueprint:
  id: "my-blueprint"
  name: "My Blueprint"
  project_dir: "D:/my-project"
  nature_code: "CODE"              # Optional: triggers Genius Layer

config:
  max_parallel: 3
  max_budget_usd: 10.0
  advisory:
    enabled: "auto"                # auto | true | false
  meta_loop:
    enabled: true
    max_cycles: 2

workers:
  implementer:
    prompt: "workers/implementer.md"
    tools: "Read,Write,Edit,Grep,Glob"

tasks:
  - id: "my-task"
    worker: "implementer"
    description: "..."
    acceptance_criteria: ["..."]
    output: "outputs/result.md"
    depends_on: []
    files_write: ["outputs/result.md"]   # Optional: conflict detection
    expected_format: "md"                 # Optional: immune validation
```

## Workers

| Worker | Role | Tools |
|--------|------|-------|
| implementer | Code, configuration | Read, Write, Edit, Grep, Glob |
| writer | Documentation, content | Read, Write, Grep, Glob |
| analyst | Research, analysis | Read, Grep, Glob |
| architect | System design | Read, Grep, Glob |
| advisor | Coherence review (NEW) | Read, Grep, Glob |
| forger | Blueprint re-forge (NEW) | Read, Write, Grep, Glob |
| qa | Quality review (READ-ONLY) | — (no tools) |

## Runtime Directory

```
runtime/{blueprint-id}/
├── state.json              # Blueprint state (atomic writes)
├── events.jsonl            # Event log (debugging trace)
├── cost.jsonl              # Per-task cost records
├── progress.txt            # Human-readable status
├── file_registry.json      # File conflict matrix (NEW)
├── colony_signals.jsonl    # Trophallaxis signals (NEW)
├── immune_events.jsonl     # Immune violations (NEW)
├── advisory_reviews.jsonl  # Advisory coherence data (NEW)
├── demand_signals.json     # Colony demand patterns (NEW)
├── blueprint-report.yaml    # Post-blueprint summary
├── advisory/               # Advisory artifacts (NEW)
├── attempts/               # Per-attempt worker artifacts
│   └── {task-id}-attempt-{N}/
│       ├── context-pack.md
│       ├── worker-response.json
│       ├── qa-response.json
│       └── qa-verdict.json
├── outputs/                # Worker deliverables
├── locks/                  # mkdir-based locks
└── logs/                   # Orchestrator + worker logs
```

## CLI Options

```
orchestrate.sh [--manifest] <blueprint.yaml> [options]

  --manifest, -m  Path to blueprint YAML manifest
  --resume, -r    Resume interrupted blueprint
  --dry-run, -n   Validate + show execution plan
  --parallel, -p  Override max concurrent workers
  --status, -s    Show blueprint status
  --interactive   Pause on critical failures
  --debug         Enable debug logging
  --help, -h      Show help
```

## Cost Model

| Model | Input (per 1M) | Output (per 1M) | Typical task |
|-------|----------------|------------------|-------------|
| haiku | $0.80 | $4.00 | ~$0.012 |
| sonnet | $3.00 | $15.00 | ~$0.04 |
| opus | $15.00 | $75.00 | ~$0.20 |

QA adds ~$0.008 per review (haiku). Advisory adds ~$0.15 per wave (sonnet).

## Documentation

| Doc | Contents |
|-----|----------|
| `docs/ARCHITECTURE.md` | Three-layer design, data flow, biomimetic patterns |
| `docs/DECISIONS.md` | 10 Architecture Decision Records |
| `docs/BLUEPRINT-REFERENCE.md` | Complete blueprint YAML field reference |
| `docs/DECISION-TREES.md` | 8 decision trees with flowcharts |

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.0.0-formiga | 2026-02-16 | Intelligence layer, meta-loop, biomimetic patterns, ATHENA integration |
| v0.1.0-alpha | 2026-02-16 | Core orchestrator, Ralph Loop, DAG, QA, cost tracking |
