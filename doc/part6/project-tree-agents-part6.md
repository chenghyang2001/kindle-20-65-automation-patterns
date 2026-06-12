# Project Tree — agents (part6-cost)

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part6-cost\agents`
- 統計：0 個子資料夾 / 1 個檔案 / 排除 0 個噪音目錄

```
agents/               # Part 6 成本：示範用 haiku 探索型 sub-agent 省 token
└── code-explorer.md  # 程式碼探索 agent：model haiku，只做結構理解/依賴對應，輸出 bullet 並少引用程式碼（深入項目只回檔案路徑）
```

## 結構特徵

- 單一檔案，示範「探索型任務用 haiku」的成本原則（對應全域 agent-rules.md：檔案探索/搜尋用 haiku 省 60-80% token）。
- 輸出格式刻意要求「少引用程式碼、深入項目只回路徑」——降低 token 並把細讀留給主 agent，是成本章節的核心手法。


```
