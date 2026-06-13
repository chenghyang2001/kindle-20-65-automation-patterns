---
name: daily-standup
description: >
  產出每日站會報告，整理昨天完成了什麼、今天要做什麼、有沒有 blocker。
  適用於：早上站會前、每日進度更新、sprint check-in、
  幫我整理今天要做什麼、yesterday today blocker、今天站會、
  昨天做了什麼、今天計畫、有沒有卡住的地方。
  不觸發：週報（用 rd2-weekly-summary）、每日閉環（用 aihcr daily）。
context: fork
agent: Explore
---

# 每日站會報告

> 基於 kindle-20-65-automation-patterns Part 1 第 6 課設計

## 今日工作狀態（自動注入）

- 昨天的 commit：!`git log --oneline --since="24 hours ago"`
- 目前的 open PR：!`gh pr list --state open 2>/dev/null || echo "（無 GitHub remote 或未安裝 gh）"`
- 最新測試結果：!`npm test 2>&1 | tail -20 2>/dev/null || echo "（無 package.json 或測試未設定）"`
- 未完成的 TODO：!`grep -rn "TODO\|FIXME" src/ --include="*.ts" --include="*.py" --include="*.js" 2>/dev/null | head -20 || echo "（無 src/ 目錄或無 TODO）"`
- 目前分支：!`git branch --show-current`
- 未 commit 的變更：!`git status --short`

## 任務

根據以上自動注入的即時資訊，整理出標準三欄站會報告：

### Yesterday（昨天完成了什麼）

根據 git log 列出昨天的 commit，整理成人類可讀的完成事項（不要直接貼 commit hash）。

### Today（今天要做什麼）

根據 open PR、未完成 TODO、未 commit 變更，推斷今天最優先要處理的 2-3 件事。

### Blockers（有沒有卡住的地方）

根據失敗的測試、長期未關閉的 PR、大量 TODO 集中在某個模組，判斷是否有需要討論的 blocker。

## 輸出格式

```
## 每日站會 — YYYY-MM-DD

### ✅ Yesterday
- [完成事項1]
- [完成事項2]

### 🔜 Today
- [優先事項1]
- [優先事項2]
- [優先事項3]

### 🚧 Blockers
- [blocker] 或「無」
```

## 紀律

- `context: fork` 確保注入的 log/diff 輸出不污染主對話
- 每個 `!{...}` 指令都有 `2>/dev/null || echo` fallback，避免 gh/npm 未安裝時整個 Skill 報錯
- 輸出是整理過的摘要，不是原始 log 貼上
