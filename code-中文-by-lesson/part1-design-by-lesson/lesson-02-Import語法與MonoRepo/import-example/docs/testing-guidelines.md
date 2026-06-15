# 測試準則

## 測試結構

所有測試放在 `tests/` 之下，鏡像對應原始碼目錄結構。

## 覆蓋率要求

- 所有模組至少 80% 行覆蓋率
- 關鍵路徑（auth、payment）要求 100% 覆蓋率

## 測試類型

- **單元測試**：純函式、獨立邏輯
- **整合測試**：API endpoint、資料庫互動
- **E2E 測試**：完整使用者流程（Playwright）

## 執行測試

```bash
npm test              # 單元 + 整合測試
npm run test:e2e      # 端對端測試
npm run test:coverage # 含覆蓋率報告
```

## 命名慣例

測試檔案：單元測試用 `*.test.ts`，整合測試用 `*.spec.ts`。

## Mock

外部依賴使用 `vi.mock()`。絕不 mock 內部模組。
