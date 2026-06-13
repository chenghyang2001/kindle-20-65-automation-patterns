# 第 2 課演練記錄：模型選擇矩陣

> 對應文件：`code-中文/part6-cost/model-selection-matrix.md`

## 課程目標

學會依任務的「認知需求」選對模型，而不是一律用最貴的 Opus。
理解 Haiku / Sonnet / Opus 的價差達 20 倍，錯誤的選擇等於浪費 95% 預算。
學會在 sub-agent 定義中加入 `model:` 欄位讓 AI 自動降階。

## 工作目錄

`code-中文/part6-cost/demo/02-模型選擇矩陣/`

---

## Step 1：閱讀模型選擇矩陣，填入判斷

### 閱讀任務

打開 `model-selection-matrix.md`，填入以下表格：

| 任務 | 你選哪個模型 | 原因 |
|------|------------|------|
| 在 10 萬行程式碼中找所有用到 `getUserById` 的地方 | | |
| 設計微服務拆分的整體架構方案 | | |
| 修一個 NPE（Null Pointer Exception）的 bug | | |
| 把 200 個 JSON 檔案格式化成統一結構 | | |
| 進行安全稽核，找 SQL injection 漏洞 | | |
| 生產環境關鍵報告生成，品質必須與主對話一致 | | |

### 實際結果

（演練時填入）

---

## Step 2：計算省了多少錢

### 計算練習

假設你每天有一個任務：搜尋程式碼庫（約 50,000 input tokens），目前用 Opus。

| 模型 | 輸入定價（/M token） | 每天成本 | 每月成本（30天） |
|------|-------------------|---------|----------------|
| Opus | $15 | | |
| Sonnet | $3 | | |
| Haiku | $0.80 | | |

回答：

1. 從 Opus 換成 Haiku，每月省多少錢？

   答：

2. 如果你有 5 個這樣的搜尋任務每天，每月省多少？

   答：

### 實際結果

（演練時填入）

---

## Step 3：閱讀 code-explorer.md，理解 sub-agent 模型設定

### 閱讀任務

打開 `agents/code-explorer.md`，回答：

1. 這個 agent 在 frontmatter（---區段）宣告了什麼模型？

   答：

2. 這個 agent 的 description 說它「聚焦於」什麼？為什麼這種任務適合 Haiku？

   答：

3. 輸出格式要求「盡量減少詳細的程式碼引用」，這個設計如何幫助節省成本？

   答：

### 實際結果

（演練時填入）

---

## Step 4：理解 `inherit` 的用途

### 情境判斷

對照 `model-selection-matrix.md` 中 `inherit` 的說明，回答：

1. 什麼情況下應該用 `inherit` 而不是寫死 `sonnet` 或 `haiku`？

   答：

2. 如果主對話用 Opus，sub-agent 設 `inherit`，sub-agent 跑幾個模型？

   答：

3. `inherit` 的風險是什麼？（提示：主對話如果換成 Haiku 呢）

   答：

### 全域環境變數

你也可以用一行指令讓所有 sub-agent 降階：

```bash
export CLAUDE_CODE_SUBAGENT_MODEL=haiku
```

這行加在 `.bashrc` 或 `~/.claude/settings.json` 的 `env` 區段都可以。

### 實際結果

（演練時填入）

---

## 本課重點

```
模型選擇的鐵律：
  搜尋 / 格式化 / 重複性任務 → Haiku（最便宜，20x 省）
  功能實作 / bug 修復 / 安全稽核 → Sonnet（主力，cp 值高）
  架構設計 / 極模糊需求 → Opus（鎖保險箱，只在真正需要時出動）

在 agent 的 frontmatter 寫上 model: haiku
是最省力的成本控制 — 一次設定，終身受益。
```

| 模型 | 輸入 | 輸出 | 適合 |
|------|------|------|------|
| Haiku | $0.80/M | $4/M | 搜尋、格式化、重複任務 |
| Sonnet | $3/M | $15/M | 實作、修 bug、審查 |
| Opus | $15/M | $75/M | 架構決策（謹慎動用） |
