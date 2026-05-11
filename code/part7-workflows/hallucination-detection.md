# Hallucination Detection Guide

## Four Verification Questions

Ask Claude the following questions before and after implementation.

```text
Q1: "Please provide the official documentation URL and the relevant section
    for each function or method you used in this implementation."
    → If Claude cannot cite a real URL, verify independently.

Q2: "What version is required to run this code?
    Did you confirm that constraint in the official documentation?"
    → "I haven't checked" signals hallucination risk.

Q3: "Are there alternative implementations? What are the trade-offs of each?"
    → Unable to name any alternatives may indicate narrow or incorrect understanding.

Q4: "Name three cases or edge cases where this implementation would fail."
    → Cannot name failure cases suggests shallow understanding of the implementation.
```

## Seven Red Flags

```text
RF1: "It should be...", "Probably...", "It seems..."
     → Presenting uncertain information as fact.

RF2: Figures without citations
     → "30% faster", "memory usage cut in half" — unsubstantiated benchmarks.

RF3: Mixed old and new syntax
     → New library API mixed with old version syntax.

RF4: Non-existent options or flags
     → CLI flags that don't actually exist; config keys that aren't valid.

RF5: Error messages that don't match documentation
     → Error handling in code examples uses wrong exception class names.

RF6: Overly optimistic description
     → Implementation description with no mention of constraints, caveats, or failure cases.

RF7: Contradiction with a previous answer
     → Different information provided for the same topic within the same session.
```

## Hallucination Response Flow

```text
Red flag detected
  → Check local docs at ~/.claude/docs/
  → Cannot confirm → mark as "(verify)" and hold
  → Contradiction found → replace with correct information
  → After correction, re-verify with Q1–Q4
```

## Usage Tips

- The four questions use a "have Claude validate its own answers" approach
- The seven red flags are observed by the human reviewer
- Whenever "It should be..." appears, make it a habit to check official documentation
- Hallucination is not a capability failure — it's a structural property of LLMs
- "Your answer is wrong" produces less accurate corrections than
  "Please verify this information in the documentation"
