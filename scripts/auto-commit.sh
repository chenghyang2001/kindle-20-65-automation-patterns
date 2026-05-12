#!/bin/bash
# auto-commit.sh — AI-generated commit messages via claude -p (Max subscription)
#
# Usage:
#   git add <files>
#   bash scripts/auto-commit.sh
#
# Requires: claude CLI (Max subscription), git
# Note: Uses Max subscription — no API credits consumed

set -e

# 沒有 staged 變更時提前退出，避免產生空 commit
if git diff --cached --quiet; then
    echo "No staged changes to commit." >&2
    exit 0
fi

# 讓使用者確認即將 commit 哪些檔案
echo "Staged changes:" >&2
git diff --cached --name-only >&2

# 呼叫 claude -p 自動生成繁體中文 commit message 並執行 commit
# 不匯出 ANTHROPIC_API_KEY，走 Max 訂閱而非 API Credits
claude -p \
    "Review git diff --cached and git status, then create a single git commit.
Commit message convention for this project:
- Language: 繁體中文 (Traditional Chinese)
- Format: 動詞：簡短說明
- Valid verbs: 新增、修復、重構、更新、移除、合併
- Examples: 新增：auto-commit 腳本 / 修復：hook 路徑問題 / 更新：agents 設定
- One line only, under 72 characters total
Commit now using the git commit tool." \
    --allowedTools "Bash(git status *),Bash(git diff *),Bash(git commit *)" \
    --max-turns 3
