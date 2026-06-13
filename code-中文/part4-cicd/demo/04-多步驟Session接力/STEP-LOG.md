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
| Step 1 | | |
| Step 2 | | |
| Step 3 | | |

回答：

1. Step 1 抓出的 `session_id` 存在哪個變數？

   答：

2. Step 2 和 Step 3 用什麼引數來接力 Step 1 的記憶？

   答：

3. Step 3 為什麼又加了 `--allowedTools "Read"` 限制？（Step 2 沒有限制）

   答：

4. 如果不用 `--resume`，Step 2 要重新做什麼事才能有 Step 1 的上下文？

   答：

### 實際結果

（演練時填入）

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

### 實際結果

（演練時填入）

---

## Step 3：實際執行 multi-step-ci.sh

### 指令

```bash
cd c:/Users/user/workspace/kindle-20-65-automation-patterns
bash code-中文/part4-cicd/scripts/multi-step-ci.sh
```

### 觀察重點

1. Step 1 輸出的 Session ID 格式（記下來）：

   答：

2. Step 2 說的「前 3 大改進項目」是什麼？

   答：

3. Step 3 有沒有重新讀取任何檔案？（觀察它有沒有 Read 工具的呼叫）

   答：

4. 整個流程執行了多久？

   答：

### 實際結果

（演練時填入）

---

## Step 4：設計你自己的三步驟 Pipeline

### 練習

參考 multi-step-ci.sh 的結構，設計一個「PR 審查三步驟 Pipeline」的偽代碼：

```bash
# Step 1：分析 PR 的程式碼差異（做什麼？存什麼？）
SESSION_ID=$(claude -p "___________" \
  --allowedTools "___________" \
  --output-format json < /dev/null | jq -r '.session_id')

# Step 2：基於分析結果，找出安全漏洞（用什麼引數接力？）
claude -p "___________" \
  --___________ "$SESSION_ID" \
  --output-format json < /dev/null | jq -r '.result'

# Step 3：生成 PR 留言草稿（唯讀，只報告）
claude -p "___________" \
  --resume "$SESSION_ID" \
  --allowedTools "___________" \
  --max-turns 3 < /dev/null
```

### 實際結果

（演練時填入）

---

## 本課重點

```
Session 記憶接力三步驟：
  1. Step 1 執行後 → jq -r '.session_id' 存起來
  2. Step 2 加上 → --resume $SESSION_ID
  3. Step 3 繼續 → --resume $SESSION_ID（可加更嚴格的 --allowedTools）

記憶接力的雙重效益：
  省錢：不重新讀檔 → Input token 大幅降低
  準確：思考脈絡完整延續 → 不需要重新推論

設計原則：
  越後面的步驟，--allowedTools 應該越嚴格
  （分析 → 推薦 → 唯讀報告，權限逐步收緊）
```
