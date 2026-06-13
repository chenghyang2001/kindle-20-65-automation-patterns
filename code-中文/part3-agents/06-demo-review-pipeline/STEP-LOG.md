# 第 6 課演練記錄：四層審查鏈

> 對應文件：`agents/*.md`、`workflows/test-scenarios.md`

## 課程目標

用一個「故意寫爛的 Python API 函式」當測試對象，
按 `spec-compliance → code-quality → security → api-reviewer` 順序，
依序跑四個 reviewer，理解為何「串聯順序很重要」。

## 工作目錄

`code-中文/part3-agents/demo-review-pipeline/`

---

## Step 1：建立測試對象 buggy-api.py

### 檔案說明

這個 Python 檔案故意包含以下問題：


- SQL injection（字串串接組 query）
- 缺少輸入驗證
- 硬編碼密碼
- 命名不清楚（`d`, `r`, `tmp`）
- 缺少錯誤處理

### 建立指令

```bash
# 透過 code-writer → code-qa → code-reviewer 三 agent 流程建立
# （因為 .py 需要走 writer-qa 鐵律）
```

### 實際檔案路徑

`demo-review-pipeline/buggy-api.py`（演練時建立）

---

## Step 2：第一關 — spec-compliance-reviewer

### 呼叫方式（Claude Code 互動模式）

```bash
Use spec-compliance-reviewer to review demo-review-pipeline/buggy-api.py
```

### 預期輸出格式

```
PASS：功能 X 已實作
FAIL [錯誤處理]：缺少 try/except 包裝
FAIL [API 規格]：回傳格式不符規格
```

### 實際結果

（演練時填入）

---

## Step 3：第二關 — code-quality-reviewer

### 呼叫方式

```bash
Use code-quality-reviewer to review demo-review-pipeline/buggy-api.py
```

### 預期輸出

- Critical：硬編碼憑證
- Warning：命名問題（d, r, tmp）
- Suggestion：抽取重複邏輯

### 實際結果

（演練時填入）

---

## Step 4：第三關 — security-reviewer

### 呼叫方式

```bash
Use security-reviewer to review demo-review-pipeline/buggy-api.py
```

### 預期輸出

- Critical：SQL injection（附 file:line）
- Critical：明文密碼
- High：缺少授權檢查

### 實際結果

（演練時填入）

---

## Step 5：第四關 — api-reviewer（視需要）

### 呼叫方式

```bash
Use api-reviewer to review demo-review-pipeline/buggy-api.py
```

### 預期輸出

- Critical：缺少輸入驗證
- Warning：HTTP 狀態碼不正確
- Suggestion：加入分頁

### 實際結果

（演練時填入）

---

## 本課重點

| 串聯順序 | 原因 |
|---------|------|
| spec-compliance 最先 | 不符規格的功能根本不用審查品質 |
| quality 第二 | 功能對了，再看可維護性 |
| security 第三 | 品質過關再掃安全漏洞（節省時間） |
| api 最後 | 上三關都過才值得做 API 設計建議 |

**為什麼不平行跑？**
→ 各 reviewer 的 context 不同：security reviewer 需要知道 quality review 已確認的問題範圍。
→ spec 失敗 → 直接退回修改，不浪費 security 的成本。
