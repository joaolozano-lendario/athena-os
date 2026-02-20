---
blueprint_id: {BP-YYYY-MM-DD-NNN}
started_at: {YYYY-MM-DD HH:MM:SS}
status: IN_PROGRESS
executor: {claude_instance_id}
last_updated: {YYYY-MM-DD HH:MM:SS}
---

# Execution State

## Current Position
- **Epic:** {epic_id} - {epic_name}
- **Story:** {story_id} - {story_name}
- **Task:** {task_id} - {task_name}

## Progress Overview

| Epic | Status | Progress | Tasks Completed | Total Tasks |
|------|--------|----------|-----------------|-------------|
| E1   | ✓      | 100%     | 12/12           | 12          |
| E2   | →      | 45%      | 5/11            | 11          |
| E3   | ○      | 0%       | 0/8             | 8           |

**Legend:** ✓ Complete | → In Progress | ○ Not Started

## Execution Metrics

| Metric | Value |
|--------|-------|
| Iterations | {count} |
| Time elapsed | {duration_in_hours}h {minutes}m |
| Token estimate | {tokens_consumed} / {tokens_budgeted} |
| Commits created | {commit_count} |
| Tests run | {test_count} |

## Active Blockers

| Blocker | Severity | Impact | Mitigation |
|---------|----------|--------|------------|
| {blocker_description} | HIGH/MED/LOW | {affected_tasks} | {mitigation_strategy} |

## Next Actions

1. **Immediate:** {next_task_description}
2. **Queued:** {queued_task}
3. **On Hold:** {blocked_task}

## Session History

| Session | Date | Duration | Tasks Completed | Notes |
|---------|------|----------|-----------------|-------|
| 1 | {date} | {duration} | {tasks} | {notes} |

## Notes
{execution_notes}
