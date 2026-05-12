#!/bin/bash
# PR 自動 AI 審查腳本
# 用法：bash review.sh <PR_NUMBER>
# 取得 PR diff 後呼叫 Claude Code 進行審查，並將結果發表為 PR 留言
set -euo pipefail

# --- 參數驗證 ---
PR_NUMBER="${1:-}"
if [ -z "$PR_NUMBER" ]; then
  echo "錯誤：未提供 PR 編號" >&2
  echo "用法：bash review.sh <PR_NUMBER>" >&2
  exit 1
fi

# --- 必要環境變數檢查 ---
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "錯誤：ANTHROPIC_API_KEY 未設定" >&2
  exit 1
fi

if [ -z "${GH_TOKEN:-}" ]; then
  echo "錯誤：GH_TOKEN 未設定" >&2
  exit 1
fi

echo "開始審查 PR #${PR_NUMBER}..."

# --- 取得 PR diff ---
DIFF_FILE=$(mktemp /tmp/pr-diff-XXXXXX.diff)
# 確保臨時檔案在腳本結束時清理
trap 'rm -f "$DIFF_FILE"' EXIT

if ! gh pr diff "$PR_NUMBER" > "$DIFF_FILE" 2>&1; then
  echo "錯誤：無法取得 PR #${PR_NUMBER} 的 diff" >&2
  cat "$DIFF_FILE" >&2
  exit 1
fi

DIFF_SIZE=$(wc -c < "$DIFF_FILE")
if [ "$DIFF_SIZE" -eq 0 ]; then
  echo "PR #${PR_NUMBER} 無程式碼變更，跳過 AI 審查"
  gh pr comment "$PR_NUMBER" --body "此 PR 無程式碼變更，略過 AI 審查。"
  exit 0
fi

echo "取得 PR diff 成功（大小：${DIFF_SIZE} bytes）"

# --- 執行 Claude Code 審查 ---
# 傳遞 diff 檔案路徑而非展開內容，避免 diff 內含 shell 特殊字元造成注入攻擊
# Claude 透過 Read tool 讀取檔案，不經過 shell 展開
# --permission-mode plan 確保 Claude 只讀取不修改任何檔案
# --max-turns 3 限制 API 用量，避免長對話耗費過多費用
REVIEW_JSON=$(claude -p \
  "請審查 GitHub Pull Request #${PR_NUMBER}。
diff 檔案路徑為：${DIFF_FILE}
請使用 Read tool 讀取該檔案，然後用繁體中文進行程式碼審查，輸出以下格式：

## 摘要
（一段話說明此 PR 的主要變更）

## 問題清單
### 🔴 Critical（必須修正）
（如無則填「無」）

### 🟡 Warning（建議修正）
（如無則填「無」）

### 🔵 Suggestion（可選改進）
（如無則填「無」）

## 結論
**Verdict：APPROVE** 或 **Verdict：REQUEST_CHANGES**

請輸出 JSON，包含 'result' 欄位，值為上方的 markdown 審查內容。" \
  --allowedTools "Read,Grep,Glob" \
  --permission-mode plan \
  --max-turns 3 \
  --output-format json 2>&1) || {
  echo "錯誤：Claude Code 執行失敗" >&2
  echo "$REVIEW_JSON" >&2
  # 失敗時發表說明留言而非直接中斷，讓 PR 作者知道審查無法完成
  gh pr comment "$PR_NUMBER" --body "⚠️ AI 自動審查執行失敗，請手動審查此 PR。"
  exit 1
}

# --- 從 JSON 輸出提取審查文字 ---
# 先讀取全部 stdin 存入 raw，避免 json.load 消耗後 except 區塊 stdin 已耗盡的 bug
REVIEW=$(echo "$REVIEW_JSON" | python3 -c "
import json, sys
raw = sys.stdin.read()
try:
    data = json.loads(raw)
    result = data.get('result', '')
    if not result:
        print('審查結果為空，可能是 API 錯誤')
    else:
        print(result)
except (json.JSONDecodeError, Exception):
    # JSON 解析失敗時直接輸出原始內容（raw 已讀取，不再重讀 stdin）
    print('無法解析審查 JSON，原始輸出如下：')
    print(raw)
" 2>&1)

if [ -z "$REVIEW" ]; then
  echo "錯誤：審查結果為空" >&2
  exit 1
fi

# --- 發表 PR 留言 ---
COMMENT_BODY="## 🤖 AI Code Review（自動審查）

${REVIEW}

---
_由 Claude Code 自動生成，僅供參考。_"

gh pr comment "$PR_NUMBER" --body "$COMMENT_BODY"
echo "PR #${PR_NUMBER} 審查留言發表成功"
