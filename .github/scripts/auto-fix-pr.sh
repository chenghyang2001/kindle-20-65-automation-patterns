#!/bin/bash
# PR 自動修復腳本（Phase 2）
# AI Code Review 判定 REQUEST_CHANGES 時呼叫，讀取審查意見並自動修復 code/ 目錄下的問題
# 用法：bash auto-fix-pr.sh <PR_NUMBER> <REVIEW_FILE_PATH>
set -euo pipefail

# --- 參數驗證 ---
PR_NUMBER="${1:-}"
REVIEW_FILE_PATH="${2:-}"

if [ -z "$PR_NUMBER" ]; then
  echo "錯誤：未提供 PR 編號" >&2
  echo "用法：bash auto-fix-pr.sh <PR_NUMBER> <REVIEW_FILE_PATH>" >&2
  exit 1
fi

if [ -z "$REVIEW_FILE_PATH" ]; then
  echo "錯誤：未提供審查意見檔案路徑" >&2
  echo "用法：bash auto-fix-pr.sh <PR_NUMBER> <REVIEW_FILE_PATH>" >&2
  exit 1
fi

if [ ! -f "$REVIEW_FILE_PATH" ]; then
  echo "錯誤：審查意見檔案不存在：${REVIEW_FILE_PATH}" >&2
  exit 1
fi

# --- 必要環境變數檢查 ---
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "錯誤：ANTHROPIC_API_KEY 未設定，無法執行 Claude 修復" >&2
  exit 1
fi

if [ -z "${GH_TOKEN:-}" ]; then
  echo "錯誤：GH_TOKEN 未設定，無法呼叫 gh CLI" >&2
  exit 1
fi

echo "開始對 PR #${PR_NUMBER} 執行自動修復..."
echo "審查意見檔案：${REVIEW_FILE_PATH}"

# --- 設定 git 身份（GitHub Actions 環境需要明確指定，否則 commit 會失敗）---
git config user.email "github-actions[bot]@users.noreply.github.com"
git config user.name "github-actions[bot]"

# --- 切換到 PR 分支 ---
echo "切換到 PR #${PR_NUMBER} 分支..."
gh pr checkout "$PR_NUMBER"

# --- 計算本 PR 已有幾次 Auto-fix commit（防止無限修復迴圈）---
# 用 gh pr view 取得 commit headline 清單，過濾以 "Auto-fix:" 開頭的 commit
AUTO_FIX_COUNT=$(gh pr view "$PR_NUMBER" --json commits \
  --jq '[.commits[].messageHeadline | select(startswith("Auto-fix:"))] | length' \
  2>/dev/null || echo "0")

echo "本 PR 已有 ${AUTO_FIX_COUNT} 次 Auto-fix commit"

# 超過 2 次後停止自動修復，避免 Claude 陷入無法收斂的修復迴圈
if [ "$AUTO_FIX_COUNT" -ge 2 ]; then
  echo "警告：PR #${PR_NUMBER} 已達自動修復上限（2 次），停止修復" >&2
  echo "請人工審查剩餘問題後手動修正"
  # 以 exit 0 結束，讓後續 review.sh 的標籤邏輯正常執行
  exit 0
fi

# --- 呼叫 Claude 執行修復 ---
# 傳遞審查意見檔案路徑而非展開內容，避免檔案內含 shell 特殊字元造成注入
# Claude 透過 Read tool 讀取，不經過 shell 展開
# --dangerously-skip-permissions 允許在非互動環境使用 Edit 工具
FIX_RESULT=$(claude -p \
  "你是一個自動修復工具。請讀取審查意見檔案 ${REVIEW_FILE_PATH}，
然後對 code/ 目錄下相關的 Shell 腳本應用修復。
規則：
1. 只修改 code/ 目錄下的檔案，不動 .github/ 目錄
2. 優先修復 Critical 問題，其次 Warning
3. 每個修復加短註解說明原因（繁體中文）
4. 無法安全自動修復的問題：說明原因，不要修改
完成後輸出：已修復的問題清單（bullet points）" \
  --allowedTools "Read,Edit,Grep,Glob" \
  --dangerously-skip-permissions \
  --max-turns 10 \
  --output-format json 2>&1) || FIX_RESULT=""

# --- 從 JSON 輸出提取修復摘要 ---
# 先讀取全部 stdin 存入 raw，避免 json.load 消耗後 except 區塊 stdin 已耗盡的問題
FIX_SUMMARY=$(echo "$FIX_RESULT" | python3 -c "
import json, sys
raw = sys.stdin.read()
try:
    data = json.loads(raw)
    result = data.get('result', '')
    if result:
        print(result)
    else:
        print('自動修復完成（無詳細輸出）')
except (json.JSONDecodeError, Exception):
    print('自動修復完成（無詳細輸出）')
" 2>&1)

echo "=== 修復摘要 ==="
echo "$FIX_SUMMARY"
echo "================"

# --- 路徑安全檢查：確認 Claude 沒有修改 code/ 以外的目錄 ---
# --dangerously-skip-permissions 給 Claude Edit 工具無路徑限制，只靠 prompt 不夠，必須硬檢查
# grep -v 篩出不在 code/ 下的變更路徑；|| true 避免 grep 無結果時 set -e 中斷
ILLEGAL_CHANGES=$(git diff --name-only 2>/dev/null | grep -v "^code/" || true)
if [ -n "$ILLEGAL_CHANGES" ]; then
  echo "錯誤：Claude 修改了 code/ 以外的路徑，還原所有工作目錄變更" >&2
  echo "受影響的路徑：" >&2
  echo "$ILLEGAL_CHANGES" >&2
  git checkout -- .
  exit 1
fi

# --- 檢查 code/ 目錄是否有變更 ---
# 限定只看 code/ 避免誤判 .github/ 等目錄的變更
if git diff --quiet -- code/ && git diff --staged --quiet -- code/; then
  echo "沒有需要修復的變更，code/ 目錄無任何修改"
  exit 0
fi

echo "偵測到 code/ 目錄有變更，準備 commit..."

# --- 暫存 code/ 目錄下的修改（只暫存 code/，不動 .github/）---
git add code/

# 確認暫存區確實有內容才 commit，避免空 commit 造成 git 錯誤
if git diff --staged --quiet; then
  echo "code/ 目錄無 staged 變更，跳過 commit"
  exit 0
fi

# --- 組建 commit message（標示第 N 次修復供後續防迴圈計數用）---
FIX_INDEX=$((AUTO_FIX_COUNT + 1))
git commit -m "Auto-fix: 修正 AI 審查發現的問題（第 ${FIX_INDEX} 次）

${FIX_SUMMARY}"

# --- 推送到 PR 分支 ---
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "推送修復到分支：${CURRENT_BRANCH}"

# 使用 PAT 設定 remote URL，確保推送能觸發新的 workflow
# GITHUB_TOKEN 推送不觸發 workflow（GitHub 平台限制），PAT 推送才會觸發
if [ -n "${GH_PAT:-}" ] && [ -n "${GITHUB_REPOSITORY:-}" ]; then
  git remote set-url origin "https://x-access-token:${GH_PAT}@github.com/${GITHUB_REPOSITORY}.git"
fi

git push

echo "PR #${PR_NUMBER} 自動修復完成並已推送（第 ${FIX_INDEX} 次）"
