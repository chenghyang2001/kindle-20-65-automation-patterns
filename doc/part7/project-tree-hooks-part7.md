# Project Tree — hooks (part7-workflows)

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part7-workflows\hooks`
- 統計：0 個子資料夾 / 1 個檔案 / 排除 0 個噪音目錄

```
hooks/                # Part 7 工作流：操作模式觀測 hook
└── observe-pattern.sh # PostToolUse 記錄器：把每次工具呼叫（ts/tool/input）以 JSONL 追加到 ~/.claude/logs/patterns.jsonl，供日後分析抽取 skill
```

## 結構特徵

- 單一 hook，純記錄不阻擋，輸出 JSONL 行到 `~/.claude/logs/patterns.jsonl`。
- 與 `skills/analyze-patterns` 形成「觀測 → 分析 → 建 skill」閉環：此 hook 蒐集原始操作日誌，analyze-patterns 再從中找重複 3 次以上的指令序列當 skill 候選。

```
