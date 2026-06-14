# Session 摘要：Part 4 CI/CD 第 1-4 課

日期：2026-06-14

## 本 Session 完成

### Part 3 補完（第 4-7 課）

| 課 | 主題 | 關鍵收穫 |
|----|------|---------|
| 4 | 自訂 Agent 四元素 | 領域知識注入系統提示；「主動」語意 = 授權自觸發 |
| 5 | 反理由化防護 | 12 種迴避行為；合理停工三段報告；系統提示放防禦 |
| 6 | 串聯 Reviewer Pipeline | 正確性優先品質；fix 永遠回第一關；sub-agents vs Agent Teams |
| 7 | DOT 視覺化 | Graphviz 語法；dashed+orange 標非正常路徑；三層文件互補 |

### Part 4 CI/CD（第 1-4 課）

| 課 | 主題 | 關鍵收穫 |
|----|------|---------|
| 1 | 無頭模式入門 | `claude -p`、exit code 0=成功、三道防爆引數 |
| 2 | JSON 結構化輸出 | 四種模式；`--output-format json` = CLI 包裝不是 AI 輸出；`--json-schema` = 合約 |
| 3 | 自動產生 Commit 訊息 | 最小權限白名單；Conventional Commits；`set -e` 快速失敗 |
| 4 | 多步驟 Session 接力 | `--resume` 記憶接力；省 token + 保留脈絡；越後面越嚴格 |

## 核心技術要點

```
claude -p 三道防爆：
  --allowedTools  → 防工具呼叫（不防 AI 推理繞過）
  --max-turns     → 防無限循環
  --max-budget-usd → 防費用爆炸

JSON 輸出三欄位：
  .result         → AI 文字答案
  .session_id     → --resume 接力用
  .structured_output → --json-schema 強制結構

--resume 設計原則：
  分析步驟 → 給 Read + Glob + Bash
  推論步驟 → 只用 context，不加工具
  報告步驟 → 空白名單，禁止任何操作
```

## Commit 清單

| Commit | 說明 |
|--------|------|
| 574b3b5 | Part4 第 1 課：無頭模式入門 |
| 3958448 | Part4 第 2 課：JSON 結構化輸出 |
| 51d4e31 | Part4 第 3 課：自動產生 Commit 訊息 |
| 4e0f322 | Part4 第 4 課：多步驟 Session 接力 |

## 下次繼續

Part 4 第 5 課：`PlanMode 安全護欄`
對應文件：`code-中文/part4-cicd/demo/05-PlanMode安全護欄/STEP-LOG.md`
