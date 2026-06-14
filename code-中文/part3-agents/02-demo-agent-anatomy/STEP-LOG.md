# 第 2 課演練記錄：解析自訂 Agent 結構

> 對應文件：`agents/api-reviewer.md`、`agents/security-reviewer.md` 等四個 agent
> 主題：frontmatter 四要素，`description` 是觸發條件不是自我介紹

---

## 核心觀念

Claude Code 讀 `description` 是為了**決策**（何時派這個 agent），不是展示。
Description 是「觸發說明書」，不是 README。

---

## Step 1：四個 agent 比較表

**命令：**

```bash
head -10 code-中文/part3-agents/agents/api-reviewer.md
head -10 code-中文/part3-agents/agents/security-reviewer.md
head -10 code-中文/part3-agents/agents/code-quality-reviewer.md
head -10 code-中文/part3-agents/agents/spec-compliance-reviewer.md
```

**實際驗證：** ✅

| Agent | model | tools | permissionMode | description（觸發時機）|
|-------|-------|-------|----------------|----------------------|
| api-reviewer | sonnet | Read, Grep, Glob | 無（預設）| **新增或修改端點時**主動使用 |
| security-reviewer | sonnet | Read, Grep, Glob | **plan（唯讀）** | **程式碼審查、PR 合併前、部署前**使用 |
| code-quality-reviewer | **inherit** | Read, Grep, Glob | 無（預設）| **spec-compliance-reviewer 之後**使用 |
| spec-compliance-reviewer | sonnet | Read, Grep, Glob, **Bash** | 無（預設）| **實作完成時**主動使用 |

**三個值得注意的設計：**

1. **security-reviewer 唯一有 `permissionMode: plan`**：安全稽核員只能看不能改，避免「自己既審又改」的角色衝突。
2. **code-quality-reviewer 用 inherit**：品質判斷的深度跟著主對話模型走（彈性）；其他三個固定 sonnet（精確判斷）。
3. **spec-compliance-reviewer 多了 Bash**：驗規格需要能跑測試（`pytest`、`curl`），其他三個只需靜態讀取。

---

## Step 2：description 是觸發條件，不是自我介紹

**兩種寫法對比：**

```
寫法 A（❌ 自我介紹）：
  description: "我是 API 審查員，專門檢查 RESTful 設計原則和輸入驗證。"

寫法 B（✅ 觸發條件）：
  description: >
    API 端點設計審查專家。
    新增或修改端點時主動使用。
```

| | 寫法 A | 寫法 B |
|--|--------|--------|
| 主詞 | 「我是...」 | 「...審查專家」（能力標籤）|
| 觸發時機 | ❌ 沒有 | ✅ 「新增或修改端點時主動使用」|
| Claude 能做什麼 | 知道它叫什麼 | **知道何時叫它** |

Claude 比對流程：「使用者正在修改 API 端點 → description 說這時用 api-reviewer → 呼叫它」。
寫法 A 讓這個比對無法發生。

---

## Step 3：自己設計一個 agent frontmatter

**題目**：資料庫遷移審查員，修改 `migrations/*.sql` 時自動介入，只讀，用 sonnet。

**答案：**

```markdown
---
name: db-migration-reviewer
description: >
  資料庫遷移腳本審查專家。
  新增或修改 migrations/ 目錄下的 .sql 檔時主動使用。
tools: Read, Grep, Glob
model: sonnet
permissionMode: plan
---
```

**`permissionMode: plan` vs 只列唯讀工具的差別**：

- 只列 Read/Grep/Glob = 工具白名單（清單外不能用）
- `permissionMode: plan` = 模式鎖（即使主對話臨時授權寫入也突破不了）

雙重保險，security-reviewer 同款設計。

---

## Step 4：reviewer 順序為何是 spec-compliance → code-quality

**如果反過來先跑 code-quality 再跑 spec-compliance 的問題：**

```
錯誤順序：
code-quality 挑剔命名品質
  → spec-compliance 發現整個模組缺功能 → 回去大改
  → code-quality 白做了

正確順序：
spec-compliance 確認「所有功能存在且正確」
  → code-quality 才在「已確認正確」的基礎上審品質
```

**根本原因**：**正確性優先於品質**。先確認內容對了，再談風格。
比喻：先審「文章寫得優美嗎」，再發現「根本離題」— 優美也白費。

這是 code-quality-reviewer description 寫「在 spec-compliance-reviewer 之後使用」的精確動機 — 執行順序藏在 description 裡，不只是說明文字。

**產出物：** 四個 `agents/*.md` 分析 + `db-migration-reviewer` frontmatter 設計
