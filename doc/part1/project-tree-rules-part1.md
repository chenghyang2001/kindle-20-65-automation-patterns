# Project Tree — part1-design/rules

**生成日期：** 2026-06-12
**掃描目標：** C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part1-design\rules
**統計：** 0 個資料夾 / 1 個檔案 / 排除 0 個噪音目錄

```
rules/
└── coding-conventions.md                  # 全域 coding 規範：import 風格、架構邊界、命名慣例（可被 CLAUDE.md @ import 引用）
```

## 檔案內容摘要

`coding-conventions.md` 含兩段規則，以 frontmatter `paths: ["src/api/**/*.ts"]` 限制作用域：

| 類別 | 規則 |
|------|------|
| API | 每個端點必須有 input validation + `ApiError` 型別 + OpenAPI 注釋 |
| Import | 只用 ES modules，禁 `require()`；非同步一律 async/await |
| 架構 | API 回傳型別來自 `src/types/api.ts`；DB 存取限 `src/repositories/` |
| 命名 | 檔名 kebab-case / Class PascalCase / Function camelCase / 常數 UPPER_SNAKE_CASE |
