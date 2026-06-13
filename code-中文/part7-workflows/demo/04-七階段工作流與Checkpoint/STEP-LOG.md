# 第 4 課演練記錄：七階段工作流 + Checkpoint 安全網

> 對應文件：
>
>
> - `code-中文/part7-workflows/skills/dev-workflow/SKILL.md`
> - `code-中文/part7-workflows/docs/checkpointing-guide.md`
> - `code-中文/part7-workflows/seven-stage-workflow.dot`（流程圖）

## 課程目標

完整走一遍 7 階段工作流的前 4 階段，
理解 Checkpoint 的追蹤範圍限制（bash 指令不追蹤），
建立「Git + Checkpoint 雙重保護」的正確心智模型。

## 工作目錄

`code-中文/part7-workflows/demo/04-七階段工作流與Checkpoint/`

---

## Step 1：安裝 dev-workflow Skill，認識 7 個階段

### 指令

```bash
cp -r code-中文/part7-workflows/skills/dev-workflow \
      ~/.claude/skills/dev-workflow
```

### 演練任務

對照 `dev-workflow/SKILL.md`，填入每個階段的核心限制：

| 階段 | 名稱 | 核心限制或關鍵動作 |
|------|------|------------------|
| S1 | 腦力激盪 | |
| S2 | Worktree | |
| S3 | 規劃 | |
| S4 | Sub-agent | |
| S5 | TDD | |
| S6 | 審查 | |
| S7 | 完成 | |

### 實際結果

（演練時填入）

---

## Step 2：執行 7 階段工作流到 S3

### 模擬任務

> 「為購物車模組新增『套用折扣碼』功能」

### 指令

```
/dev-workflow add-discount-code
```

### 觀察每個階段的 AI 行為

**S1 腦力激盪**（AI 應輸出純文字，禁止修改任何程式碼）：

```
（填入 AI 的定義與完成標準）
```

**S2 Worktree**（AI 應建立隔離環境）：

```bash
git worktree add ../work-add-discount-code-$(date +%s) -b feature/add-discount-code
```

**S3 規劃**（需先執行 /confidence-check，≥90% 才能繼續）：

```
（填入 C1–C5 的評分結果）
```

### 實際結果

（演練時填入）

---

## Step 3：認識 Checkpoint 的使用方式與限制

### 閱讀任務

打開 `docs/checkpointing-guide.md`，回答：

1. 開啟 Checkpoint rewind 選單的鍵盤操作是什麼？

   答：

2. 以下哪些動作會被 Checkpoint 追蹤？（打 ✓）

   - [ ] Claude 用 Write 工具建立一個新檔案
   - [ ] Claude 在 bash 中執行 `npm install`
   - [ ] Claude 用 Edit 工具修改一行程式碼
   - [ ] Claude 在 bash 中執行 `rm -rf build/`
   - [ ] Claude 用 Write 工具覆蓋整個設定檔

3. 快照在 session 結束後保留幾天？

   答：

### 實際結果

（演練時填入）

---

## Step 4：雙重保護實作

### 情境

AI 即將執行以下危險操作：

```bash
npm install --save-dev @testing-library/react @testing-library/jest-dom
rm -rf node_modules && npm install
```

### 演練任務

在讓 AI 執行之前，你應該先做什麼？

```bash
# 在終端機手動執行：
git add -A
git stash
# 然後再讓 AI 繼續
```

解釋為什麼 Checkpoint 無法保護這個情境，而 Git Stash 可以：

（填入說明）

### 實際結果

（演練時填入）

---

## 本課重點

```
Git Stash          負責保護：bash 指令造成的檔案異動（npm/rm/mv）
Checkpoint (Esc+Esc) 負責保護：Claude 用 Write/Edit 工具的對話與文字編輯

兩者缺一不可。只用 Checkpoint 是假安全。
```

| Checkpoint 動作 | 用途 |
|---------------|------|
| Restore code and conversation | 完整回到該時間點（最常用） |
| Restore conversation only | 保留程式碼，只回退對話（少用） |
| Restore code only | 只還原檔案（不回退對話） |
| Summarize from here | 壓縮舊對話釋放 context（長 debug session 後使用） |
