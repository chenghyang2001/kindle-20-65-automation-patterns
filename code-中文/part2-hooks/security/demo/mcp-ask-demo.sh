#!/bin/bash
# mcp-write-guard.sh
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')

# 只檢查來自 filesystem server 的寫入/刪除工具
if echo "$TOOL" | grep -qE "mcp__filesystem__(write|delete|move)"; then
  FILE=$(echo "$INPUT" | jq -r '.tool_input.path // .tool_input.source // empty')
  if echo "$FILE" | grep -qE "\.(sql)$"; then
    echo "需人工確認 MCP 操作：$FILE" >&2
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: "偵測到資料庫遷移腳本，請人工確認是否執行"
      }
    }'
    exit 0
  fi
fi

exit 0
