#!/bin/bash
# debug-hook.sh - 開發階段的除錯工具

INPUT=$(cat)

# 把收到的所有資料寫入日誌檔
echo "=== $(date) ===" >> "$(dirname "$0")/hook-debug.log"
echo "EVENT: $(echo "$INPUT" | jq -r '.hook_event_name')" \
  >> "$(dirname "$0")/hook-debug.log"
echo "INPUT:" >> "$(dirname "$0")/hook-debug.log"
echo "$INPUT" | jq '.' >> "$(dirname "$0")/hook-debug.log"
echo "" >> "$(dirname "$0")/hook-debug.log"

exit 0
