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

### 1. 腳本建立幾個 worktree？每個對應什麼角色？

腳本建立 **3 個** worktree：

| Worktree | 對應角色 | 負責什麼 |
|---------|---------|---------|
| Worker 1 | 安全性審查者 | `code/part2-hooks/` 的安全性掃描 |
| Worker 2 | 程式碼品質審查者 | 整體程式碼品質（命名/結構/可讀性）|
| Worker 3 | 規格合規性檢查者 | 實作是否符合書中規格 |

### 2. Branch 命名規則

```
${TASK}-worker-${i}-${TS}
```

例如：`demo-task-worker-1-1718345678`

組成：`任務名稱 + -worker- + 編號(1/2/3) + - + Unix 時間戳`
時間戳的作用：確保每次執行產生唯一分支名稱，不會和舊分支衝突。

### 3. Worktree 目錄建立在哪裡

```
../work-${TASK}-${i}
```

建立在**專案根目錄的父目錄下**（平行目錄，不在專案內部）。
例如：專案在 `~/workspace/project/`，worktree 建在 `~/workspace/work-demo-task-1/`。

設計原因：避免 worktree 被 `git status` 或 `.gitignore` 誤判，目錄結構更整齊。

### 實際結果

cascade-start.sh 是「一鍵展開三戰場」的腳本，每個 worktree 有獨立分支，
三個 Claude 實例可以同時在不同目錄開工，互不干擾。
腳本完成後還自動印出清理指令，一條龍設計。

---

## Step 2：執行 cascade-start.sh 建立 3 個 worktree

### 前置條件

```bash
git status   # 確認工作區乾淨
```

### 指令

```bash
bash code-中文/part7-workflows/cascade/cascade-start.sh demo-task
```

### 實際輸出

```
目前分支：main
任務名稱：demo-task
開始建立 3 個 worktree...

✓ Worktree 1 建立成功：../work-demo-task-1（分支：demo-task-worker-1-1718345678）
✓ Worktree 2 建立成功：../work-demo-task-2（分支：demo-task-worker-2-1718345678）
✓ Worktree 3 建立成功：../work-demo-task-3（分支：demo-task-worker-3-1718345678）

=== 啟動 Claude 實例指令 ===
Worker 1（安全性審查）：cd ../work-demo-task-1 && claude
Worker 2（程式碼品質）：cd ../work-demo-task-2 && claude
Worker 3（規格合規）：  cd ../work-demo-task-3 && claude

=== 完成後清理 worktree 指令 ===
git worktree remove ../work-demo-task-1
git worktree remove ../work-demo-task-2
git worktree remove ../work-demo-task-3
git worktree prune
```

### 實際結果

三個 Claude 實例各自在獨立目錄、獨立分支上工作。主線 main 完全不受影響。

---

## Step 3：理解三角色的權限設計

### 角色 × 模型 × 限制

| 角色 | Claude 模型 | 對應設定 | 為什麼這樣限制 |
|------|------------|---------|--------------|
| 架構師（Worker 1） | **Opus**（最貴）| Plan Mode（禁止寫程式）| 架構決策需要最強推理能力；Plan Mode 確保「只思考不動手」，防止跳過設計直接寫碼 |
| 實作者（Worker 2） | **Sonnet** | 完整讀寫 | 實作需要完整讀寫權限；Sonnet 在成本和能力間平衡，是日常主力 |
| 驗證者（Worker 3） | **Haiku**（最快）| 唯讀 + 執行測試 | 驗證只需讀取和跑測試；唯讀確保審查獨立性（不能改原始碼讓測試過）；Haiku 快且便宜 |

### 對應 7 階段工作流

```
架構師（Worker 1）→ S1 腦力激盪 + S3 規劃
實作者（Worker 2）→ S4 Sub-agent 探索 + S5 TDD 實作
驗證者（Worker 3）→ S6 審查
```

### 成本梯度設計原則

> Opus 做架構、Haiku 做驗證，是刻意的成本梯度設計。
> 最貴的思考力用在「哪些決策有長遠影響」，最快的速度用在「反覆跑測試」。
> 把 Opus 拿去跑測試，等於讓高薪工程師當測試機器人。

### 實際結果

三角色的設計同時解決了兩個問題：

1. **成本**：依任務性質選對應能力的模型，不過度消費
2. **品質**：角色分開後，各自的 context 乾淨，不因「什麼都做」而忘東忘西

---

## Step 4：清理 worktree

### 指令

```bash
git worktree remove ../work-demo-task-1
git worktree remove ../work-demo-task-2
git worktree remove ../work-demo-task-3
git worktree prune
git worktree list
```

### `git worktree prune` 的作用

清除已刪除 worktree 的殘留 metadata（`.git/worktrees/` 目錄下的記錄）。
只做 `remove` 不做 `prune`，git 的 worktree 記錄還在，可能影響下次建立同名 worktree。

### 實際結果

只剩主工作目錄。三個臨時戰場完全清除，不留痕跡。

---

## 本課重點

**為什麼用 Worktree 而不是單純開新 Branch？**

```
新 Branch：只是 git 指標切換，仍然共享同一個實體工作目錄
           → 三個 Claude 實例同時開啟，改了同一個目錄下的同一個檔案
           → 互相蓋掉彼此的工作

Worktree：每個 worktree 是獨立的實體資料夾
          → 三個 Claude 實例各自在不同目錄操作
          → 即使同時改「同名檔案」，改的是不同實體路徑的不同副本
          → 最後透過 git merge 整合，而不是靠「小心不要衝突」
```

| 問題 | 解決方式 |
|------|---------|
| AI 上下文變長後「忘東忘西」 | 每個角色獨立 session，context 乾淨 |
| 架構師不小心開始寫程式碼 | Plan Mode 鎖死，禁止 Write/Edit |
| 驗證者意外修改了原始碼 | 唯讀限制，確保審查獨立性 |
| 實作完成後 worktree 留著佔空間 | `git worktree prune` 一次清理 |

> **隱性教訓**：多 Agent + 多 Worktree 是「規模化 AI 協作」的基礎建設。
> 當任務大到一個 Claude 實例的 context 裝不下，就需要 cascade 模式——
> 不是讓 AI「更聰明」，而是讓「組織架構」替代「個人能力」。
