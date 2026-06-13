# 第 3 課演練記錄：模型選擇矩陣

> 對應文件：`docs/model-cost-matrix.md`

## 課程目標

學會依任務類型選 haiku / sonnet / inherit，
用一個成本估算實例說明為何「探索用 haiku、審查用 sonnet」。

## 工作目錄

`code-中文/part3-agents/demo-model-selection/`

---

## Step 1：讀取模型成本矩陣

### 指令

```bash
cat ../docs/model-cost-matrix.md
```

### 填入成本表（演練時填入）

| 模型 | 成本（輸入/輸出 per M tokens） | 適用任務 |
|------|---------------------------|---------|
| Haiku | | |
| Sonnet | | |
| Opus | | |

---

## Step 2：建立 haiku 版 log-searcher agent

### 建立位置

`~/.claude/agents/log-searcher.md`（實際部署位置）
`demo-model-selection/log-searcher.md`（Demo 備份）

### 內容設計

```markdown
---
name: log-searcher
description: >
  快速搜尋 log 檔案中的錯誤或關鍵字。
  需要查找 error / warning / 特定字串時主動使用。
tools: Read, Grep, Glob
model: haiku
---

你是 log 搜尋專家。找到符合條件的行並直接回傳，不做分析。
```

### 實際建立指令

```bash
# 複製到 demo 目錄（之後再決定是否部署到 ~/.claude/agents/）
cat > demo-model-selection/log-searcher.md << 'EOF'
...
EOF
```

### 結果

（演練時填入）

---

## Step 3：對比 — 用 sonnet 做相同的探索任務

### 成本試算

```
場景：每天搜尋 log 100 次

haiku：  100 × 0.8   = $0.08/天  → $2.4/月
sonnet： 100 × 3.0   = $0.30/天  → $9.0/月
差異：   37.5 倍成本差異
```

### 結論

（演練時填入）

---

## Step 4：CLAUDE_CODE_SUBAGENT_MODEL 環境變數

### 說明

可以一次設定所有 sub-agent 用 haiku：

```bash
export CLAUDE_CODE_SUBAGENT_MODEL=haiku
```

適合「全部降成本」的情境；若個別 agent 需要 sonnet，在 frontmatter 覆寫。

---

## 本課重點

| 選擇規則 | 說明 |
|---------|------|
| 探索 / 搜尋 / log | haiku（速度快、成本低） |
| 審查 / 分析 / 安全 | sonnet（準確度高） |
| 重構 / 正式實作 | inherit（跟主對話一致） |
| 全局省成本 | `CLAUDE_CODE_SUBAGENT_MODEL=haiku` |
