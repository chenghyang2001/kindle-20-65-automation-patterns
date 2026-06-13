---
name: take-screenshot
description: "對指定 URL 截圖。參數：URL"
---

# 截圖

參數：$ARGUMENTS

## 步驟

執行以下腳本進行截圖：

```bash
npx playwright screenshot --browser chromium \
  "$ARGUMENTS" \
  "screenshots/$(date +%Y%m%d-%H%M%S).png"
```

截圖完成後，回報檔案路徑。
