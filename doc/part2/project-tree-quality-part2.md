# Project Tree — part2-hooks/quality

**生成日期：** 2026-06-12
**掃描目標：** C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part2-hooks\quality
**統計：** 0 個資料夾 / 3 個檔案 / 排除 0 個噪音目錄

```
quality/
├── auto-format.sh           # PostToolUse hook：檔案存檔後依副檔名自動執行對應 formatter
├── prompt-hook-examples.json  # settings.json 範本：示範 Stop / UserPromptSubmit / PostToolUse 三種 prompt-type hook
└── quality-gate.sh          # Stop hook：有未提交變更或殘留 TODO 標記時封鎖 session 結束
```

## 各檔案功能摘要

### `auto-format.sh` — PostToolUse

讀取 `.tool_input.file_path`，依副檔名分派 formatter：

| 副檔名 | 工具 |
|--------|------|
| js / jsx / ts / tsx / css / json | `npx prettier --write` |
| go | `gofmt -w` |
| py | `black` |
| md | `npx markdownlint-cli2 --fix` |

失敗靜默忽略（`2>/dev/null`），不阻塞主流程。

---

### `prompt-hook-examples.json` — Hook 設定範本

示範三種 `type: "prompt"` hook 的使用場景：

| Hook 事件 | 用途 | 模型 |
|----------|------|------|
| `Stop` | 檢查 last_assistant_message 是否有錯誤 / 未完成工作 | 預設 |
| `UserPromptSubmit` | 偵測使用者輸入中是否含 API key / 密碼等敏感資訊 | 預設 |
| `PostToolUse` (matcher: `Edit\|Write`) | 掃描 .ts/.js 檔案是否有 SQL injection / XSS / 硬編碼憑證 | **claude-haiku-4-5**（省成本） |

---

### `quality-gate.sh` — Stop hook

封鎖 session 結束的兩個條件：

1. `git diff` 或 `git diff --cached` 有未提交的變更
2. `src/` 下存在 `<!-- TODO -->` 標記（`grep -r` 計數）

設有 `stop_hook_active` 守衛避免無限迴圈（Stop hook 再觸發 Stop hook）。
