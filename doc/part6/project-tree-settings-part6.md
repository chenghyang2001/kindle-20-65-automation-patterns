# Project Tree — settings (part6-cost)

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part6-cost\settings`
- 統計：0 個子資料夾 / 4 個檔案 / 排除 0 個噪音目錄

```
settings/                   # Part 6 成本：4 個省 token / 控成本的 settings.json 片段
├── model-matrix.json        # 指定 model: sonnet（任務用對模型，不一律 opus）
├── effort-level.json        # 設 effortLevel: medium（推理力度適中以省成本）
├── minimal-mcp.json         # deny mcp__playwright__* / mcp__magic__*（停用重型 MCP 省啟動 context）
└── disable-1m-context.json  # env CLAUDE_CODE_DISABLE_1M_CONTEXT=1（關閉 1M context 視窗以降成本）
```

## 結構特徵

- 4 個極小 JSON，各示範一個成本旋鈕：模型選擇、推理力度、MCP 精簡、關閉 1M context。
- 與全域 cost-rules 呼應：成本最佳化往往不是大改架構，而是這類 settings 微調的累積。

```
