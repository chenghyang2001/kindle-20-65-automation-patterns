# 第 4 課演練記錄：建立並呼叫自訂 Agent

> 整合 agents/ 目錄所有範例，第一次親手建 agent 並呼叫

## 課程目標

完整走一遍「設計 → 建立 → 部署 → 呼叫」的流程，
建立一個能真正運作的 pm25-log-finder agent（搜尋 PM2.5 log 關鍵字）。

## 工作目錄

`code-中文/part3-agents/demo-custom-agent/`

---

## Step 1：設計 agent frontmatter

### 目標 agent：pm25-log-finder

```markdown
---
name: pm25-log-finder
description: >
  快速在 AIHCR log 檔案中搜尋 PM2.5 數值異常或 998 錯誤碼。
  查找感測器異常、場域問題時主動使用。
tools: Read, Grep, Glob
model: haiku
---

你是 PM2.5 log 搜尋專家。
找到含有指定關鍵字的行並回傳原始內容 + 行號 + 檔案路徑。
998 = 感測器故障，不是真實污染值，請特別標記。
不做額外分析，只做搜尋。
```

### 說明

（演練時填入：為何選 haiku？tools 為何不含 Bash？）

---

## Step 2：建立 agent 檔案

### 部署路徑

```
~/.claude/agents/pm25-log-finder.md    ← 全域可用
```

或

```
<project>/.claude/agents/pm25-log-finder.md  ← 只在該專案可用
```

### 建立指令

```bash
mkdir -p ~/.claude/agents
# 將設計好的 .md 存入
```

### 實際結果

（演練時填入）

---

## Step 3：呼叫 agent（在 Claude Code 互動模式）

### 指令

```bash
# 在 Claude Code 互動模式下：
Use pm25-log-finder to search for "998" in code-中文/
```

### 預期行為

1. Claude 識別到「search for 998」→ 觸發 pm25-log-finder
2. Agent 用 Grep 搜尋
3. 回傳搜尋結果（含行號）
4. 退出 agent session，結果回到主 context

### 實際結果

（演練時填入）

---

## Step 4：驗證單層委派鐵律

### 關鍵規則

**Sub-agent 不能再派 sub-agent。**

```
主對話 → agent（第 1 層）→ ✅ 允許
agent（第 1 層）→ agent（第 2 層）→ ❌ 禁止
```

### 驗證方式

觀察 pm25-log-finder 的 tools 清單：
`Read, Grep, Glob` → 沒有 `Task` 工具 → 無法派出 sub-agent。

這是設計上的保護，不是 bug。

---

## 本課重點

| 步驟 | 關鍵動作 |
|------|---------|
| 設計 description | 寫觸發條件，不是自我介紹 |
| 選 model | 搜尋任務 → haiku |
| 限制 tools | 只給需要的（最小權限原則） |
| 部署路徑 | `~/.claude/agents/` 全域；`.claude/agents/` 專案 |
| 呼叫方式 | Claude 自動觸發 or 直接說 "Use <name>" |
