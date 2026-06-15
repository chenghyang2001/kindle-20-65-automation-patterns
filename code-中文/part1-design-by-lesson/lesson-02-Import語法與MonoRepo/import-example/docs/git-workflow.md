# Git 工作流

## 分支命名

- `feat/` — 新功能
- `fix/` — bug 修復
- `chore/` — 維護、依賴套件更新

## Commit 訊息

遵循 Conventional Commits 格式：

```
feat(auth): add JWT refresh token support
fix(api): handle null response in user endpoint
chore(deps): update express to 4.18.2
```

## Pull Request

- 每個功能或修復一個 PR
- 連結到相關的 issue
- 合併前至少需要一位 reviewer 核准

## 合併策略

功能分支使用 squash merge。main 上保留 commit 歷史。
