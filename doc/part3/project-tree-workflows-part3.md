# Project Tree — workflows

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part3-agents\workflows`
- 統計：0 個子資料夾 / 2 個檔案 / 排除 0 個噪音目錄

```
workflows/                # Part 3 sub-agent 審查鏈的流程圖與測試情境
├── code-review.dot       # Graphviz 流程圖：Explore → 規格 → 品質 → 資安 串聯審查，任一關卡 FAIL/Critical 就跳 Fix 再回頭重審
└── test-scenarios.md     # code-reviewer 的 3 個測試案例：SQL 注入偵測 / 不誤報正常碼 / 優先級分類（含 Pass 判定字串）
```

## 結構特徵

- 兩個檔案把 `agents/` 的審查鏈「視覺化 + 可驗證化」。
- `code-review.dot` 用 DOT 語言描述串聯審查的狀態機：`fix -> spec_check` 形成回圈，呼應書中「修完打回票重審」的閉環設計（可用 `dot -Tpng` 渲染）。
- `test-scenarios.md` 提供 happy/edge/分類三類驗證點，與全域 code-quality 規則「測試含正常/邊界/錯誤三案例」一致。

```
