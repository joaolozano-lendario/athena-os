# {Epic_ID}: {Epic_Name} - Verification Report

## Epic Overview

**Epic:** {epic_id} - {epic_name}
**Blueprint:** {blueprint_id}
**Verification Date:** {YYYY-MM-DD HH:MM:SS}
**Verified By:** {executor_id}
**Status:** PASS | FAIL | PARTIAL

## Automated Tests

### Unit Tests

| Test Suite | Status | Tests | Passed | Failed | Skipped | Coverage | Duration |
|------------|--------|-------|--------|--------|---------|----------|----------|
| {suite_name} | ✓ PASS | {total} | {passed} | {failed} | {skipped} | {coverage}% | {duration}ms |
| {suite_name_2} | ✗ FAIL | {total} | {passed} | {failed} | {skipped} | {coverage}% | {duration}ms |

**Summary:**
- Total Suites: {count}
- Total Tests: {count}
- Pass Rate: {percentage}%
- Coverage: {percentage}%

### Integration Tests

| Test | Status | Duration | Notes |
|------|--------|----------|-------|
| {test_name} | ✓ PASS | {duration}ms | {notes} |
| {test_name_2} | ✗ FAIL | {duration}ms | {failure_reason} |

### End-to-End Tests

| Scenario | Status | Browser | Duration | Screenshots |
|----------|--------|---------|----------|-------------|
| {scenario_name} | ✓ PASS | {browser} | {duration}s | {path/to/screenshots} |

## Build Status

### Development Build
```
{build_output}
```

**Status:** ✓ SUCCESS | ✗ FAILED
**Duration:** {duration}s
**Artifacts:** {artifact_paths}

### Production Build
```
{production_build_output}
```

**Status:** ✓ SUCCESS | ✗ FAILED
**Duration:** {duration}s
**Size:** {bundle_size}
**Artifacts:** {artifact_paths}

## Static Analysis

### Linting

| Tool | Status | Errors | Warnings | Files Checked |
|------|--------|--------|----------|---------------|
| ESLint | ✓ PASS | 0 | {warning_count} | {file_count} |
| Prettier | ✓ PASS | 0 | 0 | {file_count} |

### Type Checking

| Tool | Status | Errors | Files |
|------|--------|--------|-------|
| TypeScript | ✓ PASS | 0 | {file_count} |

**Output:**
```
{typecheck_output}
```

### Security Scanning

| Tool | Status | Critical | High | Medium | Low |
|------|--------|----------|------|--------|-----|
| {scanner_name} | ✓ PASS | 0 | 0 | {count} | {count} |

## Performance Metrics

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Page Load Time | {value}ms | <{threshold}ms | ✓/✗ |
| Time to Interactive | {value}ms | <{threshold}ms | ✓/✗ |
| Bundle Size | {value}kb | <{threshold}kb | ✓/✗ |
| Lighthouse Score | {score}/100 | >{threshold} | ✓/✗ |

## UAT Checklist

### Functional Requirements
- [x] {requirement_1} - Verified by {who} on {date}
- [x] {requirement_2} - Verified by {who} on {date}
- [ ] {requirement_3} - NOT VERIFIED - {reason}

### Non-Functional Requirements
- [x] Performance meets SLA
- [x] Accessibility (WCAG 2.1 AA)
- [x] Cross-browser compatibility
- [x] Mobile responsiveness
- [ ] {nfr_item} - {status}

### User Stories Acceptance
| Story | Acceptance Criteria Met | Verified By | Date |
|-------|-------------------------|-------------|------|
| {story_id} | ✓ {count}/{total} | {name} | {YYYY-MM-DD} |

## Manual Testing

### Test Scenarios

#### Scenario 1: {Scenario_Name}
**Status:** ✓ PASS | ✗ FAIL
**Tested By:** {tester_name}
**Date:** {YYYY-MM-DD}

**Steps:**
1. {step_1} - ✓ PASS
2. {step_2} - ✓ PASS
3. {step_3} - ✗ FAIL - {reason}

**Notes:** {testing_notes}

---

#### Scenario 2: {Scenario_Name}
**Status:** {status}
**Tested By:** {tester_name}
**Date:** {YYYY-MM-DD}

**Steps:**
1. {step_1} - {status}
2. {step_2} - {status}

**Notes:** {notes}

## Regression Testing

| Area | Tests Run | Passed | Failed | Notes |
|------|-----------|--------|--------|-------|
| {feature_area} | {count} | {passed} | {failed} | {notes} |

## Known Issues

| Issue | Severity | Impact | Mitigation | Tracked In |
|-------|----------|--------|------------|------------|
| {issue_description} | HIGH/MED/LOW | {impact} | {mitigation} | {ticket_id} |

## Deployment Readiness

### Pre-Deployment Checklist
- [x] All critical tests passing
- [x] No critical security vulnerabilities
- [x] Documentation updated
- [x] Migration scripts tested
- [x] Rollback plan documented
- [ ] {item} - {status}

### Environment Verification

| Environment | Status | URL | Verified By | Date |
|-------------|--------|-----|-------------|------|
| Development | ✓ PASS | {url} | {who} | {date} |
| Staging | ✓ PASS | {url} | {who} | {date} |
| Production | PENDING | {url} | - | - |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation Status |
|------|------------|--------|-------------------|
| {risk} | HIGH/MED/LOW | HIGH/MED/LOW | MITIGATED/OPEN |

## Sign-off

### Technical Sign-off
- **Status:** APPROVED | REJECTED | CONDITIONAL
- **Signed By:** {technical_lead_name}
- **Date:** {YYYY-MM-DD}
- **Comments:** {comments}

### Product Sign-off
- **Status:** APPROVED | REJECTED | CONDITIONAL
- **Signed By:** {product_owner_name}
- **Date:** {YYYY-MM-DD}
- **Comments:** {comments}

### Quality Assurance Sign-off
- **Status:** APPROVED | REJECTED | CONDITIONAL
- **Signed By:** {qa_lead_name}
- **Date:** {YYYY-MM-DD}
- **Comments:** {comments}

## Final Verdict

**Epic Status:** APPROVED FOR DEPLOYMENT | NEEDS WORK | BLOCKED
**Deployment Authorized:** YES | NO
**Deployment Date:** {YYYY-MM-DD} or PENDING

### Conditions (if conditional approval)
1. {condition_1}
2. {condition_2}

### Next Steps
1. {next_step_1}
2. {next_step_2}

---
**Verification Report Generated:** {YYYY-MM-DD HH:MM:SS}
**Blueprint:** {blueprint_id}
**Report Version:** 1.0
