#!/bin/bash
# audit-config.sh
INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source')
FILE=$(echo "$INPUT" | jq -r '.file_path')
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Write to audit log
echo "${DATE} | ${SOURCE} | ${FILE}" \
  >> ".claude/config-audit.log"

# Block external modifications to project settings files
if [ "$SOURCE" = "project_settings" ]; then
  BASENAME=$(basename "$FILE")
  if [ "$BASENAME" = "settings.json" ]; then
    echo "External modification to settings file detected: $FILE" >&2
    jq -n '{
      "decision": "block",
      "reason": "External modification to settings.json detected. Please review the changes before proceeding."
    }'
    exit 0
  fi
fi

exit 0
