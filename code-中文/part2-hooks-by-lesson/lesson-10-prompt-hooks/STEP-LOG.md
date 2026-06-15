# 第 10 課演練記錄：prompt-hook-examples.json

> 範例檔：`quality/prompt-hook-examples.json`
> 事件：Stop / UserPromptSubmit / PostToolUse｜ 難度：⭐⭐⭐⭐
> 主題：字串黑名單的終點 — 讓 AI 自己當裁判（`type: "prompt"` hook）

---

## 核心觀念

前幾課（第 4、8 課）用 Bash 字串比對做決策，但 66% 繞過率、大小寫盲點全指向同一天花板：**規則有限，語意無限**。

解法：`type: "prompt"` hook — 把整個 payload 丟給 Claude，讓 AI 讀懂意圖，回傳 `{"ok": true/false, "reason": "..."}` 讓 harness 決定放行或阻擋。

```
Claude Code 事件發生
  → 把 payload JSON 填入 prompt 的 $ARGUMENTS 佔位符
  → 送給 AI 模型（可指定 Haiku 省錢）
  → AI 回傳 {"ok": ...}
  → ok: false → 阻擋 + 顯示 reason
```

---

## Step 1：讀懂三種 prompt hook 的結構

**命令：**

```bash
cat quality/prompt-hook-examples.json | python -m json.tool | head -40
```

⚠️ **Windows cp950 陷阱**：直接 `python -c "open(...)"` 會報 UnicodeDecodeError，必須加 `encoding='utf-8'`（全課程通則）。

**目的：** 認識三個不同事件的 prompt hook 設計。
**實際驗證：** ✅ 三個事件各有不同的 prompt，PostToolUse 多了 `"model"` 欄位：

| 事件 | 任務 | 特色 |
|------|------|------|
| Stop | 工作是否真的完成 | 也處理 `stop_hook_active` 防迴圈 |
| UserPromptSubmit | 掃描使用者訊息有沒有敏感資訊 | Claude 讀到之前就過濾 |
| PostToolUse（Edit/Write）| 掃描剛寫的 .ts/.js 有無安全漏洞 | 指定 `claude-haiku-4-5-20251001` 省成本 |

---

## Step 2：對比欄位 — PostToolUse 多了什麼

**命令：**

```python
import json
with open('quality/prompt-hook-examples.json', encoding='utf-8') as f:
    data = json.load(f)
for event, rules in data['hooks'].items():
    for rule in rules:
        h = rule['hooks'][0]
        keys = list(h.keys())
        print(f'{event}: {keys}')
```

**實際驗證：** ✅

```
Stop: ['type', 'prompt']
UserPromptSubmit: ['type', 'prompt']
PostToolUse: ['type', 'model', 'prompt']
```

**PostToolUse 多 `model` 的原因**：每次 Edit/Write 都觸發（高頻），指定 `claude-haiku-4-5-20251001`（最便宜模型）做安全掃描，成本控制。Stop 和 UserPromptSubmit 頻率低，不指定 = 繼承當前模型。

---

## Step 3：解析 $ARGUMENTS — 三個事件注入什麼

**命令：**

```python
import json
with open('quality/prompt-hook-examples.json', encoding='utf-8') as f:
    data = json.load(f)
for event, rules in data['hooks'].items():
    for rule in rules:
        p = rule['hooks'][0]['prompt']
        idx = p.find('$ARGUMENTS')
        before = p[max(0,idx-30):idx]
        after = p[idx+10:idx+50]
        print(f'{event}:')
        print(f'  ...{before}[$ARGUMENTS]{after}...')
        print()
```

**實際驗證：** ✅

| 事件 | $ARGUMENTS 是 | prompt 指示看哪個欄位 |
|------|--------------|------------------|
| Stop | session 結束 metadata | `.stop_hook_active`、`.last_assistant_message` |
| UserPromptSubmit | 使用者剛送的訊息 | `.prompt`（敏感資訊掃描）|
| PostToolUse | Edit/Write tool 呼叫結果 | `.tool_input.file_path`、`.tool_response` |

每個事件的 payload 格式不同，prompt 必須對應寫正確的欄位路徑。

---

## Step 4：設計練習 — 保護 production.env

**題目：** 用 UserPromptSubmit prompt hook，讓 AI 判斷使用者是否要求讀取含 `production`/`prod` 關鍵字的環境變數檔案。

**標準答案：**

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "hooks": [{
        "type": "prompt",
        "prompt": "請檢視以下使用者 prompt：\n$ARGUMENTS\n\n檢查 .prompt 欄位是否包含要求讀取、顯示、輸出、或存取含有 'production' 或 'prod' 關鍵字的環境變數檔案（如 production.env、prod.env 或相似命名）。若有此意圖，回傳 ok: false；其餘情況回傳 ok: true。\n\n{\"ok\": true/false, \"reason\": \"原因\"}"
      }]
    }]
  }
}
```

**關鍵句**：「讀取、顯示、輸出、或存取」+ 說明什麼樣的檔案算 → AI 懂語意，一句話涵蓋所有說法。

**若改用 bash `grep -qF` 至少需要幾條 pattern？**

```
cat production.env    show production.env    read production.env
display production    print prod.env         output production
cat prod.env.local    顯示 production.env    列出 prod 環境變數
幫我看 production 設定  ...+ 大小寫 + 路徑前綴 + 多語言
```

→ **20+ 條**，仍有漏網之魚。

---

## Part 2 Hooks 旅程終點：兩種防禦的分工

| | Command Hook（第 4 課） | Prompt Hook（第 10 課）|
|---|---|---|
| 判斷方式 | 固定規則（字串比對） | AI 動態理解語意 |
| 速度 | 毫秒 | 1-3 秒（API 呼叫）|
| 靈活性 | 低（66% 繞過率）| 高（理解意圖）|
| 成本 | 零 | 每次觸發扣 Haiku token |
| 適用 | 明確禁止清單 | 模糊、需要語意判斷 |

**縱深防禦梯次（從第 4 課到第 10 課的完整答案）：**

```
字串黑名單（快、免費）→ 擋明顯笨攻擊
     +
AI 語意裁判（慢一點、有成本）→ 處理語意繞過
     +
Permission Model 白名單（Part 5）→ 從根阻斷
```

三層不是取代關係，而是**互補的縱深防禦**。

**產出物：** `prompt-hook-examples.json`（分析對象）
