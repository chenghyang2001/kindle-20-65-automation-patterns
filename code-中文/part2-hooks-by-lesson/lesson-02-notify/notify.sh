#!/bin/bash
# notify.sh
INPUT=$(cat)
TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"')
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL}"

# macOS 原生通知
osascript -e \
  'display notification "Claude Code 正在等待輸入" with title "Claude Code"' \
  2>/dev/null

# Slack 通知（僅在環境變數已設定時發送）
if [ -n "$SLACK_WEBHOOK" ]; then
  curl -s -X POST "$SLACK_WEBHOOK" \
    -H 'Content-type: application/json' \
    --data "{\"text\": \"Claude Code: $TYPE - 正在等待輸入\"}" \
    > /dev/null
fi

exit 0
