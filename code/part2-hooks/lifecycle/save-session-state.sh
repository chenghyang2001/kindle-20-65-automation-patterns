#!/bin/bash
# save-session-state.sh
INPUT=$(cat)

# jq 存在性檢查：若未安裝則無法解析 hook 輸入
if ! command -v jq &>/dev/null; then
  echo "錯誤：jq 未安裝，無法解析 hook 輸入" >&2
  exit 1
fi

# 避免 ${INPUT:-{}} 的 bash 參數展開歧義（會多吐一個 } 污染 jq）
[ -z "$INPUT" ] && INPUT='{}'
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "n/a"')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
STATE_FILE="${PWD}/.claude/session-state.md"
mkdir -p "$(dirname "$STATE_FILE")"

# 寫入失敗時回報錯誤並中止，避免靜默遺失 session 狀態
if ! cat > "$STATE_FILE" << EOF
# Session State (saved: ${TIMESTAMP} / trigger: ${TRIGGER})

## Branch
$(git branch --show-current 2>/dev/null)

## Uncommitted Changes
$(git diff --name-only 2>/dev/null)
$(git diff --name-only --cached 2>/dev/null | \
  sed 's/^/[staged] /')

## Recent Commits (5)
$(git log --oneline -5 2>/dev/null)

## Change Summary
$(git diff --stat 2>/dev/null | tail -5)
EOF
then
  echo "錯誤：寫入 ${STATE_FILE} 失敗" >&2
  exit 1
fi

echo "Session state saved: ${STATE_FILE}" >&2
exit 0
