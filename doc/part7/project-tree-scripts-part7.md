# Project Tree — scripts (part7-workflows)

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part7-workflows\scripts`
- 統計：0 個子資料夾 / 1 個檔案 / 排除 0 個噪音目錄

```
scripts/             # Part 7 工作流：從 GitHub repo 安裝 skill 的腳本
└── install-skill.sh # 從 GitHub repo clone 指定 skill 到 project 或 personal scope，含已存在檢查、淺 clone、mktemp+trap 清理
```

## 結構特徵

- 單支安裝腳本，用法 `./install-skill.sh <skill-name> <repo-url> [project|personal]`。
- 防禦性寫法齊全：`set -euo pipefail`、`${1:?required}` 強制參數、目標已存在即中止、`--depth=1` 淺 clone、`trap rm -rf` 確保暫存目錄清掉。
- 對應書中「skill 跨 repo 分發/安裝」的工作流，把社群/團隊 skill 拉進本地 `.claude/skills/`。


```
