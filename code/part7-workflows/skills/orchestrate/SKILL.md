---
name: orchestrate
description: >
  Select and run the workflow appropriate for the task type
  (feature/bugfix/refactor/security).
  Arguments: feature|bugfix|refactor|security [task name]
disable-model-invocation: true
argument-hint: "[feature|bugfix|refactor|security] [task name]"
---

# Orchestrate: $ARGUMENTS

Select and run the workflow below.

## feature (new feature)
1. Define requirements and acceptance criteria
2. Pre-implementation check (/confidence-check)
3. Create design document (`docs/design/`)
4. Implement with TDD
5. Update documentation

## bugfix (bug fix)
1. Confirm and record reproduction steps
2. Identify root cause (investigate with Grep + Read)
3. Apply the fix with minimal scope
4. Add a regression test
5. Run full regression suite

## refactor (refactoring)
1. Verify test coverage before making changes
2. Migrate incrementally using the Strangler Fig pattern
3. Confirm existing tests pass at each step
4. Measure performance and show improvements with numbers

## security (security response)
1. Investigate scope read-only (no Write)
2. Match against CVE or vulnerability patterns
3. Apply fix in an isolated worktree
4. Verify with security review agent
5. Include CVE number in release notes

## custom
If the argument doesn't match any of the above, describe the task.
