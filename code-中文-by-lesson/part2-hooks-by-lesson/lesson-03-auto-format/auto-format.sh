#!/bin/bash
# auto-format.sh
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

EXT="${FILE_PATH##*.}"

case "$EXT" in
  js|jsx|ts|tsx|css|json)
    npx prettier --write "$FILE_PATH" 2>/dev/null
    ;;
  go)
    gofmt -w "$FILE_PATH" 2>/dev/null
    ;;
  py)
    black "$FILE_PATH" 2>/dev/null
    ;;
  md)
    npx markdownlint-cli2 --fix "$FILE_PATH" 2>/dev/null
    ;;
esac

exit 0
