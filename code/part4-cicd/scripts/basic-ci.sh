#!/bin/bash
# basic-ci.sh - Basic usage patterns for claude -p
# Adapted for: kindle-20-65-automation-patterns project
#
# Run from the project root:
#   cd C:/Users/B00332/workspace/kindle-20-65-automation-patterns
#   bash code/part4-cicd/scripts/basic-ci.sh

# ── Pattern 1: Pass a prompt directly ────────────────────────────────────────
claude -p "What is this project about? Look at the README or CLAUDE.md if available, otherwise infer from the directory structure. Answer in exactly 2 sentences." \
  --allowedTools "Read,Glob" \
  --max-turns 5 < /dev/null

# ── Pattern 2: Pipe file contents ────────────────────────────────────────────
cat code/part2-hooks/quality/quality-gate.sh | \
  claude -p "Explain what this Claude Code Stop hook does and what it blocks. One sentence."

# ── Pattern 3: CI/CD pattern — restrict tools, cap turns ─────────────────────
# Note: In GitHub Actions, add:  env: ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
claude -p "List all .sh files in code/part2-hooks/ grouped by subfolder. Just the file names, no explanation." \
  --allowedTools "Glob" \
  --max-turns 3 < /dev/null
