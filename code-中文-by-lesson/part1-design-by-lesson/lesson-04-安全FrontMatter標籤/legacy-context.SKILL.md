---
name: legacy-system-context
description: 舊系統（legacy system）的背景與限制。處理與此系統相關的任務時使用。
user-invocable: false
---

# 舊版付款系統背景

本系統建於 2008 年。有以下限制：

- Session 管理是檔案式的（沒有資料庫）
- 字元編碼是 Shift-JIS
- 必須相容 PHP 5.6（不可使用現代 PHP 功能）
- 外部 API 整合只能透過 XML-RPC

## 重要注意事項

- `payment_processor.php` 不可修改（正在接受 PCI DSS 稽核）
- 不可直接寫入 `session/` 目錄底下
- Log 必須寫到 `logs/legacy/`

## 常見問題

- 亂碼：所有輸入/輸出一律經過 `mb_convert_encoding()`
- Session 過期：已設定 30 分鐘 timeout
