#!/bin/bash
# bash 3.2+ compatible (no associative arrays for macOS default bash)
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

if [[ "$TOOL_NAME" == "Write" ]]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // ""')
elif [[ "$TOOL_NAME" == "Edit" ]]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // ""')
else
  exit 0
fi

NAMES=(    "AWS"                       "GITHUB"                    "ANTHROPIC"                    "OPENAI"              "GOOGLE"                    "STRIPE"                              "PRIVKEY")
PATTERNS=( "AKIA[0-9A-Z]{16}"         "gh[ps]_[A-Za-z0-9]{36}"   "sk-ant-[A-Za-z0-9\-]{95}"    "sk-[A-Za-z0-9]{48}"  "AIza[0-9A-Za-z\-_]{35}"   "(sk|pk)_(test|live)_[A-Za-z0-9]{24}" "-----BEGIN (RSA|EC|DSA) PRIVATE KEY-----")

for i in "${!NAMES[@]}"; do
  if echo "$CONTENT" | grep -qE "${PATTERNS[$i]}"; then
    echo "{\"decision\":\"block\",\"reason\":\"Secret detected: ${NAMES[$i]}\"}" >&2
    exit 2
  fi
done
exit 0
