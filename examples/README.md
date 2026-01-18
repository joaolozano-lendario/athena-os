# ATHENA OS — Example Blueprints

> Reference implementations demonstrating the ATHENA OS pipeline

---

## Available Examples

### 1. SaaS MVP Architecture — User Management Module

**Location:** `/examples/saas-mvp-architecture/`

**Complexity:** MEDIUM

**Description:** A complete Blueprint for implementing a User Management Module in a SaaS MVP application. Covers authentication, authorization, profile management, and multi-tenancy.

**Files:**
- `BLUEPRINT.md` — Master document (5 epics, 12 stories, 34 tasks)
- `ACTIVATION.md` — Ready-to-paste execution prompt
- `intent-spec.yaml` — Structured intent specification
- `checkpoint-map.yaml` — Complete work breakdown
- `_metadata.yaml` — Blueprint metadata

**What It Demonstrates:**
- Complete Intent Specification with all dimensions (WHAT, WHY, WHO, WHERE, WHEN, HOW)
- Multi-phase Execution Architecture with agents
- Atomic task decomposition with binary acceptance criteria
- Task dependencies and critical path identification
- Security warnings on sensitive operations
- Full Activation Prompt ready for execution

**Ideal For:**
- Understanding how a complete Blueprint looks
- Starting a new SaaS project
- Learning the ATHENA methodology

---

## Using These Examples

### As Learning Material

Read the examples to understand:
1. How intentions are decoded into specifications
2. How specifications become architectures
3. How architectures fragment into tasks
4. How everything crystallizes into a Blueprint

### As Templates

Copy and adapt:
1. Copy the example folder structure
2. Replace content with your specific needs
3. Run through `/ATHENA:tasks:forge-blueprint`
4. Let ATHENA guide you through the pipeline

### As Validation

Compare your Blueprints:
1. Generate a Blueprint for a similar task
2. Compare structure and detail level
3. Ensure your Blueprint has similar completeness

---

## Example Quality Standards

All examples in this folder meet ATHENA standards:

- [ ] **G1 PASSED** — Intent is unambiguously clear
- [ ] **G2 PASSED** — Architecture is logical and executable
- [ ] **G3 PASSED** — All work mapped to atomic tasks
- [ ] **G4 PASSED** — Blueprint is self-contained and transferable

---

## Contributing Examples

Want to add an example? See [CONTRIBUTING.md](/CONTRIBUTING.md).

Requirements:
- Must be a complete Blueprint (all phases)
- Must pass all gates
- Must be actually tested (not theoretical)
- Must include all standard files

---

*"The best way to understand ATHENA is to see it in action."*
