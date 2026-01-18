# ATHENA OS

> **A Claude Code Native System for Intelligent Workflow Architecture**

```
      ___  _________ _   _ _____ _   _   ___    _____ _____
     / _ \|__   __| | | | |  ___| \ | | / _ \  |  _  /  ___|
    / /_\ \  | |  | |_| | |__ |  \| |/ /_\ \ | | | \ `--.
    |  _  |  | |  |  _  |  __|| . ` ||  _  | | | |  `--. \
    | | | |  | |  | | | | |___| |\  || | | | \ \_/\/ \__/ /
    \_| |_/  \_/  \_| |_/\____/\_| \_/\_| |_/  \___/\____/

    Slash Commands for Smarter AI Workflows
```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Built%20for-Claude%20Code-blueviolet)](https://claude.ai/code)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/yourusername/athena-os)

---

## What is ATHENA OS?

**ATHENA OS is a slash command system for Claude Code** that transforms how you plan and execute complex work.

### In Plain Terms

```
You type:    /ATHENA:tasks:forge-blueprint
ATHENA does: Guides you through a 4-phase process to create a complete execution plan
You get:     A Blueprint + Activation Prompt ready to execute in any Claude session
```

### What It Actually Is

- **8 slash commands** that live in `.claude/commands/`
- **A STATE.yaml file** that tracks everything across sessions
- **Templates and protocols** that ensure consistent, high-quality outputs
- **A knowledge base** of patterns and principles

### What It Does

1. **Takes your vague intention** ("I want to build an auth system")
2. **Forces clarity** through structured questions (What exactly? Why? For whom? Constraints?)
3. **Generates a Blueprint** with every task broken down to atomic level
4. **Produces an Activation Prompt** you can paste into any Claude session to execute

---

## Why Claude Code Native Matters

ATHENA isn't a standalone tool. It's designed specifically for **Claude Code's architecture**:

| Claude Code Feature | How ATHENA Uses It |
|--------------------|--------------------|
| **Slash Commands** | 8 commands in `.claude/commands/ATHENA/tasks/` |
| **CLAUDE.md** | System identity and instructions in `.claude/CLAUDE.md` |
| **Project Context** | Reads/writes STATE.yaml for persistent memory |
| **File Operations** | Generates Blueprints, templates, and configs |
| **Multi-session** | Blueprints transfer perfectly between sessions |

This means:
- **Zero setup** — Clone and start using
- **Native integration** — Works with Claude Code's existing features
- **Persistent state** — STATE.yaml survives session restarts
- **Transferable outputs** — Blueprints work in any Claude instance

---

## The Problem It Solves

| Problem | What Happens | ATHENA's Solution |
|---------|--------------|-------------------|
| **Context Loss** | "We discussed this yesterday, now I have to re-explain" | STATE.yaml + Blueprint documentation |
| **Vague Requirements** | "Make it better" → hours of rework | P1: DECODE forces explicit specs |
| **Scattered Files** | "Where did I put that output?" | Rigid taxonomy, one place per thing |
| **Invisible Progress** | "Are we done yet? What's left?" | Atomic tasks with binary completion |
| **Session Dependency** | "Only this Claude instance has context" | Activation Prompts work anywhere |

---

## How It Works (The Technical Reality)

### The 4-Phase Pipeline

```
/ATHENA:tasks:forge-blueprint
           │
           ▼
┌──────────────────────────────────────────────────────────────────┐
│  P1: DECODE                                                       │
│  "What do you actually want?"                                    │
│  Input:  Your description      Output: intent-spec.yaml          │
│  Gate:   Is intent unambiguous?                                  │
├──────────────────────────────────────────────────────────────────┤
│  P2: ARCHITECT                                                    │
│  "How should this be built?"                                     │
│  Input:  Intent spec           Output: exec-arch.yaml            │
│  Gate:   Is architecture logical?                                │
├──────────────────────────────────────────────────────────────────┤
│  P3: FRAGMENT                                                     │
│  "What are all the tasks?"                                       │
│  Input:  Architecture          Output: checkpoint-map.yaml       │
│  Gate:   Is everything broken into atomic tasks?                 │
├──────────────────────────────────────────────────────────────────┤
│  P4: CRYSTALLIZE                                                  │
│  "Package it for execution"                                      │
│  Input:  All above             Output: BLUEPRINT.md + ACTIVATION.md│
│  Gate:   Can someone execute this without asking questions?      │
└──────────────────────────────────────────────────────────────────┘
           │
           ▼
    outputs/blueprints/{date}/{slug}/
```

### What Gets Generated

```
outputs/blueprints/2025-01-16/my-project/
├── BLUEPRINT.md           # The complete execution plan
├── ACTIVATION.md          # Paste this into any Claude to execute
├── intent-spec.yaml       # Structured requirements
├── exec-arch.yaml         # How it will be built
├── checkpoint-map.yaml    # Every task, with dependencies
├── taxonomy-config.yaml   # Where outputs go in target project
└── _metadata.yaml         # Blueprint metadata
```

### The STATE.yaml (Persistent Memory)

```yaml
# STATE.yaml - ATHENA's memory across sessions
current_session:
  active_blueprint: "BP-2025-01-16-001"
  current_phase: "P2"

active_work:
  intent_summary: "User auth system with OAuth2"
  target_project: "D:/my-saas-app"
  phases_status:
    P1_DECODE: { status: "COMPLETED", gate_status: "PASSED" }
    P2_ARCHITECT: { status: "IN_PROGRESS" }

blueprints:
  total_generated: 12
  recent:
    - id: "BP-2025-01-16-001"
      title: "Auth System"
      status: "IN_PROGRESS"
```

---

## Core Principles (The "Why" Behind Decisions)

### 1. Context is King
Every output is self-contained. No "you had to be there" explanations needed.

### 2. Obsessive Fragmentation
Big task → Epics → Stories → Tasks. Every task has binary completion (done/not done).

### 3. STATE as Consciousness
If it's not in STATE.yaml, it didn't happen. This file IS the system's memory.

### 4. Rigid Taxonomy
Every file type has exactly one place it belongs. No creative folder structures.

### 5. Gates Before Progress
Each phase ends with a quality check. Failed? Go back. No shortcuts.

### 6. Meta-Application
ATHENA's own documentation follows ATHENA's principles. Recursively consistent.

### 7. Total Transferability
Any Claude instance can execute any Blueprint without verbal context.

---

## Quick Start

### 1. Install

```bash
git clone https://github.com/yourusername/athena-os.git
cd athena-os
cp STATE.example.yaml STATE.yaml  # Create your state file
```

### 2. Open with Claude Code

```bash
claude
```

### 3. Create Your First Blueprint

```bash
# Check system state
/ATHENA:tasks:check-state

# Start the pipeline
/ATHENA:tasks:forge-blueprint
```

When prompted, describe what you want to build:

```
"I want to build a user authentication system with OAuth2,
focusing on security and clean architecture."
```

ATHENA will guide you through P1→P2→P3→P4, asking clarifying questions and generating artifacts at each phase.

### 4. Execute the Blueprint

```bash
# Export to your target project
/ATHENA:tasks:export-to-project /path/to/your/project

# Or copy the ACTIVATION.md and paste it into a new Claude session
```

---

## All Commands

| Command | What It Does |
|---------|--------------|
| `/ATHENA:tasks:forge-blueprint` | **Main command** — Full P1→P4 pipeline |
| `/ATHENA:tasks:check-state` | Show current STATE (active work, history, metrics) |
| `/ATHENA:tasks:decode-intent` | Run only P1: Extract and structure intent |
| `/ATHENA:tasks:architect-execution` | Run only P2: Design execution architecture |
| `/ATHENA:tasks:fragment-work` | Run only P3: Break into atomic tasks |
| `/ATHENA:tasks:crystallize-output` | Run only P4: Generate final artifacts |
| `/ATHENA:tasks:validate-blueprint` | Validate an existing Blueprint |
| `/ATHENA:tasks:export-to-project` | Export Blueprint to target project |

---

## Project Structure

```
athena-os/
├── .claude/
│   ├── CLAUDE.md                    # System identity (read by Claude Code)
│   └── commands/ATHENA/tasks/       # The 8 slash commands
│
├── docs/                            # Deep documentation
│   ├── 00-MANIFESTO.md              # Core principles
│   ├── GENESIS.md                   # Origin story
│   ├── PHILOSOPHY.md                # Why it works this way
│   └── architecture/                # Technical docs
│
├── protocols/                       # Detailed phase protocols
│   ├── P1-DECODE.md
│   ├── P2-ARCHITECT.md
│   ├── P3-FRAGMENT.md
│   └── P4-CRYSTALLIZE.md
│
├── templates/                       # Master templates for outputs
├── knowledge/                       # Patterns and principles
├── examples/                        # Example Blueprints to learn from
├── outputs/                         # Your generated Blueprints (gitignored)
│
├── STATE.yaml                       # System memory (your copy)
├── STATE.example.yaml               # Template for new users
└── README.md                        # This file
```

---

## Example: See It In Action

Check `/examples/saas-mvp-architecture/` for a complete Blueprint showing:

- **BLUEPRINT.md** — 5 epics, 12 stories, 34 atomic tasks
- **ACTIVATION.md** — Ready to paste into any Claude session
- **checkpoint-map.yaml** — Full task breakdown with dependencies
- **intent-spec.yaml** — Structured requirements

This example covers building a User Management Module (auth, RBAC, profiles, security hardening).

---

## Who Is This For?

ATHENA OS is for people who:

- **Use Claude Code regularly** and want structured workflows
- **Work on complex projects** that span multiple sessions
- **Value documentation** but hate doing it manually
- **Want transferable context** between Claude instances
- **Believe planning prevents rework**

It's NOT for:

- Simple one-off tasks (just ask Claude directly)
- People who prefer improvisation over structure
- Projects that don't benefit from documentation

---

## Documentation

| Doc | What's In It |
|-----|--------------|
| [MANIFESTO](docs/00-MANIFESTO.md) | The 7 core principles |
| [GENESIS](docs/GENESIS.md) | Why ATHENA exists |
| [PHILOSOPHY](docs/PHILOSOPHY.md) | Deep dive into the thinking |
| [ARCHITECTURE](docs/architecture/01-ARCHITECTURE.md) | Technical structure |
| [PROTOCOLS](docs/architecture/02-PROTOCOLS.md) | How each phase works |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). We welcome:

- Example Blueprints for different domains
- Template improvements
- Documentation translations
- Bug reports and suggestions

---

## License

MIT — Use it however you want.

---

<p align="center">
  <strong>ATHENA OS v1.0.0</strong><br>
  <em>A Claude Code native system for intelligent workflow architecture</em><br><br>
  Built for people who think in systems.
</p>
