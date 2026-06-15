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

   答：**PostToolUse**（工具執行後）——要計算「已執行次數」，必須在工具跑完之後才數得到

2. 它從哪個輸入欄位取得 transcript 路徑？

   ```bash
   TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
   ```

   填入空格：答：**`transcript_path`**（`// empty` 確保欄位不存在時回傳空字串而非 null）

3. 它怎麼計算工具呼叫次數？

   答：`grep -c '"type":"tool_use"' "$TRANSCRIPT"`（`-c` = 計算符合的行數，每行一個 tool call）

4. 警告的觸發條件是什麼？（精確描述）

   答：`TOOL_COUNT -gt 0 AND TOOL_COUNT % 50 -eq 0`
   - `-gt 0`：排除 transcript 不存在時 TOOL_COUNT=0 的誤觸（0 % 50 = 0）
   - `% 50 -eq 0`：50 的倍數時觸發（第 50、100、150... 次）

5. 如果 transcript 檔案不存在，腳本會怎麼處理？（看第 7 行）

   答：`TOOL_COUNT` 維持第 4 行初始值 `0`，整個 grep block 被跳過，腳本靜默結束 `exit 0`，不 crash

### 實際結果

腳本只有 12 行，但結構完整：預設值初始化 → 安全讀取 → 條件警告 → 正常退出

---

## Step 2：設置為全域 Hook

### 操作步驟

**複製腳本到全域 hooks 目錄：**

```bash
mkdir -p ~/.claude/hooks
cp code-中文/part6-cost/hooks/suggest-compact.sh ~/.claude/hooks/
```

**確認複製成功：**

```
-rwxr-xr-x 1 B00332 1049089 414 Jun 15 08:26 /c/Users/B00332/.claude/hooks/suggest-compact.sh
```

### 要加入的 Hook 設定

加入 `~/.claude/settings.json` 的 `PostToolUse` 陣列最後：

```json
{
  "matcher": ".*",
  "hooks": [
    {
      "type": "command",
      "command": "bash ~/.claude/hooks/suggest-compact.sh"
    }
  ]
}
```

`matcher: ".*"` = 所有工具都觸發（每次工具呼叫都要計數）

### 實際結果

settings.json 已有 4 條 PostToolUse hook（secret-scanner、post-edit-log、prettier、security prompt），
新增為第 5 條。JSON 格式驗證：`python -m json.tool` 確認合法 ✓

---

## Step 3：理解「每 50 次工具呼叫」的設計邏輯

### 思考練習

1. 為什麼選 50 次工具呼叫，而不是 100 次或 10 次？

   答：50 次 ≈ 中型任務（讀幾個檔 + 搜尋 + 幾次編輯）的體積
   - 10 次 → 太頻繁，打斷感強，使用者會煩
   - 100 次 → 太鬆，context 可能已爆炸才提醒
   - 50 次 → 甜蜜點：一個功能做完後剛好提醒一次

2. 腳本用 `$(( TOOL_COUNT % 50 )) -eq 0` 判斷，這意味著什麼？

   | TOOL_COUNT | 觸發警告嗎？ |
   |-----------|------------|
   | 0 | ✗（`-gt 0` 擋住，0%50=0 但不大於 0） |
   | 49 | ✗（49%50=49，不等於 0） |
   | 50 | ✅ 是（50>0 且 50%50=0） |
   | 100 | ✅ 是（100>0 且 100%50=0） |
   | 151 | ✗（151%50=1，不等於 0） |

3. 警告輸出到 `>&2`（stderr），而不是 stdout，為什麼這樣設計？

   答：Hook 的 stdout/stderr 對 Claude Code 有不同語義：
   - **stdout** → Claude Code 讀取作為結構化回傳（`exit 2` + JSON 可阻斷工具）
   - **stderr** → Claude Code 把它**顯示給使用者看**，但不影響工具執行流程

   用 stderr = 只是「提醒」，不會中斷任何操作。使用者看到警告後自己決定要不要 `/compact`。

### 實際結果

stdout/stderr 分流是 Hook 設計的核心：stderr 給人看，stdout 給 Claude 看。
`exit 2` + stdout JSON 可以阻斷（PreToolUse），但這個 PostToolUse 腳本只想提醒不想阻斷。

---

## Step 4：驗證 Hook 生效

### 操作步驟

查看本 session 的工具呼叫次數：

```bash
LATEST=$(ls -t ~/.claude/projects/*/transcripts/*.jsonl 2>/dev/null | head -1)
COUNT=$(grep -c '"type":"tool_use"' "$LATEST" 2>/dev/null || echo 0)
echo "工具呼叫次數：$COUNT"
```

### 觀察

- 本 session transcript：`4c457d3f-a4cd-4096-8b4a-b5f4f4f4401b.jsonl`
- 工具呼叫次數：**26 次**
- 距下一個 50 倍數還差：**24 次**

### 實際結果

Hook 已生效，從下一次工具呼叫開始默默計數。第 50 次工具呼叫時會在 stderr 顯示：
`建議檢查 context 用量並執行 /compact（工具呼叫次數：50）`

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

**關鍵設計模式：防禦性初始化**
先設 `TOOL_COUNT=0`，讓所有異常路徑（transcript 不存在、grep 失敗）安全落地，
而非讓未初始化變數炸掉整個 shell。
