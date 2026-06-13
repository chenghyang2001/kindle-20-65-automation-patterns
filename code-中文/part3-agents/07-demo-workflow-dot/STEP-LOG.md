# 第 7 課演練記錄：DOT 工作流圖（防止 Workflow Drift）

> 對應文件：`workflows/code-review.dot`、`workflows/code-review.png`

## 課程目標

學會用 DOT 格式定義多 agent 工作流，
理解「workflow drift（流程漂移）」是什麼，
以及為什麼圖定義能防止 AI 自行改變流程。

## 工作目錄

`code-中文/part3-agents/demo-workflow-dot/`

---

## Step 1：讀懂 code-review.dot

### 指令

```bash
cat ../workflows/code-review.dot
```

### 填入流程圖（演練時填入節點關係）

```
start → explore → spec_check
spec_check --FAIL--> fix
spec_check --PASS--> quality_check
quality_check --PASS--> security_check
quality_check --Critical--> fix
security_check --PASS--> done
security_check --Critical--> fix
fix → spec_check（重新跑一遍）
```

---

## Step 2：什麼是 Workflow Drift？

### 說明

沒有 DOT 定義時，AI 可能：

- 跳過 spec_check（「感覺 quality 更重要」）
- 把 security + quality 平行跑（「這樣比較快」）
- fix 完直接跳 security（「spec 剛才已過了」）

有 DOT 定義後，prompt 裡貼入圖定義：
AI 讀到「spec → quality → security，修完回 spec」→ 嚴格照流程走。

---

## Step 3：修改 DOT 圖 — 加入 api-check 節點

### 目標

在 security_check → done 之間插入 api_check 節點。

### 修改前後對比

```dot
# 修改前：
security_check -> done [label="PASS"];

# 修改後：
security_check -> api_check [label="PASS"];
api_check -> done [label="PASS"];
api_check -> fix [label="發現 Critical"];
```

### 建立修改版

```bash
cp ../workflows/code-review.dot demo-workflow-dot/code-review-v2.dot
# 手動編輯加入 api_check
```

### 實際結果

（演練時填入）

---

## Step 4：渲染 DOT 圖為 PNG（可選）

### 指令（需要安裝 graphviz）

```bash
# 檢查是否已安裝
dot -V

# 渲染
dot -Tpng demo-workflow-dot/code-review-v2.dot -o demo-workflow-dot/code-review-v2.png
```

### 實際結果

（演練時填入）

---

## 本課重點

| 概念 | 說明 |
|------|------|
| DOT 格式 | `A → B [label="條件"]` 定義節點與轉換 |
| Workflow Drift | AI 自行簡化或修改流程，偏離設計 |
| 防止方式 | 在 prompt 中貼入 DOT 圖 + 說明「嚴格依圖執行」 |
| `rankdir=LR` | 左到右排列（`TB` = 上到下） |
| `shape=oval` | 橢圓 = 起始/結束節點；`box` = 處理步驟 |

## 為什麼 DOT 比文字描述更好？

| 文字描述 | DOT 圖 |
|---------|--------|
| AI 可能「理解」成不同順序 | 明確定義每個轉換條件 |
| 新人看不懂「依序」是什麼意思 | 圖直觀，一目了然 |
| 修改後容易前後矛盾 | 改 DOT 節點，關係圖自動更新 |
