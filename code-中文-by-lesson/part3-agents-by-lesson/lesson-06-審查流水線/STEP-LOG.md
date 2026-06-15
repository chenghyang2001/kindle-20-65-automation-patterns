# 第 6 課演練記錄：串聯 Reviewer Pipeline

> 對應文件：`06-demo-review-pipeline/buggy-api.py` + `docs/decision-matrix.md`
> 主題：多 reviewer 依序串接 + sub-agents vs Agent Teams 架構選型

---

## 核心觀念

reviewer pipeline 的兩個設計維度：

- **順序**：正確性優先於品質（spec-compliance → code-quality → security → api-reviewer）
- **架構**：review 任務獨立 → sub-agents，不需開 Agent Teams

---

## Step 1：分析 buggy-api.py — 各 reviewer 的報告重心

**命令：**

```bash
cat code-中文/part3-agents/06-demo-review-pipeline/buggy-api.py
```

**實際驗證：** ✅ 程式的問題清單（由嚴重到輕微）：

**🔴 安全性（spec-compliance-reviewer 會先報）：**

| 行號 | 問題 | 類型 |
|------|------|------|
| 第 3 行 | `password = "admin123"` 硬編碼明文密碼 | 安全性 |
| 第 10 行 | 字串串接 SQL（`"... WHERE id = " + user_id`）| SQL Injection |
| 第 21 行 | 同上，`login()` 的 username 參數未過濾 | SQL Injection |
| 第 18 行 | `pwd == password` 明文比對，不用 bcrypt hash | 安全性 |

**🟡 功能缺失（spec-compliance 同步回報）：**

| 行號 | 問題 | 類型 |
|------|------|------|
| 第 8、19 行 | `conn.close()` 未包在 try/finally，例外時資源洩漏 | 錯誤處理 |

**⚪ 品質問題（code-quality-reviewer 等 spec-compliance 跑完才報）：**

- 變數命名含糊：`d`, `r`, `tmp`, `c` 完全不知道是什麼
- 無 docstring / type hint
- 無 logging

**兩個 reviewer 的報告重心對比：**

| Reviewer | 先報什麼 | 原因 |
|----------|---------|------|
| spec-compliance-reviewer | SQL Injection + 硬編碼密碼 | 功能是否安全正確的問題 |
| code-quality-reviewer | 變數命名（d, r, tmp）| 功能確認正確後才有意義審品質 |

---

## Step 2：串聯順序的代價分析

**錯誤順序（先 code-quality 再 spec-compliance）的浪費：**

```
code-quality 花時間審命名（d → user_query, r → cursor_result）
  → spec-compliance 發現 SQL Injection = 整個函式要重寫
  → code-quality 做的命名審查全部白費
```

**Token 成本計算（Sonnet $15/M output）：**

| 順序 | 步驟 | 成本 |
|------|------|------|
| 錯誤順序 | code-quality + spec-compliance 發現 bug + code-quality 重跑 | ~$0.06 |
| 正確順序 | spec-compliance → 修 bug → code-quality | ~$0.03 |

錯誤順序多花 2 倍成本。這是第 2 課「description 寫 spec-compliance 之後使用」那一行的量化底層。

---

## Step 3：串聯呼叫指令序列

**在 Claude Code 互動模式中，依序呼叫 4 個 reviewer：**

```
Use spec-compliance-reviewer to review code-中文/part3-agents/06-demo-review-pipeline/buggy-api.py
```

等完成後：

```
Use code-quality-reviewer to review code-中文/part3-agents/06-demo-review-pipeline/buggy-api.py
```

等完成後：

```
Use security-reviewer to review code-中文/part3-agents/06-demo-review-pipeline/buggy-api.py
```

視結果決定是否加：

```
Use api-reviewer to review code-中文/part3-agents/06-demo-review-pipeline/buggy-api.py
```

**為什麼必須手動依序，不能一次下四個：**

sub-agent 不能巢狀（第 1 課）。若一次說「跑四個 reviewer」，Claude 可能讓 agent 1 呼叫 agent 2 → 巢狀失敗。正確方式是主對話（唯一指揮官）一次只派一個，收到結果後繼續。

---

## Step 4：decision-matrix — sub-agents vs Agent Teams 架構選型

**命令：**

```bash
cat code-中文/part3-agents/docs/decision-matrix.md
```

**實際驗證：** ✅ 這個文件不是「呼叫哪個 reviewer」的分流，而是**架構層**選型：

```
任務是否獨立？
  是 → Sub-agents 就夠了
  否 → 代理之間需要直接溝通？
    是 → 考慮 Agent Teams（實驗性）
    否 → 主對話循序執行
```

| 面向 | Sub-agents | Agent Teams |
|------|-----------|-------------|
| 溝通方式 | 只能透過主代理 | 代理之間直接溝通 |
| Token 成本 | 低 | 高（多個實例）|
| 狀態 | 官方功能 | 實驗性 |

**兩個維度的關係 — 互補，不重複：**

| | Step 3 的排序邏輯 | decision-matrix |
|--|------------------|-----------------|
| 回答的問題 | 什麼**順序**跑 reviewer？| 用什麼**架構**跑多個 agent？|
| 層次 | 戰術層 | 架構層 |
| review pipeline 的答案 | spec-compliance → ... → api-reviewer | 獨立任務 → sub-agents，不用 teams |

**最關鍵的一行**：「能由 Sub-agents 處理的任務，優先使用 Sub-agents。」
review pipeline 四個 reviewer 完全獨立（只讀不改）→ 決策樹走左邊 → sub-agents。Agent Teams 是有協作溝通需求才用，不是「讓 agent 更快」的選項。

---

## 第 6 課四 Step 對照

| Step | 主題 | 關鍵收穫 |
|------|------|---------|
| 1 | 分析 buggy-api.py | 安全性問題 > 功能缺失 > 品質問題，嚴重程度決定優先順序 |
| 2 | 順序代價分析 | 錯誤順序多花 2 倍 token；正確性優先品質 |
| 3 | 呼叫指令序列 | 主對話是唯一指揮官，一次一個 agent |
| 4 | 架構選型 | review 任務獨立 → sub-agents；需互相協作 → Agent Teams（實驗性）|

**產出物：** `buggy-api.py`（分析對象）、`decision-matrix.md`（架構選型）
