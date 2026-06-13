# 第 3 課演練記錄：動態編排 — 不同任務走不同流程

> 對應文件：`code-中文/part7-workflows/skills/orchestrate/SKILL.md`

## 課程目標

理解為什麼同一套工具要依任務類型（bugfix / feature / refactor / security）
走不同的工作流，學會用 `/orchestrate` 自動選擇正確流程，
避免「殺雞用牛刀」或「牛刀殺不了牛」的兩種失敗。

## 工作目錄

`code-中文/part7-workflows/demo/03-動態編排/`

---

## Step 1：安裝 orchestrate Skill

### 指令

```bash
cp -r code-中文/part7-workflows/skills/orchestrate \
      ~/.claude/skills/orchestrate
```

### 驗證

```
/orchestrate
```

### 預期結果

顯示 feature / bugfix / refactor / security 四種工作流說明。

### 實際結果

（演練時填入）

---

## Step 2：對比四種任務的工作流差異

### 演練任務

閱讀 `orchestrate/SKILL.md`，填入下表：

| 任務類型 | 第一步 | 最後一步 | 核心關鍵 |
|---------|-------|---------|---------|
| bugfix | | | |
| feature | | | |
| refactor | | | |
| security | | | |

### 觀察點

- bugfix：為什麼要「以最小範圍套用修復」？
- refactor：為什麼第一步是「確認測試覆蓋率」而不是直接開始改？
- security：為什麼調查階段「只讀不寫」（不使用 Write 工具）？

### 實際結果

（演練時填入）

---

## Step 3：依情境選擇正確的任務類型

### 情境判斷練習

對以下 3 個情境，選擇 bugfix / feature / refactor / security 並說明理由：

**情境 A**：
> 使用者回報「購物車金額算錯，折扣沒有套用到最後一件商品」

任務類型：＿＿＿　理由：

---

**情境 B**：
> 產品要求新增「匯出訂單為 CSV 檔案」的功能

任務類型：＿＿＿　理由：

---

**情境 C**：
> 發現程式庫用的是 bcrypt 1.0（舊版），有已知的 CVE-2023-8080 漏洞

任務類型：＿＿＿　理由：

---

### 參考答案

<details>
<summary>展開答案</summary>

- 情境 A → bugfix：有明確的重現步驟和預期行為，目標是最小化修復
- 情境 B → feature：從零開始的新功能，需要先設計再實作
- 情境 C → security：先唯讀調查影響範圍，在隔離 worktree 中套用修復，附 CVE 編號

</details>

### 實際結果

（演練時填入）

---

## Step 4：執行 bugfix 流程的第一步

### 指令

```
/orchestrate bugfix 購物車折扣計算錯誤
```

### 觀察點

- AI 是否要求先重現 Bug？
- AI 是否直接開始修程式碼（這是錯誤的）？
- Orchestrate 如何限制 AI 的行為？

### 實際結果

（演練時填入）

---

## 本課重點

| 原則 | 說明 |
|------|------|
| 任務分類先於動手 | 不同類型的失敗模式不同，流程也不同 |
| bugfix 最小化 | 修錯一行就夠，不要「順便重構」 |
| refactor 先有測試 | 沒有測試的重構是賭博 |
| security 先只讀 | 調查階段改了東西會污染影響範圍分析 |
| feature 先設計文件 | 沒有設計就寫的功能，下一個人看不懂 |
