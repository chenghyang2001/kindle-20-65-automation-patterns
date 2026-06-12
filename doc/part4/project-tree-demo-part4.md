# Project Tree — demo

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part4-cicd\demo`
- 統計：0 個子資料夾 / 2 個檔案 / 排除 0 個噪音目錄

```
demo/                       # Part 4 CI/CD：auto-pilot 自動修復管線的「示範靶子」腳本
├── backup-files.sh         # 正向範本：嚴格錯誤防護（set -euo pipefail）+ 參數檢查 + 時間戳備份目錄，標註 Critical/Warning 修復點
└── check-disk-usage.sh     # 反向範本：刻意保留 3 個可修復 bug（缺 set -e、$1 無預設、字串 > 比較誤用重導向），供 AI 自動修復展示
```

## 結構特徵

- 這兩支 shell 是 Chapter 4 auto-pilot 的「教學對照組」：一支寫對、一支故意寫錯。
- `check-disk-usage.sh` 的三個 bug（無錯誤中止、空變數、`>` 在 `[ ]` 內變成檔案重導向）正是 AI 自動修復管線要偵測並修正的標的。
- `backup-files.sh` 則示範修好後的樣子，註解直接標出 `Critical #1/#4`、`Warning #3` 對應哪一類問題。


```
