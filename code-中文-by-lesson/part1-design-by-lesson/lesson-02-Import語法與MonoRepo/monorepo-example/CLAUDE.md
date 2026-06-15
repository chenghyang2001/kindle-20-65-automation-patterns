# Monorepo：my-project

## 共用規則

- Commit 訊息：Conventional Commits 格式
- 分支命名：`feat/`、`fix/`、`chore/` 前綴
- 每個 PR 只做一個功能

## 建置指令

- 建置所有套件：`npm run build --workspaces`
- 建置特定套件：`cd packages/[name] && npm run build`

## 限制

- 不可直接在 `packages/` 底下建立檔案 — 一律建在某個套件內
- 不可直接在根目錄的 `package.json` 加入依賴
