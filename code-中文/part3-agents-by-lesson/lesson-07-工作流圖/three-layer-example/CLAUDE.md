# 第三層：機器執行層（給 Claude Code 看）

## PR 審查 Pipeline

實作完成或收到 PR 後，**依序**執行以下步驟（不可平行、不可跳過）：

### Step 1 — 探索程式碼

```
Use Explore to map changed files in this PR
```

### Step 2 — 規格遵循檢查

```
Use spec-compliance-reviewer to review [changed files]
```

- FAIL → 停止，回報給實作者修正，修完後**從 Step 2 重新開始**
- PASS → 繼續 Step 3

### Step 3 — 品質審查

```
Use code-quality-reviewer to review [changed files]
```

- Critical → 停止，回報修正，修完後**從 Step 2 重新開始**
- PASS → 繼續 Step 4

### Step 4 — 安全性審查

```
Use security-reviewer to review [changed files]
```

- Critical → 停止，回報修正，修完後**從 Step 2 重新開始**
- PASS → 繼續 Step 5

### Step 5 — API 設計審查（涉及 API 端點時）

```
Use api-reviewer to review [changed files]
```

- Critical → 停止，回報修正，修完後**從 Step 2 重新開始**
- PASS → PR 可合併
- 超時（60 秒無回應）→ 帶警告標記直接進入可合併狀態，人工補審

## 重要規則

- **fix 後永遠回 Step 2**，不跳回觸發點
- **不平行跑** reviewer（一次一個，等結果後繼續）
- **主對話是唯一指揮官**（不讓 reviewer 之間互相呼叫）
