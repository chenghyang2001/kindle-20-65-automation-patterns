# Project Tree — part2-hooks/platform

**生成日期：** 2026-06-12
**掃描目標：** C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part2-hooks\platform
**統計：** 0 個資料夾 / 1 個檔案 / 排除 0 個噪音目錄

```
platform/
└── check-command.mjs    # PreToolUse hook（Node.js ESM）：攔截 Bash tool 呼叫，封鎖危險指令模式後 exit 2
```

## 檔案功能摘要

**Hook 事件：** `PreToolUse`
**執行環境：** Node.js（`#!/usr/bin/env node`，ESM 模組 `.mjs`）

**封鎖清單：**

| 模式 | 危險原因 |
|------|---------|
| `rm -rf` | 遞迴刪除，無法還原 |
| `git push --force` | 覆蓋遠端歷史 |
| `DROP TABLE` | 破壞性 SQL |

**實作要點：**

- stdin 以 `readline` 非同步讀取 → `JSON.parse()` 解析
- 只在 `tool_name === 'Bash'` 時檢查（其他工具直接放行）
- 命中封鎖模式 → `process.exit(2)`（Claude 解讀為「封鎖此工具呼叫」）
- 相較於 Shell 版本，Node.js 的優勢：正則表達式更強、可引用 npm 套件、跨平台無 `jq` 依賴
