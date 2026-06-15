#!/bin/bash
# restore-context.sh
# 為 compact 之後的 session 注入上下文

BRANCH=$(git branch --show-current 2>/dev/null)
RECENT=$(git log --oneline -3 2>/dev/null)
UNCOMMITTED=$(git status --short 2>/dev/null | head -10)
SESSION_STATE="$(dirname "$0")/session-state.md"

echo "## 已還原的 Session 上下文"
echo ""
echo "### 分支：${BRANCH}"
echo ""
echo "### 最近的 Commit"
echo "$RECENT"
echo ""

if [ -n "$UNCOMMITTED" ]; then
  echo "### 未 Commit 的變更"
  echo "$UNCOMMITTED"
  echo ""
fi

# 若存在上次的 session 狀態檔則一併附加
if [ -f "$SESSION_STATE" ]; then
  echo "### 上次 Session 狀態"
  cat "$SESSION_STATE"
fi
