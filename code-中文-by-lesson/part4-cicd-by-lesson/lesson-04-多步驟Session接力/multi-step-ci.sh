#!/bin/bash
# multi-step-ci.sh - 跨多次 claude -p 呼叫的 session 延續（--resume 模式）
# 適用專案：kindle-20-65-automation-patterns
#
# 從專案根目錄執行：
#   cd C:/Users/B00332/workspace/kindle-20-65-automation-patterns
#   bash code/part4-cicd/scripts/multi-step-ci.sh
#
# 核心概念：Step 1 擷取的 SESSION_ID 會在 Step 2 與 Step 3 重複使用。
# Claude 會記得完整的分析上下文，不需要重新讀取任何檔案。

set -e

# ── Step 1：分析 hooks 並擷取 session ID ─────────────────────────────────────
echo -e "\n▶ Step 1：分析 hook 腳本（擷取 session_id）..." >&2
SESSION_ID=$(claude -p \
  "Analyze all hook scripts in code/part2-hooks/. For each script, identify: which Claude Code hook event triggers it, what it does, and what tool permissions it requires." \
  --allowedTools "Read,Grep,Glob" \
  --output-format json < /dev/null | jq -r '.session_id')
echo "Session ID：$SESSION_ID" >&2

# ── Step 2：重用上下文 — 找出改進項目 ────────────────────────────────────────
echo -e "\n▶ Step 2：找出前 3 大改進項目（--resume，不重新讀檔）..." >&2
claude -p "Based on the hook scripts you just analyzed, list the top 3 specific improvements in priority order. For each: name the file, describe the issue, and suggest the fix." \
  --resume "$SESSION_ID" \
  --output-format json < /dev/null | jq -r '.result'

# ── Step 3：深入分析最高優先項目（唯讀報告）─────────────────────────────────
echo -e "\n▶ Step 3：深入分析最高優先的 hook（--resume，唯讀）..." >&2
claude -p "Focus on the highest-priority improvement from your previous analysis. Show the exact lines that need changing and the corrected version. Do not modify any files — report only." \
  --resume "$SESSION_ID" \
  --allowedTools "Read" \
  --max-turns 5 < /dev/null
