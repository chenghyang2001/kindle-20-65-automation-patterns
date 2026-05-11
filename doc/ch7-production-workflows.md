# 第7章 Production Workflows — AI 寫程式防翻車指南

> Claude Code in Production | Yosuke Morikawa | Patterns 62–65

---

## 章節概覽

生產環境最怕的兩件事：**AI 幻覺（說謊）+ 中途翻車（無法回頭）**。
本章提供 Checkpointing、幻覺偵測、Cascade 模式、觀察模式四大防翻車機制。

---

## 核心模式

### Pattern 62：Checkpointing — 安全網

#### /rewind 操作選單

```
Esc + Esc  或  /rewind

選項：
1. Restore code and conversation  → 程式碼 + 對話歷史都恢復
2. Restore conversation           → 只回滾對話，程式碼改動保留
3. Restore code                   → 只恢復程式碼，繼續對話
4. Summarize from here            → 把這段歷史壓縮成摘要（釋放 context）
5. Never mind                     → 取消
```

#### 大改動前建立 Checkpoint

```markdown
請先記錄目前狀態作為 checkpoint。
我即將執行以下重構：把 src/auth/ 下的 class-based 程式碼
改寫為 function-based。
如果失敗，我會用 Esc+Esc 回到這個點。
```

#### Summarize 用法（釋放長 debug session 的 context）

```markdown
# 漫長 debug 後釋放 context
1. 開啟 /rewind
2. 選取 debug 開始的那條訊息
3. 選「Summarize from here」
4. 輸入摘要指令：「只保留根本原因和最終解法。」
```

**注意：** Bash 指令（rm/mv/cp）的改動不被追蹤，只有 Claude Code 的 Write/Edit 才有 checkpoint。

---

### Pattern 63：幻覺偵測系統

#### 四個驗證問題

在 AI 實作完成後，逐一詢問：

```
Q1：「你用到的每個函式/方法，請提供官方文件 URL 和對應章節。」
    → AI 無法給出真實 URL = 需要獨立驗證

Q2：「執行這段程式碼需要什麼版本？你確認過文件嗎？」
    → 「我沒有確認」= 幻覺風險

Q3：「有沒有替代實作方式？各有什麼 trade-off？」
    → 說不出替代方案 = 理解可能不完整

Q4：「這個實作會在哪三種情況下失敗？」
    → 說不出失敗情境 = 對實作理解很淺
```

#### 七個紅旗（看到就要驗證）

```
RF1: 「應該是...」「大概...」「似乎...」→ 不確定資訊當事實說
RF2: 沒有引用的數字 → 「快 30%」「記憶體減半」沒來源
RF3: 新舊語法混用 → 新版 API + 舊版語法搭配
RF4: 不存在的 flag/選項 → CLI flag 根本沒這個
RF5: 錯誤訊息和文件不符 → 例外類別名稱錯
RF6: 過度樂觀描述 → 沒提任何限制、注意事項、失敗情境
RF7: 和前次答案矛盾 → 同主題前後說法不一致
```

#### 幻覺處理流程

```
偵測到紅旗
  → 查本地 docs/（~/.claude/docs/ 或 code/）
  → 無法確認 → 標記「(待驗證)」先暫緩
  → 找到矛盾 → 替換正確資訊
  → 修正後重跑四個驗證問題
```

**重要心態：** 說「你的答案是錯的」反而讓 AI 更不準確。
改說「請在文件中驗證這個資訊」→ 準確率更高。

---

### Pattern 64：Cascade 模式（結果驅動串聯）

```bash
# cascade-start.sh
set -euo pipefail

echo "Phase 1: Architecture review..."
ARCH_RESULT=$(claude -p "Analyze architecture and output JSON: 
  {issues: [], recommendations: [], affected_files: []}" \
  --allowedTools "Read,Grep,Glob" --output-format json)

AFFECTED=$(echo "$ARCH_RESULT" | jq -r '.affected_files[]')

echo "Phase 2: Targeted implementation..."
for file in $AFFECTED; do
  claude -p "Implement recommendations for $file" \
    --allowedTools "Read,Edit" \
    --output-format json
done

echo "Phase 3: Verification..."
claude -p "Verify all changes are consistent" \
  --allowedTools "Read,Grep,Glob" \
  --output-format json
```

前一階段的 JSON 輸出 → 驅動下一階段的輸入。
不再是「叫 AI 做一大堆事」，而是**結構化的 Phase 串聯**。

---

### Pattern 65：Observe 模式 + Confidence Check

#### observe-pattern.sh

```bash
# observe-pattern.sh — 只觀察不執行，適合高風險操作前確認
claude -p "Describe what changes you would make to implement X.
  Do NOT make any actual changes. Output as JSON:
  {planned_changes: [{file, action, reason}]}" \
  --allowedTools "Read,Grep,Glob" \
  --output-format json | tee proposed-changes.json

echo "Review the plan above before proceeding."
read -p "Proceed? (y/n): " confirm
if [ "$confirm" = "y" ]; then
  claude -p "Now implement the changes from proposed-changes.json" \
    --allowedTools "Read,Edit,Write"
fi
```

#### Confidence Check Skill

```yaml
# confidence-check/SKILL.md
---
name: confidence-check
description: >
  Check confidence level before starting a risky implementation.
  Use before: large refactors, database migrations, breaking API changes.
---

Before I proceed, please rate your confidence:

1. How many files will this change affect? (estimate)
2. Confidence level (1-10) on the approach
3. Potential risks or unknowns
4. Suggested checkpoints during implementation

If confidence < 7, we should discuss the approach first.
```

#### orchestrate/SKILL.md

```yaml
---
name: orchestrate
description: >
  Orchestrate a multi-phase implementation plan.
  Breaks complex tasks into verifiable phases with checkpoints.
---

Phase plan for [TASK]:
1. Analysis phase (read-only)
2. Design phase (output plan, no edits)
3. Implementation phase (one component at a time)
4. Verification phase (test + review)

Create a checkpoint before each phase.
```

---

## 防翻車完整 Checklist

```
□ 大改動前說出 checkpoint prompt（讓 /rewind 有意義的還原點）
□ AI 完成後問四個驗證問題（特別是 Q1 官方文件 URL）
□ 看到七個紅旗任一個 → 立即查文件驗證
□ 高風險操作前跑 observe-pattern.sh（先看計劃再執行）
□ confidence < 7 → 先討論方案再開始
□ 複雜任務用 Cascade 模式（不要一次性指令）
□ 長 debug session 用 "Summarize from here" 釋放 context
```

---

## 如何套用到我的工作流

| 場景 | 防翻車工具 |
|------|----------|
| AIHCR 控制規則變更 | Observe 模式 + Confidence Check |
| NLM 批次作業 | Cascade 模式（分析→觸發→等待→下載） |
| VPS 設定變更 | `readonly-review.json`（Ch5）+ Checkpoint |
| 新 Skill 開發 | confidence-check Skill → orchestrate Skill |

---

## 最值得馬上借鑑

1. **四個驗證問題加入我的 Session 收工 SOP**
   - 每次 AI 完成重要實作後，問 Q1（URL）和 Q4（失敗情境）
   - 防止「看起來正確但其實幻覺」的情況悄悄進生產

2. **Observe 模式用於高風險 NUC/VPS 操作**
   - 改 cron / systemd / nginx 前先問「你打算改什麼」
   - 確認計劃合理再執行，不再事後才發現改錯了

---

## Sample Code 位置

```
code/part7-workflows/
├── docs/checkpointing-guide.md     ← /rewind 完整操作指南
├── hallucination-detection.md      ← 四問題 + 七紅旗
├── cascade/cascade-start.sh        ← Cascade 串聯腳本
├── confidence-check/SKILL.md       ← 信心評估 Skill
├── orchestrate/SKILL.md            ← 多階段編排 Skill
└── hooks/observe-pattern.sh        ← Observe 模式腳本
```
