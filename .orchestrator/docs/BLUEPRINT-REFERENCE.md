# Blueprint YAML Reference

Complete reference for ATHENA Orchestrated Execution Engine (FORMIGA v1.0) blueprint manifests.

---

## Overview

Blueprint YAML files define orchestrated execution plans with:
- **Metadata**: Project context and identification
- **Config**: Execution parameters and intelligence settings
- **Workers**: Reusable agent roles
- **Tasks**: Work units with dependencies, QA, and file safety

---

## Blueprint Metadata

```yaml
blueprint:
  id: string                    # Required. Unique ID (used for runtime directory)
  name: string                  # Required. Human-readable blueprint name
  project_dir: string           # Required. Absolute path to target project
  nature_code: string|null      # Optional. Domain code for Genius Layer
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique blueprint identifier. Used for runtime directory names. Format: `project-date-number` |
| `name` | string | Yes | Human-readable name for logs and reports |
| `project_dir` | string | Yes | Absolute path to target project. Workers get `--add-dir` access |
| `nature_code` | string\|null | No | Domain code: `COPY`\|`ARCH`\|`META`\|`DATA`\|`PROD`\|`BRAND`\|`LEARN`\|`CODE` |

### Example

```yaml
blueprint:
  id: "marketing-os-upgrade-001"
  name: "Marketing OS v4.0 Upgrade"
  project_dir: "D:/marketing-os"
  nature_code: "ARCH"
```

---

## Configuration

### Core Config

```yaml
config:
  max_parallel: integer         # Default: 2. Max concurrent workers
  max_budget_usd: float         # Default: 10.0. Total blueprint budget
  max_retries: integer          # Default: 3. Max attempts per task (including first)
  qa_threshold: integer         # Default: 80. Min QA score to PASS (0-100)
  default_model: string         # Default: "sonnet". Default model for workers
  qa_model: string              # Default: "haiku". Default model for QA reviews
  task_budget_usd: float        # Default: 0.50. Default per-task budget
  task_timeout_s: integer       # Default: 600. Default per-task timeout (seconds)
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `max_parallel` | integer | 2 | Maximum workers running simultaneously |
| `max_budget_usd` | float | 10.0 | Total blueprint cost limit (USD) |
| `max_retries` | integer | 3 | Max attempts per task (1st + retries) |
| `qa_threshold` | integer | 80 | Minimum QA score (0-100) to pass |
| `default_model` | string | "sonnet" | Default model: `haiku`\|`sonnet`\|`opus` |
| `qa_model` | string | "haiku" | QA reviewer model |
| `task_budget_usd` | float | 0.50 | Default budget per task |
| `task_timeout_s` | integer | 600 | Default timeout per task |

### FORMIGA Intelligence Config

```yaml
config:
  advisory:
    enabled: string|bool        # Default: "auto". Advisory system: true|false|auto
    frequency: string           # Default: "per_wave". When to run: per_wave
    model: string               # Default: "sonnet". Advisory model

  meta_loop:
    enabled: bool               # Default: true. Enable forge→execute→learn cycles
    max_cycles: integer         # Default: 2. Max improvement cycles
    quorum:
      enabled: string|bool      # Default: "auto". Quorum sensing: true|false|auto

  routing:
    default: string             # Default: "auto". Routing mode: auto|manual
    upgrade_on_retry: bool      # Default: true. Upgrade model on retry 2+
```

#### Advisory System

Coherence review between execution waves. Detects emergent issues.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | string\|bool | "auto" | `true` = always, `false` = never, `auto` = allometry decides |
| `frequency` | string | "per_wave" | When to run. Currently only `per_wave` supported |
| `model` | string | "sonnet" | Model for advisory reviews |

#### Meta-Loop

Self-improvement cycles: forge → execute → learn → re-forge.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | bool | true | Enable meta-loop cycles |
| `max_cycles` | integer | 2 | Max improvement cycles (prevent infinite loops) |
| `quorum.enabled` | string\|bool | "auto" | Quorum sensing: `true`\|`false`\|`auto` (allometry decides) |

#### Routing

Task-to-model assignment intelligence.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `default` | string | "auto" | `auto` = allometry + model selection, `manual` = use task model field |
| `upgrade_on_retry` | bool | true | On retry 2+: haiku→sonnet, sonnet→opus |

---

## Workers

Reusable agent role definitions. Tasks reference workers by name.

```yaml
workers:
  worker_name:
    prompt: string              # Required. Path to worker prompt (relative to .orchestrator/)
    tools: string               # Required. Comma-separated tool list
    model: string               # Optional. Override default_model
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `prompt` | string | Yes | Path to worker prompt file (relative to `.orchestrator/`) |
| `tools` | string | Yes | Comma-separated: `Read,Write,Edit,Grep,Glob,Bash` |
| `model` | string | No | Override `default_model` for this worker |

### Built-in Workers

Pre-configured in `_template.yaml`:

| Worker | Tools | Use Case |
|--------|-------|----------|
| `analyst` | Read, Grep, Glob | Data analysis, audits |
| `writer` | Read, Write, Grep, Glob | Documentation, content |
| `implementer` | Read, Write, Edit, Grep, Glob | Code, structured files |
| `architect` | Read, Grep, Glob | Architecture, design |
| `advisor` | Read, Grep, Glob | Reviews, coherence checks |

### Custom Workers

Create `.orchestrator/workers/{name}.md` and reference in blueprint YAML.

### Example

```yaml
workers:
  analyst:
    prompt: "workers/analyst.md"
    tools: "Read,Grep,Glob"
  implementer:
    prompt: "workers/implementer.md"
    tools: "Read,Write,Edit,Grep,Glob"
    model: "sonnet"               # Override default
```

---

## Tasks

Work units with dependencies, context, QA, and file safety.

### Core Task Fields

```yaml
tasks:
  - id: string                  # Required. Unique task ID
    worker: string              # Required. Worker name (from workers section)
    description: string         # Required. Task description (passed to worker)
    acceptance_criteria: list   # Required. Success criteria (list of strings)
    context_files: list         # Required. Files to read (relative to project_dir)
    output: string              # Required. Output file path (relative to project_dir)
    depends_on: list            # Required. Task IDs this task depends on (empty = Wave 1)
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique task identifier. Used in `depends_on` references |
| `worker` | string | Yes | Worker name from `workers:` section |
| `description` | string | Yes | Task description. Passed to worker via `--query` |
| `acceptance_criteria` | list | Yes | List of success criteria (evaluated by QA) |
| `context_files` | list | Yes | Files worker reads (relative to `project_dir`). Empty = `[]` |
| `output` | string | Yes | Output file path (relative to `project_dir`) |
| `depends_on` | list | Yes | Task IDs this depends on. Empty = Wave 1 (runs first) |

### QA Configuration

```yaml
tasks:
  - id: "task-001"
    # ... core fields ...
    qa:
      criteria: list            # Required. QA-specific criteria
      threshold: integer        # Optional. Override global qa_threshold (0-100)
      model: string             # Optional. Override qa_model
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `criteria` | list | Yes | QA evaluation criteria (in addition to acceptance_criteria) |
| `threshold` | integer | No | Override `config.qa_threshold` for this task |
| `model` | string | No | Override `config.qa_model` (e.g., `"sonnet"` for critical tasks) |

### Override Fields

```yaml
tasks:
  - id: "task-001"
    # ... core fields ...
    model: string               # Optional. Override worker model
    budget_usd: float           # Optional. Override task_budget_usd
    timeout_s: integer          # Optional. Override task_timeout_s
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `model` | string | worker.model or default_model | Override model for this task |
| `budget_usd` | float | task_budget_usd | Override budget for this task |
| `timeout_s` | integer | task_timeout_s | Override timeout for this task |

### FORMIGA Safety Fields (v1.0)

```yaml
tasks:
  - id: "task-001"
    # ... core fields ...
    files_read: list            # Optional. Files read (conflict detection)
    files_write: list           # Optional. Files written (conflict detection)
    expected_format: string     # Optional. Expected format: json|yaml|sh|md
    expected_lines: integer     # Optional. Expected line count (0 = skip)
    override_blacklist: bool    # Optional. Skip negative pheromone check
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `files_read` | list | `[]` | Files read (for parallel safety checks) |
| `files_write` | list | `[]` | Files written (for conflict detection) |
| `expected_format` | string | null | Expected output format. Enables innate immune check |
| `expected_lines` | integer | 0 | Expected line count. 0 = skip check |
| `override_blacklist` | bool | false | If true, skip negative pheromone check |

---

## Example Blueprints

### Minimal Blueprint (Backward Compatible)

```yaml
blueprint:
  id: "simple-001"
  name: "Simple Two-Task Execution"
  project_dir: "D:/my-project"
  nature_code: null

config:
  max_parallel: 1
  max_budget_usd: 5.0
  max_retries: 2
  qa_threshold: 75
  default_model: "haiku"
  qa_model: "haiku"
  task_budget_usd: 0.25
  task_timeout_s: 300

workers:
  analyst:
    prompt: "workers/analyst.md"
    tools: "Read,Grep,Glob"
  writer:
    prompt: "workers/writer.md"
    tools: "Read,Write,Grep,Glob"

tasks:
  - id: "analyze"
    worker: "analyst"
    description: "Analyze metrics.yaml and summarize key findings."
    acceptance_criteria:
      - "Contains quantitative data"
      - "Organized with clear sections"
    context_files:
      - "data/metrics.yaml"
    output: "outputs/analysis.md"
    depends_on: []
    qa:
      criteria:
        - "All numbers cite sources"

  - id: "write-report"
    worker: "writer"
    description: "Write executive summary based on analysis."
    acceptance_criteria:
      - "One page maximum"
      - "3-5 recommendations"
    context_files:
      - "outputs/analysis.md"
    output: "outputs/report.md"
    depends_on: ["analyze"]
    qa:
      criteria:
        - "Under 500 words"
        - "Actionable recommendations"
```

### Standard Blueprint (Advisory + Meta-Loop)

```yaml
blueprint:
  id: "standard-002"
  name: "Four-Task Blueprint with Intelligence"
  project_dir: "D:/my-project"
  nature_code: "ARCH"

config:
  max_parallel: 2
  max_budget_usd: 15.0
  max_retries: 3
  qa_threshold: 80
  default_model: "sonnet"
  qa_model: "haiku"
  task_budget_usd: 0.50
  task_timeout_s: 600

  advisory:
    enabled: true               # Always run advisory
    frequency: "per_wave"
    model: "sonnet"

  meta_loop:
    enabled: true
    max_cycles: 2
    quorum:
      enabled: "auto"           # Allometry decides

  routing:
    default: "auto"
    upgrade_on_retry: true

workers:
  analyst:
    prompt: "workers/analyst.md"
    tools: "Read,Grep,Glob"
  architect:
    prompt: "workers/architect.md"
    tools: "Read,Grep,Glob"
  implementer:
    prompt: "workers/implementer.md"
    tools: "Read,Write,Edit,Grep,Glob"
  writer:
    prompt: "workers/writer.md"
    tools: "Read,Write,Grep,Glob"

tasks:
  # Wave 1: Parallel analysis
  - id: "analyze-code"
    worker: "analyst"
    description: "Analyze codebase structure and patterns."
    acceptance_criteria:
      - "Quantitative metrics (files, lines, functions)"
      - "Pattern identification with examples"
    context_files:
      - "src/"
    output: "outputs/code-analysis.md"
    depends_on: []
    qa:
      criteria:
        - "All metrics cite source files"
    files_read: ["src/**/*.ts"]

  - id: "analyze-docs"
    worker: "analyst"
    description: "Audit documentation completeness."
    acceptance_criteria:
      - "Coverage percentage"
      - "List gaps by priority"
    context_files:
      - "docs/"
    output: "outputs/docs-analysis.md"
    depends_on: []
    qa:
      criteria:
        - "Gap list is prioritized"
    files_read: ["docs/**/*.md"]

  # Wave 2: Architecture
  - id: "design-refactor"
    worker: "architect"
    description: "Design refactoring plan based on analyses."
    acceptance_criteria:
      - "Clear phases with dependencies"
      - "Risk assessment per phase"
    context_files:
      - "outputs/code-analysis.md"
      - "outputs/docs-analysis.md"
    output: "outputs/refactor-plan.md"
    depends_on: ["analyze-code", "analyze-docs"]
    qa:
      criteria:
        - "All phases have risk levels"
        - "Dependencies are clear"

  # Wave 3: Implementation
  - id: "implement-phase1"
    worker: "implementer"
    description: "Implement Phase 1 from refactor plan."
    acceptance_criteria:
      - "All Phase 1 files modified"
      - "No broken references"
    context_files:
      - "outputs/refactor-plan.md"
      - "src/"
    output: "outputs/phase1-summary.md"
    depends_on: ["design-refactor"]
    qa:
      criteria:
        - "All planned files modified"
        - "No syntax errors"
      model: "sonnet"           # Upgrade QA for implementation
    model: "sonnet"
    budget_usd: 1.00            # Higher budget for implementation
    files_write: ["src/core/refactored.ts", "src/utils/helpers.ts"]
    expected_format: "md"
    expected_lines: 50
```

### Full-Featured Blueprint (All FORMIGA Features)

```yaml
blueprint:
  id: "advanced-003"
  name: "Full-Featured Blueprint"
  project_dir: "D:/my-project"
  nature_code: "META"

config:
  max_parallel: 3
  max_budget_usd: 25.0
  max_retries: 3
  qa_threshold: 85
  default_model: "sonnet"
  qa_model: "sonnet"            # Upgrade QA model
  task_budget_usd: 0.75
  task_timeout_s: 900

  advisory:
    enabled: true
    frequency: "per_wave"
    model: "opus"               # Premium advisory

  meta_loop:
    enabled: true
    max_cycles: 2
    quorum:
      enabled: true             # Force quorum sensing

  routing:
    default: "auto"
    upgrade_on_retry: true

workers:
  analyst:
    prompt: "workers/analyst.md"
    tools: "Read,Grep,Glob"
  architect:
    prompt: "workers/architect.md"
    tools: "Read,Grep,Glob"
  implementer:
    prompt: "workers/implementer.md"
    tools: "Read,Write,Edit,Grep,Glob"
    model: "opus"               # Premium worker
  writer:
    prompt: "workers/writer.md"
    tools: "Read,Write,Grep,Glob"

tasks:
  - id: "audit-system"
    worker: "analyst"
    description: "Comprehensive system audit with metrics."
    acceptance_criteria:
      - "Quantitative analysis across all modules"
      - "Risk matrix with severity levels"
    context_files:
      - "src/"
      - "docs/"
      - "config/"
    output: "outputs/audit.yaml"
    depends_on: []
    qa:
      criteria:
        - "Valid YAML format"
        - "All modules covered"
      threshold: 90             # Higher threshold for audit
    files_read: ["src/**/*", "docs/**/*", "config/**/*"]
    expected_format: "yaml"
    expected_lines: 200

  - id: "design-v2"
    worker: "architect"
    description: "Design v2.0 architecture based on audit."
    acceptance_criteria:
      - "ADRs for all major decisions"
      - "Migration path from v1.0"
    context_files:
      - "outputs/audit.yaml"
    output: "outputs/v2-design.md"
    depends_on: ["audit-system"]
    qa:
      criteria:
        - "All ADRs follow template"
        - "Migration is phased"
    model: "opus"               # Complex design task
    budget_usd: 2.00
    files_read: ["outputs/audit.yaml"]
    expected_format: "md"

  - id: "implement-core"
    worker: "implementer"
    description: "Implement v2.0 core module."
    acceptance_criteria:
      - "All functions have unit tests"
      - "TypeScript compiles with no errors"
    context_files:
      - "outputs/v2-design.md"
      - "src/v1/"
    output: "src/v2/core.ts"
    depends_on: ["design-v2"]
    qa:
      criteria:
        - "100% test coverage for new functions"
        - "No TypeScript errors"
      model: "opus"             # Premium QA
    model: "opus"
    budget_usd: 3.00
    timeout_s: 1800             # 30 min timeout
    files_read: ["outputs/v2-design.md", "src/v1/**/*"]
    files_write: ["src/v2/core.ts", "src/v2/core.test.ts"]
    expected_format: "ts"
    expected_lines: 500
    override_blacklist: true    # Experimental, allow despite pattern library warnings
```

---

## File Paths

All file paths in tasks are **relative to `project_dir`**.

### Valid

```yaml
blueprint:
  project_dir: "D:/my-project"

tasks:
  - id: "task-001"
    context_files:
      - "src/index.ts"          # Resolves to D:/my-project/src/index.ts
      - "docs/README.md"        # Resolves to D:/my-project/docs/README.md
    output: "outputs/result.md" # Resolves to D:/my-project/outputs/result.md
```

### Invalid

```yaml
# Don't use absolute paths in tasks
context_files:
  - "D:/my-project/src/index.ts"    # WRONG — use relative
```

---

## Validation

Run validation before execution:

```bash
orchestrate.sh blueprints/my-blueprint.yaml --dry-run
```

Checks:
- YAML syntax
- Required fields present
- Worker references valid
- Task dependencies valid (no cycles)
- File paths resolve correctly

---

## Usage

```bash
# Run blueprint
orchestrate.sh blueprints/my-blueprint.yaml

# Dry-run (validate only)
orchestrate.sh blueprints/my-blueprint.yaml --dry-run

# Resume interrupted blueprint
orchestrate.sh blueprints/my-blueprint.yaml --resume

# Check status
orchestrate.sh blueprints/my-blueprint.yaml --status
```

---

*ATHENA Orchestrated Execution Engine (FORMIGA v1.0)*
*"Structured autonomy at scale."*
