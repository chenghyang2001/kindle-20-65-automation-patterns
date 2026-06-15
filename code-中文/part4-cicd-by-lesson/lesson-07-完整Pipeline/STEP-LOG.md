# 第 7 課演練記錄：完整 CI/CD Pipeline

> 對應文件：
>
> - `code-中文/part4-cicd/github-actions/pr-review.yml`
> - `code-中文/part4-cicd/github-actions/auto-fix.yml`

## 課程目標

把前六課的技術整合成真實的生產級 CI/CD Pipeline：
PR 提交 → AI 審查留言 → 測試失敗 → AI 自動修復 → 開 PR 等待人工確認。
理解什麼時候 AI 可以自動執行，什麼時候必須停下來等待人類決策。

## 工作目錄

`code-中文/part4-cicd/demo/07-完整Pipeline/`

---

## Step 1：閱讀兩個 Workflow，拼出完整流程圖

### pr-review.yml 的觸發條件

| 欄位 | 值 |
|------|-----|
| 觸發事件 | `pull_request` |
| 觸發類型 | `opened`、`synchronize`（開 PR 和每次新 push 都觸發） |
| 需要的 Permission | `pull-requests: write`（才能留 PR 留言） |
| 呼叫的腳本 | `.github/scripts/review.sh ${{ github.event.pull_request.number }}` |

### auto-fix.yml 的觸發條件

| 欄位 | 值 |
|------|-----|
| 觸發事件（監聽哪個 Workflow） | `workflow_run`，監聽 **"Run Tests"** |
| 觸發條件 | `github.event.workflow_run.conclusion == 'failure'`（只在測試失敗時執行） |
| 失敗輸出存在哪裡 | `test-output.txt`（`npm test 2>&1 \| tee test-output.txt` 產生） |
| 呼叫的腳本 | `.github/scripts/auto-fix.sh` |

### 完整流程圖

```
開發者 push PR
  ↓
[pr-review.yml 觸發]
AI 讀 diff → 分析程式碼問題（安全/品質/規範） → 留 PR 留言
  ↓
開發者合併 PR → 主線測試執行（"Run Tests" Workflow）
  ↓（若測試失敗）
[auto-fix.yml 觸發]
AI 讀 test-output.txt → 分析根本原因 + 嘗試修復 + 執行測試驗證 → 開 PR（不直接 push main）
  ↓
等待 人類 reviewer 審核
```

### 實際結果

讀取 pr-review.yml 和 auto-fix.yml 確認：兩個 Workflow 串成完整 PR → 合併 → 修復 → 人工審核的閉環 Pipeline。

---

## Step 2：理解「Verify → Fix → Verify」迴圈

### 思考問題

1. 為什麼 auto-fix.yml 的最後一步是「開 PR」而不是「直接 push main」？

   答：AI 可能修錯（測試通過不代表邏輯正確）；main 直接修改影響所有人且難回滾；開 PR 保留人類最後把關點——合併決策永遠屬於人類。

2. 如果 AI 修復失敗（測試還是過不了），流程應該怎麼處理？

   答：設最大重試次數（如 3 次），超過後：(1) 開失敗狀態的 PR 說明需人工介入，或 (2) 直接發通知（Slack/Telegram）讓人類接手。不設上限會造成無限重試迴圈，燒光 API 額度。

3. commit 訊息裡加入 `[skip actions]` 標籤的目的是什麼？

   答：防止無限觸發迴圈。AI commit → 觸發 "Run Tests" → 若失敗 → 觸發 auto-fix → AI 再 commit → 無限循環。加 `[skip actions]` 後 GitHub Actions 跳過觸發，打破迴圈。

### 實際結果

理解三鐵律：AI 不直接 push main、`[skip actions]` 防無限迴圈、最小化修改範圍。

---

## Step 3：整合前六課技術，填入對應課程

### 對應表

| Pipeline 步驟 | 使用的技術 | 對應第幾課 |
|--------------|-----------|----------|
| `claude -p` 背景執行 | CI 不掛起、exit code 判斷 | 第 1 課 |
| `--output-format json` + `jq` | 擷取 `.result` / `.session_id` | 第 2 課 |
| Conventional Commits 自動 commit | `fix:` 前綴 + `[skip actions]` | 第 3 課 |
| `--resume $SESSION_ID` | 分析 → 修復 → 驗證三步共享脈絡 | 第 4 課 |
| `--permission-mode plan` | PR 審查唯讀，不改生產程式碼 | 第 5 課 |
| 多個 `&` 平行審查 | 安全/品質/規範同時跑 | 第 6 課 |

### 完整七步驟 Pipeline

```
步驟 1：PR 開啟時
  → claude -p "審查 diff，找出安全/品質/規範問題..."
  → 引數：--permission-mode plan --allowedTools "Bash(gh pr review *)"
  → 輸出：留 PR 留言

步驟 2：PR 合併後，跑測試
  → CI 執行 npm test / pytest
  → 失敗時 → 進步驟 3

步驟 3：分析失敗原因
  → claude -p "讀 test-output.txt，分析根本原因..."
  → 引數：--permission-mode plan --output-format json
  → 輸出：SESSION_ID 存起來

步驟 4：根據分析結果修復
  → 引數：--resume $SESSION_ID --allowedTools "Read,Edit,Bash(pytest *)"
  → 輸出：修復後的程式碼

步驟 5：驗證修復是否有效
  → 引數：--resume $SESSION_ID --allowedTools "Bash(pytest *)" --permission-mode plan
  → 輸出：pass / fail

步驟 6：Commit 修復內容
  → 引數：--allowedTools "Bash(git add *),Bash(git commit *)" --max-turns 2
  → commit message 用 fix: 前綴 + [skip actions] 避免無限循環

步驟 7：開 PR 等待人工審核
  → 使用 gh pr create
  → 永遠不直接 push main
```

### 實際結果

六課技術在七步驟 Pipeline 中各司其職，形成完整閉環。

---

## Step 4：設定你的 repository 使用 AI Review（模擬）

### 思考問題

如果你現在管理一個真實的 GitHub repository，要導入 pr-review.yml，
你需要在 GitHub 的哪個地方設定 `ANTHROPIC_API_KEY`？

答：GitHub repository → **Settings → Secrets and variables → Actions → New repository secret**，名稱設為 `ANTHROPIC_API_KEY`。Workflow 用 `${{ secrets.ANTHROPIC_API_KEY }}` 讀取，永遠不出現在程式碼或 log 裡。

### 安全考量 Checklist

| 項目 | 狀態 | 說明 |
|------|------|------|
| `ANTHROPIC_API_KEY` 存在 GitHub Secrets | ✅ 已具備 | yml 裡用 `${{ secrets.ANTHROPIC_API_KEY }}`，不硬編碼 |
| auto-fix 的 PR 需人類 reviewer 批准 | ⚠️ 需手動設定 | 要在 branch protection rule 開 "Require approvals" |
| Workflow 只對 feature branch 有寫入權限 | ⚠️ 需手動設定 | 預設 GITHUB_TOKEN 有 main 寫入權；要設 branch protection |
| auto-fix commit 加 `[skip actions]` | ✅ 已設計 | 七步驟流程已包含此設計 |
| 設定每月 API 費用上限 | ⚠️ 需手動設定 | 到 Anthropic console → Billing → Usage limits 設定 |
| PR review 留言格式在 prompt 明確規定 | ✅ 已設計 | review.sh 的 prompt 應含格式規範（嚴重程度必填） |

### 實際結果

6 項 Checklist：3 項已具備，3 項需在 GitHub 設定後才能完整保護生產環境。

---

## Step 5：組合拳——本課 7 堂課的整合

### 回顧

| 課程 | 技術 | 在 Pipeline 裡解決什麼問題 |
|------|------|--------------------------|
| 第 1 課 | `claude -p` 無頭模式 | 讓 CI 能在背景呼叫 AI，不掛起 pipeline，用 exit code 判斷成敗 |
| 第 2 課 | `--output-format json` | 從 AI 輸出擷取 `session_id`，讓跨步驟接力成為可能 |
| 第 3 課 | 自動 commit 訊息 | AI 修復後產出符合 Conventional Commits 的 `fix:` commit，加 `[skip actions]` 防無限迴圈 |
| 第 4 課 | `--resume $SESSION_ID` | 分析 → 修復 → 驗證三步共享同一個 context，省 token 且脈絡連貫 |
| 第 5 課 | `--permission-mode plan` | PR 審查步驟完全唯讀，AI 看完 diff 只能留言，不能改生產程式碼 |
| 第 6 課 | 平行 `&` + `wait` | PR 審查同時跑安全/品質/規範三個維度，省 2/3 時間且無思維污染 |

### 實際結果

Part 4 全部 7 課完成。六個技術各司其職，整合成生產可用的 CI/CD Pipeline。

---

## 本課重點

```
完整 Pipeline 的三個鐵律：

  鐵律 1：AI 永遠不直接 push main
    → auto-fix 的最後一步是「開 PR」，等人類決定
    → 保留最後的人類把關點

  鐵律 2：避免無限觸發迴圈
    → AI commit 加 [skip actions] 標籤
    → 否則 auto-fix commit → 觸發測試 → 又觸發 auto-fix → 無限循環

  鐵律 3：最小化 AI 的修改範圍
    → auto-fix 只修復測試失敗的那個問題
    → 不做順手重構、不改不相關的程式碼
    → 改動越小，PR 越容易審核

Pipeline 設計心法：
  分析步驟 → Plan Mode（唯讀，最安全）
  修復步驟 → allowedTools 白名單（最小寫入權限）
  多維度檢查 → 平行執行（省時 + 獨立判斷）
  跨步驟記憶 → --resume（省錢 + 脈絡連貫）
```
