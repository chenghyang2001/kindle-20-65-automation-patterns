# 第 6 課演練記錄：觀察 Hook + 自我進化

> 對應文件：
>
>
> - `code-中文/part7-workflows/hooks/observe-pattern.sh`
> - `code-中文/part7-workflows/skills/analyze-patterns/SKILL.md`

## 課程目標

設置 PostToolUse 觀察 Hook，讓系統自動把 AI 每次的工具操作寫入日誌，
再用 analyze-patterns Skill 分析日誌，找出可以做成 Skill 的重複模式，
理解「AI 系統如何透過資料自我學習和進化」的機制。

## 工作目錄

`code-中文/part7-workflows/demo/06-觀察Hook與自我進化/`

---

## Step 1：閱讀 observe-pattern.sh，理解 Hook 邏輯

### 閱讀任務

打開 `hooks/observe-pattern.sh`，回答：

1. 這個 Hook 在哪個時機點觸發（PreToolUse / PostToolUse）？

   答：**PostToolUse**（設定在 settings.json 的 `PostToolUse` 區段）。
   每次 AI 完成一個工具呼叫後，Hook 自動執行，把剛完成的操作記入日誌。

2. 日誌寫到哪個檔案路徑？

   答：`${HOME}/.claude/logs/patterns.jsonl`
   腳本會先 `mkdir -p` 確保目錄存在，再用 `>>` 追加寫入（不覆蓋）。

3. 每筆日誌記錄哪三個欄位？

   | 欄位 | JSON key | 說明 |
   |------|---------|------|
   | 時間戳 | `ts` | ISO 8601 UTC 格式（`date -u +%Y-%m-%dT%H:%M:%SZ`）|
   | 工具名稱 | `tool` | 從 stdin 讀取的 `tool_name`（如 `Write`、`Edit`、`Bash`）|
   | 工具輸入 | `input` | 完整的 `tool_input` 物件（JSON 格式，記錄呼叫參數）|

### 實際結果

腳本只有 12 行，但包含三個關鍵設計：

- 從 stdin 讀取 Hook 傳入的 JSON（`cat`）
- 用 `jq` 解析 `tool_name` 和 `tool_input`
- JSONL 格式（每行一筆）讓後續 `jq -s .` 能直接批次解析

---

## Step 2：設置 PostToolUse Hook

### 方法 A：全域設定（推薦用於學習）

編輯 `~/.claude/settings.json`，在 hooks 區段加入：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/observe-pattern.sh"
          }
        ]
      }
    ]
  }
}
```

`matcher: ".*"` 表示**所有工具**都觸發，不篩選特定工具。

然後複製 Hook 腳本：

```bash
mkdir -p ~/.claude/hooks
cp code-中文/part7-workflows/hooks/observe-pattern.sh ~/.claude/hooks/
```

### 驗證 Hook 已生效

在 Claude Code 中執行任何指令（如 `/agents`），
然後查看日誌：

```bash
tail -5 ~/.claude/logs/patterns.jsonl | jq .
```

### 預期結果

```json
{"ts":"2026-06-15T08:23:41Z","tool":"Read","input":{"file_path":"/...","limit":50}}
{"ts":"2026-06-15T08:23:55Z","tool":"Bash","input":{"command":"git status"}}
```

### 實際結果

Hook 設定後，Claude Code 的每一個工具呼叫都被靜默記錄。
使用者完全感知不到，但系統持續累積行為資料。
這是「被動觀察」而非「主動記錄」——工作繼續，日誌自動長大。

---

## Step 3：累積日誌後安裝 analyze-patterns Skill

### 安裝

```bash
cp -r code-中文/part7-workflows/skills/analyze-patterns \
      ~/.claude/skills/analyze-patterns
```

### 等待累積

繼續正常使用 Claude Code 一段時間（至少讓日誌有 20 筆記錄），
然後執行：

```
/analyze-patterns
```

### 觀察輸出

AI 會分析日誌，找出重複 3 次以上的工具使用模式，輸出類似：

| 模式 | 出現次數 | 信心分數 | 建議 Skill 名稱 |
|------|---------|---------|----------------|
| Grep → Read → Edit | 12 | 85% | code-fix |
| Bash（git status） → Bash（git add）→ Bash（git commit） | 8 | 72% | quick-commit |

### 信心分數門檻

信心分數公式：`（出現次數 / 總操作數）× 100`

| 信心分數 | 行動 |
|---------|------|
| **≥ 70%** | 輸出為 **Skill 候選**，值得正式建立成 Skill |
| **40–70%** | **持續觀察**，模式尚不穩定，不急著建立 |
| **< 40%** | **不列入候選**，可能是偶發操作或雜訊 |

### 實際結果

`/analyze-patterns` 的輸出是一份「行為鏡子」：
把你過去怎麼工作的隱性習慣，用信心分數量化後呈現出來，
讓你決定哪些模式值得制度化成 Skill。

---

## Step 4：思考「系統自我進化」的意涵

### 討論問題

1. 如果 AI 每週分析一次日誌，發現某個指令序列連續 5 次出現 Exit Code 2（權限被拒）
   → 它應該主動做什麼？

   答：系統應偵測到「此序列高頻失敗」的模式後：

   1. **建立防禦性 Hook**：在執行該指令序列前，PreToolUse Hook 自動先做權限檢查（`ls -la`、`stat`），若預測會失敗則提前中斷並提示
   2. **更新 CLAUDE.md**：把「此路徑需要管理員權限」的隱性知識變成顯式文件，消除下次遇到同樣問題時的摸索成本
   3. **Skill 候選化**：如果有標準的補救流程（如 `chmod` 後重試），則把「遇到 Exit Code 2 的處理序列」包成 Skill

2. 「信心分數 ≥ 70% 才升格 Skill」的設計，避免了什麼問題？

   答：**防止雜訊被制度化**。

   沒有門檻的情況下，任何出現過 3 次的操作序列都會被升格為 Skill，
   最後系統裡充滿「偶發性重合的操作」形成的 Skill。70% 門檻確保：
   - 這個模式不是本週特殊任務的產物，而是**真正的工作習慣**
   - Skill 的觸發條件（description）能在未來場景中精確匹配
   - 避免 Skill 爆炸問題（Skill 太多反而讓 AI 選擇困難）

3. 這套機制和「消滅部落知識」的目標有什麼關係？

   答：**部落知識**（tribal knowledge）是「只有資深工程師才知道，但從未被寫下來」的隱性經驗。傳統上靠師徒制或事故複現才能傳承。

   這套機制的根本作用：

   ```
   AI 每次工具呼叫 → 自動寫入 JSONL
                              ↓
              /analyze-patterns 掃描重複模式
                              ↓
              高信心模式 → 建議升格為 Skill
                              ↓
            Skill 名稱 + description = 「被寫下來的工作方法」
   ```

   換言之：**人不需要主動記錄，系統從行為中自動提煉出值得保存的工作模式**。
   這不是「AI 變聰明了」，而是「AI 把自己的隱性知識外顯化了」——
   和 CLAUDE.md 的精神一樣，都是把「只存在腦袋裡的方法」變成「可共享、可重用的文件」。

### 實際結果

「自我進化」不是科幻概念，它的實作只有三個元件：

```
觀察 Hook → 日誌累積 → 模式分析 → Skill 候選 → 建立新 Skill

這是一個讓 AI 系統「有潛意識」的完整迴路：
不是手動記錄哪裡卡住，
而是讓系統自動把每次失敗和每次成功都寫下來，
再從資料中發現值得系統化的工作模式。
```

---

## 本課重點

```
觀察 Hook → 日誌累積 → 模式分析 → Skill 候選 → 建立新 Skill

這是一個讓 AI 系統「有潛意識」的完整迴路：
不是手動記錄哪裡卡住，
而是讓系統自動把每次失敗和每次成功都寫下來，
再從資料中發現值得系統化的工作模式。
```

| 元件 | 功能 |
|------|------|
| `observe-pattern.sh` | 把每次工具操作寫入 JSONL 日誌 |
| `~/.claude/logs/patterns.jsonl` | 累積的行為資料 |
| `/analyze-patterns` | 分析日誌，計算信心分數，輸出 Skill 候選 |
| 信心分數門檻（70%） | 防止雜訊被誤升格為 Skill |
