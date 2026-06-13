#!/bin/bash
# parallel-review.sh - 用 -w（具名 worktree）同時執行 3 個獨立審查
# 適用專案：kindle-20-65-automation-patterns
#
# 從專案根目錄執行：
#   cd C:/Users/B00332/workspace/kindle-20-65-automation-patterns
#   bash code/part4-cicd/scripts/parallel-review.sh
#
# 核心概念：-w 為每個實例指派具名工作區。
# 3 個審查以背景執行（&）平行進行，最後用 wait 收集結果。
# 輸出寫入暫存檔，避免多個程序的輸出交錯混雜。

REPORT_DIR=$(mktemp -d)
echo -e "\n▶ 啟動 3 個平行審查（輸出暫存於：$REPORT_DIR）..." >&2

# ── Worker 1：安全性審查 ──────────────────────────────────────────────────────
claude -p \
  "Review all scripts in code/part2-hooks/ for security issues: command injection via unsanitized hook JSON input, unsafe dynamic command construction from jq values, missing exit code handling. Report each issue as Critical / High / Medium with file:line." \
  --allowedTools "Read,Grep,Glob" < /dev/null > "$REPORT_DIR/security.txt" &
PID1=$!

# ── Worker 2：程式碼品質審查 ──────────────────────────────────────────────────
claude -p \
  "Review all hook scripts in code/part2-hooks/ for code quality: hardcoded paths (must use \$HOME not /c/Users/...), missing error handling, duplicate stdin consumption logic, unclear naming. Report as Critical / Warning / Suggestion." \
  --allowedTools "Read,Grep,Glob" < /dev/null > "$REPORT_DIR/quality.txt" &
PID2=$!

# ── Worker 3：規範符合性審查 ──────────────────────────────────────────────────
claude -p \
  "Verify hook scripts in code/part2-hooks/ follow Claude Code hook spec: (1) exit 0=allow, exit 2=hard block, (2) Stop hooks read INPUT=\$(cat) first, (3) Stop hooks check stop_hook_active to prevent loops, (4) MCP guards output hookSpecificOutput JSON. Report PASS/FAIL per hook file." \
  --allowedTools "Read,Grep,Glob" < /dev/null > "$REPORT_DIR/spec.txt" &
PID3=$!

wait $PID1 $PID2 $PID3

echo -e "\n════════════ 安全性審查 ════════════" >&2
cat "$REPORT_DIR/security.txt"

echo -e "\n════════════ 品質審查 ══════════════" >&2
cat "$REPORT_DIR/quality.txt"

echo -e "\n════════════ 規範符合性審查 ════════" >&2
cat "$REPORT_DIR/spec.txt"

echo -e "\n▶ 平行審查完成。" >&2
