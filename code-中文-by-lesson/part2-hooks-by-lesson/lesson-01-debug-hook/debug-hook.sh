#!/bin/bash
# debug-hook.sh - 開發階段的除錯工具

INPUT=$(cat)

# 把收到的所有資料寫入日誌檔
echo "=== $(date) ===" >> /tmp/claude-hook-debug.log
echo "EVENT: $(echo "$INPUT" | jq -r '.hook_event_name')" \
  >> /tmp/claude-hook-debug.log
echo "INPUT:" >> /tmp/claude-hook-debug.log
echo "$INPUT" | jq '.' >> /tmp/claude-hook-debug.log
echo "" >> /tmp/claude-hook-debug.log

exit 0
