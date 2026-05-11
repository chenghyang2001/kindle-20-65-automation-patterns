---
name: confidence-check
description: >
  Pre-implementation checklist. Clear at least 4 of 5 items (≥ 90%) before starting.
  Always run before new features or large-scale changes.
disable-model-invocation: true
---

# Pre-Implementation Checklist

**Implementation task**: $ARGUMENTS

Verify the following 5 items and answer each with PASS / FAIL / SKIP.

## C1: Duplicate Implementation Check
- Run `grep -r "RelatedClassName\|relatedFunctionName" --include="*.{ts,py,go}" src/`
- Confirm no equivalent functionality exists in the codebase
- FAIL if existing code can be extended (new implementation unnecessary)

## C2: Architecture Compliance Check
- Review the architecture constraints in `CLAUDE.md`
- Confirm no violations of dependency direction, layer separation, or naming conventions

## C3: Official Documentation Check
- Review official docs for the libraries or frameworks to be used
- Confirm the planned APIs are valid in the current version

## C4: OSS Reference Check
- Check whether any OSS implements a similar pattern
- Evaluate whether reinventing the wheel can be avoided

## C5: Root Cause Identification Check
- For bug fixes or performance improvements: has the root cause been identified?
- For new features: has the user's actual need been confirmed?

---

## Score Calculation
- PASS count: N / 5
- ≥ 90% (4 / 5 or more) → Implementation is clear to start
- ≤ 60% (2 / 5 or fewer) → Stop and re-investigate

List the reason and remediation for each FAIL or SKIP item.
