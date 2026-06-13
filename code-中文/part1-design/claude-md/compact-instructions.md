# Compact Instructions 範例

加到 CLAUDE.md 結尾的 compact instructions 範例。

## Compact Instructions

壓縮 context 時，務必保留：

- 所有修改過的檔案完整路徑
- 已執行的建置指令及其成功/失敗狀態
- 已發現的 bug 與預定的修復方案
- 本次 session 做出的設計決策
- 未完成的任務（還剩下什麼要做）

---

# 與 PreCompact Hook 搭配使用

PreCompact Hook 可以讓你在壓縮前把 session 狀態存到檔案。

```json
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "auto",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/save-session-state.sh"
          }
        ]
      }
    ]
  }
}
```

## Session 狀態儲存腳本

```bash
#!/bin/bash
SESSION_FILE=".claude/session-state.md"
DATE=$(date '+%Y-%m-%d %H:%M')

cat > "$SESSION_FILE" << EOF
# Session 狀態（自動儲存：${DATE}）

## 修改過的檔案
$(git diff --name-only)
$(git diff --name-only --cached)

## 未 commit 的變更摘要
$(git diff --stat | tail -5)

## 最近的 commit
$(git log --oneline -5)
EOF
```
