# Project Tree — part1-design/claude-md

**生成日期：** 2026-06-12
**掃描目標：** C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part1-design\claude-md
**統計：** 8 個資料夾 / 12 個檔案 / 排除 0 個噪音目錄

```
claude-md/
├── import-example/                        # 示範如何用 @ import 語法拆分 CLAUDE.md 規則
│   ├── docs/                              # 被主 CLAUDE.md 以 @docs/ 引用的規則文件群
│   │   └── *.md × 3                      # api-conventions / git-workflow / testing-guidelines（分類規則文件）
│   └── CLAUDE.md                          # 主示範文件：用 @README.md / @docs/*.md 拉入外部規則
├── monorepo-example/                      # Monorepo 多套件場景的 CLAUDE.md 分層繼承示範
│   ├── packages/
│   │   ├── backend/
│   │   │   └── CLAUDE.md                  # 後端專屬規則：Express + DB 存取限 repositories/
│   │   └── frontend/
│   │       └── CLAUDE.md                  # 前端專屬規則：React + React Query / Zustand 分工
│   ├── shared/
│   │   └── CLAUDE.md                      # 跨套件共用規則：只放 shared types，禁業務邏輯
│   └── CLAUDE.md                          # Monorepo 根規則：Conventional Commits + branch 命名
├── templates/                             # 各技術棧現成 CLAUDE.md 範本，可直接複製使用
│   └── *.CLAUDE.md × 3                   # django / go / nextjs 三種框架範本
└── compact-instructions.md                # context 壓縮時的保留清單 + PreCompact hook 整合示範
```
