# Project Tree — skills (part6-cost)

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part6-cost\skills`
- 統計：1 個子資料夾 / 1 個檔案 / 排除 0 個噪音目錄

```
skills/                       # Part 6 成本：把固定操作封裝成 skill（取代 MCP）
└── take-screenshot/
    └── SKILL.md              # take-screenshot skill：以 $ARGUMENTS 收 URL，呼叫 npx playwright screenshot 截圖（內建工具，免 MCP server）
```

## 結構特徵

- 與 `mcp-to-skill/` 同調：用一個 `SKILL.md` + `npx playwright` 取代「截圖用 MCP server」，省常駐成本。
- 標準 skill 目錄結構（`<skill-name>/SKILL.md`），`$ARGUMENTS` 接收呼叫參數，是封裝重複操作的最小範式。

```
