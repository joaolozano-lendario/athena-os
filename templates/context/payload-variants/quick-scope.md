# Quick-Scope Payload Template

**Use Case:** Simple, atomic tasks with clear inputs/outputs
**Token Budget:** 500-1500 tokens
**Complexity:** Low
**Best For:** Data extraction, formatting, simple transformations, quick analysis

---

## PERSONA

{persona_brief}

---

## OBJECTIVE

{single_objective}

---

## CONSTRAINTS

- {constraint_1}
- {constraint_2}
- {constraint_3}

---

## FORMAT

{output_format}

---

## USAGE NOTES

### When to Use Quick-Scope

- Task is well-defined with single objective
- Input/output relationship is clear
- Minimal context needed
- No multi-step reasoning required
- Speed is priority over depth

### Customization Points

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{persona_brief}` | 1-2 sentence role definition | "You are a data analyst specializing in CSV operations." |
| `{single_objective}` | One clear action verb + target | "Extract all email addresses from the provided text and deduplicate them." |
| `{constraint_N}` | Hard boundaries or rules | "Maximum 100 results", "US date format only", "No external API calls" |
| `{output_format}` | Exact format specification | "JSON array of strings", "Markdown table with columns: Name, Email, Status" |

### Anti-Patterns to Avoid

- Multiple objectives (split into separate payloads)
- Vague constraints ("make it good")
- Ambiguous output format ("something useful")
- Complex multi-step reasoning (use deep-context instead)

---

## EXAMPLES

### Example 1: Email Extraction

```markdown
## PERSONA
You are a data extraction specialist.

## OBJECTIVE
Extract all unique email addresses from the provided customer feedback text.

## CONSTRAINTS
- Only valid email formats (RFC 5322 compliant)
- Remove duplicates (case-insensitive)
- Sort alphabetically

## FORMAT
Plain text list, one email per line.
```

---

### Example 2: Date Normalization

```markdown
## PERSONA
You are a data transformation specialist focusing on temporal data.

## OBJECTIVE
Convert all dates in the input CSV to ISO 8601 format (YYYY-MM-DD).

## CONSTRAINTS
- Preserve all other columns unchanged
- Handle MM/DD/YYYY, DD-MM-YYYY, and "Month DD, YYYY" formats
- Invalid dates should output "INVALID_DATE"

## FORMAT
CSV with same structure as input, only date column modified.
```

---

### Example 3: Text Summarization

```markdown
## PERSONA
You are a technical documentation specialist.

## OBJECTIVE
Create a 2-sentence summary of the provided API documentation section.

## CONSTRAINTS
- Maximum 50 words total
- Include the primary function name
- Target audience: developers with 2+ years experience

## FORMAT
Plain text, two sentences separated by a space.
```

---

## QUALITY CHECKLIST

Before deploying a Quick-Scope payload:

- [ ] Single, atomic objective clearly stated
- [ ] Persona directly relevant to objective
- [ ] All constraints are testable/measurable
- [ ] Output format leaves zero ambiguity
- [ ] No hidden assumptions about context
- [ ] Could be executed by someone unfamiliar with broader project

---

**Template Version:** 1.0.0
**Last Updated:** 2026-01-20
**Part of:** ATHENA OS Context Engineering System
