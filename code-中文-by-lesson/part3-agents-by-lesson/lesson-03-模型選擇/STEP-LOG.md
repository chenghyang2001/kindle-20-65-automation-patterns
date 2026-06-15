# 第 3 課演練記錄：模型選擇矩陣

> 對應文件：`docs/model-cost-matrix.md` + `03-demo-model-selection/log-searcher.md`
> 主題：依任務類型選 haiku / sonnet / inherit，用成本計算驗證選擇

---

## 核心觀念

Sub-agent 每次呼叫都花 API 費。選對模型 = 在「夠用的準確度」和「最低成本」之間找平衡。
探索/搜尋 → Haiku；稽核/實作 → Sonnet；大規模重構 → inherit。

---

## Step 1：模型選擇矩陣

**命令：**

```bash
cat code-中文/part3-agents/docs/model-cost-matrix.md
```

**實際驗證：** ✅ 文件的任務→模型對應（加上全域 cost-rules.md 補充的實際成本）：

| 模型 | 輸入（/M tokens） | 輸出（/M tokens） | 適用任務 |
|------|-----------------|-----------------|---------|
| Haiku 4.5 | $0.80 | $4 | 搜尋、pattern matching、格式審查 |
| Sonnet 4.6 | $3 | $15 | Bug 修復、安全稽核、實作 |
| Opus | $15 | $75 | 架構設計、複雜推理 |

**`model: inherit` 的語意**：不是「不指定」，而是「明確跟著主對話模型走」— 主對話換模型，sub-agent 自動跟上，不需逐一修改 agent 檔案。適用大規模重構（需要主對話級別品質）。

---

## Step 2：成本計算 — 換 Haiku 能省多少

**情境**：log-searcher agent 每天呼叫 100 次，每次 500 input + 200 output tokens。

**每月總量**：100 × 30 = 3,000 次 → 輸入 1.5M tokens，輸出 0.6M tokens

| | Sonnet（$3/$15 per M）| Haiku（$0.80/$4 per M）|
|--|----------------------|----------------------|
| 輸入費 | 1.5 × $3 = $4.50 | 1.5 × $0.80 = $1.20 |
| 輸出費 | 0.6 × $15 = $9.00 | 0.6 × $4 = $2.40 |
| **月費** | **$13.50** | **$3.60** |

→ 換 Haiku **省 $9.90/月（73%）**，搜尋任務功能完全一樣。這是文件範例設 `model: haiku` 的量化底層。

---

## Step 3：CLAUDE_CODE_SUBAGENT_MODEL 環境變數的適用邊界

```bash
export CLAUDE_CODE_SUBAGENT_MODEL=haiku   # 全域覆蓋所有 sub-agent
```

**適合：**

| 場景 | 原因 |
|------|------|
| 開發測試期 | 頻繁呼叫驗功能，暫時接受準確率下降 |
| 全是探索/搜尋任務 | 整個 session 不涉及安全稽核 |
| API Credits 快用完 | 緊急限速，接受全面降品質 |

**不適合：**

| 場景 | 問題 |
|------|------|
| 同時跑 security-reviewer | Haiku 準確度不足，可能漏掉漏洞（假陽性的安心感更危險）|
| 架構設計任務 | Haiku 推理不足，設計品質大幅下降 |
| 生產 PR 合併前 | 省成本代價是品質風險，不划算 |

**根本問題**：全域覆蓋把精心設計的 `model: sonnet` 一刀切掉。個別 agent frontmatter 設 `model` 比全域覆蓋細緻，只有「全部 agent 都是低權限探索」的情境才用全域設定。

---

## Step 4：讀 log-searcher agent — 驗證設計完整鏈

**命令：**

```bash
cat code-中文/part3-agents/03-demo-model-selection/log-searcher.md
```

**實際驗證：** ✅

| 項目 | 值 | 評估 |
|------|----|----|
| model | haiku | ✅ 搜尋任務，不需推理，符合矩陣 |
| tools | Read, Grep, Glob | ✅ 唯讀三件套，無法寫入或執行指令 |
| 系統提示末句 | 「不要加上額外說明」| ✅ 壓縮輸出 token（Haiku 輸出 $4/M，少輸出 = 省更多）|

**四者完整鏈**：


```
description（何時用）→ model（成本）→ tools（權限）→ 系統提示（行為）

```

系統提示「只回傳找到的內容」配合 Haiku 低輸出單價，雙重降本。設計 agent 時四個維度要一起考慮。

**產出物：** `docs/model-cost-matrix.md`（分析對象）、`log-searcher.md`（驗證對象）
