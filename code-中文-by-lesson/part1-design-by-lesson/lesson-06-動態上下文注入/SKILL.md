---
name: pr-summary
description: 摘要 Pull Request 的內容
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

## Pull Request 資訊


- PR diff：!`gh pr diff`
- PR 留言：!`gh pr view --comments`
- 變更的檔案：!`gh pr diff --name-only`
- PR 總覽：!`gh pr view`

## 任務

從以下角度摘要這個 Pull Request：

1. 變更的目的與背景
2. 主要變更（逐檔說明）
3. 審查時需留意的重點
4. 潛在風險

---

# branch-analysis Skill 範例

另一個動態 context 注入的範例（用於分支分析）：

```yaml
name: branch-analysis
description: 分析當前分支的變更
```

## 當前分支資訊（執行時注入）

- 分支：!`git branch --show-current`
- 與 base 分支的 diff：!`git diff origin/main --stat`
- Commits：!`git log origin/main..HEAD --oneline`
