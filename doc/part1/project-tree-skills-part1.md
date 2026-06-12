# Project Tree — part1-design/skills

**生成日期：** 2026-06-12
**掃描目標：** C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part1-design\skills
**統計：** 5 個資料夾 / 7 個檔案 / 排除 0 個噪音目錄

```
skills/
├── dynamic-context/                       # 示範 `!` 動態指令：執行時自動注入 PR 資訊到 Skill 上下文
│   └── SKILL.md                           # pr-summary：context: fork + agent: Explore + !`gh pr diff` 等
├── good-description/                      # 示範 description 欄位的好壞寫法對比
│   ├── examples/
│   │   ├── bad-example.md                 # 反例：把部署步驟全塞進 description（觸發條件不明確）
│   │   └── good-example.md                # 正例：code-review Skill，description 明確列觸發語句及排除條件
│   └── SKILL.md                           # 範本：disable-model-invocation: true 的生產部署 Skill
├── invocation-control/                    # 進階觸發控制：限制 Skill 的啟動方式
│   ├── deploy.SKILL.md                    # 加 disable-model-invocation: true，防止自然語言誤觸部署
│   └── legacy-context.SKILL.md            # user-invocable: false，Claude 自動按需注入舊系統背景知識
└── subagent-skill/                        # 示範用 context: fork 隔離上下文，以 Explore agent 執行稽核
    └── SKILL.md                           # security-audit：Grep TypeScript src/ 找 SQL injection 等漏洞
```

## Skill 設計模式對照

| 目錄 | 核心 frontmatter | 設計意圖 |
|------|-----------------|---------|
| `dynamic-context` | `context: fork` + `agent: Explore` + `!cmd` | 讓 Skill 執行時抓取即時資訊（PR diff、comments） |
| `good-description` | `disable-model-invocation: true` | 說明 description 是「觸發條件」而非「指令步驟」 |
| `invocation-control/deploy` | `disable-model-invocation: true` | 安全門：只允許 `/deploy` 指令觸發，防誤觸生產部署 |
| `invocation-control/legacy-context` | `user-invocable: false` | 背景注入：Claude 自動決定何時帶入舊系統約束知識 |
| `subagent-skill` | `context: fork` + `agent: Explore` + `allowed-tools: Read,Grep,Glob` | 唯讀子代理掃描，確保不修改任何檔案 |
