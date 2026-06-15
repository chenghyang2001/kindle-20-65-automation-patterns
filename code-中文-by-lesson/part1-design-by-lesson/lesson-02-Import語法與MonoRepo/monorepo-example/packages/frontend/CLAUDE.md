# Frontend 套件

## 技術堆疊

React + TypeScript + Vite + Tailwind CSS

## 元件準則

- 使用函式型元件搭配 hooks
- 測試與元件放在一起（co-locate）
- 優先用 Tailwind utility class，而非自訂 CSS

## 狀態管理

伺服器狀態用 React Query。本地 UI 狀態用 Zustand。

## 本機執行

```bash
npm run dev     # 啟動開發伺服器（port 5173）
npm test        # 單元測試
npm run build   # 生產環境建置
```
