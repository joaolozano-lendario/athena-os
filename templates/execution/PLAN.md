# {Epic_ID}-{Story_ID} Execution Plan

## Story Overview

**Story:** {story_name}
**Epic:** {epic_name}
**Type:** {feature | bugfix | refactor | test | docs}
**Estimated Tasks:** {task_count}
**Status:** {NOT_STARTED | IN_PROGRESS | COMPLETED}

### Description
{story_description}

### Acceptance Criteria
- [ ] {criterion_1}
- [ ] {criterion_2}
- [ ] {criterion_3}

## Task Breakdown

### Task 1: {Task_Name}

<task type="auto" status="pending">
  <name>Task 1: {descriptive_task_name}</name>

  <files>
    - {path/to/file1.ts}
    - {path/to/file2.ts}
  </files>

  <action>
    {detailed_description_of_what_to_do}

    Steps:
    1. {step_1}
    2. {step_2}
    3. {step_3}
  </action>

  <verify>
    {command_to_run_for_verification}
    # Example: npm test -- {test_file}
  </verify>

  <done>
    - {acceptance_criterion_1}
    - {acceptance_criterion_2}
    - Tests passing
    - No lint errors
  </done>
</task>

---

### Task 2: {Task_Name}

<task type="manual" status="pending">
  <name>Task 2: {descriptive_task_name}</name>

  <files>
    - {path/to/file3.ts}
  </files>

  <action>
    {what_to_do}
  </action>

  <verify>
    {verification_command_or_manual_check}
  </verify>

  <done>
    - {done_criterion}
  </done>
</task>

---

### Task 3: {Task_Name}

<task type="review" status="pending">
  <name>Task 3: {descriptive_task_name}</name>

  <files>
    - {path/to/changed/files}
  </files>

  <action>
    Review and validate:
    - {what_to_review_1}
    - {what_to_review_2}
  </action>

  <verify>
    Manual review checklist:
    - [ ] {check_1}
    - [ ] {check_2}
  </verify>

  <done>
    - All checks passed
    - Documentation updated
  </done>
</task>

## Dependencies

### Prerequisite Tasks
- **Requires:** {task_id_or_story_id} - {description}
- **Requires:** {epic_id} to reach {milestone}

### Blocking Tasks
- **Blocks:** {task_id} - {reason}

### External Dependencies
- {dependency_1}: {status}
- {dependency_2}: {status}

## Technical Context

### Required Knowledge
- {knowledge_area_1}
- {knowledge_area_2}

### Key Files
| File | Purpose | Modification Type |
|------|---------|-------------------|
| {file_path} | {purpose} | CREATE/UPDATE/DELETE |

### Relevant Documentation
- [{doc_name}]({path_or_url})

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| {risk_description} | HIGH/MED/LOW | HIGH/MED/LOW | {mitigation_strategy} |

## Verification Strategy

### Unit Tests
```bash
{test_command_1}
{test_command_2}
```

### Integration Tests
```bash
{integration_test_command}
```

### Manual Verification
- [ ] {manual_check_1}
- [ ] {manual_check_2}

## Rollback Plan

**If this story fails:**
1. {rollback_step_1}
2. {rollback_step_2}

**Commits to revert:** {commit_range_or_strategy}

---
**Created:** {YYYY-MM-DD HH:MM:SS}
**Last Updated:** {YYYY-MM-DD HH:MM:SS}
**Task Types:** auto (automated execution) | manual (requires human input) | review (verification only)
