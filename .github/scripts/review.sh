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
REVIEW_FILE=""
DIFF_FILE=$(mktemp /tmp/pr-diff-XXXXXX.diff)
# EXIT trap 同時清理 DIFF_FILE 和 REVIEW_FILE，防止 set -e 提前退出時臨時檔案殘留
trap 'rm -f "$DIFF_FILE" "${REVIEW_FILE:-}"' EXIT

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

請直接輸出以上格式的 markdown，不需要額外包裝成 JSON 格式。" \
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

# --- 解析 verdict 並自動處理 PR ---

# 從審查內容中提取 verdict（匹配 "Verdict：APPROVE" 或 "Verdict: APPROVE"）
if echo "$REVIEW" | tail -10 | grep -qE "Verdict[：:]\s*APPROVE"; then
  VERDICT="APPROVE"
else
  VERDICT="REQUEST_CHANGES"
fi

echo "審查 Verdict：${VERDICT}"

# 計算本 PR 已有幾次自動修復 commit（防止無限迴圈）
AUTO_FIX_COUNT=$(gh pr view "$PR_NUMBER" --json commits \
  --jq '[.commits[].messageHeadline | select(startswith("Auto-fix:"))] | length' \
  2>/dev/null || echo "0")

echo "已自動修復次數：${AUTO_FIX_COUNT}"

if [ "$VERDICT" = "APPROVE" ]; then
  # Phase 1：自動合併（squash merge）
  echo "AI 審查 APPROVE，啟用自動合併..."
  # --auto 旗標：等所有 required checks 通過後再 merge（安全機制）
  gh pr merge "$PR_NUMBER" \
    --squash \
    --auto \
    --subject "Auto-merged: AI Review APPROVED (#${PR_NUMBER})" \
    --body "AI code review approved and all CI checks passed. Auto-merged by GitHub Actions."
  echo "PR #${PR_NUMBER} 已設定自動合併（等待 CI checks 完成）"

elif [ "$AUTO_FIX_COUNT" -lt 2 ]; then
  # Phase 2：自動修復後重新審查
  echo "AI 審查 REQUEST_CHANGES，嘗試自動修復（第 $((AUTO_FIX_COUNT + 1)) 次）..."

  # 把審查內容存入臨時檔案，傳給 auto-fix-pr.sh
  REVIEW_FILE=$(mktemp /tmp/review-content-XXXXXX.md)
  echo "$REVIEW" > "$REVIEW_FILE"

  # 呼叫自動修復腳本（與 review.sh 同目錄）
  SCRIPT_DIR="$(dirname "$(realpath "$0")")"
  bash "${SCRIPT_DIR}/auto-fix-pr.sh" "$PR_NUMBER" "$REVIEW_FILE"
  # REVIEW_FILE 由頂部 EXIT trap 統一清理，不在此手動 rm

else
  # 超過自動修復上限，標記需人工介入
  echo "已嘗試 ${AUTO_FIX_COUNT} 次自動修復，超過上限（2 次），標記需人工審查"
  # 嘗試加 label（若 label 不存在會失敗，用 || true 容錯）
  gh pr edit "$PR_NUMBER" --add-label "needs-human-review" 2>/dev/null || true
  gh pr comment "$PR_NUMBER" \
    --body "⚠️ 已嘗試 **${AUTO_FIX_COUNT}** 次自動修復，仍有未通過的審查問題，請人工介入處理。"
fi
