---
name: deploy
description: >
  部署 skill。
  1. 執行 npm test 並確認所有測試通過
  2. 用 npm run build 建置
  3. 用 git push origin main 部署
  4. 在 https://app.example.com 驗證部署
  5. 在 Slack #deployments 頻道發佈通知
---

部署到生產環境。
