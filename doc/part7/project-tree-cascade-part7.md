# Project Tree — cascade

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part7-workflows\cascade`
- 統計：0 個子資料夾 / 1 個檔案 / 排除 0 個噪音目錄

```
cascade/             # Part 7 工作流：平行多實例審查的 worktree 啟動器
└── cascade-start.sh # 為 3 個平行 Claude 實例各建 1 個 git worktree（Worker1 安全/Worker2 品質/Worker3 規格），印出啟動與清理指令
```

## 結構特徵

- 單支腳本，用 `git worktree add` 建 3 個隔離工作目錄，讓 3 個 Claude 實例平行審查互不撞 repo。
- 註解為繁體中文，並貼心印出「啟動 claude 指令」+「完成後 worktree remove/prune 清理指令」，是 part3 reviewer 鏈的平行化執行層。


```
