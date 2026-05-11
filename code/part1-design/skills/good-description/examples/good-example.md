---
name: code-review
description: >
  Run a code review. Handles PR reviews, code checks, quality checks,
  security audits, and bug detection. Responds to requests like
  "review this code", "check this PR", "what do you think of this code?".
---

# Code Review

Review code from the following angles.

## Security
- Proper authentication and authorization
- SQL injection and XSS risks
- Hardcoded secrets or credentials

## Quality
- Clarity of function and variable names
- Duplicate code
- Adequate error handling

## Performance
- Unnecessary loops or N+1 queries
- Caching opportunities

Report each issue classified by severity (Critical / Warning / Suggestion).
