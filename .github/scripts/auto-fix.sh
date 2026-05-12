#!/bin/bash
# CI 自動修復腳本
# 讀取測試失敗輸出，呼叫 Claude Code 嘗試修復，並在有變更時 commit & push
# 在 commit message 加入 [skip ci] 防止再次觸發 CI 造成無限迴圈
set -euo pipefail

# --- 必要環境變數檢查 ---
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "錯誤：ANTHROPIC_API_KEY 未設定，無法執行自動修復" >&2
  exit 1
fi

# --- 確認測試失敗輸出檔存在且非空 ---
TEST_OUTPUT_FILE="test-output.txt"
if [ ! -f "$TEST_OUTPUT_FILE" ]; then
  echo "找不到 ${TEST_OUTPUT_FILE}，無法判斷失敗原因，跳過自動修復"
  exit 0
fi

# 僅檢查空檔而不 cat 展開，避免檔案內容被 shell 展開後作為指令注入
if [ ! -s "$TEST_OUTPUT_FILE" ]; then
  echo "測試輸出檔為空，無法判斷失敗原因，跳過自動修復"
  exit 0
fi

echo "=== 測試失敗內容（直接由 Claude 讀取）==="
cat "$TEST_OUTPUT_FILE"
echo "===================="

# --- 執行 Claude Code 自動修復 ---
# 傳遞檔案路徑而非展開內容，避免測試輸出內含 shell 特殊字元造成注入攻擊
# Claude 透過 Read tool 讀取 test-output.txt，不經過 shell 展開
# allowedTools 限定只能讀取、編輯，以及執行 bash -n（Shell 語法檢查）
# 不允許任意 bash 執行，避免修復腳本本身造成副作用
echo "呼叫 Claude Code 分析並修復失敗..."
FIX_RESULT=$(claude -p \
  "CI 測試失敗了。請使用 Read tool 讀取 test-output.txt 取得失敗輸出。
請分析失敗原因，並直接修復 code/ 目錄下對應的檔案。
可能的問題類型：
1. Shell 腳本語法錯誤（bash -n 檢查失敗）
2. YAML 格式錯誤（yaml.safe_load 失敗）

修復規則：
- 只修改有問題的檔案，不要動其他檔案
- Shell 腳本修復後必須通過 bash -n 語法檢查
- 保持繁體中文註解風格
- 修復後請說明修改了哪些檔案及原因
- 加入 [skip ci] 的 commit 已由外部腳本處理，請勿自行 commit" \
  --allowedTools "Read,Edit,Bash(bash -n *)" \
  --permission-mode default \
  --max-turns 5 \
  --output-format json 2>&1) || {
  echo "警告：Claude Code 執行時發生錯誤，跳過自動修復" >&2
  echo "$FIX_RESULT" >&2
  exit 0
}

# 從 JSON 輸出提取修復說明
FIX_SUMMARY=$(echo "$FIX_RESULT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('result', '（無修復說明）'))
except (json.JSONDecodeError, Exception):
    print('（無法解析修復結果）')
" 2>&1)

echo "=== 修復說明 ==="
echo "$FIX_SUMMARY"
echo "================"

# --- 檢查是否有檔案被修改 ---
# git diff --quiet 若有變更會回傳非零退出碼（exit 1）
if git diff --quiet; then
  echo "沒有檔案被修改，自動修復未產生任何變更"
  exit 0
fi

echo "偵測到檔案變更，準備 commit..."

# --- 設定 git 身份（GitHub Actions 環境需要明確設定）---
git config user.email "github-actions[bot]@users.noreply.github.com"
git config user.name "github-actions[bot]"

# --- 暫存變更並 commit ---
# 只暫存 code/ 與 .github/scripts/ 底下的既有修改，
# 避免 Claude 可能意外建立的新檔案被一起 commit（git add -A 太寬鬆）
# [skip ci] 標記確保此 commit 不會再次觸發 CI，避免無限循環
git add code/ .github/scripts/ 2>/dev/null || true
# 若上述目錄無變更，再 fallback 只暫存有 diff 的既有檔案
if git diff --cached --quiet; then
  git diff --name-only | xargs git add 2>/dev/null || true
fi
git commit -m "auto-fix: resolve CI failures [skip ci]

${FIX_SUMMARY}"

# --- 推送到當前分支 ---
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "推送修復到分支：${CURRENT_BRANCH}"
git push origin "$CURRENT_BRANCH"

echo "自動修復完成並已推送"
