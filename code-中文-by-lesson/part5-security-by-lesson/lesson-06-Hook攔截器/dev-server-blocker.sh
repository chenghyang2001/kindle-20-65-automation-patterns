#!/bin/bash
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
[[ "$TOOL_NAME" != "Bash" ]] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
DEV_PATTERNS=(
  "npm run dev" "npm run start" "yarn dev" "yarn start"
  "pnpm dev" "pnpm start" "next dev" "vite"
  "python manage.py runserver" "flask run" "rails server"
)

for PATTERN in "${DEV_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -q "^${PATTERN}"; then
    if [[ -z "$TMUX" ]]; then
      MSG="開發伺服器只允許在 tmux session 內啟動。"
      echo "{\"decision\":\"block\",\"reason\":\"${MSG}\"}" >&2
      exit 2
    fi
    break
  fi
done
exit 0
