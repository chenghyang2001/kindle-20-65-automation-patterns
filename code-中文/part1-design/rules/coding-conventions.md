---
paths:
  - "src/api/**/*.ts"
---

# API 開發規則

- 每個 endpoint 都必須包含輸入驗證
- 所有錯誤回應一律使用 `ApiError` 型別
- 一律加上 OpenAPI 註解

---

# 程式碼撰寫慣例（全域）

## Import 規則


- 只用 ES modules（不可用 `require()`）
- 非同步操作：使用 `async/await`（不可用 callback）


## 架構

- 所有 API 回應必須使用 `src/types/api.ts` 中的型別
- 資料庫存取一律透過 `src/repositories/`


## 命名慣例

- 檔案名稱：kebab-case
- 類別名稱：PascalCase
- 函式名稱：camelCase
- 常數：UPPER_SNAKE_CASE
