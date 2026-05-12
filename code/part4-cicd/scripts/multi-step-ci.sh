#!/bin/bash
# multi-step-ci.sh - Session continuity across claude -p calls (--resume pattern)
# Adapted for: kindle-20-65-automation-patterns project
#
# Run from the project root:
#   cd C:/Users/B00332/workspace/kindle-20-65-automation-patterns
#   bash code/part4-cicd/scripts/multi-step-ci.sh
#
# Key concept: SESSION_ID captured in Step 1 is reused in Steps 2 & 3.
# Claude remembers the full analysis context without re-reading any files.

set -e

# ── Step 1: Analyze hooks and capture session ID ──────────────────────────────
echo -e "\n▶ Step 1: Analyzing hook scripts (capturing session_id)..." >&2
SESSION_ID=$(claude -p \
  "Analyze all hook scripts in code/part2-hooks/. For each script, identify: which Claude Code hook event triggers it, what it does, and what tool permissions it requires." \
  --allowedTools "Read,Grep,Glob" \
  --output-format json < /dev/null | jq -r '.session_id')
echo "Session ID: $SESSION_ID" >&2

# ── Step 2: Reuse context — identify improvement areas ───────────────────────
echo -e "\n▶ Step 2: Identifying top 3 improvement areas (--resume, no re-read)..." >&2
claude -p "Based on the hook scripts you just analyzed, list the top 3 specific improvements in priority order. For each: name the file, describe the issue, and suggest the fix." \
  --resume "$SESSION_ID" \
  --output-format json < /dev/null | jq -r '.result'

# ── Step 3: Deep-dive on top priority (read-only report) ─────────────────────
echo -e "\n▶ Step 3: Deep-dive on top-priority hook (--resume, read-only)..." >&2
claude -p "Focus on the highest-priority improvement from your previous analysis. Show the exact lines that need changing and the corrected version. Do not modify any files — report only." \
  --resume "$SESSION_ID" \
  --allowedTools "Read" \
  --max-turns 5 < /dev/null
