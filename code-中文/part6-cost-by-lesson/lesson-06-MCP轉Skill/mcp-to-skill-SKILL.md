---
name: fetch-docs
description: >
  抓取並摘要某個函式庫或框架的官方文件。
  當你需要最新的 API 文件或使用範例時使用。
allowed-tools: Bash(curl *), Bash(npx *)
---

# 抓取文件

抓取並摘要使用者要求的函式庫或框架文件。

## 步驟

1. 找出該函式庫的官方文件 URL
2. 用 curl 或 npx 抓取相關頁面
3. 萃取並摘要關鍵的 API 或使用方式資訊
4. 以結構化格式呈現摘要

## 範例

```bash
# 抓取 React hooks 參考文件
curl -s https://react.dev/reference/react/useState | \
  npx @mozilla/readability-cli -
```

## 注意事項

- 優先抓取官方文件，而非依賴訓練知識
- 經常參考的文件，可在 `.claude/docs/` 本地快取內容
- 這個 skill 取代了「只為簡單文件抓取而架 MCP server」的需求
