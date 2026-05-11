#!/bin/bash
# save-session-state.sh
INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "n/a"')
DATE=$(date '+%Y-%m-%d %H:%M')
STATE_FILE=".claude/session-state.md"

cat > "$STATE_FILE" << EOF
# Session State (saved: ${DATE} / trigger: ${TRIGGER})

## Branch
$(git branch --show-current 2>/dev/null)

## Uncommitted Changes
$(git diff --name-only 2>/dev/null)
$(git diff --name-only --cached 2>/dev/null | \
  sed 's/^/[staged] /')

## Recent Commits (5)
$(git log --oneline -5 2>/dev/null)

## Change Summary
$(git diff --stat 2>/dev/null | tail -5)
EOF

echo "Session state saved: ${STATE_FILE}" >&2
exit 0
