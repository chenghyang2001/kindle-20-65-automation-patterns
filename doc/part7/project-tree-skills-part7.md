# Project Tree — skills (part7-workflows)

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part7-workflows\skills`
- 統計：4 個子資料夾 / 4 個檔案 / 排除 0 個噪音目錄

```
skills/                        # Part 7 工作流：4 個開發流程 skill（皆 disable-model-invocation，手動觸發）
├── dev-workflow/
│   └── SKILL.md               # 7 階段開發工作流入口（Stage1 Brainstorm 定義任務+完成標準…），新功能/修 bug/重構的起點
├── orchestrate/
│   └── SKILL.md               # 依 feature|bugfix|refactor|security 選並執行對應工作流（總調度入口）
├── confidence-check/
│   └── SKILL.md               # 動手前 5 項檢查清單，過 4/5（≥90%）才開工
└── analyze-patterns/
    └── SKILL.md               # 讀 ~/.claude/logs/patterns.jsonl 後 200 行，找重複 ≥3 次的指令序列當 skill 候選（附信心分數）
```

## 結構特徵

- 4 個 skill 構成一條自我演化的開發流程：`dev-workflow`（7 階段主流程）→ `orchestrate`（依類型分流）→ `confidence-check`（動手前把關）→ `analyze-patterns`（事後從日誌長出新 skill）。
- 全部 `disable-model-invocation: true`，是刻意設計的「手動工具」——這些流程控制型 skill 不該被模型自動觸發。
- `analyze-patterns` 與 `hooks/observe-pattern.sh` 配對：hook 蒐集操作日誌，此 skill 分析並建議把高頻序列封裝成新 skill，完成「觀測→分析→建 skill」閉環。

```
