#!/bin/bash
# PreCompact hook：在 context 壓縮前將 session 狀態存入 .claude/session-state.md
# 讓壓縮後的 context 仍能透過讀取此檔案還原關鍵工作進度
set -euo pipefail

SESSION_FILE=".claude/session-state.md"
DATE=$(date '+%Y-%m-%d %H:%M')

cat > "$SESSION_FILE" << EOF
# Session 狀態（自動儲存：${DATE}）

## 修改過的檔案
$(git diff --name-only)
$(git diff --name-only --cached)

## 未 commit 的變更摘要
$(git diff --stat | tail -5)

## 最近的 commit
$(git log --oneline -5)
EOF
