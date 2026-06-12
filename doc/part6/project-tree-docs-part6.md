# Project Tree — docs (part6-cost)

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part6-cost\docs`
- 統計：0 個子資料夾 / 1 個檔案 / 排除 0 個噪音目錄

```
docs/                    # Part 6 成本：prompt cache 設計指南
└── cache-design-guide.md # CLAUDE.md 提高快取命中率的寫法：穩定資訊放頂部（概述/技術棧/規範）、易變資訊放底部（現況/TODO），別動頂部以保留快取
```

## 結構特徵

- 單一文件，講「穩定在上、易變在下」的 CLAUDE.md 結構，讓頂部維持 prompt cache 命中以省 token + 加速。
- 與本機全域 session-end 規則的 hot-cache / MEMORY 分層理念一致：固定基線與每日變動分開存放。


```
