#!/bin/bash
# restore-context.sh
# Context injection for post-compact sessions

BRANCH=$(git branch --show-current 2>/dev/null)
RECENT=$(git log --oneline -3 2>/dev/null)
UNCOMMITTED=$(git status --short 2>/dev/null | head -10)
SESSION_STATE=".claude/session-state.md"

echo "## Restored Session Context"
echo ""
echo "### Branch: ${BRANCH}"
echo ""
echo "### Recent Commits"
echo "$RECENT"
echo ""

if [ -n "$UNCOMMITTED" ]; then
  echo "### Uncommitted Changes"
  echo "$UNCOMMITTED"
  echo ""
fi

# Append previous session state if it exists
if [ -f "$SESSION_STATE" ]; then
  echo "### Previous Session State"
  cat "$SESSION_STATE"
fi
