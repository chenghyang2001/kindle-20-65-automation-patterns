#!/bin/bash
# json-output-patterns.sh - Usage patterns for --output-format json

# Extract only the response text
claude -p "Summarize this project" \
  --output-format json | jq -r '.result'

# Save session ID for later steps
SESSION=$(claude -p "Review the code" \
  --output-format json | jq -r '.session_id')

# Enforce output schema with --json-schema
claude -p "Extract all function names from auth.py" \
  --output-format json \
  --json-schema '{
    "type": "object",
    "properties": {
      "functions": {
        "type": "array",
        "items": {"type": "string"}
      }
    },
    "required": ["functions"]
  }' | jq '.structured_output'

# Process in real time with stream-json
claude -p "Execute the large-scale refactoring" \
  --output-format stream-json \
  --verbose \
  --include-partial-messages | \
  jq -rj 'select(.type == "stream_event" and
    .event.delta.type? == "text_delta") |
    .event.delta.text'
