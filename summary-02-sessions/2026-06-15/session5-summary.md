# Session 5 Summary — 2026-06-15

## 完成事項

### Part 6 成本最佳化（第 1-3 課完成，第 4 課進行中）

| 課 | 主題 | commit |
|----|------|--------|
| 第 1 課 | 看懂 Token 帳單 | `2d24169` |
| 第 2 課 | 模型選擇矩陣 | `70e652b` |
| 第 3 課 | Prompt 快取設計 | `a7a3558` |

### 其他完成項目

- 補完 Part 6 第 1 課 STEP-LOG 的 Step 2 & Step 3（context 斷點延續）
- 建立交接文件 `doc/HANDOFF.md`（家用 PC → 公司 PC 切換用）
- 建立 Part 5 全 7 課 session 摘要 `doc/session-part5-L1-L7-summary.md`

---

## 關鍵技術筆記

### Part 6 核心知識

**Token 計費結構（第 1 課）**：

- 四個欄位：`input_tokens` / `output_tokens` / `cache_read_input_tokens` / `cache_creation_input_tokens`
- 迴轉壽司計費：每輪 Input = 所有歷史累積，第 N 輪 Input 成等差增長
- 「叫 AI 答短一點」只省 Output（小頭），省不了 Input（大頭）
- 真正的省錢：`/compact` 截斷歷史 或 善用 Prompt Cache

**模型選擇矩陣（第 2 課）**：

- haiku：搜尋 / 格式化 / 重複任務（$0.80/M input）
- sonnet：bug 修復 / 安全稽核 / 通用實作（$3/M input）
- opus：架構決策（$15/M input，謹慎動用）
- `inherit`：品質必須與主對話一致時使用；風險：主對話降階會靜默拉低所有繼承者
- `CLAUDE_CODE_SUBAGENT_MODEL=haiku`：全域讓所有 sub-agent 降階
- 單一搜尋任務 Opus → Haiku，每月省 $21.3（省 95%）

**Prompt 快取設計（第 3 課）**：

- 快取對象：系統提示 / CLAUDE.md（固定部分），**不是**對話歷史
- 命中條件：**Exact Prefix Matching**——一個字元不同就從那行開始全部重算
- 最常見快取殺手：CLAUDE.md 頂部放時間戳
- 三層結構：穩定（頂部）→ 半穩定（中間）→ 動態（底部，理想上空白）
- CLAUDE.md 是「永遠正確的專案說明書」，不是工作日誌
- `claude --continue` 最大化快取命中率；`DISABLE_PROMPT_CACHING=1` 除錯用

---

## 產出檔案

| 檔案 | 說明 |
|------|------|
| `code-中文/part6-cost/demo/01-看懂Token帳單/STEP-LOG.md` | 第 1 課完整答案（含 Step 2/3 補完） |
| `code-中文/part6-cost/demo/02-模型選擇矩陣/STEP-LOG.md` | 第 2 課完整答案 |
| `code-中文/part6-cost/demo/03-Prompt快取設計/STEP-LOG.md` | 第 3 課完整答案 |
| `doc/HANDOFF.md` | 跨機器交接文件 |
| `doc/session-part5-L1-L7-summary.md` | Part 5 全 7 課摘要 |

---

## HANDOFF（下次 session 優先處理）

### 立即行動

- [ ] 繼續 Part 6 第 4 課「成本警示 Hook」（`suggest-compact.sh` 腳本分析）——本課題目已呈現，尚未 answer
- [ ] 完成 Part 6 第 5-7 課（Sub-agent 套利 / MCP 轉 Skill / 組合拳全面控制）
- [ ] 完成 Part 6 後建立 session 摘要並更新 MEMORY.md 的 Part 6 狀態

### 進行中（需接續）

- Part 6 第 4 課題目已呈現（4 個 Step，對應 `hooks/suggest-compact.sh`），用戶下次說「answer」即可繼續
- Part 6 共 7 課，目前完成 1-3 課，剩 4-7 課

### 注意事項

- 互動演練固定流程：呈現題目 → 用戶說「answer」→ 填答案 → 用戶說「存檔進第 N 課」→ commit + push → 呈現下一課
- 「go 下一課」= 同時存檔當前課 + 呈現下一課（shortcuts for 存檔指令）
- PostToolUse hook 修改檔案後需重讀再 Edit，避免 old_string 不符
- Part 6 源碼目錄：`code-中文/part6-cost/`，STEP-LOG 模板在 `demo/0N-課名/STEP-LOG.md`
