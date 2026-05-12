#!/bin/bash
# json-output-patterns.sh - Usage patterns for --output-format json
# Adapted for: kindle-20-65-automation-patterns project
#
# Run from the project root:
#   cd C:/Users/B00332/workspace/kindle-20-65-automation-patterns
#   bash code/part4-cicd/scripts/json-output-patterns.sh

# ── Pattern 1: Extract only the response text ────────────────────────────────
echo -e "\n▶ Pattern 1: --output-format json | jq -r '.result'" >&2
claude -p "List all hook scripts in code/part2-hooks/ and what each one does in one sentence each." \
  --allowedTools "Glob,Read" \
  --output-format json < /dev/null | jq -r '.result'

# ── Pattern 2: Save session ID for later steps ───────────────────────────────
echo -e "\n▶ Pattern 2: save session_id for --resume" >&2
SESSION=$(claude -p "Analyze all hook scripts in code/part2-hooks/ and understand their purpose and trigger events." \
  --allowedTools "Glob,Read" \
  --output-format json < /dev/null | jq -r '.session_id')
echo "Captured session_id: $SESSION" >&2
echo "(Use: claude -p \"...\" --resume \$SESSION to continue with this context)" >&2

# ── Pattern 3: Enforce output schema with --json-schema ──────────────────────
echo -e "\n▶ Pattern 3: --json-schema to enforce structured output" >&2
claude -p "List all .sh hook script filenames found in code/part2-hooks/ recursively. Return only filenames, no paths." \
  --allowedTools "Glob" \
  --output-format json \
  --json-schema '{
    "type": "object",
    "properties": {
      "hooks": {
        "type": "array",
        "items": {"type": "string"}
      }
    },
    "required": ["hooks"]
  }' < /dev/null | jq '.structured_output'

# ── Pattern 4: Process in real time with stream-json ─────────────────────────
echo -e "\n▶ Pattern 4: --output-format stream-json (real-time token streaming)" >&2
claude -p "Read code/part2-hooks/quality/quality-gate.sh and explain what it does in 3 sentences." \
  --allowedTools "Read" \
  --output-format stream-json \
  --verbose \
  --include-partial-messages < /dev/null | \
  jq -rj 'select(.type == "stream_event" and
    .event.delta.type? == "text_delta") |
    .event.delta.text'
echo "" >&2
