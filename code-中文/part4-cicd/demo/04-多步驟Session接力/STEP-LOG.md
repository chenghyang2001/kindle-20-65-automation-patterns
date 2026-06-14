# 第 4 課演練記錄：多步驟 + Session 記憶接力

> 對應文件：`code-中文/part4-cicd/scripts/multi-step-ci.sh`

## 課程目標

理解為什麼多步驟 Pipeline 需要「記憶接力」，
學會用 `--resume $SESSION_ID` 讓下一個步驟繼承上一步驟的分析狀態，
體驗「不重新讀檔，直接延續思考脈絡」的效果。

## 工作目錄

`code-中文/part4-cicd/demo/04-多步驟Session接力/`

---

## Step 1：閱讀 multi-step-ci.sh，理解三步驟設計

### 閱讀任務

打開 `scripts/multi-step-ci.sh`，填入：

| 步驟 | 做什麼 | 用的引數 |
|------|--------|---------|
| Step 1 | 分析 code/part2-hooks/ 下所有 hook 腳本（觸發事件、功能、工具權限） | `--allowedTools "Read,Grep,Glob"`、`--output-format json` |
| Step 2 | 基於 Step 1 的分析，列出前 3 大改進項目（不重新讀檔） | `--resume "$SESSION_ID"`、`--output-format json` |
| Step 3 | 深入分析最高優先項目，顯示需要修改的確切行號（唯讀，不修改） | `--resume "$SESSION_ID"`、`--allowedTools "Read"`、`--max-turns 5` |

回答：

1. Step 1 抓出的 `session_id` 存在哪個變數？

   答：`$SESSION_ID`（`SESSION_ID=$(claude -p ... | jq -r '.session_id')`）

2. Step 2 和 Step 3 用什麼引數來接力 Step 1 的記憶？

   答：`--resume "$SESSION_ID"`，告訴 Claude CLI 載入 Step 1 session 的完整對話歷史。

3. Step 3 為什麼又加了 `--allowedTools "Read"` 限制？（Step 2 沒有限制）

   答：Step 3 的任務是「唯讀報告」，不應該修改任何檔案。Step 2 沒有限制，AI 理論上可以寫檔。Step 3 加回 `Read` 白名單 = 明確擋掉 Write / Edit / Bash。**越後面的步驟，權限應該越收緊。**

4. 如果不用 `--resume`，Step 2 要重新做什麼事才能有 Step 1 的上下文？

   答：重新傳入 Step 1 讀過的所有檔案內容（重送 10 萬 token），再傳入 Step 1 的分析結論（手動複製貼上）。成本翻倍，且 AI 需要重新建立推理脈絡。

### 實際結果

✅ multi-step-ci.sh 三步驟設計分析完成

---

## Step 2：理解記憶熱插拔的原理

### 概念說明

`--resume` 不只是讀取上一步的文字輸出——它繼承了：

| 繼承的內容 | 說明 |
|-----------|------|
| 思考脈絡 | AI 之前推論出的所有結論 |
| 快取住的檔案內容 | Step 1 讀過的檔案不用再讀一次 |
| 關注的具體項目 | AI 之前標記為重要的行號、函式名 |

### 思考練習

假設 Step 1 讀了 50 個檔案（共 10 萬 token），Step 2 用 `--resume`：

| 方式 | Step 2 的 Input token | 成本 |
|------|--------------------|------|
| 不用 `--resume`（重新讀） | 10 萬 token | 高 |
| 用 `--resume` | 只有 Step 2 的問題（~100 token） | 低 |

1. 記憶接力同時解決了哪兩個問題？

   答：
   - **成本問題**：讀過的檔案快取在 session，Step 2 只送新問題（~100 token），不重送 10 萬 token
   - **準確性問題**：AI 完整記得 Step 1 的推論脈絡和優先排序，不需要重新推論，直接延續思考

### 實際結果

✅ 記憶接力雙重效益分析完成

---

## Step 3：實際執行 multi-step-ci.sh

### 指令

```bash
cd c:/Users/user/workspace/kindle-20-65-automation-patterns
bash code-中文/part4-cicd/scripts/multi-step-ci.sh
```

### 預測結果

1. **Session ID 格式**：UUID v4（例：`a3f7c291-48de-4b12-9e05-7c3d8f6a1b2e`）

2. **Step 2「前 3 大改進項目」預測**：
   - `quality-gate.sh` — 缺 `set -e`，執行失敗時繼續跑，可能掩蓋問題
   - `notify.sh` — 硬編碼路徑，不支援跨機器使用（違反 no-hardcoded-paths 規則）
   - `check_auth.py` — 缺少 timeout 處理，外部 API 無回應時 hook 無限卡住

3. **Step 3 有沒有重新呼叫 Read？**：有，但只補讀具體行號。Step 3 需要精確到「第 23 行改成這樣」才需要再 Read；Step 2 不需要讀檔就能說「哪個問題最嚴重」。

4. **整個流程執行時間預測**：30-90 秒（Step 1 讀多個檔案最慢，Step 2/3 只傳遞新問題，明顯更快）

### 實際結果

✅ 執行結果預測完成

---

## Step 4：設計你自己的三步驟 Pipeline

### 練習：PR 審查三步驟 Pipeline

```bash
# Step 1：分析 PR 的程式碼差異（建立地圖）
SESSION_ID=$(claude -p "Analyze the code changes in the PR: read the diff, understand what changed, identify the files involved and their purposes." \
  --allowedTools "Read,Glob,Bash(git diff *)" \
  --output-format json < /dev/null | jq -r '.session_id')

# Step 2：基於分析結果，找出安全漏洞（只用 context，不重新讀）
claude -p "Based on your analysis, identify security vulnerabilities: SQL injection, hardcoded secrets, missing auth checks, XSS risks. List each with file and line number." \
  --resume "$SESSION_ID" \
  --output-format json < /dev/null | jq -r '.result'

# Step 3：生成 PR 留言草稿（唯讀，只報告，無工具）
claude -p "Based on your security analysis, write a PR review comment in markdown. Include: summary, security findings (blocking), suggestions (non-blocking). Do not modify any files." \
  --resume "$SESSION_ID" \
  --allowedTools "" \
  --max-turns 3 < /dev/null
```

**三步驟的權限遞減：**

```
Step 1：Read + Glob + git diff  → 需要讀檔建立地圖
Step 2：無限制（只用既有 context）  → 在記憶中分析，不需新工具
Step 3：空白名單（--allowedTools ""）  → 純輸出報告，嚴格禁止任何操作
```

### 實際結果

✅ PR 審查三步驟 Pipeline 設計完成

---

## 本課重點

```
Session 記憶接力三步驟：
  1. Step 1 完成後 → jq -r '.session_id' 存入 $SESSION_ID
  2. 後續步驟加上 → --resume "$SESSION_ID"
  3. 越後面的步驟 → --allowedTools 越嚴格（逐步收緊）

記憶接力的雙重效益：
  省錢：不重新讀檔 → Input token 大幅降低
  準確：思考脈絡完整延續 → 不需要重新推論

設計原則：
  分析步驟（需要讀）→ Read + Glob + Bash
  推論步驟（只用記憶）→ 不加限制或只 Read
  報告步驟（只輸出）→ 空白名單或最小工具
```
