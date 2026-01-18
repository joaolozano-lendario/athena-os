# Contributing to ATHENA OS

First off, thank you for considering contributing to ATHENA OS. It's people like you that make it a better system for everyone.

---

## The ATHENA Way of Contributing

ATHENA OS is a system built on principles. Contributions should embody those same principles:

1. **CONTEXT IS KING** — Your contribution should be self-explanatory
2. **RIGID TAXONOMY** — Follow existing conventions exactly
3. **QUALITY OVER SPEED** — A good contribution later beats a rushed one now
4. **TRANSFERABILITY** — Someone else should understand your changes without explanation

---

## Ways to Contribute

### 1. Example Blueprints

Create example Blueprints that demonstrate ATHENA in action:

**Good examples:**
- Complete Pipeline walkthrough for a common task
- Domain-specific Blueprints (DevOps, Data Science, Design Systems)
- Edge cases that push the system

**Requirements:**
- Must follow full P1→P4 pipeline
- Must pass all gates
- Must be self-contained
- Must include all standard artifacts

**Where to submit:** `examples/`

---

### 2. Templates

Add templates for specific use cases:

**Good templates:**
- Industry-specific Intent Specifications
- Domain-specific Checkpoint Maps
- Specialized Activation Prompts

**Requirements:**
- Must follow existing template structure
- Must include usage documentation
- Must be actually tested (not theoretical)

**Where to submit:** `templates/`

---

### 3. Knowledge Base

Expand the knowledge base:

**Good additions:**
- New cognitive principles with documentation
- Proven patterns from real usage
- Anti-patterns with examples

**Requirements:**
- Must be principle-based, not opinion-based
- Must include practical application
- Must reference ATHENA principles

**Where to submit:** `knowledge/`

---

### 4. Documentation Improvements

Help clarify existing documentation:

**Good improvements:**
- Clearer explanations of complex concepts
- Additional examples where helpful
- Translations (creating `/docs/lang/{language}/`)
- Fixing errors or inconsistencies

**Requirements:**
- Must maintain existing tone (precise, authoritative, calm)
- Must not add unnecessary verbosity
- Must follow existing structure

---

### 5. Bug Reports

Found something that doesn't work as documented?

**A good bug report includes:**
- What you expected to happen
- What actually happened
- Steps to reproduce
- Which files/commands were involved

**Where to submit:** GitHub Issues

---

### 6. Feature Suggestions

Have an idea for improving ATHENA?

**A good feature suggestion includes:**
- The problem it solves
- How it aligns with ATHENA principles
- Proposed implementation approach
- Potential drawbacks

**Where to submit:** GitHub Issues with `[FEATURE]` prefix

---

## Contribution Process

### Step 1: Fork and Clone

```bash
# Fork the repo on GitHub, then:
git clone https://github.com/YOUR-USERNAME/athena-os.git
cd athena-os
```

### Step 2: Create a Branch

```bash
git checkout -b contribution/your-contribution-name
```

**Branch naming:**
- `contribution/example-payment-api`
- `contribution/template-data-pipeline`
- `contribution/docs-spanish-translation`
- `contribution/fix-taxonomy-typo`

### Step 3: Make Your Changes

Follow the guidelines for your contribution type above.

### Step 4: Test Your Contribution

For examples and templates:
- Actually run them through ATHENA
- Verify all gates pass
- Ensure artifacts are complete

For documentation:
- Read it as if you've never seen ATHENA
- Check all links work
- Verify code blocks are correct

### Step 5: Commit

```bash
git add .
git commit -m "Add: description of what you added"
```

**Commit message format:**
- `Add: new payment API example Blueprint`
- `Fix: typo in P2-ARCHITECT protocol`
- `Update: clarify Gate G1 criteria`
- `Docs: add Spanish translation of MANIFESTO`

### Step 6: Push and Create PR

```bash
git push origin contribution/your-contribution-name
```

Then create a Pull Request on GitHub.

---

## Pull Request Requirements

Your PR description must include:

1. **What** — What does this contribution add/change?
2. **Why** — Why is this valuable to ATHENA users?
3. **How** — How does it align with ATHENA principles?
4. **Testing** — How did you verify it works?

**Template:**

```markdown
## What
[Describe your contribution]

## Why
[Explain the value]

## Alignment with ATHENA Principles
- [ ] CONTEXT IS KING - My contribution is self-explanatory
- [ ] RIGID TAXONOMY - I followed existing conventions
- [ ] QUALITY OVER SPEED - I took time to do this right
- [ ] TRANSFERABILITY - Someone else can understand this

## Testing
[How you verified this works]

## Checklist
- [ ] I have read the CONTRIBUTING.md
- [ ] My contribution follows existing style
- [ ] I have tested my changes
- [ ] I have updated relevant documentation
```

---

## Style Guide

### Markdown

- Use ATX-style headers (`#`, `##`, `###`)
- Use fenced code blocks with language hints
- One blank line between sections
- Use tables for structured comparisons
- Use blockquotes (`>`) for key insights

### YAML

- 2-space indentation
- Use quotes for strings with special characters
- Comments for non-obvious values
- Consistent key ordering within files

### Naming

- Files: `lowercase-with-hyphens.md`
- Folders: `lowercase-with-hyphens/`
- IDs: `TYPE-YYYY-MM-DD-NNN`
- Timestamps: ISO-8601 with timezone

### Language

- Clear, direct sentences
- Active voice preferred
- No jargon without explanation
- Technical terms defined on first use
- Avoid unnecessary words

---

## What We Don't Accept

### Philosophical Deviations

ATHENA has core principles. Contributions that contradict these principles will not be accepted, regardless of quality:

- Suggestions to "make gates optional"
- Proposals to "simplify" taxonomy
- Ideas that prioritize speed over rigor
- Changes that reduce transferability

### Untested Contributions

We don't accept theoretical contributions:

- Example Blueprints that weren't actually used
- Templates that weren't tested in practice
- Patterns without real-world validation

### Style Inconsistencies

ATHENA has a specific tone and style. Contributions must match:

- No excessive emojis
- No casual/informal language
- No unexplained opinions
- No redundant documentation

---

## Questions?

If you're unsure whether your contribution is appropriate:

1. Open a GitHub Issue with `[QUESTION]` prefix
2. Describe what you want to contribute
3. Ask for guidance before starting

We'd rather help you succeed than reject good work done wrong.

---

## Recognition

All contributors are recognized in the following ways:

- Git commit history
- Contributors section in documentation (for significant contributions)
- Release notes mentions

---

## Code of Conduct

Be respectful. Be constructive. Be ATHENA.

- Critique ideas, not people
- Assume good intentions
- Provide specific, actionable feedback
- Help others succeed

---

*"A system is only as good as the community that builds it."*

Thank you for making ATHENA OS better.

---

*ATHENA OS v1.0.0*
