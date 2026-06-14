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

   答：`push` 到 `main` 分支，以及對 `main` 發出的 `pull_request`，兩種事件都會觸發。

2. 執行 Claude 的那個 `run:` 步驟用了哪個引數讓 Claude 進入唯讀模式？

   答：`--permission-mode plan`（第 21 行）

3. `--permission-mode plan` 和在 prompt 裡說「不要修改任何檔案」有什麼本質上的差別？

   | 方式 | 機制 | 能被繞過嗎？ |
   |------|------|-------------|
   | Prompt 說「不要修改」 | 語言層約束，依賴 AI 遵守 | **能** — AI 可能被後續 prompt 說服或「誤解」需求而改變行為 |
   | `--permission-mode plan` | 系統層鎖定，harness 攔截 Write/Edit/Bash(寫入) 的工具呼叫 | **不能** — AI 即使「想改」，工具呼叫在執行前就被攔截，不會落地 |

4. 報告最後被存到哪個檔案，用什麼 Actions 步驟上傳？

   答：存到 `security-report.txt`；用 `actions/upload-artifact@v4` 上傳，artifact 名稱為 `security-report`。

### 實際結果

讀取 `security-scan.yml` 確認：on 觸發為 push/PR to main，唯讀引數為 `--permission-mode plan`，報告存至 `security-report.txt` 並由 `upload-artifact@v4` 上傳。

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

   答：**沒有**。整個過程只有 Read/Grep/Glob 工具呼叫，零個 Write/Edit 呼叫——這正是 `--permission-mode plan` 的效果。

2. 報告中找到了哪些問題？嚴重程度如何？

   答：共 10 個 **Medium** 問題，0 個 Critical/High：
   - 硬編碼路徑（4 支腳本第 6 行，`C:/Users/B00332/...`）
   - 缺 `set -e` / `set -o pipefail`（3 支腳本）
   - jq 吞掉上游失敗（SESSION_ID 可能變 `"null"`）
   - 暫存目錄未清理（`parallel-review.sh` 缺 `trap` 清除）
   - PID 未 quote（慣例違反）

3. 整個掃描耗時多久？

   答：（實際執行時觀察填入）

### 實際結果

執行成功。Claude 產出完整安全審查報告，掃描了 5 支 .sh 腳本，找到 10 個 Medium 問題，**全程零 Write/Edit 工具呼叫**，驗證 Plan Mode 確實限制了寫入能力。

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

   答：Claude 讀取檔案後提出修改計畫（說「我打算在第一行加上注解」），但接著告知「在 Plan Mode 下無法執行寫入操作」。

2. 最終結果：檔案被修改了嗎？（執行後用 `git diff` 確認）

   ```bash
   git diff code-中文/part4-cicd/scripts/basic-ci.sh
   ```

   答：**git diff 輸出為空**，檔案完全未被修改。

3. 這說明了 Plan Mode 的什麼特性？

   答：Plan Mode 的攔截發生在**工具呼叫層**，不是在 AI 的推理層——AI 可以思考「要修改」，但呼叫 Write/Edit 時 harness 直接拒絕執行。想法存在，行動不落地。

### 實際結果

驗證成功：Claude 在 Plan Mode 下無法修改任何檔案，即使 prompt 明確要求，硬護欄依然生效。

---

## Step 4：思考三種安全場景的護欄選擇

### 填表練習

| 場景 | 適合的護欄 | 原因 |
|------|-----------|------|
| 安全性掃描（只讀） | `--permission-mode plan` | 系統層攔截，不依賴 AI 自律 |
| 自動 commit 訊息 | `--allowedTools "Bash(git status *),Bash(git diff *),Bash(git commit *)"` | 需要寫入（commit），但範圍限定為 git 三指令；白名單比 Plan Mode 更精準 |
| 測試失敗自動修復 | `--allowedTools "Read,Edit,Bash(pytest *)"` + 人工審核 gate | 必須可以改檔案，但限制只能跑測試；最終 push 留給人工 |
| PR 程式碼審查留言 | `--allowedTools "Bash(gh pr review *)"` | 只需要呼叫 GitHub CLI 留言，零寫入本地檔案 |

### 思考問題

1. 為什麼安全性掃描選 Plan Mode，而不是用 `--allowedTools "Read,Grep,Glob"` 白名單？

   答：`--allowedTools` 白名單是「我只給你這些工具」，若未來有人加了新工具（如 `WebFetch`）白名單要手動更新。`--permission-mode plan` 是「整個模式切換為唯讀」，所有現有和未來的寫入工具一律攔截，不需逐一列舉。Plan Mode 更適合「永遠不能寫」的場景。

2. 如果 CI 機器的 ANTHROPIC_API_KEY 洩漏了，Plan Mode 能保護什麼？不能保護什麼？

   答：
   - **能保護**：CI 機器上的原始碼不被竄改——即使攻擊者送出惡意 prompt，Plan Mode 讓 Claude 無法 Write/Edit 任何檔案
   - **不能保護**：程式碼被讀取（Read/Grep 仍可執行，原始碼可被外洩到輸出結果中）
   - **不能保護**：API 額度被濫用（Key 洩漏本身造成帳單損失，Plan Mode 管不到）

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

Plan Mode vs allowedTools 選擇原則：
  「永遠不能寫」→ Plan Mode（防未來工具擴充）
  「只允許特定寫入」→ allowedTools 白名單（精準控制）
  API Key 洩漏 → Plan Mode 保護程式碼完整性，但無法防讀取洩漏
```
