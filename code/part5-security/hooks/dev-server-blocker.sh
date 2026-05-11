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
      MSG="Development server startup is only allowed inside a tmux session."
      echo "{\"decision\":\"block\",\"reason\":\"${MSG}\"}" >&2
      exit 2
    fi
    break
  fi
done
exit 0
