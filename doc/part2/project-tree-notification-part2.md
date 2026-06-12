# Project Tree — part2-hooks/notification

**生成日期：** 2026-06-12
**掃描目標：** C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part2-hooks\notification
**統計：** 0 個資料夾 / 1 個檔案 / 排除 0 個噪音目錄

```
notification/
└── notify.sh    # Notification hook：macOS 桌面通知 + 可選 Slack webhook，在 Claude 等待輸入時推送提醒
```

## 檔案功能摘要

**Hook 事件：** `Notification`（Claude 需要使用者輸入時觸發）

**雙軌通知策略：**

| 通道 | 機制 | 條件 |
|------|------|------|
| macOS 桌面 | `osascript -e 'display notification ...'` | 永遠嘗試（失敗靜默忽略） |
| Slack | `curl -X POST $SLACK_WEBHOOK_URL` | 僅在環境變數 `SLACK_WEBHOOK_URL` 設定時發送 |

**輸入欄位：** `.notification_type`（來自 Claude 的通知類型字串）
**設計原則：** 兩個通道皆不阻塞主流程（`exit 0`），失敗不影響 Claude 繼續運作
