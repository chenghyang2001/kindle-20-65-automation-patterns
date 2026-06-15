# 第 5 課演練記錄：Sub-agent Token 套利

> 對應文件：`code-中文/part6-cost/agents/code-explorer.md`

## 課程目標

理解如何透過 agent 模型分層（Haiku 探索 + Sonnet 決策）大幅降低 token 成本，
學會設計「只回傳路徑」的輕量偵察 agent，把昂貴的推理留給主模型。

## 工作目錄

`code-中文/part6-cost/demo/05-SubAgent套利/`

---

## Step 1：讀懂 agent 設計

`code-explorer.md` 的 3 個關鍵設計決策：

### Q1：`model: haiku` 的意義與成本差異

frontmatter 的 `model: haiku` 強制讓這個 agent 用 Haiku，無論主 Claude 是什麼模型。

| 模型 | 輸入成本 | 輸出成本 |
|------|---------|---------|
| Haiku 4.5 | $0.80/M token | $4/M token |
| Sonnet 4.6 | $3/M token | $15/M token |
| **差距** | **3.75× 便宜** | **3.75× 便宜** |

探索任務交給 Haiku，**省 73% 的 token 費用**。

### Q2：「聚焦結構概覽」如何省錢

- 詳細分析 → 大量輸出 token（逐行解釋、完整範例）
- 結構概覽 → 少量輸出 token（條列清單、檔名）

輸出 token 是最貴的一塊（Haiku $4/M、Sonnet $15/M）。
職責限縮為「只看結構」，輸出量從幾千壓縮到幾百 token。

### Q3：「回傳路徑」vs「回傳完整程式碼」

```
完整程式碼：300 行 × 40 chars/行 = 12,000 chars ≈ 3,000 token（輸出）
檔案路徑：  src/auth/middleware.ts              ≈ 10 token（輸出）
省了 299× 的輸出 token
```

Haiku 做偵察只報座標，Sonnet 做決策只讀必要的檔案。
主 Claude 收到路徑後用 Read 工具直接讀需要的段落，不用把整個 codebase 塞進 context。

---

## Step 2：計算省了多少

假設一個任務需要探索 50 個檔案，才能找到 3 個真正需要修改的：

| 方案 | 動作 | 成本 |
|------|------|------|
| 傳統（只用 Sonnet） | Sonnet 讀 50 個檔 + 分析 | ~50,000 input @ $3/M + ~5,000 output @ $15/M |
| 套利（Haiku 探索） | Haiku 掃 50 個檔回傳路徑，Sonnet 讀 3 個檔決策 | ~50,000 input @ $0.8/M + ~3,000 input @ $3/M |

**探索階段省 73%，整體任務可省 40–60%**

---

## Step 3：agent 邊界設計

**應該派 code-explorer 的情況：**

- 找某個功能在哪個檔案實作
- 列出所有涉及某模組的檔案
- 確認目錄結構與相依關係
- 任何「先找到再說」的偵察任務

**不應該派的情況：**

- 需要理解複雜業務邏輯（Haiku 推理能力有限）
- 需要產出修改建議或設計決策
- 需要理解多個檔案的互動關係並做出判斷

**邊界原則：找（Haiku）vs 分析（Sonnet）**

---

## 本課重點

```
Sub-agent Token 套利三步驟：
  1. 識別任務中的「探索」vs「決策」兩個階段
  2. 把探索任務外包給 model: haiku 的輕量 agent
  3. 主模型只處理「已找到的目標」，不掃描整個 codebase

設計套利 agent 的三個要素：
  model: haiku          ← 強制用便宜模型
  description 限縮職責  ← 防止 agent 越界做昂貴的分析
  輸出只回傳路徑        ← 輸出 token 最少化
```

| 概念 | 比喻 |
|------|------|
| Haiku agent | 偵察兵——找到目標位置就回報 |
| Sonnet 主模型 | 狙擊手——只在精確座標上用精力 |
| 回傳路徑 | 座標——不是帶整個地圖回來 |
