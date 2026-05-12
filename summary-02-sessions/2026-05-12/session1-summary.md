# Session 1 — 2026-05-12

## 主題

Chapter 4：GitHub Actions CI/CD 全自動 AI 審查 + Auto-merge + Auto-fix 完整閉環

## 完成事項

### 1. 修復 Security Scan 工作流（commit `5c157c1`）

- **問題**：`set -euo pipefail` + `SCAN_RESULT=$(claude -p ...)` → `claude` 非零退出碼讓 shell 立即終止（11 秒失敗）
- **修復**：改用 `if ! SCAN_RESULT=$(claude -p ...)` 模式，claude 非零時捕獲輸出並繼續
- **新增** `--dangerously-skip-permissions`：CI 無 TTY，必須加此 flag 跳過互動提示
- 結果：掃描 20 支腳本、產出報告、上傳 artifact，全程成功

### 2. 修復 PR 審查留言格式（commit `a34f2ad`）

- **問題**：prompt 要求 Claude 輸出 JSON，加上 `--output-format json` 造成雙層 JSON 包裝，留言顯示原始 JSON 而非 markdown
- **修復**：prompt 末尾改為「請直接輸出 markdown，不需要包裝成 JSON」，`--output-format json` 只負責外層包裝

### 3. 建立全自動 AI 審查 Auto-pilot（commit `1c1abfe`）

新增完整 PR 自動處理流程：

- **Phase 1（APPROVE）**：`gh pr merge --squash --auto` 等 CI checks 全過後自動合併
- **Phase 2（REQUEST_CHANGES）**：呼叫 `auto-fix-pr.sh`，讓 Claude 讀取審查意見自動修正 `code/` 目錄
- **迴圈防護**：計算 Auto-fix commit 數量，≥ 2 次改加 label `needs-human-review` 並通知
- **Verdict 解析**：`echo "$REVIEW" | tail -10 | grep -qE "Verdict[：:]\s*APPROVE"` — 用 `tail -10` 防止 quoted text 誤觸 APPROVE
- **硬路徑安全**：`auto-fix-pr.sh` 中驗證 `git diff --name-only | grep -v "^code/"` 確保 Claude 不修改 `.github/` 等非授權路徑
- **EXIT trap**：`trap 'rm -f "$DIFF_FILE" "${REVIEW_FILE:-}"' EXIT` 統一清理兩個臨時檔

### 4. 修復 GITHUB_TOKEN 不觸發 workflow 問題（commit `305e594`）

- **問題**：GitHub 平台限制：`github-actions[bot]` 使用 `GITHUB_TOKEN` push 的 commit 不會觸發新的 workflow run（防止無限迴圈）
- **修復方案**：使用者新增 `GH_PAT` Personal Access Token secret
  - `pr-review.yml`：checkout 改用 `token: ${{ secrets.GH_PAT }}`，env 加 `GH_TOKEN` + `GH_PAT`
  - `auto-fix-pr.sh`：git push 前 `git remote set-url origin "https://x-access-token:${GH_PAT}@..."` 重設 remote URL
- **QA 驗證**：兩個檔案均通過 V1-V5 全層 QA（SHA256 比對、YAML/bash 語法、動態欄位驗證）

### 5. 端對端測試 PR 自動閉環（3 個 PR）

- **PR #1**（`demo/pr-review-test`）：有免責聲明的 demo 腳本 → REQUEST_CHANGES（含免責聲明不影響審查）
- **PR #2**（`demo/auto-pilot-test`）：check-disk-usage.sh 有說明 intentional bug → APPROVE → **auto-merged**
- **PR #3**（`demo/backup-script`）：backup-files.sh 有真實 bug（no `set -e`、未引號、`find` 缺括號）
  - Round 1：REQUEST_CHANGES → auto-fix pushed（但 GITHUB_TOKEN push 未觸發 Round 2）
  - GH_PAT 修復後推新 commit → Round 2 觸發 → **APPROVE → auto-merged at 09:12:33**
  - **完整閉環驗證成功**

## 關鍵技術決定

| 決定 | 原因 |
|------|------|
| `if ! SCAN_RESULT=$(cmd)` 而非裸 subshell | `set -e` + command substitution 的 exit code 傳播機制 |
| `--dangerously-skip-permissions` 用於 CI | CI 無 TTY，claude 會卡在互動提示 |
| `tail -10` 搭配 Verdict grep | 防止 review 內容引用文字含「APPROVE」造成誤判 |
| `git remote set-url` 用 PAT | GITHUB_TOKEN 的 push 不觸發 workflow（GitHub 平台硬規則）|
| 硬路徑安全 `grep -v "^code/"` | 防止 `--dangerously-skip-permissions` 下 Claude 修改 .github/ 等敏感路徑 |
| auto-fix 迴圈上限 2 次 | 防止永久迴圈，超限後走人工介入流程 |

## 產出檔案

| 檔案 | 狀態 | 說明 |
|------|------|------|
| `.github/workflows/security-scan.yml` | 修改 | 修復 set -e + dangerously-skip-permissions |
| `.github/workflows/pr-review.yml` | 修改 | auto-pilot + GH_PAT 支援 |
| `.github/scripts/review.sh` | 修改 | 修復 JSON 格式、新增 Phase 1/2 auto-pilot |
| `.github/scripts/auto-fix-pr.sh` | 新增 | 145→152 行，含硬路徑安全 + GH_PAT remote URL |
| `code/part4-cicd/demo/cleanup-old-logs.sh` | 新增 | PR #1 demo（intentional bugs） |
| `code/part4-cicd/demo/check-disk-usage.sh` | 新增 | PR #2 demo（intentional bugs declared） |
| `code/part4-cicd/demo/backup-files.sh` | 新增 | PR #3 demo，Round 1 auto-fix 修正後 approved |

## Git Commits（本 session 範圍）

```
305e594 修復：使用 GH_PAT 觸發 PR 工作流（繞過 GITHUB_TOKEN 限制）
1c1abfe 新增：PR 全自動 AI 處理（Phase 1 auto-merge + Phase 2 auto-fix）
a34f2ad 修復：review.sh 移除雙層 JSON 包裝
5c157c1 修復：security-scan.yml claude 非零退出碼導致 set -e 提前終止
```

---

## HANDOFF（下次 session 優先處理）

### 立即行動

- [ ] **Chapter 5：安全性增強**（依 doc/ch5-security.md 大綱）— security-scan.yml 已有基礎，可延伸加 SAST 工具（shellcheck CI integration）
- [ ] **auto-fix-pr.sh nice-to-have**：git push 後加 `git remote set-url origin "https://github.com/${GITHUB_REPOSITORY}.git"` 還原無 token URL（QA reviewer 建議，避免 token 暴露在 `git remote -v`）
- [ ] **PR #1 未完成閉環**：`demo/pr-review-test` 分支仍 OPEN，可考慮 close 或繼續做 demo

### 進行中（需接續）

- `demo/backup-script` 分支已 **MERGED** 到 main（09:12:33）
- `demo/auto-pilot-test` 分支已 **MERGED** 到 main（PR #2）
- 主分支 main 最新 commit：`305e594`

### 注意事項

- **GH_PAT secret 已設在 GitHub Repo**（使用者確認），但此 secret 會過期，需定期更新
- **`--dangerously-skip-permissions` 是 CI 必要旗標**，本機開發時不需要，勿混用
- **auto-fix 只修改 `code/` 目錄**，這是刻意設計的安全限制，不能改放寬
- Security Scan 工作流 `--permission-mode plan` 確保 Claude 只讀不寫，這個限制要保留
- PR #3 Round 2 審查 verdict 是 APPROVE（改善後的腳本通過），但仍有 Warning：未驗證 SRC_DIR 是否為有效目錄
