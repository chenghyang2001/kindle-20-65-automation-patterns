# 第 3 課演練記錄：自動產生 Commit 訊息

> 對應文件：`code-中文/part4-cicd/scripts/auto-commit.sh`

## 課程目標

學會用 `claude -p` 分析 `git diff --staged`，自動產生符合 Conventional Commits 規範的 commit 訊息，
理解最小化工具白名單的設計原則（只給 git status / diff / commit，不給 rm / push）。

## 工作目錄

`code-中文/part4-cicd/demo/03-自動產生Commit訊息/`

---

## Step 1：閱讀 auto-commit.sh，理解設計邏輯

### 閱讀任務

打開 `scripts/auto-commit.sh`，回答：

1. 腳本在什麼條件下才會呼叫 Claude？（看第 5 行的 if 條件）

   答：

2. `--allowedTools` 白名單裡有三個指令，分別是：

   | 工具 | 用途 |
   |------|------|
   | `Bash(git status *)` | |
   | `Bash(git diff *)` | |
   | `Bash(git commit *)` | |

3. 為什麼白名單沒有 `Bash(git push *)`？

   答：

4. `--max-turns 3` 的設計邏輯是什麼？commit 操作需要幾個步驟？

   答：

### 實際結果

（演練時填入）

---

## Step 2：認識 Conventional Commits 格式

### 格式說明

```
<type>(<scope>): <description>

type 類型：
  feat     → 新功能
  fix      → bug 修復
  docs     → 文件更新
  refactor → 重構（不影響功能）
  test     → 新增/修改測試
  chore    → 其他雜項（CI 設定、工具更新）
```

### 練習

以下是三個 git diff，猜測 AI 會產生什麼 commit 訊息：

**Diff 1**：新增了一個 `--max-turns` 引數到 basic-ci.sh


```
答：
```


**Diff 2**：修復了 json-output-patterns.sh 中 jq 路徑錯誤

```
答：
```


**Diff 3**：更新 README.md，加入 Part 4 的說明

```
答：
```

### 實際結果

（演練時填入）

---

## Step 3：實際執行 auto-commit.sh（模擬）

### 準備一個暫存變更

先對任意文字檔做一個小修改並暫存：

```bash
cd c:/Users/user/workspace/kindle-20-65-automation-patterns

# 在 demo 目錄建一個測試檔案
echo "# 測試 auto-commit" > code-中文/part4-cicd/demo/03-自動產生Commit訊息/test.md
git add code-中文/part4-cicd/demo/03-自動產生Commit訊息/test.md

# 確認已暫存
git diff --cached --stat
```

### 執行 auto-commit.sh（乾跑模式 — 只看 AI 建議的訊息，不真正 commit）

修改版（不真正 commit，只顯示 AI 建議）：

```bash
git diff --cached | claude -p \
  "Based on this git diff, suggest a Conventional Commits message. Only output the commit message, nothing else." \
  --max-turns 2
```

### 觀察

1. AI 建議的 commit 訊息格式符合 Conventional Commits 嗎？
2. 說明夠精確嗎？（描述了「做了什麼」而不是「改了哪些字」）

### 清理暫存

```bash
git restore --staged code-中文/part4-cicd/demo/03-自動產生Commit訊息/test.md
rm code-中文/part4-cicd/demo/03-自動產生Commit訊息/test.md
```

### 實際結果

（演練時填入）

---

## Step 4：思考安全邊界

### 討論問題

1. auto-commit.sh 只給了 `git commit`，沒有給 `git push`。如果要加 push，你會擔心什麼？

   答：

2. 如果 AI 產生的 commit 訊息是「Fixed stuff」，這表示什麼問題？要怎麼避免？

   提示：看腳本的 prompt 部分。

   答：

3. 這個腳本用了 `set -e`，代表什麼？

   答：

### 實際結果

（演練時填入）

---

## 本課重點

```
Auto Commit 的安全設計：
  白名單只給 status + diff + commit（不給 push / rm）
  --max-turns 3 夠完成「看狀態 → 看差異 → commit」三步驟
  Conventional Commits 格式讓 Git 歷史變成可機器讀取的資料

Prompt 管理原則：
  把 prompt 規則（如「一定要用 fix / feat / docs 前綴」）
  存成獨立 .txt 檔案並納入 git 版本控制
  → 審查規則的演進歷史一目瞭然

最小權限原則（Principle of Least Privilege）：
  AI 只需要看差異 + commit → 只給這兩個
  任何超出範圍的工具呼叫 → 系統直接拒絕
```
