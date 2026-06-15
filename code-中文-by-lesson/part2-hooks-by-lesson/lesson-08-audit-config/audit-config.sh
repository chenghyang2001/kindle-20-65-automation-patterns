#!/bin/bash
# audit-config.sh
INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source')
FILE=$(echo "$INPUT" | jq -r '.file_path')
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# 寫入稽核日誌
echo "${DATE} | ${SOURCE} | ${FILE}" \
  >> ".claude/config-audit.log"

# 阻擋對專案設定檔的外部修改
if [ "$SOURCE" = "project_settings" ]; then
  BASENAME=$(basename "$FILE")
  if [ "$BASENAME" = "settings.json" ]; then
    echo "偵測到設定檔遭外部修改：$FILE" >&2
    jq -n '{
      "decision": "block",
      "reason": "偵測到 settings.json 遭外部修改。請先檢視變更內容再繼續。"
    }'
    exit 0
  fi
fi

exit 0
