# 第 10 課演練記錄：prompt-hook-examples.json

> 範例檔：`quality/prompt-hook-examples.json`（Prompt Hook — AI 評判 AI）

## 課程目標

學習 `type: "prompt"` Hook：
不執行 shell 腳本，而是讓 **AI 模型當評判官**，
動態判斷是否允許 Claude Code 繼續執行。

## 工作目錄

`code-中文/part2-hooks/quality/demo-prompt-hooks/`

---

## Step 1：建立 demo 目錄，解析三種 Prompt Hook 結構

### 指令

```bash
mkdir -p demo-prompt-hooks/
cp quality/prompt-hook-examples.json demo-prompt-hooks/
# 分析三種 hook 結構 → 寫入 hook-analysis.txt
```

### 三種 Prompt Hook 一覽

| Hook 事件 | 模型 | 評判邏輯 |
|-----------|------|---------|
| Stop | 預設（Haiku） | stop_hook_active=true 放行；last_message 含錯誤 → 阻擋 |
| UserPromptSubmit | 預設（Haiku） | 偵測 API key / 密碼 / 個人資料 → 阻擋 |
| PostToolUse | claude-haiku-4-5-20251001 | .js/.ts 檔案掃描 XSS / SQL 注入 / 寫死憑證 |

### 關鍵機制：$ARGUMENTS

```
Claude Code 觸發 Prompt Hook 時：
1. 把事件資料序列化成 JSON 字串
2. 把 $ARGUMENTS 替換成該 JSON 字串
3. 把完整 prompt 送給 AI 模型
4. AI 模型回傳 {"ok": ..., "reason": ...}
5. ok: false → Claude Code 阻擋動作並顯示 reason
```

### 實際驗證結果 ✅

`hook-analysis.txt` 已產生，包含三種 hook 結構的詳細說明。

---

## Step 2：模擬 UserPromptSubmit — 敏感資訊過濾

### 指令

```bash
# 構造測試輸入（模擬 $ARGUMENTS）
# 用 claude -p 實際呼叫 AI 評判

# 情境 A：安全的一般 prompt
echo '{"prompt": "請幫我用 Python 寫一個讀取 CSV 檔案並計算平均值的腳本"}' \
  | [hook prompt 包裝] \
  | claude -p

# 情境 B：含 API key 的敏感 prompt
echo '{"prompt": "我的 API key 是 sk-ant-api03-abcd1234efgh5678，請用它呼叫..."}' \
  | [hook prompt 包裝] \
  | claude -p
```

### 實際 AI 評判結果 ✅

**情境 A（安全 prompt）：**

```json
{"ok": true, "reason": "prompt 內容為一般程式設計請求（讀取 CSV 並計算平均值），不含 API 金鑰、密碼或個人資料。"}
```

**情境 B（含 API key）：**

```json
{"ok": false, "reason": "prompt 欄位包含 Anthropic API 金鑰（sk-ant-api03-...），屬於敏感憑證，不應出現在請求內容中"}
```

Claude Code 收到 ok: false → 阻擋使用者 prompt，顯示 reason，保護 API key 不被傳入 AI context。

---

## Step 3：模擬 PostToolUse — AI 掃描 .js 安全漏洞

### 指令

```bash
# 情境 A：含 XSS 漏洞的 .js 寫入
XSS_ARGS='{"tool_name":"Write","tool_input":{"file_path":"src/render.js","content":"document.getElementById(\"output\").innerHTML = comment;"}}'

# 情境 B：安全的 .js（改用 textContent）
SAFE_ARGS='{"tool_name":"Write","tool_input":{"file_path":"src/render.js","content":"document.getElementById(\"output\").textContent = comment;"}}'

echo "$XSS_ARGS"  | [hook prompt 包裝] | claude -p
echo "$SAFE_ARGS" | [hook prompt 包裝] | claude -p
```

### 實際 AI 評判結果 ✅

**情境 A（innerHTML = comment，XSS 漏洞）：**

```json
{"ok": false, "reason": "XSS 漏洞：`innerHTML = comment` 直接將使用者輸入注入 DOM，攻擊者可注入任意 HTML/JS（如 `<img src=x onerror=alert(1)>`）。應改用 `textContent = comment` 或先對 comment 做 HTML 跳脫。"}
```

**情境 B（textContent，安全）：**

```json
{"ok": true, "reason": "使用 textContent 而非 innerHTML，已正確防禦 XSS。"}
```

AI 不只說「有問題」，還提供具體攻擊範例和修復建議，比靜態 lint 更聰明。

---

## Step 4：模擬 Stop hook — AI 評判 session 結束品質

### 指令

```bash
# 情境 A：stop_hook_active = true（煞車保護）
BRAKE='{"stop_hook_active": true, "last_assistant_message": "工作完成！"}'

# 情境 B：last_assistant_message 含錯誤
ERROR='{"stop_hook_active": false, "last_assistant_message": "抱歉，執行失敗了。錯誤：FileNotFoundError: config.json 不存在，工作未完成。"}'

echo "$BRAKE" | [hook prompt 包裝] | claude -p
echo "$ERROR" | [hook prompt 包裝] | claude -p
```

### 實際 AI 評判結果 ✅

**情境 A（stop_hook_active = true）：**

```json
{"ok": true, "reason": "stop_hook_active 為 true，且 last_assistant_message 顯示工作已完成"}
```

**情境 B（last_assistant_message 含錯誤）：**

```json
{"ok": false, "reason": "last_assistant_message 含有 FileNotFoundError 錯誤訊息，且明確顯示工作未完成"}
```

---

## 本課重點總結

| 觀念 | 說明 |
|------|------|
| Prompt Hook vs Command Hook | Command = 執行 shell 腳本；Prompt = 讓 AI 當評判官 |
| $ARGUMENTS | Claude Code 把事件 JSON 填入，AI 看到完整事件資料 |
| ok: false 效果 | Claude Code 阻擋動作，把 reason 顯示給使用者 |
| 模型指定 | `"model": "claude-haiku-4-5-20251001"` 節省成本（PostToolUse 每次 Edit 都觸發！） |
| 無模型指定 | 預設使用 Haiku 系列，不指定也省成本 |
| 適用場景 | 規則複雜、需要自然語言理解（「這算敏感嗎？」「這算完成嗎？」）時 |

## 與其他課的比較

| | Command Hook（第 4 課：block-dangerous） | Prompt Hook（第 10 課） |
|---|---|---|
| 判斷方式 | 固定規則（黑名單字串比對） | AI 動態理解語意 |
| 速度 | 毫秒 | 1-3 秒（網路 API 呼叫） |
| 靈活性 | 低（78% 繞過率） | 高（理解意圖而非表面字串） |
| 成本 | 零 | 每次觸發扣 Haiku token |
| 適用 | 明確禁止清單 | 模糊、需要判斷的情境 |

## 職場類比

Prompt Hook = **公司的「老闆審批制度」**。
一般 Hook 是「規則手冊」：查手冊有沒有這條 → 照辦。
Prompt Hook 是「問老闆」：把情況說清楚，老闆用判斷力決定。

老闆（AI）會說：「這個 API key 不該出現在這裡，擋下來。」
規則手冊找不到 `sk-ant-api03-` 怎麼寫，老闆一眼就認出來了。
