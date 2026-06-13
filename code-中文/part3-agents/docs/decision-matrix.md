# Sub-agents vs Agent Teams 決策指南

## 比較

| 面向 | Sub-agents | Agent Teams |
|--------|-----------|-------------|
| Session | 單一主 session | 多個獨立 session |
| 溝通方式 | 只能透過主代理 | 代理之間直接溝通 |
| 協調方式 | 主代理統一管理 | 共享任務清單 + 自主認領 |
| Context | 結果回傳給主代理 | 每個實例各自持有 |
| Token 成本 | 低（結果摘要後回傳） | 高（多個實例） |
| 狀態 | 官方功能 | 實驗性 |

## 啟用 Agent Teams

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## 決策流程

```text
任務是否獨立？
 ├─ 是 → Sub-agents 就夠了
 └─ 否 → 是否需要代理之間直接溝通？
           ├─ 是 → 考慮 Agent Teams
           └─ 否 → 在主對話中循序執行
```

## 何時選擇 Sub-agents

- 探索型任務（程式碼庫調查、log 分析）
- 專門審查（安全性、規格遵循）
- 只需要結果、不在乎中間步驟的處理
- 想把 token 成本降到最低時

## 何時選擇 Agent Teams

- 多個代理需要互相參考並討論彼此的發現
- 平行驗證互相競爭的假設（例如：同時從多角度調查 bug）
- 長時間運行的平行實作，且每個代理需要獨立的 context

## 注意事項

Agent Teams 是實驗性功能。已知限制包括：session 恢復（`/resume`）對
in-process 隊友無效（截至 2026 年 2 月）。
在功能穩定前，請避免在正式工作流中使用 Agent Teams。
能由 Sub-agents 處理的任務，優先使用 Sub-agents。
