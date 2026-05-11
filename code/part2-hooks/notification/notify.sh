#!/bin/bash
# notify.sh
INPUT=$(cat)
TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"')
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL}"

# macOS native notification
osascript -e \
  'display notification "Claude Code is waiting for input" with title "Claude Code"' \
  2>/dev/null

# Slack notification (only if env var is set)
if [ -n "$SLACK_WEBHOOK" ]; then
  curl -s -X POST "$SLACK_WEBHOOK" \
    -H 'Content-type: application/json' \
    --data "{\"text\": \"Claude Code: $TYPE - waiting for input\"}" \
    > /dev/null
fi

exit 0
