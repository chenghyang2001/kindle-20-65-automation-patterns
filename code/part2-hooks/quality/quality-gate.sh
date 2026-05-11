#!/bin/bash
# quality-gate.sh
INPUT=$(cat)
# Guard against infinite loops: exit if stop_hook is already running
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi
ISSUES=()
# Check for uncommitted changes
UNCOMMITTED=$(git diff --name-only 2>/dev/null)
STAGED=$(git diff --name-only --cached 2>/dev/null)
if [ -n "$UNCOMMITTED" ] || [ -n "$STAGED" ]; then
  ISSUES+=("Uncommitted changes detected")
fi
# Check for remaining TODO markers
TODO_COUNT=$(grep -r "<!-- TODO -->" src/ 2>/dev/null | wc -l | tr -d ' ')
if [ "$TODO_COUNT" -gt 0 ]; then
  ISSUES+=("${TODO_COUNT} TODO marker(s) remaining")
fi
if [ ${#ISSUES[@]} -gt 0 ]; then
  jq -n \
    --arg reason "$(printf '%s\n' "${ISSUES[@]}" | \
      awk '{print NR". "$0}')" \
    '{"decision": "block", "reason": $reason}'
  exit 0
fi
exit 0
