# Next.js 專案

## 設定

```bash
npm install
npm run dev    # 啟動開發伺服器（port 3000）
```

## 程式碼慣例

- 使用 TypeScript strict mode
- 優先使用 Server Components；僅在必要時使用 Client Components
- 頁面專屬的元件與頁面檔案放在一起（co-locate）

## 測試

```bash
npm test             # 單元測試（Jest + Testing Library）
npm run test:e2e     # 端對端測試（Playwright）
```

## 資料抓取

- 盡可能用 Server Components 抓取資料
- 需要快取的客戶端資料使用 React Query
- 凡是能在伺服器端抓取的資料，絕不在 Client Components 中抓取

## 環境變數

- 僅限伺服器的機密：不加 `NEXT_PUBLIC_` 前綴
- 客戶端可安全使用的設定：必須加 `NEXT_PUBLIC_` 前綴
