# Project Tree — part2-hooks/settings-examples

**生成日期：** 2026-06-12
**掃描目標：** C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part2-hooks\settings-examples
**統計：** 0 個資料夾 / 2 個檔案 / 排除 0 個噪音目錄

```
settings-examples/
├── debug-hook.sh        # 開發除錯工具：將所有 hook 事件的完整 JSON 輸入追加記錄到 /tmp/claude-hook-debug.log
└── hooks-overview.json  # settings.json 片段：PostToolUse + matcher "Edit|Write" 觸發 prettier 的最小設定範例
```

## 各檔案功能摘要

### `debug-hook.sh` — 開發期除錯用

```bash
# 記錄格式
=== 2026-06-12 14:00:00 ===
EVENT: PostToolUse
INPUT: { ... 完整 JSON ... }
```

**用途：** 開發新 hook 時掛入任意 hook 事件，觀察 Claude 實際傳入的 JSON 結構。
**注意：** 僅限本機開發使用，不應進入 CI 或生產環境（日誌無限增長）。

---

### `hooks-overview.json` — settings.json 最小範例

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{ "type": "command", "command": "npx prettier --write ..." }]
    }]
  }
}
```

展示 settings.json 的三層結構：`hooks 物件` → `事件名稱陣列` → `{matcher, hooks[]}` 設定單元。
`matcher` 支援正則，`"Edit|Write"` 表示兩種工具都觸發，是最常用的 PostToolUse 過濾模式。
