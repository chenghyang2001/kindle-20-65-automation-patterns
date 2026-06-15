#!/bin/bash
# mcp-write-guard.sh
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')

# 只檢查來自 filesystem server 的寫入/刪除工具
if echo "$TOOL" | grep -qE "mcp__filesystem__(write|delete|move)"; then
  FILE=$(echo "$INPUT" | jq -r '.tool_input.path // .tool_input.source // empty')
  if echo "$FILE" | grep -qE "\.(env|pem|key)$"; then
    echo "已阻擋 MCP 存取敏感檔案：$FILE" >&2
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "不允許存取敏感檔案"
      }
    }'
    exit 0
  fi
fi

exit 0
