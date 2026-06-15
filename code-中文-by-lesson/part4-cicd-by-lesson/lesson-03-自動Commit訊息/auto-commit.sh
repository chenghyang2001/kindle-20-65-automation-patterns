#!/bin/bash
# auto-commit.sh - 偵測已暫存變更並自動產生 commit
set -e

if ! git diff --cached --quiet; then
  echo "偵測到已暫存的變更，正在產生 commit 訊息..."
  claude -p "Review git status and git diff --cached, then commit with an appropriate Conventional Commits message." \
    --allowedTools \
      "Bash(git status *),Bash(git diff *),Bash(git commit *)" \
    --max-turns 3
else
  echo "沒有已暫存的變更"
fi
