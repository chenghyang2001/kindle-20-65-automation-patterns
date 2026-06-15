# 第 6 課演練記錄：動態上下文注入（!{command}）

> 對應文件：
>
> - `code-中文/part1-design/skills/dynamic-context/SKILL.md`

## 課程目標

理解為什麼靜態的 CLAUDE.md 和 Skill 無法追上專案的即時狀態，
學會用 `!{command}` 語法在 Skill 送給 AI 之前先執行 shell 指令並注入結果，
體驗讓 AI「睜開眼就看到最新狀態」而不是「依靠過時的文字描述猜測現狀」。

## 工作目錄

`code-中文/part1-design/demo/06-動態上下文注入/`

---

## Step 1：閱讀 dynamic-context/SKILL.md，理解兩個範例

### 閱讀任務

打開 `skills/dynamic-context/SKILL.md`，這個 Skill 有兩個範例（pr-summary 和 branch-analysis）。

閱讀 pr-summary 的 Skill 主體，填入：

| `!{...}` 指令 | 注入的內容 |
|-------------|---------|
| `!{gh pr diff}` | |
| `!{gh pr view --comments}` | |
| `!{gh pr diff --name-only}` | |
| `!{gh pr view}` | |

回答：

1. 這些 `!{...}` 什麼時候被執行？（在送給 AI 之前，還是 AI 讀到這行時？）

   答：

2. AI 最終看到的是什麼？（原始的 `!{gh pr diff}` 字串，還是指令的執行結果？）

   答：

3. 如果不用 `!{...}`，要讓 AI 知道 PR 的最新內容，你需要手動做什麼？

   答：

### 實際結果

| `` !`...` `` 指令 | 注入的內容 |
|----------------|---------|
| `` !`gh pr diff` `` | 當前 PR 的完整程式碼差異（+新增 / -刪除的行） |
| `` !`gh pr view --comments` `` | PR 上所有的 reviewer 留言和討論串 |
| `` !`gh pr diff --name-only` `` | 被變更的檔案名稱清單（不含 diff 內容） |
| `` !`gh pr view` `` | PR 總覽：標題、描述、作者、狀態、標籤 |

- Q1：在送給 AI 之前就執行。系統攔截 `` !`...` `` 語法 → 執行 shell 指令 → 替換結果 → AI 收到的已是替換完成的內容，完全不知道底層跑了任何指令
- Q2：AI 看到指令的執行結果（實際 diff 內容），不是原始 `` !`gh pr diff` `` 字串
- Q3：不用 `` !`...` `` 需要手動：自己跑 `gh pr diff` → 複製輸出 → 貼進對話；每次 PR 有新 commit 或新留言都要重複，忘了更新 AI 就分析舊版 diff

---

## Step 2：理解「即時感測器」的運作原理

### 概念說明

```
Skill 主體（靜態文字）：
  "PR diff：!{gh pr diff}"
          ↓
  （系統在送給 AI 之前攔截）
          ↓
  執行 shell 指令：gh pr diff
          ↓
  拿到當前 PR 的實際 diff 輸出
          ↓
  把 "!{gh pr diff}" 替換成 diff 輸出
          ↓
  AI 看到的是：
  "PR diff：
   --- a/src/auth.ts
   +++ b/src/auth.ts
   @@ -23,5 +23,8 @@..."
```

### 思考練習

1. 這個機制和 shell script 裡的「command substitution」`$(command)` 有什麼相似之處？

   答：

2. 列出三個在 CI/CD 工作流程中，`!{...}` 特別有用的注入場景：

   | 注入的指令 | 注入的內容 | 為什麼有用 |
   |-----------|-----------|-----------|
   | `!{git diff}` | | |
   | `!{npm test 2>&1}` | | |
   | `!{git log --oneline -10}` | | |

3. `!{...}` 和第五課的 `context.fork` 解決的是什麼層面的不同問題？

   | 技術 | 解決的問題 |
   |------|-----------|
   | `context.fork` | |
   | `!{command}` | |

### 實際結果

- Q1：`!{...}` 和 shell 的 `$(command)` 相似：兩者都是「執行指令，把輸出結果替換進原來的位置」。差別在 `$()` 是 shell 執行時替換，`!{...}` 是 Claude Code 在送給 AI 之前替換

| 注入的指令 | 注入的內容 | 為什麼有用 |
|-----------|-----------|-----------|
| `` !`git diff` `` | 未 commit 的程式碼變更（+/- 行） | AI 直接看到你改了什麼，不用複製貼上 |
| `` !`npm test 2>&1` `` | 最新測試結果，含失敗的錯誤訊息 | AI 拿到真實 error log，修復建議直接可用 |
| `` !`git log --oneline -10` `` | 最近 10 個 commit 的摘要 | AI 知道開發脈絡，分析 bug 時能追溯歷史 |

| 技術 | 解決的問題 |
|------|-----------|
| `context.fork` | **空間問題**：大量讀取污染主 context，用 fork 隔離讓子代理承擔，主對話保持清晰 |
| `` !{command} `` | **時間問題**：靜態文字是過時的知識，動態注入確保 AI 每次拿到當下最新即時狀態 |

---

## Step 3：實際用 !{command} 準備 PR 分析資料

### 指令（在專案根目錄執行）

```bash
cd c:/Users/user/workspace/kindle-20-65-automation-patterns

# 觀察最近的 git 狀態（這就是 !{...} 注入的效果）
git log --oneline -5
git diff --stat HEAD~1 HEAD
git status --short
```

### 模擬注入效果

想像以下 Skill 主體：

```
## 當前分支狀態

- 最近 5 個 commit：!`git log --oneline -5`
- 最近一次 commit 的變更：!`git diff --stat HEAD~1 HEAD`
- 未 commit 的變更：!`git status --short`
```

把你剛才執行的指令結果填入，模擬 AI 實際收到的 context：

```
## 當前分支狀態

- 最近 5 個 commit：
（填入 git log 結果）

- 最近一次 commit 的變更：
（填入 git diff --stat 結果）

- 未 commit 的變更：
（填入 git status 結果）
```

### 實際結果

```
## 當前分支狀態

- 最近 5 個 commit：
  de8bf4b 填入第 5 課演練答案：子代理隔離 Step 1-4 實際結果
  2e97f7f 填入第 4 課演練答案：安全 Front Matter 標籤 Step 1-4 實際結果
  0e6bd52 填入第 3 課演練答案：Skill 描述陷阱 Step 1-4 實際結果
  a9c4f9e 填入第 2 課演練答案：@import 語法與 MonoRepo 向上遍歷 Step 1-4
  b3f752b 填入第 1 課演練答案：三層設定架構 Step 1-4 實際結果

- 最近一次 commit 的變更：
  STEP-LOG.md（05-子代理隔離）
  1 file changed, 71 insertions(+), 5 deletions(-)

- 未 commit 的變更：
  （空，working tree 是乾淨的）
```

AI 從注入後的 context 能直接讀出：這個專案正在做 Part 1 互動演練，課 1-5 已完成，最新 commit 加了子代理隔離那課的答案，目前沒有未 commit 的變更。AI 不需要任何人工解釋。

---

## Step 4：設計自己的動態注入 Skill

### 情境

設計一個「每日站會報告」Skill，在每天早上自動給 AI 注入：

- 昨天 commit 了什麼
- 現在有哪些 open PR
- 測試是否通過

```yaml
---
name: daily-standup
description: >
  （填入：做什麼、什麼時候用）
context: fork
agent: Explore
---

## 今日工作狀態（自動注入）

- 昨天的 commit：!`___________`
- 目前的 open PR：!`___________`
- 最新測試結果：!`___________`
- 未完成的 TODO：!`___________`

## 任務

根據以上資訊，整理出：
1. 昨天完成了什麼
2. 今天需要處理什麼
3. 有沒有需要討論的 blocker
```

### 實際結果

```yaml
---
name: daily-standup
description: >
  產出每日站會報告，整理昨天完成了什麼、今天要做什麼、有沒有 blocker。
  適用於：早上站會前、每日進度更新、sprint check-in、
  幫我整理今天要做什麼、yesterday today blocker。
context: fork
agent: Explore
---

## 今日工作狀態（自動注入）

- 昨天的 commit：!`git log --oneline --since="24 hours ago"`
- 目前的 open PR：!`gh pr list --state open`
- 最新測試結果：!`npm test 2>&1 | tail -20`
- 未完成的 TODO：!`grep -rn "TODO|FIXME" src/ --include="*.ts"`

## 任務

根據以上資訊，整理出：
1. 昨天完成了什麼
2. 今天需要處理什麼
3. 有沒有需要討論的 blocker
```

四個指令的設計邏輯：`--since="24 hours ago"` 只看昨天；`--state open` 只看未關閉 PR；`2>&1 | tail -20` 合併 stderr 且截斷避免 token 爆炸；`grep -rn "TODO|FIXME"` 找出隱藏工作

---

## 本課重點

```
!{command} 的核心機制：

  Skill 主體 → 系統攔截 → 執行 shell 指令 → 替換結果 → 送給 AI
  AI 看到的是「熱騰騰的即時資料」，不知道底層跑了任何指令

解決的問題：
  靜態文字 = 過時的知識（CLAUDE.md 昨天寫的，今天已經不準）
  動態注入 = 即時狀態（每次觸發 Skill 都拿最新資料）

最常用的注入場景：
  !{git diff}           → PR / commit 的實際差異
  !{npm test 2>&1}      → 最新測試結果（含錯誤訊息）
  !{git log --oneline}  → 最近的 commit 歷史
  !{gh pr view}         → PR 當前狀態和留言
  !{git status}         → 未暫存 / 未 commit 的變更

組合技：!{command} + context.fork
  子代理拿到即時資料 → 分析 → 只把重點回傳主 context
  主對話永遠保持清晰 + 永遠拿到最新狀態
```
