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
| S1 | 腦力激盪 | 只輸出純文字（定義 + 完成標準 + 範圍外），**禁止寫任何程式碼** |
| S2 | Worktree | `git worktree add` 建立隔離分支，所有工作都在這個 worktree 中進行 |
| S3 | 規劃 | 執行 `/confidence-check`，C1–C5 **≥ 90%（4/5 以上）才能進入下一階段** |
| S4 | Sub-agent | 把探索任務委派給 Explore agent（不自己看，讓 Haiku 看）|
| S5 | TDD | **先寫測試，再實作**（測試紅燈 → 實作 → 測試綠燈）|
| S6 | 審查 | 執行 `/review`，**解決所有**被提出的問題，不允許跳過 |
| S7 | 完成 | Commit → 移除 worktree → 執行 `/session-end` |

**為什麼 S1 禁止寫程式碼：** 腦力激盪階段邊想邊寫，會把「還沒釐清的需求」
變成「已存在的程式碼」，後來要推翻成本高。先確定「要做什麼」，才能決定「怎麼做」。

### 實際結果

7 個階段形成一個「防失敗護欄序列」：S1 防需求模糊、S2 防污染主分支、
S3 防動手前的低信心、S4 防主 context 被大量讀檔塞爆、
S5 防沒有安全網的實作、S6 防品質欠缺、S7 防忘記整理。

---

## Step 2：執行 7 階段工作流到 S3

### 模擬任務

> 「為購物車模組新增『套用折扣碼』功能」

### 指令

```
/dev-workflow add-discount-code
```

### 觀察每個階段的 AI 行為

**S1 腦力激盪**（AI 只輸出純文字）：

```
任務定義：在購物車結帳流程中，加入折扣碼欄位，
           套用後自動重算訂單總金額。

完成標準：
- 輸入有效折扣碼 → 金額更新，顯示折扣後的合計
- 輸入無效折扣碼 → 顯示「折扣碼無效」錯誤訊息
- 結帳後折扣碼儲存於訂單記錄

不在範圍內：
- 折扣碼的建立與管理介面（那是 admin 功能）
- 多個折扣碼同時套用
```

**S2 Worktree**（AI 建立隔離環境）：

```bash
git worktree add ../work-add-discount-code-$(date +%s) \
  -b feature/add-discount-code
```

隔離分支確保主分支乾淨，feature 做壞了直接刪 worktree，不污染 main。

**S3 規劃**（執行 `/confidence-check`）：

| 項目 | 結果 | 理由 |
|------|------|------|
| C1 重複實作 | PASS | `grep -r "discount\|coupon" src/` → 無命中 |
| C2 架構合規 | PASS | 折扣邏輯屬於業務層，放 `services/` 符合分層 |
| C3 官方文件 | PASS | 無需外部 API，純業務邏輯 |
| C4 OSS 參考 | PASS | 邏輯簡單，無需套件 |
| C5 根本原因 | PASS | 需求明確（結帳時套用一個折扣碼）|
| **總分** | **5 / 5** | ✅ 直接進入 S4 |

### 實際結果

S1→S2→S3 走完後，才有資格開始真正的程式碼工作。
前三個階段全是「阻力」，設計目的就是讓糟糕的想法在花工夫之前被擋下來。

---

## Step 3：認識 Checkpoint 的使用方式與限制

### 1. 開啟 rewind 選單

`Esc + Esc` 或輸入 `/rewind`

### 2. 哪些動作會被 Checkpoint 追蹤

| 動作 | 追蹤？ | 原因 |
|------|--------|------|
| Claude 用 **Write** 工具建立新檔案 | ✅ **是** | Checkpoint 追蹤 Write/Edit 工具 |
| Claude 在 bash 中執行 `npm install` | ❌ **否** | bash 磁碟變更不進快照 |
| Claude 用 **Edit** 工具修改一行程式碼 | ✅ **是** | Edit 工具有追蹤 |
| Claude 在 bash 中執行 `rm -rf build/` | ❌ **否** | bash 刪除不追蹤 |
| Claude 用 **Write** 工具覆蓋整個設定檔 | ✅ **是** | Write 工具有追蹤 |

**結論：** 只有 Claude Code 的 **Write / Edit 工具**會進快照。bash 指令對磁碟的任何操作都**不追蹤**。

### 3. 快照保留時間

**30 天**（session 結束後，截至 2026 年 2 月）

### 實際結果

Checkpoint 不是萬能備份，是「Claude Code 工具操作」的部分快照。
知道它的盲點（bash 指令），才不會在關鍵時刻誤信「Checkpoint 保護了我」。

---

## Step 4：雙重保護實作

### 情境

AI 即將執行以下危險操作：

```bash
npm install --save-dev @testing-library/react @testing-library/jest-dom
rm -rf node_modules && npm install
```

### 正確做法：先手動執行

```bash
git add -A
git stash     # 或 git stash push -m "before-npm-install"
# 然後再讓 AI 繼續
```

### 為什麼 Checkpoint 無法保護，Git Stash 可以

```
npm install / rm -rf → bash 指令對磁碟直接操作
→ 完全不在 Checkpoint 的快照範圍內
→ 出了問題，Checkpoint 還原只回到 Claude 上次 Edit 的狀態
→ bash 刪掉的東西不見了

Git Stash：
→ 把所有未 commit 的修改打包進 stash stack（git object）
→ 即使 bash 之後刪了檔案，`git stash pop` 能把改動還原
→ 因為 stash 是磁碟層的快照，不依賴 Claude Code 機制
```

| 保護工具 | 保護範圍 | 盲點 |
|---------|---------|------|
| **Checkpoint** (Esc+Esc) | Claude Write/Edit → 對話與程式碼編輯 | **bash 指令**（npm/rm/mv）完全不追蹤 |
| **Git Stash** | 所有未 commit 的磁碟變更 | 需要人工手動觸發 |

### 實際結果

雙重保護分工明確：

```
Claude 工具操作失控 → Checkpoint 救你
bash 指令造成磁碟損壞 → Git Stash 救你
兩者缺一不可。只用 Checkpoint 是假安全。
```

---

## 本課重點

```
Git Stash          負責保護：bash 指令造成的檔案異動（npm/rm/mv）
Checkpoint (Esc+Esc) 負責保護：Claude 用 Write/Edit 工具的對話與文字編輯

兩者缺一不可。只用 Checkpoint 是假安全。
```

| Checkpoint 動作 | 用途 |
|---------------|------|
| Restore code and conversation | 完整回到該時間點（最常用）|
| Restore conversation only | 保留程式碼，只回退對話（少用）|
| Restore code only | 只還原檔案（不回退對話）|
| Summarize from here | 壓縮舊對話釋放 context（長 debug session 後使用）|

> **隱性教訓**：7 階段工作流的真正價值不在於「有 7 個步驟」，
> 而在於每個步驟的**前置條件**（S3 要 ≥ 90%、S5 要先寫測試）
> 讓後面的步驟在有保護的前提下才開始。
> Checkpoint + Git Stash 也是同樣邏輯：多一層保護，少一次事故。
