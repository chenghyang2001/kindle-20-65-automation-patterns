# 第 2 課演練記錄：解析自訂 Agent 結構

> 對應文件：`agents/api-reviewer.md`、`agents/security-reviewer.md` 等

## 課程目標

看懂 `.md` agent 檔案的 frontmatter 四要素：
`name`、`description`（觸發條件！）、`tools`、`model`。
理解 `permissionMode: plan` 的用途。

## 工作目錄

`code-中文/part3-agents/demo-agent-anatomy/`

---

## Step 1：讀四個 agent，填入比較表

### 指令

```bash
cat ../agents/api-reviewer.md
cat ../agents/security-reviewer.md
cat ../agents/code-quality-reviewer.md
cat ../agents/spec-compliance-reviewer.md
```

### 比較表（演練時填入）

| Agent | model | tools | permissionMode | description 摘要 |
|-------|-------|-------|----------------|-----------------|
| api-reviewer | | | | |
| security-reviewer | | | | |
| code-quality-reviewer | | | | |
| spec-compliance-reviewer | | | | |

---

## Step 2：description 是觸發條件，不是自我介紹

### 關鍵概念

```
❌ 錯誤寫法（自我介紹）：
  description: "我是 API 審查員，我會檢查 RESTful 設計。"

✅ 正確寫法（觸發條件）：
  description: >
    API 端點設計審查專家。
    新增或修改端點時主動使用。
```

Claude Code 讀 description 決定「何時該呼叫這個 agent」，
不是讓 agent 自我介紹。

### 辨識實驗

哪個 agent 的 description 寫的是觸發條件？哪個較像自我介紹？

（演練時填入）

---

## Step 3：permissionMode: plan 的效果

### 指令（在 Claude Code 互動模式）

```bash
# 觀察 security-reviewer 的 permissionMode: plan
# 呼叫它後，它只能閱讀不能修改（plan mode = 唯讀）
```

### 觀察結果

（演練時填入）

---

## 本課重點

| frontmatter 欄位 | 作用 |
|-----------------|------|
| `name` | Agent 的唯一識別名 |
| `description` | 觸發條件（Claude 自動決定何時呼叫） |
| `tools` | 工具白名單（不在清單 = 不能用） |
| `model` | haiku / sonnet / inherit（成本最佳化） |
| `permissionMode: plan` | 強制唯讀，不能修改任何檔案 |
