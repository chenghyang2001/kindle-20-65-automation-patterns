#!/bin/bash
# debug-hook.sh - development debugging tool

INPUT=$(cat)

# Write all received data to log file
echo "=== $(date) ===" >> /tmp/claude-hook-debug.log
echo "EVENT: $(echo "$INPUT" | jq -r '.hook_event_name')" \
  >> /tmp/claude-hook-debug.log
echo "INPUT:" >> /tmp/claude-hook-debug.log
echo "$INPUT" | jq '.' >> /tmp/claude-hook-debug.log
echo "" >> /tmp/claude-hook-debug.log

exit 0
