# 內建 Sub-agent 參考

Claude Code 開箱即附的 sub-agent 清單。

## 內建 Sub-agent

| Sub-agent | 模型 | 工具 | 用途 |
|-----------|-------|-------|---------|
| Explore | Haiku | 唯讀 | 程式碼庫探索與搜尋 |
| Plan | Inherit | 唯讀 | Plan 模式下的研究 |
| General-purpose | Inherit | 所有工具 | 複雜的多步驟任務 |
| Bash | Inherit | 僅 Bash | 獨立的終端機指令執行 |
| statusline-setup | Sonnet | Read/Write | /statusline 設定 |
| Claude Code Guide | Haiku | Read | Claude Code 功能問答 |

## Explore Sub-agent 的徹底程度層級

| 層級 | 使用情境 |
|-------|----------|
| quick | 尋找特定檔案、精準確認 |
| medium | 平衡的探索 |
| very thorough | 對整個程式碼庫做全面分析 |

## 停用特定 Sub-agent

```json
{
  "permissions": {
    "deny": [
      "Task(Explore)",
      "Task(general-purpose)"
    ]
  }
}
```

也可以透過 CLI 旗標指定：

```bash
claude --disallowedTools "Task(Explore)"
```

## 用 /agents 列出代理清單

```bash
# 互動式選單
/agents

# 從 CLI 列出
claude agents
```

## 注意事項

- Explore 和 Plan 只啟用唯讀工具
- Sub-agent 不能再派生其他 sub-agent（不可巢狀）
- 要避免巢狀，可改用 Skills 或在主對話中串接執行
