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

   答：

2. 日誌寫到哪個檔案路徑？

   答：

3. 每筆日誌記錄哪三個欄位？

   | 欄位 | JSON key | 說明 |
   |------|---------|------|
   | | | |
   | | | |
   | | | |

### 實際結果

（演練時填入）

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
{"ts":"2026-06-13T...","tool":"...","input":{...}}
```

### 實際結果

（演練時填入）

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

| 信心分數 | 行動 |
|---------|------|
| ≥ 70% | 輸出為 Skill 候選，值得建立 |
| 40–70% | 持續觀察，不急著建立 |
| < 40% | 不列入候選 |

### 實際結果

（演練時填入）

---

## Step 4：思考「系統自我進化」的意涵

### 討論問題

1. 如果 AI 每週分析一次日誌，發現某個指令序列連續 5 次出現 Exit Code 2（權限被拒）
   → 它應該主動做什麼？

   答：

2. 「信心分數 ≥ 70% 才升格 Skill」的設計，避免了什麼問題？

   答：

3. 這套機制和「消滅部落知識」的目標有什麼關係？

   答：

### 實際結果

（演練時填入）

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
