# 第 1 課演練記錄：認識內建 Sub-agents

> 對應文件：`docs/builtin-agents-reference.md`

## 課程目標

認識 Claude Code 附帶的 6 個內建 sub-agent，
理解 Explore / Plan / Bash 的分工，學會用 `/agents` 列出清單。

## 工作目錄

`code-中文/part3-agents/demo-builtin-agents/`

---

## Step 1：用 `/agents` 指令列出所有 sub-agent

### 指令

```bash
# 在 Claude Code 互動模式下輸入：
/agents
```

### 預期結果

顯示所有內建 + 自訂 agent 的清單（含名稱、描述、tools、model）。

### 實際結果

（演練時填入）

---

## Step 2：呼叫 Explore agent 搜尋關鍵字

### 指令

```bash
# 在 Claude Code 互動模式下輸入：
Use Explore to find all .md files in code-中文/part3-agents/
```

### 預期結果

Explore agent（haiku model）回傳檔案清單，不讀完整內容。

### 實際結果

（演練時填入）

---

## Step 3：比較 Explore vs 直接 Glob 的差異

### 觀察點

| 項目 | Explore sub-agent | 直接 Glob |
|------|-----------------|-----------|
| 模型 | Haiku（較省） | 主對話模型 |
| Context | 獨立 session | 佔用主 context |
| 適用 | 大範圍搜尋 | 已知路徑查詢 |
| 回傳 | 摘要 | 原始結果 |

### 結論

（演練時填入）

---

## 本課重點

| 內建 Agent | 模型 | 工具 | 典型用途 |
|-----------|------|------|---------|
| Explore | Haiku | 唯讀 | 程式碼庫搜尋 |
| Plan | Inherit | 唯讀 | Plan 模式研究 |
| General-purpose | Inherit | 所有 | 複雜多步驟任務 |
| Bash | Inherit | 僅 Bash | 獨立終端機指令 |
