---
name: deploy
description: >
  部署到生產環境。必須透過 /deploy 指令顯式呼叫。
  適用於：生產環境發布、緊急部署。
disable-model-invocation: true
---

# 部署程序

部署到生產環境。

## 1. 部署前檢查

```bash
npm test
npm run build
git status
```

確認所有測試通過、建置成功，且沒有未 commit 的變更。

## 2. 部署

```bash
git push origin main
```

## 3. 驗證

- 造訪 <https://app.example.com> 並確認頁面可正常載入
- 確認錯誤 log 中沒有錯誤

## 4. Slack 通知

在 `#deployments` 頻道發佈部署完成通知。
