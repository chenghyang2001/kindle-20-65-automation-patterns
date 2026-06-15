# Backend 套件

## 技術堆疊

Node.js + Express + TypeScript + PostgreSQL

## 資料庫

一律透過 `src/repositories/` 存取資料庫。不允許在 repositories 之外直接執行查詢。

## API 開發

所有 endpoint 都必須包含：

- 使用 `src/types/api.ts` 型別做輸入驗證
- 錯誤回應使用 `ApiError`
- OpenAPI JSDoc 註解

## 本機執行

```bash
npm run dev       # 啟動開發伺服器（port 3000）
npm run db:seed   # 填入種子資料
npm test          # 單元 + 整合測試
```
