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

`/orchestrate` 觸發後顯示四種任務類型的完整工作流清單。
同樣採用 `disable-model-invocation: true`，與 `/confidence-check` 一樣，
是純結構性提示詞 — 強迫 AI「按流程走」而非「直接下手」。

---

## Step 2：對比四種任務的工作流差異

### 演練任務

閱讀 `orchestrate/SKILL.md`，填入下表：

| 任務類型 | 第一步 | 最後一步 | 核心關鍵 |
|---------|-------|---------|---------|
| bugfix | 確認並記錄重現步驟 | 跑完整迴歸測試套件 | 最小範圍修復，禁止「順便重構」 |
| feature | 定義需求與驗收標準 | 更新文件 | TDD + 設計文件先於程式碼 |
| refactor | 變更前先確認測試覆蓋率 | 量測效能並用數字呈現改善幅度 | 沒有測試保護不能動 |
| security | 以唯讀方式調查影響範圍（不使用 Write） | release notes 附 CVE 編號 | 調查唯讀，修復在隔離 worktree |

### 觀察點解析

- **bugfix 最小範圍**：修的面積越小，迴歸風險越低。改了 3 行，就只有 3 行可能出問題。
  「順便重構」讓改動面積爆炸，一旦新 bug 出現，根本分不清是 bugfix 還是重構引起的。

- **refactor 先確認覆蓋率**：沒有測試保護的重構是在黑暗中施工 — 改完了也不知道是否破壞了原有行為。
  Strangler Fig 模式的「漸進遷移」也必須以「每一步都有測試通過」為前提，否則「漸進」只是「慢慢出問題」。

- **security 調查階段只讀**：調查時任何 Write 操作都會污染 `git diff`，讓「影響範圍調查」和「修復改動」混在一起。
  後續審查者看不出哪些是調查副產品、哪些是真正的修復。隔離 worktree 是為了同樣的原因。

### 實際結果

四種工作流各自針對一種失敗模式設計：

- bugfix 防「修一破三」
- feature 防「沒設計就施工」
- refactor 防「瞎子摸象式重構」
- security 防「污染現場」

---

## Step 3：依情境選擇正確的任務類型

### 情境判斷練習

**情境 A**：使用者回報「購物車金額算錯，折扣沒有套用到最後一件商品」

**任務類型：bugfix**
理由：有明確的重現步驟（「最後一件商品」是可重現的邊界條件），目標是找出折扣計算邏輯中的一個錯誤並最小化修復，不需要設計新功能也不是安全漏洞。

---

**情境 B**：產品要求新增「匯出訂單為 CSV 檔案」的功能

**任務類型：feature**
理由：從零開始的新功能，需要先定義需求（哪些欄位？格式是什麼？）→ 設計文件 → TDD 實作 → 文件更新。沒有任何既有行為要修復或遷移。

---

**情境 C**：發現程式庫用的是 bcrypt 1.0（舊版），有已知的 CVE-2023-8080 漏洞

**任務類型：security**
理由：有具體 CVE 編號的已知漏洞。流程是：先唯讀調查影響範圍 → 隔離 worktree 升版/套用 patch → 資安審查 agent 驗證 → release notes 附 CVE 編號。跳過任何一步都可能遺漏攻擊面。

### 實際結果

三個情境的分類關鍵字：

- 「回報錯誤 + 可重現」→ bugfix
- 「新增功能 + 從零開始」→ feature
- 「CVE + 漏洞 + 安全」→ security

---

## Step 4：執行 bugfix 流程的第一步

### 指令

```
/orchestrate bugfix 購物車折扣計算錯誤
```

### 觀察結果

| 觀察點 | 結果 |
|--------|------|
| AI 是否要求先重現 Bug？ | **是**。bugfix 第一步「確認並記錄重現步驟」，AI 先取得重現路徑才能繼續 |
| AI 是否直接開始修程式碼？ | **否**。有序步驟清單讓 AI 知道「還沒到那一步」 |
| Orchestrate 如何限制 AI？ | 明確有序步驟 + `disable-model-invocation: true`，把流程決策權從 AI 手上收回 |

### 實際結果

沒有 Orchestrate，AI 的預設行為是「看到問題就直接改程式碼」。
Orchestrate 的本質是把「任務分類」和「流程設計」從每次對話的即興決策，
變成可重用的制度化工作流。

```
沒有 Orchestrate：任務 → AI 直覺 → 可能走錯流程
有  Orchestrate：任務 → 分類 → 對應流程 → 逐步執行
                        ↑
                   這一步是整個設計的核心
```

---

## 本課重點

| 原則 | 說明 |
|------|------|
| 任務分類先於動手 | 不同類型的失敗模式不同，流程也不同 |
| bugfix 最小化 | 修錯一行就夠，不要「順便重構」 |
| refactor 先有測試 | 沒有測試的重構是賭博 |
| security 先只讀 | 調查階段改了東西會污染影響範圍分析 |
| feature 先設計文件 | 沒有設計就寫的功能，下一個人看不懂 |

> **隱性教訓**：`disable-model-invocation: true` 在 orchestrate 裡的意義：
> 不是「不讓 AI 思考」，而是「讓 AI 遵循既定流程，而非即興發揮」。
> 制度化流程的價值不在於限制聰明的 AI，而在於保護你免於 AI 的過度自信。
