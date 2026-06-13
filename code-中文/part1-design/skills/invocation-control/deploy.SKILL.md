---
name: deploy
description: 部署到生產環境
disable-model-invocation: true
---

# 部署程序

部署到生產環境。請依以下步驟執行：

## 部署前檢查

```bash
npm test
npm run build
git status
```

## 部署

```bash
git push origin main
```

## 驗證

- 造訪生產環境 URL 並確認運作正常
- 檢查錯誤 log
- 在 Slack 發佈完成通知
