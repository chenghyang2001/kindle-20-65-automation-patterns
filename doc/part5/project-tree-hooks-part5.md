# Project Tree — hooks (part5-security)

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part5-security\hooks`
- 統計：0 個子資料夾 / 2 個檔案 / 排除 0 個噪音目錄

```
hooks/                     # Part 5 資安：PreToolUse 攔截型 hook（用 exit 2 + decision:block 擋危險操作）
├── dev-server-blocker.sh  # 攔 Bash 開發伺服器指令（npm/yarn/pnpm dev、vite、runserver…），不在 tmux session 內就 block
└── secret-scanner.sh      # 攔 Write/Edit 內容，正則比對 AWS/GitHub/Anthropic/OpenAI/Google/Stripe/私鑰，命中即 block（bash 3.2 相容寫法）
```

## 結構特徵

- 兩支都是 PreToolUse hook，用 `exit 2` + `{"decision":"block","reason":...}` 阻止工具執行——這是 Claude Code hook 擋下動作的標準協定。
- `secret-scanner.sh` 刻意用平行陣列（NAMES/PATTERNS）而非關聯陣列，以相容 macOS 預設的 bash 3.2，是跨平台防禦的實例。
- `dev-server-blocker.sh` 用 tmux 在場與否當判斷：長駐型指令必須跑在可被監控/中止的 session，避免 Claude 卡在前景。

```
