# Project Tree — github-actions

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part4-cicd\github-actions`
- 統計：0 個子資料夾 / 3 個檔案 / 排除 0 個噪音目錄

```
github-actions/        # Part 4 CI/CD：三個 GitHub Actions workflow 範本（書中 P34/P36/P37）
├── pr-review.yml      # P34 PR 自動審查：pull_request opened/synchronize 觸發，跑 .github/scripts/review.sh，需 pull-requests:write 權限
├── auto-fix.yml       # P36 測試失敗自動修復：workflow_run「Run Tests」完成且 failure 才觸發，跑 auto-fix.sh 嘗試修測試
└── security-scan.yml  # P37 安全掃描：push/PR to main 觸發，用 --permission-mode plan 唯讀分析 src/（SQLi/缺認證/硬編碼機密），上傳報告 artifact
```

## 結構特徵

- 三個 workflow 對應書中三個 pattern 編號，是 CI 端呼叫 `claude -p` 的標準骨架。
- 安全設計：`security-scan.yml` 用 `--permission-mode plan` 強制唯讀，呼應全域規則「CI 掃描只讀不寫」；`pr-review.yml` 明確最小化 `permissions: pull-requests: write`。
- `auto-fix.yml` 用 `workflow_run` + `conclusion == 'failure'` 條件，只在測試真的失敗時才啟動修復，避免每次都跑。
- ⚠️ 注意：這批範本用的是 `ANTHROPIC_API_KEY` secret（扣 API Credits），與本專案實際 Chapter 4 閉環改用 `GH_PAT` + `claude -p`（Max 訂閱）的踩坑修正不同——範本是書中原始寫法，實戰版見 `.github/` 目錄。

```
