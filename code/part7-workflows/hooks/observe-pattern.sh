#!/usr/bin/env bash
# Append operation patterns to JSON log
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
INPUT_DATA=$(echo "$INPUT" | jq -c '.tool_input // {}')
LOG_FILE="${HOME}/.claude/logs/patterns.jsonl"

mkdir -p "$(dirname "$LOG_FILE")"
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\
\"tool\":\"$TOOL\",\"input\":$INPUT_DATA}" >> "$LOG_FILE"
exit 0
