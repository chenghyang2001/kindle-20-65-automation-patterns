#!/bin/bash
# block-dangerous.sh
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# 偵測危險指令 pattern
PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "git push --force"
  "git push -f"
  "chmod -R 777"
  "DROP TABLE"
  "> /dev/sda"
)

for pattern in "${PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qF "$pattern"; then
    echo "已阻擋：'$pattern' 是被禁止的指令" >&2
    exit 2
  fi
done

exit 0
