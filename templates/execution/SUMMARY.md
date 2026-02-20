---
task_id: {task_id}
task_name: {task_name}
story_id: {story_id}
epic_id: {epic_id}
completed_at: {YYYY-MM-DD HH:MM:SS}
duration: {minutes}m
commit: {git_commit_hash}
iterations: {attempt_count}
status: SUCCESS | FAILED | PARTIAL
executor: {claude_instance_id}
---

# Task Execution Summary

## Task Details

**Task:** {task_id} - {task_name}
**Story:** {story_id} - {story_name}
**Epic:** {epic_id} - {epic_name}
**Type:** {auto | manual | review}

### Objective
{what_was_supposed_to_be_done}

### Outcome
{what_was_actually_accomplished}

## Files Changed

| File | Change Type | Lines Added | Lines Deleted | Description |
|------|-------------|-------------|---------------|-------------|
| {file_path} | CREATE/UPDATE/DELETE | {+lines} | {-lines} | {what_changed} |
| {file_path_2} | UPDATE | {+lines} | {-lines} | {what_changed} |

**Total Files:** {count}
**Total Lines Changed:** +{additions} -{deletions}

## Tests Executed

### Unit Tests
| Test Suite | Status | Duration | Passing | Failing |
|------------|--------|----------|---------|---------|
| {test_name} | ✓ PASS | {duration}ms | {pass_count} | {fail_count} |

### Integration Tests
| Test | Status | Notes |
|------|--------|-------|
| {test_name} | ✓ PASS | {notes} |

### Manual Verification
- [x] {verified_item_1}
- [x] {verified_item_2}
- [ ] {not_verified_item} - {reason}

## Execution Timeline

| Step | Duration | Status | Notes |
|------|----------|--------|-------|
| Initial implementation | {duration}m | ✓ | {notes} |
| Test fixes | {duration}m | ✓ | {notes} |
| Code review adjustments | {duration}m | ✓ | {notes} |

**Total Iterations:** {count}

## Issues Encountered

### Issue 1: {Issue_Title}

**Severity:** HIGH | MEDIUM | LOW
**Impact:** {what_was_affected}

**Description:**
{detailed_description_of_issue}

**Resolution:**
{how_it_was_resolved}

**Time Cost:** {minutes}m

---

### Issue 2: {Issue_Title}

**Severity:** {severity}
**Impact:** {impact}

**Description:**
{description}

**Resolution:**
{resolution}

**Time Cost:** {duration}

## Deviations from Plan

| Planned | Actual | Reason |
|---------|--------|--------|
| {planned_approach} | {actual_approach} | {why_changed} |

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| {decision_point} | {choice_made} | {why} |

## Code Quality Metrics

| Metric | Result | Threshold | Status |
|--------|--------|-----------|--------|
| Test Coverage | {percentage}% | {threshold}% | ✓/✗ |
| Lint Errors | {count} | 0 | ✓/✗ |
| Type Errors | {count} | 0 | ✓/✗ |
| Cyclomatic Complexity | {value} | <{threshold} | ✓/✗ |

## Learnings & Notes

### What Went Well
- {positive_1}
- {positive_2}

### What Was Challenging
- {challenge_1}
- {challenge_2}

### Technical Insights
- {insight_1}
- {insight_2}

### Recommendations for Future Tasks
- {recommendation_1}
- {recommendation_2}

## References

### Commits
- [{commit_hash}]({repo_url}/commit/{hash}): {commit_message}

### Pull Requests
- [#{pr_number}]({pr_url}): {pr_title}

### Documentation Updated
- {doc_file_1}: {what_was_documented}

### External Resources Used
- [{resource_name}]({url}): {how_it_helped}

## Next Steps

1. {next_action_1}
2. {next_action_2}
3. {next_action_3}

## Sign-off

**Task Status:** {SUCCESS | FAILED | PARTIAL}
**Ready for Next Task:** {YES | NO | BLOCKED}
**Blocker (if any):** {blocker_description}

---
**Generated:** {YYYY-MM-DD HH:MM:SS}
**Blueprint:** {blueprint_id}
**Session:** {session_id}
