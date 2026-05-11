---
name: analyze-patterns
description: Analyze accumulated operation logs and suggest skill candidates.
disable-model-invocation: true
---

# Pattern Analysis

Analyze the following logs and extract patterns that are good candidates for Skills.

Log file: !`tail -200 ~/.claude/logs/patterns.jsonl | jq -s .`

## Analysis Criteria
- Detect command sequences repeated 3 or more times
- Confidence score: (occurrence count / total operations) × 100
- Confidence ≥ 70% → output as a skill candidate
- Confidence 40–70% → continue observing
- Confidence < 40% → not a candidate

## Output Format
| Pattern | Occurrences | Confidence | Suggested Skill Name |
|---------|-------------|------------|----------------------|
