# Project Tree — hooks (part6-cost)

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part6-cost\hooks`
- 統計：0 個子資料夾 / 1 個檔案 / 排除 0 個噪音目錄

```
hooks/                # Part 6 成本：context 用量提醒 hook
└── suggest-compact.sh # 讀 transcript 數 tool_use 次數，每滿 50 次就提示「考慮 /compact」以控管 context 成本（純提醒，exit 0 不阻擋）
```

## 結構特徵

- 單一 hook，靠 `transcript_path` 統計 `"type":"tool_use"` 出現次數，每 50 次給一次 compact 提示。
- 屬「軟提醒」型 hook（`exit 0`，只寫 stderr），不像 part5 的攔截型 hook 會 block——成本控制用建議而非強制。

```
