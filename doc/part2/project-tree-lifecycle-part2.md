# Project Tree — part2-hooks/lifecycle

**生成日期：** 2026-06-12
**掃描目標：** C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part2-hooks\lifecycle
**統計：** 0 個資料夾 / 3 個檔案 / 排除 0 個噪音目錄

```
lifecycle/
├── audit-config.sh          # PreToolUse hook：記錄所有設定變更到 config-audit.log，並封鎖外部對 settings.json 的修改
├── restore-context.sh       # UserPromptSubmit hook：壓縮後自動注入 git 分支 / 近期 commits / 未提交變更 / 上次 session 狀態
└── save-session-state.sh    # PreCompact hook：將當下 git 狀態（branch / 改動 / commits / diff stat）快照存入 .claude/session-state.md
```

## 各檔案功能摘要

| 檔案 | Hook 事件 | 核心功能 |
|------|----------|---------|
| `audit-config.sh` | PreToolUse | stdin JSON → `.source` + `.file_path` → 追加審計日誌；偵測 project_settings 來源改寫 settings.json 時回傳 `{"decision":"block"}` |
| `restore-context.sh` | UserPromptSubmit | `git branch` + `git log -3` + `git status` → stdout 注入；若存在 `.claude/session-state.md` 則一併附加 |
| `save-session-state.sh` | PreCompact / Stop | `jq` 檢查 → `git` 資訊 → heredoc 寫入 `.claude/session-state.md`；寫失敗 exit 1 防止靜默遺失 |

## 設計要點

- 三支 Script 形成「儲存 → 注入 → 稽核」完整 lifecycle 閉環
- `restore-context.sh` 是本專案 UserPromptSubmit hook 的原型（你在用的那版）
- `audit-config.sh` 示範 `decision: block` 回傳格式，是 PreToolUse 封鎖模式的標準範本
