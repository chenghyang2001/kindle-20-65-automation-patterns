# Project Tree — part2-hooks/security

**生成日期：** 2026-06-12
**掃描目標：** C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part2-hooks\security
**統計：** 0 個資料夾 / 2 個檔案 / 排除 0 個噪音目錄

```
security/
├── block-dangerous.sh    # PreToolUse hook：封鎖 7 種危險 Bash 指令模式（exit 2）
└── mcp-write-guard.sh    # PreToolUse hook：阻止 MCP filesystem server 對 .env/.pem/.key 等敏感檔案的寫入/刪除/移動
```

## 各檔案功能摘要

### `block-dangerous.sh` — PreToolUse

從 stdin JSON 讀取 `.tool_input.command`，逐一比對封鎖清單：

| 封鎖模式 | 危險類型 |
|---------|---------|
| `rm -rf /` | 根目錄遞迴刪除 |
| `rm -rf ~` | Home 目錄遞迴刪除 |
| `git push --force` | 強制覆蓋遠端歷史 |
| `git push -f` | 同上（縮寫形式） |
| `chmod -R 777` | 全域開放讀寫執行權限 |
| `DROP TABLE` | 破壞性 SQL |
| `> /dev/sda` | 直接寫入磁碟裝置 |

命中 → stderr 警告 + `exit 2`（Claude 解讀為封鎖）。

---

### `mcp-write-guard.sh` — PreToolUse

**針對 MCP 工具** 的專用防護層（補 block-dangerous.sh 不覆蓋 MCP 的盲點）：

- 只攔截 `mcp__filesystem__(write|delete|move)` 類工具
- 目標路徑符合 `\.(env|pem|key)$` → 回傳 Claude hooks JSON 格式的 deny 決定：

  ```json
  { "hookSpecificOutput": { "permissionDecision": "deny", "permissionDecisionReason": "..." } }
  ```

- 其他工具或其他路徑 → 直接放行（exit 0）

## 設計要點

兩支腳本組合覆蓋兩個不同的攻擊面：

- `block-dangerous.sh` — 防止 Claude 執行危險的 **Bash 指令**
- `mcp-write-guard.sh` — 防止 MCP server 存取**敏感憑證檔案**
