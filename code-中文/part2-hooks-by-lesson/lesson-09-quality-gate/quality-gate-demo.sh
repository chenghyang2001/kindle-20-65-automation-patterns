#!/bin/bash
# quality-gate.sh
INPUT=$(cat)
# 防止無限迴圈：若 stop_hook 已在執行中則直接離開
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi
ISSUES=()
# 檢查是否有未 commit 的變更
UNCOMMITTED=$(git diff --name-only 2>/dev/null)
STAGED=$(git diff --name-only --cached 2>/dev/null)
if [ -n "$UNCOMMITTED" ] || [ -n "$STAGED" ]; then
  ISSUES+=("偵測到未 commit 的變更")
fi
# 檢查是否還有殘留的 TODO 標記
TODO_COUNT=$(grep -r "<!-- TODO -->" src/ 2>/dev/null | wc -l | tr -d ' ')
if [ "$TODO_COUNT" -gt 0 ]; then
  ISSUES+=("還有 ${TODO_COUNT} 個 TODO 標記未處理")
fi
if [ ${#ISSUES[@]} -gt 0 ]; then
  jq -n \
    --arg reason "$(printf '%s\n' "${ISSUES[@]}" | \
      awk '{print NR". "$0}')" \
    '{"decision": "block", "reason": $reason}'
  exit 0
fi
exit 0
