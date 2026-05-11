# Cost Monitoring Guide

## Usage Data Sources

Claude Code exposes cost and usage data through several channels.

### 1. Session-level Usage (--output-format json)

```bash
claude -p "analyze this codebase" \
  --output-format json | jq '.usage'
```

Output example:
```json
{
  "input_tokens": 12450,
  "output_tokens": 3200,
  "cache_read_input_tokens": 8900,
  "cache_creation_input_tokens": 0
}
```

### 2. Transcript Analysis

```bash
# Count tool calls in a session transcript
grep -c '"type":"tool_use"' ~/.claude/projects/*/transcripts/*.jsonl
```

### 3. Cost Estimation Script

```bash
#!/bin/bash
# estimate-cost.sh — rough cost estimate from transcript
TRANSCRIPT=${1:?"Usage: estimate-cost.sh <transcript.jsonl>"}

INPUT=$(grep -o '"input_tokens":[0-9]*' "$TRANSCRIPT" | \
  awk -F: '{s+=$2} END {print s}')
OUTPUT=$(grep -o '"output_tokens":[0-9]*' "$TRANSCRIPT" | \
  awk -F: '{s+=$2} END {print s}')

# Sonnet 4 pricing (per million tokens)
INPUT_COST=$(echo "scale=4; $INPUT * 3 / 1000000" | bc)
OUTPUT_COST=$(echo "scale=4; $OUTPUT * 15 / 1000000" | bc)
TOTAL=$(echo "scale=4; $INPUT_COST + $OUTPUT_COST" | bc)

echo "Input:  $INPUT tokens (\$$INPUT_COST)"
echo "Output: $OUTPUT tokens (\$$OUTPUT_COST)"
echo "Total:  \$$TOTAL"
```

## Hook-based Cost Alerting

Trigger a warning when tool call count crosses a threshold:

```bash
# In suggest-compact.sh (PreToolUse or SubagentStop hook)
if [[ "$TOOL_COUNT" -gt 0 && $(( TOOL_COUNT % 50 )) -eq 0 ]]; then
  echo "Consider running /compact (tool calls: ${TOOL_COUNT})" >&2
fi
```

## Reducing Cost with Prompt Caching

Keep stable content at the top of CLAUDE.md. See `docs/cache-design-guide.md`.

## Cost Allocation by Project

Use separate CLAUDE.md files per project so each session's context reflects
only the relevant project, avoiding unnecessary token consumption from
unrelated instructions.
