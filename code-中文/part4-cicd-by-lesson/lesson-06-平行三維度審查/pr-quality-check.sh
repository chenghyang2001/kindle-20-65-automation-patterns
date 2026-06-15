#!/bin/bash
# pr-quality-check.sh - PR 提交品質三維度平行審查
# Step 5 演練設計稿
#
# 從專案根目錄執行：
#   bash code-中文/part4-cicd/demo/06-平行三維度審查/pr-quality-check.sh
#
# 三個維度同時平行審查：
#   Worker 1：Commit 訊息格式（Conventional Commits）
#   Worker 2：機密資訊掃描（硬編碼路徑 / API Key）
#   Worker 3：測試覆蓋率（是否有對應 test 檔）

set -e

REPORT_DIR=$(mktemp -d)
echo "▶ 啟動 PR 品質三維度平行審查（輸出暫存於：$REPORT_DIR）..." >&2

# ── Worker 1：Commit 訊息格式 ─────────────────────────────────────────────────
claude -p "Review the latest git commit message in this repo.
  Check: (1) follows Conventional Commits format <type>(<scope>): <desc>,
  (2) type is one of feat/fix/docs/refactor/test/chore,
  (3) description is under 72 chars and in imperative mood.
  Report PASS or FAIL with specific reason." \
  --allowedTools "Bash(git log *)" < /dev/null > "$REPORT_DIR/commit.txt" &
PID1=$!

# ── Worker 2：機密資訊掃描 ────────────────────────────────────────────────────
claude -p "Review files changed in the latest git commit.
  Find: (1) hardcoded absolute paths (/c/Users/... or C:/Users/...),
  (2) hardcoded API keys or tokens (strings matching [A-Za-z0-9]{32,}),
  (3) passwords or secrets in plain text.
  Report each finding as Critical/High with file:line." \
  --allowedTools "Bash(git diff *),Read,Grep" < /dev/null > "$REPORT_DIR/secrets.txt" &
PID2=$!

# ── Worker 3：測試覆蓋率 ──────────────────────────────────────────────────────
claude -p "Review files changed in the latest git commit.
  For each .py or .js file added or modified,
  check if a corresponding test_*.py or *.test.js file exists.
  Report COVERED or MISSING per source file." \
  --allowedTools "Bash(git diff *),Glob" < /dev/null > "$REPORT_DIR/tests.txt" &
PID3=$!

wait $PID1 $PID2 $PID3

echo -e "\n════════════ Commit 格式 ════════════" >&2
cat "$REPORT_DIR/commit.txt"

echo -e "\n════════════ 機密掃描 ══════════════" >&2
cat "$REPORT_DIR/secrets.txt"

echo -e "\n════════════ 測試覆蓋率 ════════════" >&2
cat "$REPORT_DIR/tests.txt"

echo -e "\n▶ PR 品質檢查完成。" >&2
