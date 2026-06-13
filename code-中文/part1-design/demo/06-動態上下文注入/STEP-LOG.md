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

（演練時填入）

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

（演練時填入）

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

（演練時填入）

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

（演練時填入）

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
