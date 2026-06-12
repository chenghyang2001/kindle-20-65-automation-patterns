# Project Tree — docs

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part3-agents\docs`
- 統計：0 個子資料夾 / 4 個檔案 / 排除 0 個噪音目錄

```
docs/                              # Part 3 sub-agent 章節的參考資料（決策表 / 成本表 / 反理由化）
├── builtin-agents-reference.md    # Claude Code 內建 sub-agent 一覽表：Explore/Plan/General-purpose/Bash 等的模型、工具權限與用途
├── decision-matrix.md             # 「單一 sub-agent vs Agent Teams」決策指南：session 數、通訊方式、協調、context、token 成本比較
├── model-cost-matrix.md           # sub-agent 模型選擇對照表：依任務類型（探索/審查/修 bug/資安/架構/重構）建議 haiku/sonnet/opus/inherit
└── rationalization-prevention.md  # 反理由化對照表：列出 Claude 逃避困難任務的常見藉口與正確應對（建議嵌入 AGENT.md）
```

## 結構特徵

- 4 份純文件（無程式碼），是書中 Part 3 sub-agent 教學的「速查表」資料層。
- `model-cost-matrix.md` 與 `rationalization-prevention.md` 的內容，正是本機全域 `agent-rules.md` 規則的來源依據（模型選擇原則、反理由化行為對照表）。
- `decision-matrix.md` 點出 Agent Teams 為實驗性功能且 token 成本高，呼應「預設用單一 sub-agent、必要時才開團隊」的取捨。

```
