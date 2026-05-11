#!/bin/bash
INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
TOOL_COUNT=0
if [[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]]; then
  TOOL_COUNT=$(grep -c '"type":"tool_use"' "$TRANSCRIPT" 2>/dev/null || echo 0)
fi

if [[ "$TOOL_COUNT" -gt 0 && $(( TOOL_COUNT % 50 )) -eq 0 ]]; then
  echo "Consider checking context usage and running /compact (tool calls: ${TOOL_COUNT})" >&2
fi
exit 0
