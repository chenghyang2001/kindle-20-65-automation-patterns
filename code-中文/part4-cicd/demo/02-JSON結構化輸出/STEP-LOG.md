# 第 2 課演練記錄：JSON 結構化輸出

> 對應文件：`code-中文/part4-cicd/scripts/json-output-patterns.sh`

## 課程目標

理解為什麼 CI Pipeline 不能靠解析自然語言來判斷成功失敗，
學會用 `--output-format json` + `jq` 抓取 `is_error`、`result`、`session_id`，
掌握 `--json-schema` 強制規定輸出結構。

## 工作目錄

`code-中文/part4-cicd/demo/02-JSON結構化輸出/`

---

## Step 1：閱讀 json-output-patterns.sh，理解四種模式

### 閱讀任務

打開 `scripts/json-output-patterns.sh`，填入：

| 模式 | `jq` 抓的欄位 | 用途 |
|------|-------------|------|
| 模式 1 | `.result` | |
| 模式 2 | `.session_id` | |
| 模式 3 | `.structured_output` | |
| 模式 4 | stream event | |

回答：

1. 如果不用 `--output-format json`，下游腳本要怎麼判斷 AI 失敗了？為什麼這很困難？

   答：

2. `--json-schema` 定義了什麼？如果 AI 回傳的格式不符合，會怎樣？

   答：

3. `stream-json` 和一般 `json` 的差異是什麼？什麼情況下需要用 `stream-json`？

   答：

### 實際結果

（演練時填入）

---

## Step 2：執行模式 1，觀察 JSON 輸出結構

### 指令

```bash
cd c:/Users/user/workspace/kindle-20-65-automation-patterns

claude -p "List all .sh files in code-中文/part4-cicd/scripts/ and what each one does in one sentence each." \
  --allowedTools "Glob,Read" \
  --output-format json < /dev/null
```

### 觀察 JSON 結構

執行完後，輸出包含哪些頂層欄位？把欄位名稱列出來：

答：

### 只取 result 欄位

```bash
claude -p "List all .sh files in code-中文/part4-cicd/scripts/ and what each one does in one sentence each." \
  --allowedTools "Glob,Read" \
  --output-format json < /dev/null | jq -r '.result'
```

觀察：有 vs 沒有 `| jq -r '.result'`，輸出差在哪裡？

答：

### 實際結果

（演練時填入）

---

## Step 3：擷取 session_id（為第 4 課準備）

### 指令

```bash
SESSION=$(claude -p "Briefly describe what the parallel-review.sh script does. One sentence." \
  --allowedTools "Read" \
  --output-format json < /dev/null | jq -r '.session_id')

echo "Session ID: $SESSION"
```

### 回答

1. session_id 的格式是什麼？（UUID / 數字 / 其他）

   答：

2. 這個 ID 要怎麼在下一個 `claude -p` 呼叫中使用？（引數是什麼）

   答：

### 實際結果

（演練時填入）

---

## Step 4：用 is_error 做 CI 判斷

### 概念

在真實的 CI Script 中，判斷 AI 是否成功的標準寫法：

```bash
RESULT=$(claude -p "..." --output-format json < /dev/null)
IS_ERROR=$(echo "$RESULT" | jq -r '.is_error')

if [ "$IS_ERROR" = "true" ]; then
  echo "❌ AI 任務失敗" >&2
  exit 1
fi
echo "✅ 成功"
echo "$RESULT" | jq -r '.result'
```

### 思考問題

1. 為什麼要用 `jq -r '.is_error'` 而不是直接看 exit code？

   答：

2. 如果 AI 完成了任務但回答品質很差，`is_error` 會是 true 還是 false？這代表什麼？

   答：

### 實際結果

（演練時填入）

---

## 本課重點

```
JSON 輸出的三個關鍵欄位：

  .result      → AI 的回答（給人看 / 給下游程式處理）
  .is_error    → 任務是否失敗（CI 判斷用，true/false）
  .session_id  → 記憶接力用（--resume 引數帶入）

機器溝通鐵律：
  下游腳本不能解析自然語言（「好的」「抱歉」「失敗」）
  必須用 .is_error 做判斷 → 精準、快速、不受語氣影響

--json-schema 強制規定輸出結構：
  連「欄位名稱錯了」都過不了 → 零解析負擔
```
