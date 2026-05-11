# 第2章 Hooks Automation — 掌控 Claude Code 的 17 個 Hooks

> Claude Code in Production | Yosuke Morikawa | Patterns 11–27

---

## 章節概覽

Hooks 是 Claude Code 的自動化引擎。在 AI 每次工具呼叫前後插入 shell 指令，
實現**品質守門、安全防護、狀態保存、通知推送**，完全不需修改 AI 本身。

---

## 核心模式

### Hook 生命週期（17 個觸發點）

```
PreToolUse    → 工具呼叫前攔截（可 block/modify）
PostToolUse   → 工具呼叫後執行（auto-format、log）
Stop          → AI 停止前執行（quality gate、checklist）
SubagentStop  → 子代理停止前執行
PreCompact    → 壓縮前執行（儲存狀態）
Notification  → AI 需要使用者輸入時通知
```

---

### Pattern 11–13：安全防護 Hooks

#### PreToolUse：封鎖危險指令

```bash
# block-dangerous.sh
PATTERNS=("rm -rf /" "git push --force" "DROP TABLE" "chmod -R 777")

for pattern in "${PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qF "$pattern"; then
    echo "Blocked: '$pattern' is prohibited" >&2
    exit 2   # exit 2 = block this tool call
  fi
done
```

#### PreToolUse：Secret 洩漏偵測

```bash
# secret-scanner.sh（Write/Edit hook）
PATTERNS=("AKIA[0-9A-Z]{16}" "sk-ant-[A-Za-z0-9\-]{95}" "AIza[0-9A-Za-z\-_]{35}")

for pattern in "${PATTERNS[@]}"; do
  if echo "$CONTENT" | grep -qE "$pattern"; then
    echo '{"decision":"block","reason":"Secret detected"}' >&2
    exit 2
  fi
done
```

---

### Pattern 14–17：品質控制 Hooks

#### PostToolUse：自動格式化

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{"type": "command", "command": "npx prettier --write \"$(jq -r '.tool_input.file_path')\""}]
    }]
  }
}
```

#### Stop Hook：品質守門（防自循環）

```bash
# quality-gate.sh
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then exit 0; fi  # 防無限循環

ISSUES=()
if [ -n "$(git diff --name-only)" ]; then ISSUES+=("Uncommitted changes"); fi
TODO_COUNT=$(grep -r "<!-- TODO -->" src/ 2>/dev/null | wc -l)
if [ "$TODO_COUNT" -gt 0 ]; then ISSUES+=("${TODO_COUNT} TODOs remaining"); fi

if [ ${#ISSUES[@]} -gt 0 ]; then
  jq -n --arg reason "$(printf '%s\n' "${ISSUES[@]}")" \
    '{"decision": "block", "reason": $reason}'
fi
```

---

### Pattern 18–20：狀態保存 Hooks

#### PreCompact：Session 壓縮前自動儲存

```bash
# save-session-state.sh
cat > ".claude/session-state.md" << EOF
# Session State (saved: $(date '+%Y-%m-%d %H:%M'))
## Branch: $(git branch --show-current)
## Uncommitted: $(git diff --name-only)
## [staged]: $(git diff --name-only --cached | sed 's/^/[staged] /')
## Recent Commits: $(git log --oneline -5)
EOF
```

#### PostToolUse：自動 Audit Log

```bash
# audit-config.sh — 記錄所有設定檔變更
if echo "$TOOL_INPUT" | grep -q "settings.json\|CLAUDE.md"; then
  echo "[$(date)] $TOOL_NAME: $(echo "$TOOL_INPUT" | jq -r '.file_path')" >> .claude/audit.log
fi
```

---

### Pattern 21–23：通知 Hooks

#### Notification：AI 需要輸入時提醒

```bash
# notify.sh
osascript -e 'display notification "Claude Code needs input" with title "Claude Code"'

if [ -n "$SLACK_WEBHOOK_URL" ]; then
  curl -s -X POST "$SLACK_WEBHOOK_URL" \
    -H 'Content-type: application/json' \
    --data '{"text": "Claude Code is waiting for your input"}'
fi
```

---

### Pattern 24–27：跨平台 & 除錯

#### PreToolUse：平台偵測

```js
// check-command.mjs（跨平台指令前置檢查）
const platform = process.platform;
const command = input.tool_input?.command || '';

if (platform === 'win32' && command.startsWith('rm ')) {
  // 建議換成 del / rmdir
  process.stderr.write(JSON.stringify({decision:'block', reason:'Use del on Windows'}));
  process.exit(2);
}
```

#### Debug Hook

```bash
# debug-hook.sh（輸出所有 hook 輸入，開發時用）
cat | tee -a /tmp/claude-hook-debug.log >&2
exit 0
```

---

## hooks-overview.json 完整設定範本

```json
{
  "hooks": {
    "PreToolUse": [
      {"matcher": "Bash", "hooks": [{"type":"command","command":"bash .claude/hooks/block-dangerous.sh"}]},
      {"matcher": "Write|Edit", "hooks": [{"type":"command","command":"bash .claude/hooks/secret-scanner.sh"}]}
    ],
    "PostToolUse": [
      {"matcher": "Edit|Write", "hooks": [{"type":"command","command":"bash .claude/hooks/auto-format.sh"}]}
    ],
    "Stop": [
      {"matcher": ".*", "hooks": [{"type":"command","command":"bash .claude/hooks/quality-gate.sh"}]}
    ],
    "PreCompact": [
      {"matcher": "auto", "hooks": [{"type":"command","command":"bash .claude/hooks/save-session-state.sh"}]}
    ]
  }
}
```

---

## 如何套用到我的工作流

| 需求 | Hook 類型 | 實作 |
|------|-----------|------|
| 防止 AI 誤 push/刪檔 | PreToolUse (Bash) | `block-dangerous.sh` |
| 防止洩漏 API Key | PreToolUse (Write/Edit) | `secret-scanner.sh` |
| 自動 format 後存檔 | PostToolUse (Edit/Write) | `prettier --write` |
| Session 壓縮前儲存進度 | PreCompact | `save-session-state.sh` |
| 完工前跑品質檢查 | Stop | `quality-gate.sh` |
| AI 卡住時通知 LINE/Telegram | Notification | 呼叫 Bot API |

---

## 最值得馬上借鑑

1. **`block-dangerous.sh` 加入現有 hooks 設定**
   - 立刻防止 `rm -rf` / `git push --force` 意外執行

2. **`quality-gate.sh` 作為 Stop Hook**
   - AI 每次結束工作前自動確認「有沒有未 commit 的改動」「有沒有殘留 TODO」
   - 注意：必須處理 `stop_hook_active` 防止無限循環

---

## Sample Code 位置

```
code/part2-hooks/
├── lifecycle/
│   ├── save-session-state.sh    ← PreCompact 狀態儲存
│   ├── restore-context.sh       ← Session 恢復
│   └── audit-config.sh          ← 設定變更稽核
├── security/
│   ├── block-dangerous.sh       ← 危險指令封鎖
│   └── mcp-write-guard.sh       ← MCP write 守衛
├── quality/
│   ├── quality-gate.sh          ← Stop hook 品質守門
│   ├── auto-format.sh           ← 自動格式化
│   └── prompt-hook-examples.json ← hooks 範例集
├── notification/notify.sh        ← macOS + Slack 通知
├── platform/check-command.mjs    ← 跨平台指令偵測
└── settings-examples/
    ├── hooks-overview.json        ← 完整設定範本
    └── debug-hook.sh              ← 開發除錯用
```
