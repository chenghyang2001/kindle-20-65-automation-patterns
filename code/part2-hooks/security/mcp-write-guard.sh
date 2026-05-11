#!/bin/bash
# mcp-write-guard.sh
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')

# Only inspect write/delete tools from the filesystem server
if echo "$TOOL" | grep -qE "mcp__filesystem__(write|delete|move)"; then
  FILE=$(echo "$INPUT" | jq -r '.tool_input.path // .tool_input.source // empty')
  if echo "$FILE" | grep -qE "\.(env|pem|key)$"; then
    echo "Blocked MCP access to sensitive file: $FILE" >&2
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "Access to sensitive files is not permitted"
      }
    }'
    exit 0
  fi
fi

exit 0
