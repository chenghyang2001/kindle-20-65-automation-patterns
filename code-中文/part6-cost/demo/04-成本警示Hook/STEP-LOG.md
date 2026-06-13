# 第 4 課演練記錄：成本警示 Hook

> 對應文件：`code-中文/part6-cost/hooks/suggest-compact.sh`

## 課程目標

理解 Hook 如何自動監控 token 用量並提醒壓縮，
閱讀 `suggest-compact.sh` 腳本的邏輯，
學會把它設置為全域 Hook 讓每個 session 都受到保護。

## 工作目錄

`code-中文/part6-cost/demo/04-成本警示Hook/`

---

## Step 1：閱讀 suggest-compact.sh，理解腳本邏輯

### 閱讀任務

打開 `hooks/suggest-compact.sh`，回答：

1. 這個 Hook 在哪個生命週期時機觸發？（PreToolUse / PostToolUse / Stop）

   答：

2. 它從哪個輸入欄位取得 transcript 路徑？

   ```bash
   TRANSCRIPT=$(echo "$INPUT" | jq -r '._______')
   ```

   填入空格：答：

3. 它怎麼計算工具呼叫次數？

   答：

4. 警告的觸發條件是什麼？（精確描述）

   答：

5. 如果 transcript 檔案不存在，腳本會怎麼處理？（看第 7 行）

   答：

### 實際結果

（演練時填入）

---

## Step 2：設置為全域 Hook

### 操作步驟

**先複製腳本到全域 hooks 目錄：**

```bash
mkdir -p ~/.claude/hooks
cp code-中文/part6-cost/hooks/suggest-compact.sh ~/.claude/hooks/
```

**確認複製成功：**

```bash
ls -la ~/.claude/hooks/suggest-compact.sh
```

**查看目前的 settings.json：**

```bash
cat ~/.claude/settings.json
```

### 要加入的 Hook 設定

在 `~/.claude/settings.json` 的 `hooks` 區段加入（注意：Windows 路徑用正斜線或雙反斜線）：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/suggest-compact.sh"
          }
        ]
      }
    ]
  }
}
```

> 注意：如果 settings.json 已有其他 hooks，要合併進去，不要覆蓋。

### 實際結果

（演練時填入）

---

## Step 3：理解「每 50 次工具呼叫」的設計邏輯

### 思考練習

1. 為什麼選 50 次工具呼叫，而不是 100 次或 10 次？

   提示：50 次大約對應多大的任務體積？

   答：

2. 腳本用 `$(( TOOL_COUNT % 50 )) -eq 0` 判斷，這意味著什麼？

   | TOOL_COUNT | 觸發警告嗎？ |
   |-----------|------------|
   | 49 | |
   | 50 | |
   | 100 | |
   | 151 | |

3. 警告輸出到 `>&2`（stderr），而不是 stdout，為什麼這樣設計？

   答：

### 實際結果

（演練時填入）

---

## Step 4：驗證 Hook 生效

### 操作步驟

在 Claude Code 中隨意執行幾個指令（如讀檔、搜尋），
然後直接查看 transcript 的工具呼叫數量：

```bash
# 找最新的 transcript
LATEST=$(ls -t ~/.claude/projects/*/transcripts/*.jsonl 2>/dev/null | head -1)
echo "Transcript: $LATEST"

# 計算工具呼叫次數
if [ -n "$LATEST" ]; then
  COUNT=$(grep -c '"type":"tool_use"' "$LATEST" 2>/dev/null || echo 0)
  echo "工具呼叫次數：$COUNT"
fi
```

### 觀察

- 你的 transcript 有幾個工具呼叫？
- 距離下一次 50 的倍數還有幾次？

### 實際結果

（演練時填入）

---

## 本課重點

```
Hook 的成本控制邏輯：
  每次工具操作完成後（PostToolUse）→ 計算累積次數 →
  達到 50 的倍數 → 輸出警告到 stderr →
  Claude Code 把 stderr 訊息顯示給使用者

為什麼要自動化這件事：
  人工記得「該壓縮了」的機率 ≈ 0
  自動化 Hook 記得的機率 = 100%
  而壓縮 = 砍掉 50-80% 的 Input token = 省 50-80% 的錢
```

| 元件 | 職責 |
|------|------|
| `suggest-compact.sh` | 計算 tool 次數，達門檻時輸出警告 |
| `PostToolUse` hook | 每次工具執行後觸發腳本 |
| `/compact` 指令 | 使用者收到警告後執行壓縮 |
| 50 次門檻 | 平衡「提醒頻率」與「任務打斷感」 |
