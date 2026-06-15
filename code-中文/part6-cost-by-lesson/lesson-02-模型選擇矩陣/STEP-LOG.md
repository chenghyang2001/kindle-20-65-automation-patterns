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
| 在 10 萬行程式碼中找所有用到 `getUserById` 的地方 | **haiku** | 搜尋 + pattern matching，重複結構化任務，速度成本優先 |
| 設計微服務拆分的整體架構方案 | **sonnet 或 opus** | 架構設計需要複雜推理，不能省 |
| 修一個 NPE 的 bug | **sonnet** | bug 修復需要準確度，能力成本兼顧 |
| 把 200 個 JSON 檔案格式化成統一結構 | **haiku** | 重複性、結構化任務，純機械轉換 |
| 進行安全稽核，找 SQL injection 漏洞 | **sonnet** | 安全稽核準確度很重要，不能冒險漏掉 |
| 生產環境關鍵報告生成，品質必須與主對話一致 | **inherit** | 跟隨主對話設定，品質自動對齊 |

### 實際結果

讀取 model-selection-matrix.md 確認六種任務對應：搜尋/格式化 → haiku；bug/安全 → sonnet；架構 → sonnet/opus；品質一致 → inherit。

---

## Step 2：計算省了多少錢

### 計算練習

假設你每天有一個任務：搜尋程式碼庫（約 50,000 input tokens），目前用 Opus。

| 模型 | 輸入定價（/M token） | 每天成本 | 每月成本（30天） |
|------|-------------------|---------|----------------|
| Opus | $15 | $0.75 | **$22.5** |
| Sonnet | $3 | $0.15 | **$4.5** |
| Haiku | $0.80 | $0.04 | **$1.2** |

回答：

1. 從 Opus 換成 Haiku，每月省多少錢？

   答：$22.5 - $1.2 = **$21.3**，省了 **95%** 的成本。

2. 如果你有 5 個這樣的搜尋任務每天，每月省多少？

   答：5 × $21.3 = **$106.5 / 月**——只是把搜尋任務降階，不改任何業務邏輯，每個月省下約 $106 美元。

### 實際結果

計算確認：Opus vs Haiku 差價 18.75 倍；單一搜尋任務每月省 $21.3；5 個任務每月省 $106.5。搜尋類任務是最容易、最安全的降階目標。

---

## Step 3：閱讀 code-explorer.md，理解 sub-agent 模型設定

### 閱讀任務

打開 `agents/code-explorer.md`，回答：

1. 這個 agent 在 frontmatter（---區段）宣告了什麼模型？

   答：`model: haiku`

2. 這個 agent 的 description 說它「聚焦於」什麼？為什麼這種任務適合 Haiku？

   答：聚焦於「**結構概覽**，而非詳細的程式碼分析」。探索任務的判斷邏輯很機械（「這個檔案有沒有用到 X」），不需要複雜推理，haiku 的速度和成本優勢完全發揮。

3. 輸出格式要求「盡量減少詳細的程式碼引用」，這個設計如何幫助節省成本？

   答：**Output token 越少，費用越低**。把「找到哪裡」（haiku 便宜做）和「深入分析」（sonnet 才做）分成兩個階段，只回傳檔案路徑而非引用大段程式碼，Output 大幅縮減。

### 實際結果

讀取 code-explorer.md 確認：frontmatter `model: haiku`、描述聚焦結構概覽、輸出只回路徑不引用程式碼。三個設計都指向同一目標：把探索成本壓到最低。

---

## Step 4：理解 `inherit` 的用途

### 情境判斷

對照 `model-selection-matrix.md` 中 `inherit` 的說明，回答：

1. 什麼情況下應該用 `inherit` 而不是寫死 `sonnet` 或 `haiku`？

   答：當 sub-agent 的**輸出品質必須與主對話一致**時——例如生成最終交付給使用者的報告、關鍵判斷，不能因為「自動降階」而讓品質低於主對話標準。

2. 如果主對話用 Opus，sub-agent 設 `inherit`，sub-agent 跑幾個模型？

   答：**Opus**（繼承呼叫方的模型，不降階也不升階）。

3. `inherit` 的風險是什麼？（提示：主對話如果換成 Haiku 呢）

   答：主對話如果切換成 Haiku（例如 `CLAUDE_CODE_SUBAGENT_MODEL=haiku`），所有設了 `inherit` 的 sub-agent 都跟著跑 Haiku——那些需要複雜推理的 agent（安全稽核、架構設計）品質會**靜默下降，不會有任何警告**。`inherit` 讓模型選擇變成全域單點，主對話切模型時要意識到副作用。

### 全域環境變數

你也可以用一行指令讓所有 sub-agent 降階：

```bash
export CLAUDE_CODE_SUBAGENT_MODEL=haiku
```

這行加在 `.bashrc` 或 `~/.claude/settings.json` 的 `env` 區段都可以。

### 實際結果

理解 `inherit` 的設計：當品質必須對齊主對話時使用；風險在於主對話降階會靜默拉低所有繼承者。全域環境變數 `CLAUDE_CODE_SUBAGENT_MODEL=haiku` 是快速讓所有 sub-agent 降階的工具，但設了 `inherit` 的 agent 會被它影響。

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
