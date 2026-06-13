# 第 5 課演練記錄：Sub-agent Token 套利

> 對應文件：`code-中文/part6-cost/agents/code-explorer.md`

## 課程目標

理解「Sub-agent Token 套利」的機制：
讓便宜的 Haiku sub-agent 在獨立 context 讀大量檔案，
主對話只接收精簡摘要，不承擔那幾萬 token 的閱讀成本。
學會設計一個具備 `model: haiku` 的 agent，並理解隔離 context 的價值。

## 工作目錄

`code-中文/part6-cost/demo/05-SubAgent套利/`

---

## Step 1：理解套利機制

### 概念說明

```
傳統做法（成本高）：
  主對話（Sonnet）
    → 讀 40 個檔案（5 萬 token 全進主 context）
    → 分析、產出摘要
  主 context 承擔：5 萬 token 的閱讀成本

套利做法（成本低）：
  主對話（Sonnet）
    → 派 code-explorer（Haiku）去讀 40 個檔案
    → Haiku 的獨立 context 承擔 5 萬 token
    → Haiku 回傳 400 字摘要給主對話
  主 context 承擔：400 字的摘要成本
```

### 思考練習

1. 5 萬 input token 用 Haiku 讀 vs 用 Sonnet 讀，成本差多少？

   | 模型 | 5 萬 input token 成本 |
   |------|---------------------|
   | Haiku（$0.80/M） | |
   | Sonnet（$3/M） | |
   | 差距 | |

2. 「Haiku 的獨立 context 在任務結束後直接丟棄」這句話的意思是什麼？

   答：

3. 為什麼這叫「套利」而不只是「省錢」？

   提示：主對話不只省了模型費，還省了什麼？

   答：

### 實際結果

（演練時填入）

---

## Step 2：閱讀 code-explorer.md，解析 Agent 設計

### 閱讀任務

打開 `agents/code-explorer.md`，逐行分析：

**Frontmatter 區段（--- 之間）**：

| 欄位 | 值 | 設計意圖 |
|------|-----|---------|
| `name` | | |
| `description` | | |
| `model` | | |

**輸出格式規定的三條規則**：

1. 規則 1：答：
2. 規則 2：答：
3. 規則 3：答：

**這三條規則如何影響 token 成本？**

答：

### 實際結果

（演練時填入）

---

## Step 3：設計你自己的套利 Agent

### 任務

參考 `code-explorer.md` 的格式，設計一個用於「在 git log 中搜尋特定關鍵字」的 Haiku agent。

填入以下模板：

```markdown
---
name: （填入 agent 名稱）
description: （填入一句描述，說明什麼時候會用到這個 agent）
model: （填入適合的模型）
---

（填入這個 agent 要做什麼事）

## 角色

（填入這個 agent 的專長範圍）

## 輸出格式

（填入輸出格式規定，要讓 Output token 盡量少）
```

### 判斷練習

對於以下任務，你會選擇：

- A. 讓主對話（Sonnet）直接做
- B. 派 Haiku sub-agent 做，主對話收摘要

| 任務 | 你的選擇（A/B） | 原因 |
|------|--------------|------|
| 在整個 codebase 搜尋所有 `console.log` | | |
| 設計一個分散式快取架構 | | |
| 把 500 個 CSV 檔案裡的欄位名稱列出來 | | |
| 修復一個涉及 race condition 的 bug | | |
| 列出所有 Python 檔案的 import 清單 | | |

### 實際結果

（演練時填入）

---

## Step 4：理解隔離 Context 的雙重價值

### 討論問題

1. 除了「省 token 費用」以外，隔離 context 還有什麼好處？

   提示：想想主對話如果吸收了 5 萬 token 的程式碼，接下來的推理品質會如何？

   答：

2. 什麼時候套利反而沒用（甚至有害）？

   提示：什麼任務需要 AI 看到完整細節才能做好判斷？

   答：

### 實際結果

（演練時填入）

---

## 本課重點

```
Sub-agent Token 套利公式：
  主對話（貴的模型）+ 子 agent（便宜的模型）
    = 主對話品質 + 便宜模型的閱讀成本

  關鍵：子 agent 的 context 在任務結束後消失
  主對話只吸收摘要（400 字），不吸收原始資料（5 萬字）

設計好的套利 Agent 的三個要素：
  1. model: haiku（明確宣告用便宜模型）
  2. 輸出格式限制（條列式、不引用程式碼、只給路徑）
  3. 描述清楚觸發條件（什麼情況下派這個 agent）
```

| 策略 | 節省的 | 代價 |
|------|--------|------|
| Haiku sub-agent 讀大量檔案 | Input token（3.75x 差價） | 多一次 agent 呼叫的 overhead |
| 輸出格式限制 | Output token | 可能遺漏細節 |
| 隔離 context | 主對話品質維護 | 需要設計好 prompt |
