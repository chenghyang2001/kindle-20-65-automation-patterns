#!/bin/bash
# block-dangerous.sh
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Detect dangerous command patterns
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
    echo "Blocked: '$pattern' is a prohibited command" >&2
    exit 2
  fi
done

exit 0
