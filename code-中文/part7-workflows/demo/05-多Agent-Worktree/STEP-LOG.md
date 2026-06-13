# 第 5 課演練記錄：多 Agent Worktree — 保護主線時間軸

> 對應文件：`code-中文/part7-workflows/cascade/cascade-start.sh`

## 課程目標

理解為什麼大型任務需要多個隔離的 worktree，
學會用 cascade-start.sh 建立「架構師 / 實作者 / 驗證者」三角色分工，
體驗平行 Claude 實例的分工協作模式。

## 工作目錄

`code-中文/part7-workflows/demo/05-多Agent-Worktree/`

---

## Step 1：閱讀 cascade-start.sh，理解腳本邏輯

### 閱讀任務

打開 `cascade/cascade-start.sh`，回答：

1. 腳本建立幾個 worktree？每個對應什麼角色？

   | Worktree | 對應角色 | 負責什麼 |
   |---------|---------|---------|
   | Worker 1 | | |
   | Worker 2 | | |
   | Worker 3 | | |

2. 腳本的 Branch 命名規則是什麼？（從程式碼中找）

   答：

3. Worktree 目錄建立在哪裡（相對於專案根目錄）？

   答：

### 實際結果

（演練時填入）

---

## Step 2：執行 cascade-start.sh 建立 3 個 worktree

### 前置條件

確認目前在專案根目錄，且 git 工作區是乾淨的：

```bash
git status
```

### 指令

```bash
bash code-中文/part7-workflows/cascade/cascade-start.sh demo-task
```

### 預期結果

```
目前分支：main
任務名稱：demo-task
開始建立 3 個 worktree...

✓ Worktree 1 建立成功：../work-demo-task-1（分支：demo-task-worker-1-...）
✓ Worktree 2 建立成功：../work-demo-task-2（分支：demo-task-worker-2-...）
✓ Worktree 3 建立成功：../work-demo-task-3（分支：demo-task-worker-3-...）
```

### 實際結果

（演練時填入）

---

## Step 3：理解三角色的權限設計

### 思考練習

對照「7 階段流程」，三個角色分別對應哪個階段的工作？

| 角色 | Claude 模型 | Claude Code 對應設定 | 為什麼這樣限制 |
|------|------------|---------------------|--------------|
| 架構師（Worker 1） | Opus（最貴）| Plan Mode（禁止寫程式） | |
| 實作者（Worker 2） | Sonnet | 完整讀寫 | |
| 驗證者（Worker 3） | Haiku（最快）| 唯讀 + 執行測試 | |

### 實際結果

（演練時填入）

---

## Step 4：清理 worktree

### 指令

```bash
git worktree remove ../work-demo-task-1
git worktree remove ../work-demo-task-2
git worktree remove ../work-demo-task-3
git worktree prune
```

### 驗證清理完成

```bash
git worktree list
```

### 預期結果

只剩主工作目錄，不再顯示三個 work- 目錄。

### 實際結果

（演練時填入）

---

## 本課重點

```
為什麼用 Worktree 而不是單純開新 Branch？
→ Worktree 建立實體隔離的資料夾，
  三個 Claude 實例可以同時存在、互不干擾，
  不會因為一個 Claude 動了檔案而影響其他實例的工作。
```

| 問題 | 解決方式 |
|------|---------|
| AI 上下文變長後「忘東忘西」 | 每個角色獨立 session，context 乾淨 |
| 架構師不小心開始寫程式碼 | Plan Mode 鎖死，禁止 Write/Edit |
| 驗證者意外修改了原始碼 | 唯讀限制，確保審查獨立性 |
| 實作完成後 worktree 留著佔空間 | `git worktree prune` 一次清理 |
