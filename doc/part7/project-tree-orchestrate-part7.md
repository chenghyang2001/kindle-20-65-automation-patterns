# Project Tree — orchestrate

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part7-workflows\orchestrate`
- 統計：0 個子資料夾 / 1 個檔案 / 排除 0 個噪音目錄

```
orchestrate/   # Part 7 工作流：依任務類型選對工作流的調度 skill
└── SKILL.md   # orchestrate skill：依參數 feature|bugfix|refactor|security [任務名] 選並執行對應工作流，disable-model-invocation + argument-hint
```

## 結構特徵

- 單一 skill，是 part7 各工作流的「總入口」：把 feature/bugfix/refactor/security 四種情境路由到各自流程。
- `argument-hint` 提供參數提示、`disable-model-invocation` 確保只在使用者明確下指令時才跑，避免誤觸發。
- 此檔與 `skills/orchestrate/SKILL.md` 內容相同。

```
