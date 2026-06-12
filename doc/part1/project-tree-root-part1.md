# Project Tree — part1-design

**生成日期：** 2026-06-12
**掃描目標：** C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part1-design
**統計：** 16 個資料夾 / 20 個檔案 / 排除 0 個噪音目錄

```
part1-design/
├── claude-md/                          # CLAUDE.md 各種使用情境的範例集合
│   ├── import-example/                 # 示範 @ import 語法，將規則拆分到多個子文件
│   │   ├── docs/                       # 被 CLAUDE.md 以 @ import 引用的規則文件
│   │   │   └── *.md × 3               # api-conventions / git-workflow / testing-guidelines
│   │   └── CLAUDE.md                  # 示範用主文件，說明 @ import 檔案結構
│   ├── monorepo-example/               # Monorepo 多套件場景的 CLAUDE.md 分層示範
│   │   ├── packages/
│   │   │   ├── backend/
│   │   │   │   └── CLAUDE.md          # 後端規則：Node.js + Express，DB 只走 repositories/
│   │   │   └── frontend/
│   │   │       └── CLAUDE.md          # 前端規則：React + Vite，React Query + Zustand
│   │   ├── shared/
│   │   │   └── CLAUDE.md              # 共用套件規則：只放 shared types，禁業務邏輯
│   │   └── CLAUDE.md                  # Monorepo 根規則：Conventional Commits、branch 命名
│   ├── templates/                      # 各技術棧 CLAUDE.md 範本
│   │   └── *.CLAUDE.md × 3            # django / go / nextjs 三種現成範本
│   └── compact-instructions.md         # context 壓縮時保留規則的說明文件（compact 指引）
├── rules/
│   └── coding-conventions.md           # 專案通用 coding 規範（可被 CLAUDE.md @ import）
└── skills/                             # Skill 設計範例集
    ├── dynamic-context/
    │   └── SKILL.md                    # 示範用 `!` 動態指令注入 PR diff / comments 的 Skill
    ├── good-description/               # 示範 description 欄位的好壞寫法
    │   ├── examples/
    │   │   ├── bad-example.md          # 觸發條件模糊、無排除條件的反例
    │   │   └── good-example.md         # 明確 use-for / not-for 的正例
    │   └── SKILL.md                    # 帶 disable-model-invocation 的部署 Skill 範本
    ├── invocation-control/             # 控制 Skill 觸發時機的進階設定示範
    │   ├── deploy.SKILL.md             # 明確只允許 /deploy 指令觸發的安全部署 Skill
    │   └── legacy-context.SKILL.md     # 引入舊系統背景知識的 context-fork Skill
    └── subagent-skill/
        └── SKILL.md                    # 示範以 context: fork + agent: Explore 執行安全稽核
```
