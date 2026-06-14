# 第 7 課演練記錄：Workflow DOT 視覺化

> 對應文件：`workflows/code-review.dot` + `07-demo-workflow-dot/code-review-v2.dot`
> 主題：用 Graphviz DOT 語言畫 agent workflow + 三層文件互補架構

---

## 核心觀念

workflow 有三種描述方式（DOT 圖、CLAUDE.md 規則、自然語言），互補而非取代。
DOT 圖是「設計階段的視覺共識」，CLAUDE.md 規則是「機器執行層」，自然語言是「動機說明層」。

---

## Step 1：讀懂 code-review.dot — DOT 語法三要素

**命令：**

```bash
cat code-中文/part3-agents/workflows/code-review.dot
```

**實際驗證：** ✅

| 語法 | 意義 |
|------|------|
| `digraph code_review_workflow { }` | 有向圖宣告，名稱是 code_review_workflow |
| `A -> B [label="條件"]` | 有向邊（箭頭），表示流程轉移 + 觸發條件 |
| `[shape=oval]` | 節點圖形；oval = 起始/結束，box = 處理步驟 |
| `rankdir=LR` | 圖形從左到右排列 |

**v1 workflow 結構：**

```
開始 → Explore（Haiku 探索）
  → spec-compliance-reviewer
    FAIL → 修正 → 回 spec-compliance（第一關重跑）
    PASS → code-quality-reviewer
      Critical → 修正 → 回 spec-compliance
      PASS → security-reviewer
        Critical → 修正 → 回 spec-compliance
        PASS → 完成
```

**對照第 6 課**：圖中順序正確（spec → quality → security）。Explore 是前置步驟，用 Haiku 先建立程式碼地圖，再花 Sonnet 跑 reviewer，省成本。

**修正後回 spec_check**（不是回觸發點）：修改可能破壞之前通過的關卡，從最嚴格的第一關重新驗起。

---

## Step 2：v1 vs v2 — 加入 api-reviewer 第 4 關

**命令：**

```bash
cat code-中文/part3-agents/07-demo-workflow-dot/code-review-v2.dot
```

**實際驗證：** ✅

| 項目 | v1 | v2 |
|------|----|----|
| 節點數 | 7 | 8（多了 api_check）|
| security 之後 | `security → done` | `security → api_check → done` |

v2 加入的邊：

```dot
security_check -> api_check [label="PASS"];
api_check -> done [label="PASS"];
api_check -> fix [label="發現 Critical"];
```

**v1 的問題**：`security PASS → done` 跳過 API 設計審查，`buggy-api.py` 缺少輸入驗證等問題永遠不被審查。v2 補上第 4 關，完整對應第 6 課四層 pipeline。

---

## Step 3：加入「超時放行」分支 — DOT 非正常路徑設計

**新增的一行：**

```dot
api_check -> done [label="超時（帶警告）", style=dashed, color=orange];
```

**屬性設計意圖：**

| 屬性 | 值 | 意義 |
|------|-----|------|
| `label` | 「超時（帶警告）」| 區分正常 PASS 和超時放行 |
| `style=dashed` | 虛線 | 非正常路徑，和實線 PASS 一眼可分 |
| `color=orange` | 橘色 | 警告語意（不是 Critical 紅，也不是正常綠）|

DOT 允許同一對節點有多條邊（不同 label），Graphviz 畫成平行箭頭，清楚表達「三種出口」。

---

## Step 4：三層 workflow 文件的定位與互補關係

**三種描述各放哪裡：**

| 描述方式 | 放在哪裡 | 讀者 | 目的 |
|----------|---------|------|------|
| DOT 圖（`.dot` + `.png`）| `docs/` 或 `workflows/` | 新加入的人、架構討論 | 快速建立全局視圖，一眼看懂分支邏輯 |
| CLAUDE.md 規則 | `CLAUDE.md` 或 agents `description` | Claude Code | 機器可執行的觸發指令 |
| 自然語言 | README 或 PR description | 所有人（含非技術）| 說明「為什麼」這樣設計，不是「怎麼做」|

**設計流程：**

```
先畫 DOT 圖（討論 pipeline，確認分支和循環）
  ↓
達成共識後，轉成 CLAUDE.md 規則（讓 Claude 執行）
  ↓
在 README 用一段自然語言說明設計動機（讓未來的人看懂）
```

**三層缺一不可：**

- 只有 DOT：Claude 看不懂 dot 語法，不會自動執行
- 只有 CLAUDE.md：新成員不知道為什麼這樣排序，也不知道有沒有 timeout 分支
- 只有自然語言：「先跑 spec 再跑 quality」有歧義，Claude 的執行行為不確定

**Part 3 七課的三層對應：**

```
第 2 課 agents/*.md frontmatter  ← CLAUDE.md 規則層
第 6 課 reviewer pipeline 順序  ← 自然語言設計原則
第 7 課 code-review.dot / v2    ← DOT 圖視覺化層
```

---

## 第 7 課四 Step 對照

| Step | 主題 | 關鍵收穫 |
|------|------|---------|
| 1 | 讀 code-review.dot | DOT 語法三要素；fix 回第一關不回原點 |
| 2 | v1 vs v2 差異 | 加 api-reviewer 第 4 關；缺關卡 = 問題漏審 |
| 3 | 超時放行分支 | dashed + orange 標記非正常路徑 |
| 4 | 三層文件互補 | DOT（視覺）+ CLAUDE.md（執行）+ 自然語言（動機）缺一不可 |

**產出物：** `workflows/code-review.dot`（v1）、`07-demo-workflow-dot/code-review-v2.dot`（v2 含 api-reviewer）
