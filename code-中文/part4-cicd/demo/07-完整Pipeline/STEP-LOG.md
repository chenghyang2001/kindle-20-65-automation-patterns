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

### 閱讀任務

打開 `github-actions/pr-review.yml` 和 `github-actions/auto-fix.yml`，填入流程：

#### pr-review.yml 的觸發條件

| 欄位 | 值 |
|------|-----|
| 觸發事件 | |
| 觸發類型 | |
| 需要的 Permission | |
| 呼叫的腳本 | |

#### auto-fix.yml 的觸發條件

| 欄位 | 值 |
|------|-----|
| 觸發事件（監聽哪個 Workflow） | |
| 觸發條件 | |
| 失敗輸出存在哪裡 | |
| 呼叫的腳本 | |

### 填入完整流程圖

```
開發者 push PR
  ↓
[pr-review.yml 觸發]
AI 讀 diff → _____________ → 留 PR 留言
  ↓
開發者合併 PR → 主線測試執行
  ↓（若測試失敗）
[auto-fix.yml 觸發]
AI 讀 test-output.txt → _____________ → _____________
  ↓
等待 _____________ 審核
```

### 實際結果

（演練時填入）

---

## Step 2：理解「Verify → Fix → Verify」迴圈

### 概念說明

auto-fix.yml 的安全設計原則：

```
測試失敗（CI 偵測）
  ↓
AI 讀取失敗輸出 → 分析根本原因
  ↓
AI 嘗試修復（有 Write 權限，但只在 feature branch）
  ↓
AI 執行測試驗證修復是否有效
  ↓（修復成功）
AI 開 PR（不直接 push main！）
  ↓
人類審核 → 決定合併
```

### 思考問題

1. 為什麼 auto-fix.yml 的最後一步是「開 PR」而不是「直接 push main」？

   答：

2. 如果 AI 修復失敗（測試還是過不了），流程應該怎麼處理？

   答：

3. commit 訊息裡加入 `[skip actions]` 標籤的目的是什麼？（防止什麼？）

   答：

### 實際結果

（演練時填入）

---

## Step 3：整合前六課技術，填入對應課程

### 對應表

| Pipeline 步驟 | 使用的技術 | 對應第幾課 |
|--------------|-----------|----------|
| `claude -p` 背景執行 | | 第 1 課 |
| `--output-format json` + `jq` | | 第 2 課 |
| Conventional Commits 自動 commit | | |
| `--resume $SESSION_ID` | | |
| `--permission-mode plan` | | |
| 多個 `&` 平行審查 | | |

### 填入 7 個步驟的完整 Pipeline

設計一個從「PR 開啟」到「main 合併」的完整七步驟流程，每步標注用哪個引數：

```
步驟 1：PR 開啟時
  → claude -p "審查 diff，找出..."
  → 引數：_______________________________
  → 輸出：留 PR 留言

步驟 2：PR 合併後，跑測試
  → CI 執行 npm test / pytest
  → 失敗時 → 進步驟 3

步驟 3：分析失敗原因
  → claude -p "讀 test-output.txt，分析根本原因..."
  → 引數：_______________________________
  → 輸出：SESSION_ID 存起來

步驟 4：根據分析結果修復
  → 引數：--resume $SESSION_ID _______________________________
  → 輸出：修復後的程式碼

步驟 5：驗證修復是否有效
  → 引數：--resume $SESSION_ID _______________________________
  → 輸出：pass / fail

步驟 6：Commit 修復內容
  → 引數：_______________________________
  → commit message 用 fix: 前綴 + [skip actions] 避免無限循環

步驟 7：開 PR 等待人工審核
  → 使用 gh pr create
  → 永遠不直接 push main
```

### 實際結果

（演練時填入）

---

## Step 4：設定你的 repository 使用 AI Review（模擬）

### 思考問題

如果你現在管理一個真實的 GitHub repository，要導入 pr-review.yml，
你需要在 GitHub 的哪個地方設定 `ANTHROPIC_API_KEY`？

答：

### 安全考量 Checklist

在真實環境導入這套 Pipeline 之前，確認以下事項：

```
- [ ] ANTHROPIC_API_KEY 存在 GitHub Secrets，不在程式碼裡
- [ ] auto-fix 的 PR 需要至少一位人類 reviewer 批准才能合併
- [ ] Workflow 只對 feature branch 有寫入權限，main 分支保護開啟
- [ ] auto-fix 的 commit 訊息加入 [skip actions] 避免觸發無限迴圈
- [ ] 設定每月 API 費用上限（Anthropic console）
- [ ] PR review 的留言格式在 prompt 裡明確規定（必填：嚴重程度）
```

逐一確認並回答：哪幾項在你現有的設定中已經具備？

答：

### 實際結果

（演練時填入）

---

## Step 5：組合拳——本課 7 堂課的整合

### 回顧

把第 1 到第 6 課學的技術統一用一句話描述它在 Pipeline 裡解決的問題：

| 課程 | 技術 | 在 Pipeline 裡解決什麼問題 |
|------|------|--------------------------|
| 第 1 課 | `claude -p` 無頭模式 | |
| 第 2 課 | `--output-format json` | |
| 第 3 課 | 自動 commit 訊息 | |
| 第 4 課 | `--resume $SESSION_ID` | |
| 第 5 課 | `--permission-mode plan` | |
| 第 6 課 | 平行 `&` + `wait` | |

### 實際結果

（演練時填入）

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
