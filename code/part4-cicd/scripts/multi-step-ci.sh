#!/bin/bash
# multi-step-ci.sh

# Step 1: Analyze and capture session ID
SESSION_ID=$(claude -p \
  "Analyze the entire repository and understand its dependencies and architecture." \
  --allowedTools "Read,Grep,Glob" \
  --output-format json | jq -r '.session_id')

# Step 2: Inherit analysis context and identify issues
claude -p "Based on the analyzed code, list the top 3 areas that need improvement, in priority order." \
  --resume "$SESSION_ID" \
  --output-format json | jq -r '.result'

# Step 3: Fix the highest-priority issue
claude -p "Fix the top-priority issue and run the tests." \
  --resume "$SESSION_ID" \
  --allowedTools "Read,Edit,Bash(npm test *)" \
  --max-turns 10
