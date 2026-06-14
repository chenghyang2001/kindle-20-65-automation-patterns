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
| 模式 1 | `.result` | 取 AI 的純文字答案（給人看 / 給下游腳本） |
| 模式 2 | `.session_id` | 存起來供 `--resume` 接力下一步 |
| 模式 3 | `.structured_output` | 取符合 `--json-schema` 規定的結構化 JSON |
| 模式 4 | `.event.delta.text` | stream-json 逐 token 串流，即時顯示 |

回答：

1. 如果不用 `--output-format json`，下游腳本要怎麼判斷 AI 失敗了？為什麼這很困難？

   答：只能靠 exit code（但 exit 0 不保證 AI 任務成功），或解析自然語言（但「抱歉」「失敗」「出錯了」在不同語言下措辭不同，regex 會漏掉）。`--output-format json` 提供 `.is_error` 布林欄位，精準可靠。

2. `--json-schema` 定義了什麼？如果 AI 回傳的格式不符合，會怎樣？

   答：定義 AI 回答的 JSON 結構（欄位名稱 + 型別 + 必填欄位）。不符合時 Claude CLI 會自動要求 Claude 重試，直到格式正確才回傳。結果保證放在 `.structured_output` 欄位，不是 `.result`。

3. `stream-json` 和一般 `json` 的差異是什麼？什麼情況下需要用 `stream-json`？

   答：`stream-json` 每產生一個 token 就輸出一行 JSON 事件；`json` 等 AI 全部回答完再輸出一整包。需要「即時顯示進度」（如長任務讓使用者看到 AI 正在工作）或「提前終止」（看到某關鍵字就停）時用 stream-json。

### 實際結果

✅ 四種模式分析完成

---

## Step 2：`--resume` 接力機制 — 多步串接 vs 單次多回合

### `--output-format json` 的真正作用

`--output-format json` 是 Claude CLI 的格式指令，不是讓 AI 輸出 JSON。
它把 AI 的回應（無論是文字還是結構化資料）包成 JSON envelope：

```json
{
  "result": "AI 說的那段文字",
  "session_id": "abc123-...",
  "is_error": false,
  "cost_usd": 0.001
}
```

只有加了 `--json-schema` 才會強制 AI 回答本身是 JSON，並放進 `.structured_output`。

### `--resume` 接力：多步串接

```bash
SESSION=$(claude -p "分析所有 hook 腳本..." --output-format json < /dev/null | jq -r '.session_id')
claude -p "根據你剛才的分析，哪個 hook 最重要？" --resume $SESSION < /dev/null
```

**Token 成本**：`--resume` 每次都把完整歷史重送，session 越長越貴。

**沒有 `--resume`**：第二個 `claude -p` 是全新 session，看不到任何第一步內容。

### 多步串接 vs 單次 `--max-turns`

| 面向 | `--resume` 多步串接 | 單次 `--max-turns N` |
|------|-------------------|---------------------|
| 控制者 | Shell 腳本（你決定下一步） | Claude 自己決定再轉幾圈 |
| 中間結果 | 可被 `jq` 抓出 → 條件判斷 | 黑盒，只有最後結果 |
| 適合情境 | 步驟依賴外部系統（跑測試、等 API） | 全部在 Claude 內部能完成的任務 |

**設計原則**：步驟之間需要插入 shell 邏輯（if/else、curl）→ `--resume` 串接；全部讓 Claude 搞定 → `--max-turns N`。

### 實際結果

✅ 接力機制分析完成

---

## Step 3：`--json-schema` 強制結構化輸出

### 有無 schema 對應不同欄位

```
沒有 --json-schema：
  AI 輸出文字 → 放進 {"result": "...", "session_id": "..."}
  取用：jq '.result'

有 --json-schema：
  AI 強制輸出符合 schema 的 JSON → 放進 {"structured_output": {...}, ...}
  取用：jq '.structured_output'
  注意：此時 .result 可能是 null
```

### 何時必須用 `--json-schema`

| 情境 | 方案 |
|------|------|
| 給人看的報告，順便要 JSON 格式 | `prompt 裡說 "output JSON"` 就夠 |
| CI pipeline 要 `jq` 解析 → 下一步邏輯依賴結果 | **`--json-schema` 必須用** |
| 多步 `--resume` 串接，中間步驟是下一步的輸入 | **`--json-schema` 必須用** |

**核心原則**：有下游程式解析這個輸出 → `--json-schema`（合約，不是請求）。

### 實際結果

✅ 結構化輸出機制分析完成

---

## Step 4：設計 PR 審查 JSON Schema

### 練習：設計可供 pipeline 使用的 schema

**需求**：CI 判斷 PR 可否合併，需要三個欄位：


- `can_merge`：布林值
- `blocking_issues`：字串陣列
- `severity`：只能是 `"low"` / `"medium"` / `"high"`

```json
{
  "type": "object",
  "properties": {
    "can_merge": {
      "type": "boolean"
    },
    "blocking_issues": {
      "type": "array",
      "items": {"type": "string"}
    },
    "severity": {
      "type": "string",
      "enum": ["low", "medium", "high"]
    }
  },
  "required": ["can_merge", "blocking_issues", "severity"]
}
```

**三個欄位設計要點：**

| 欄位 | 關鍵 schema 語法 | 作用 |
|------|----------------|------|
| `can_merge` | `"type": "boolean"` | 強制 true/false，不接受 "yes"/"no" |
| `blocking_issues` | `"items": {"type": "string"}` | 每個元素必須是字串 |
| `severity` | `"enum": ["low","medium","high"]` | 只允許三個值，其他字串拒絕 |

**CI 使用範例：**

```bash
REVIEW=$(claude -p "Review this PR." \
  --allowedTools "Read,Glob" --output-format json \
  --json-schema '{...}' < /dev/null | jq '.structured_output')

if [ "$(echo $REVIEW | jq '.can_merge')" = "false" ]; then
  echo "❌ $(echo $REVIEW | jq -r '.blocking_issues[]')"
  exit 1
fi
```

### 實際結果

✅ PR 審查 schema 設計完成

---

## 本課重點

```
四種輸出模式：
  模式 1：--output-format json | jq '.result'     → 取文字答案
  模式 2：--output-format json | jq '.session_id' → 取 ID 供 --resume 接力
  模式 3：--output-format json --json-schema       → 強制結構化，取 .structured_output
  模式 4：--output-format stream-json              → 逐 token 串流

機器溝通鐵律：
  下游腳本不能解析自然語言（「好的」「抱歉」「失敗」）
  必須用 .is_error 做判斷 → 精準、快速、不受語氣影響

三個核心原則：
  --output-format json = CLI 包裝，不是 AI 輸出 JSON
  有下游程式解析 → 必須用 --json-schema（合約，不是請求）
  --resume = 接力成本 = 每步都要送一次完整歷史
```
