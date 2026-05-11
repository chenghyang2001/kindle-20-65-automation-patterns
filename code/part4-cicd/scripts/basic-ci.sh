#!/bin/bash
# basic-ci.sh - Basic usage patterns for claude -p

# Pass a prompt directly
claude -p "your prompt text"

# Pipe file contents
cat build-error.txt | \
  claude -p "Explain the root cause of this build error in one sentence"

# Basic CI/CD pattern (equivalent to GitHub Actions)
# env:
#   ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
claude -p "Analyze the code in src/ and report any critical issues" \
  --allowedTools "Read,Grep,Glob" \
  --max-turns 5
