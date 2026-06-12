# Project Tree — agents

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part3-agents\agents`
- 統計：0 個子資料夾 / 4 個檔案 / 排除 0 個噪音目錄

```
agents/                            # Part 3 範例：串聯式 sub-agent 審查鏈定義（每個只做一件事）
├── spec-compliance-reviewer.md    # 規格合規審查員：驗證實作是否涵蓋需求/API 規格/錯誤與邊界案例（輸出 PASS/FAIL，model: sonnet，可用 Bash）
├── code-quality-reviewer.md       # 程式品質審查員：命名/重複碼/錯誤處理/硬編碼機密/測試覆蓋（分 Critical/Warning/Suggestion，model: inherit，接在規格審查後）
├── security-reviewer.md           # 資安漏洞稽核員：認證授權/注入/資料保護，唯讀 plan 模式（依嚴重度回報，附 file:line，model: sonnet）
└── api-reviewer.md                # API 設計審查員：RESTful 原則/輸入驗證/錯誤一致性/認證授權（分 Critical/Warning/Suggestion，model: sonnet）
```

## 結構特徵

- 這 4 個 Markdown 是 Claude Code **sub-agent 定義檔**（YAML frontmatter + 角色指令），對應書中 Part 3「串聯 Reviewer」教學。
- 設計順序為 `spec-compliance-reviewer → code-quality-reviewer → security-reviewer → api-reviewer`，每個 agent context 乾淨、職責單一，與全域 `agent-rules.md` 的 Reviewer 串聯規則一致。
- 工具權限刻意收斂：全部僅 `Read/Grep/Glob`（spec 多一個 `Bash`），`security-reviewer` 額外加 `permissionMode: plan` 強制唯讀，避免審查時誤改檔案。

```
