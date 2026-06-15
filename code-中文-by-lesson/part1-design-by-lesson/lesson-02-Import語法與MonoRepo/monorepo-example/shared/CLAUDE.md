# Shared 套件

## 用途

存放 `backend` 與 `frontend` 套件共用的 TypeScript 型別、工具函式與常數。

## 規則

- 這裡不放套件專屬邏輯 — 只放共用型別與工具
- 所有 export 都必須有 JSDoc 文件
- 破壞性變更需要升 major 版號

## 發佈

本套件透過 monorepo workspace 在內部發佈。
不要發佈到 npm。
