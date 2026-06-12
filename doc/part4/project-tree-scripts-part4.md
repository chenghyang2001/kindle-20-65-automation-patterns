# Project Tree — scripts

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part4-cicd\scripts`
- 統計：0 個子資料夾 / 5 個檔案 / 排除 0 個噪音目錄

```
scripts/                     # Part 4 CI/CD：claude -p 在 CI 的五種用法範本（皆從專案根執行）
├── basic-ci.sh              # 基礎用法：直接帶 prompt / 管道餵檔案內容 / 限制 --allowedTools + --max-turns 的 CI 安全模式
├── json-output-patterns.sh  # --output-format json 用法：jq -r '.result' 取回應、擷取 session_id 供後續 --resume
├── multi-step-ci.sh         # Session 接續：Step 1 取得 session_id，Steps 2/3 用 --resume 重用 context，不必重讀檔案
├── parallel-review.sh       # 平行審查：用 -w 命名 worktree 同時跑 3 個獨立 review（&），輸出各自寫 temp 檔避免交錯，wait 收集
└── auto-commit.sh           # 自動 commit：偵測 staged 變更後叫 claude 讀 diff 生成 Conventional Commits 訊息（限 git 相關工具）
```

## 結構特徵

- 五支腳本由淺入深教 `claude -p` 在 CI/腳本中的核心技巧：**限制工具權限 → JSON 解析 → session 接續 → 平行化 → 自動提交**。
- 共通安全模式：全部用 `--allowedTools` 白名單收斂權限、`--max-turns` 設上限、`< /dev/null` 阻斷互動輸入，正是無 TTY CI 環境的必要寫法。
- `multi-step-ci.sh` 的 `--resume` 與 `parallel-review.sh` 的 `-w` 命名 worktree 是省 token / 提速的兩個關鍵手法：前者讓 Claude 記住分析 context 不重讀，後者讓多個 review 真正同時跑。

```
