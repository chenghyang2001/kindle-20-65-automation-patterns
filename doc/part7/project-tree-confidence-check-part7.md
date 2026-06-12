# Project Tree — confidence-check

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part7-workflows\confidence-check`
- 統計：0 個子資料夾 / 1 個檔案 / 排除 0 個噪音目錄

```
confidence-check/   # Part 7 工作流：動手前的信心檢查清單 skill
└── SKILL.md        # 實作前 5 項檢查（C1 重複實作…），要求至少過 4/5（≥90%）才動工，disable-model-invocation（只能手動叫）
```

## 結構特徵

- 單一 skill，把「動手前先確認」變成可執行清單：5 項各答 PASS/FAIL/SKIP，門檻 4/5。
- `disable-model-invocation: true` 表示不讓模型自動觸發，必須使用者顯式 `/confidence-check`，避免每次小改都跑。
- 此檔與 `skills/confidence-check/SKILL.md` 內容相同（同一 skill 的兩處放置）。

```
