# 第 5 課演練記錄：Plan Mode 安全護欄

> 對應文件：`code-中文/part4-cicd/github-actions/security-scan.yml`

## 課程目標

理解 `--permission-mode plan` 如何在 CI 環境中把 Claude 限制為「只能讀、只能分析、不能改」，
學會設計一個不會意外修改 Production 程式碼的安全性掃描 Workflow，
體會「軟護欄（prompt 約束）」和「硬護欄（Plan Mode 系統限制）」的根本差異。

## 工作目錄

`code-中文/part4-cicd/demo/05-PlanMode安全護欄/`

---

## Step 1：閱讀 security-scan.yml，分析兩層安全機制

### 閱讀任務

打開 `github-actions/security-scan.yml`，回答：

1. 這個 Workflow 在什麼事件下觸發？（看 `on:` 區塊）

   答：

2. 執行 Claude 的那個 `run:` 步驟用了哪個引數讓 Claude 進入唯讀模式？

   答：

3. `--permission-mode plan` 和在 prompt 裡說「不要修改任何檔案」有什麼本質上的差別？

   | 方式 | 機制 | 能被繞過嗎？ |
   |------|------|-------------|
   | Prompt 說「不要修改」 | | |
   | `--permission-mode plan` | | |

4. 報告最後被存到哪個檔案，用什麼 Actions 步驟上傳？

   答：

### 實際結果

（演練時填入）

---

## Step 2：本機模擬安全掃描

### 概念說明

GitHub Actions 在雲端跑，但我們可以在本機用相同的 `--permission-mode plan` 引數模擬同樣效果：

```
--permission-mode plan
  ↓
Claude 進入計畫模式
  ↓
可以：Read / Grep / Glob / 產生分析報告
不可以：Write / Edit / Bash（任何會改檔案的操作）
  ↓
即使 prompt 要求修改，也會被系統層攔截（不是靠 AI 自律）
```

### 指令

從專案根目錄執行：

```bash
cd c:/Users/user/workspace/kindle-20-65-automation-patterns

claude --permission-mode plan -p \
  "分析 code-中文/part4-cicd/scripts/ 目錄下的所有 .sh 腳本，
   找出以下安全問題：
   1. SQL injection 或 command injection 風險
   2. 未驗證的外部輸入（未 quote 的變數）
   3. 硬編碼的路徑（應用 \$HOME 代替 /c/Users/...）
   每個問題請附上：檔案名稱、行號、嚴重程度（Critical/High/Medium）
   只輸出報告，不要提問，不要修改任何檔案。" \
  --output-format json < /dev/null | jq -r '.result'
```

### 觀察重點

1. Claude 有沒有嘗試修改任何檔案？（觀察工具呼叫記錄）

   答：

2. 報告中找到了哪些問題？嚴重程度如何？

   答：

3. 整個掃描耗時多久？

   答：

### 實際結果

（演練時填入）

---

## Step 3：驗證「硬護欄」的效果

### 實驗

故意在 prompt 裡要求 Claude 修改檔案，看 Plan Mode 能否攔截：

```bash
cd c:/Users/user/workspace/kindle-20-65-automation-patterns

claude --permission-mode plan -p \
  "Read code-中文/part4-cicd/scripts/basic-ci.sh，
   然後在第一行加上 # 這行是 Plan Mode 測試 的注解並儲存檔案。" \
  --max-turns 3 < /dev/null
```

### 觀察

1. Claude 說它要做什麼？（有沒有提出修改計畫）

   答：

2. 最終結果：檔案被修改了嗎？（執行後用 `git diff` 確認）

   ```bash
   git diff code-中文/part4-cicd/scripts/basic-ci.sh
   ```

   答：

3. 這說明了 Plan Mode 的什麼特性？

   答：

### 實際結果

（演練時填入）

---

## Step 4：思考三種安全場景的護欄選擇

### 填表練習

| 場景 | 適合的護欄 | 原因 |
|------|-----------|------|
| 安全性掃描（只讀） | `--permission-mode plan` | 系統層攔截，不依賴 AI 自律 |
| 自動 commit 訊息 | | |
| 測試失敗自動修復 | | |
| PR 程式碼審查留言 | | |

### 思考問題

1. 為什麼安全性掃描選 Plan Mode，而不是用 `--allowedTools "Read,Grep,Glob"` 白名單？

   答：

2. 如果 CI 機器的 ANTHROPIC_API_KEY 洩漏了，Plan Mode 能保護什麼？不能保護什麼？

   答：

### 實際結果

（演練時填入）

---

## 本課重點

```
Plan Mode 的本質：
  --permission-mode plan
  ↓
  系統層鎖定 Write/Edit/Bash(寫入) 等工具
  ↓
  即使 AI 想改，工具呼叫也會被 harness 攔截
  ↓
  不是靠 prompt 說「不要改」（那是軟護欄，AI 可以「改變主意」）

兩種護欄的對比：
  軟護欄（prompt 約束）：AI 遵守 = 看 AI 的「品性」，沒有系統保證
  硬護欄（Plan Mode）：系統強制 = 沒有例外，即使 AI 試圖繞過也無效

CI 安全設計原則：
  分析 / 報告任務 → Plan Mode（完全唯讀）
  修復 / commit 任務 → allowedTools 白名單（最小化可寫工具）
  推送到 main → 永遠需要人工審核（絕對不讓 AI 直接 push main）
```
