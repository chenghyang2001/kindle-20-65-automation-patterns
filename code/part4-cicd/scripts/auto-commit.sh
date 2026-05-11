#!/bin/bash
# auto-commit.sh
set -e

if ! git diff --cached --quiet; then
  echo "Staged changes detected. Generating commit message..."
  claude -p "Review git status and git diff --cached, then commit with an appropriate Conventional Commits message." \
    --allowedTools \
      "Bash(git status *),Bash(git diff *),Bash(git commit *)" \
    --max-turns 3
else
  echo "No staged changes"
fi
