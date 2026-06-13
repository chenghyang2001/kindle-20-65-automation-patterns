# Session 4 Summary

**日期**：2026-06-13
**分支**：main
**Commits**：6fc72e5、fccfd08、62ef77c

---

## 完成事項

### Part 4 CI/CD 互動演練（7 堂課）— commit 6fc72e5

| 課 | 目錄 | 核心主題 |
|---|---|---|
| 01 | `01-無頭模式入門` | `claude -p` 無頭模式基礎與 `--allowedTools` 白名單 |
| 02 | `02-JSON結構化輸出` | `--output-format json` + `jq` 管線處理 |
| 03 | `03-自動產生Commit訊息` | CI 場景：自動 git diff → commit message 生成 |
| 04 | `04-多步驟Session接力` | `--resume $SESSION_ID` 跨任務記憶傳遞 |
| 05 | `05-PlanMode安全護欄` | `--permission-mode plan` 計畫審查模式 |
| 06 | `06-平行三維度審查` | `&` + `wait` 平行三維度 Code Review |
| 07 | `07-完整Pipeline` | 整合以上所有技巧的完整 CI/CD pipeline |

### Part 1 設計基礎互動演練（7 堂課）— commit fccfd08

| 課 | 目錄 | 核心主題 |
|---|---|---|
| 01 | `01-三層設定架構` | CLAUDE.md / rules/ / skills/ 三層職責分離 |
| 02 | `02-Import語法與MonoRepo` | `@import` 模組化 + MonoRepo 向上遍歷 |
| 03 | `03-Skill描述陷阱` | description 是語意選擇器，不是執行手冊 |
| 04 | `04-安全FrontMatter標籤` | `disable-model-invocation` / `user-invocable` |
| 05 | `05-子代理隔離` | `context.fork` 隔離 sub-agent context |
| 06 | `06-動態上下文注入` | `!{command}` 動態注入即時資訊 |
| 07 | `07-記憶刺青與專案模板` | Compact Instructions + PreCompact Hook + 三個框架模板 |

### Part 5 權限與資安互動演練（7 堂課）— commit 62ef77c

| 課 | 目錄 | 核心主題 |
|---|---|---|
| 01 | `01-Deny優先順序` | Deny > Ask > Allow 絕對優先序 |
| 02 | `02-Bash空格陷阱` | `Bash(ls *)` vs `Bash(ls*)` 單字邊界 vs 前綴比對 |
| 03 | `03-三層分層權限` | 可逆性 × 影響範圍 風險矩陣分類 |
| 04 | `04-唯讀審查模式` | `defaultMode: dontAsk` + 最小權限 Code Review |
| 05 | `05-管理設定鐵腕政策` | `allowManagedPermissionRulesOnly` + MDM plist 部署 |
| 06 | `06-Hook攔截器` | Pre-Tool-Use Hook `exit 2` 反饋迴圈 |
| 07 | `07-沙盒防暴玻璃箱` | OS 沙盒 + 網域白名單 — 防 Prompt Injection 最後防線 |

---

## 關鍵技術筆記

### 互動演練課程設計模式（已成熟）

每堂課固定 4 個 Step：

1. **閱讀任務** — 打開對應源碼，填入觀察表格
2. **對比分析** — 比較兩種做法的差異（通常用填表）
3. **模擬驗證** — 假設情境，預測行為（不需實際執行）
4. **設計練習** — 自己設計新的設定或腳本（填空或從頭寫）

每課末尾固定有「本課重點」區塊，用 code block 呈現，便於截圖分享。

### Part 5 的三層防禦體系

```
第一層：Permission Model（Claude Code 層）
  Deny / Ask / Allow + Bash pattern 精確比對

第二層：Hook 攔截器（應用層）
  Pre-Tool-Use exit 2 + JSON reason 反饋迴圈

第三層：OS 沙盒（系統層）
  allowedDomains 白名單 — 唯一能防 Prompt Injection 的層次
```

關鍵認知：Prompt Injection 操控 AI 意志，前兩層都假設 AI 有良好意志；只有 OS 層「不管 AI 怎麼決定」直接系統層截斷。

### Bash 空格陷阱（最容易犯的 pattern 錯誤）

```
Bash(ls *)  → 有空格 = 單字邊界，只允許指令名是 "ls" 的呼叫
Bash(ls*)   → 無空格 = 前綴比對，lsof 也通過（危險！）
```

---

## 產出檔案

| 路徑 | 類型 | 說明 |
|------|------|------|
| `code-中文/part4-cicd/demo/01~07/STEP-LOG.md` | 7 個 STEP-LOG | Part 4 CI/CD 互動演練 |
| `code-中文/part1-design/demo/01~07/STEP-LOG.md` | 7 個 STEP-LOG | Part 1 設計基礎互動演練 |
| `code-中文/part5-security/demo/01~07/STEP-LOG.md` | 7 個 STEP-LOG | Part 5 權限資安互動演練 |

**總計**：21 個 STEP-LOG.md，3 個 Part 全部完成互動演練課程

---

## 目前已完成的 Part

| Part | 主題 | 狀態 |
|------|------|------|
| Part 1 | 設計基礎 | ✅ 7 課完成 |
| Part 3 | Sub-agents | ✅ 7 課完成 |
| Part 4 | CI/CD | ✅ 7 課完成 |
| Part 5 | 權限與資安 | ✅ 7 課完成 |
| Part 6 | 成本最佳化 | ✅ 7 課完成 |
| Part 7 | Plugin | ✅ 7 課完成 |
| Part 2 | Hooks | ❓ 未確認 |

---

## HANDOFF（下次 session 優先處理）

### 立即行動

- [ ] 確認 Part 2 Hooks 的互動演練是否已建立；若未建立，依相同模式設計 7 堂課
- [ ] 確認是否有音訊逐字稿（Ch2 / Ch3 / Ch6 / Ch7）尚未分析，對應的 Part 是否需補齊
- [ ] 開始正式進行某一 Part 的互動演練（用「進第 1 課」觸發），累積演練記錄

### 進行中（需接續）

- Part 5 互動演練課程已全部建立，尚未正式跑過任何一堂課（STEP-LOG.md 的「實際結果」欄位均為空白）
- 下次 session 可直接說「進第 1 課」進入 Part 5 第 1 課演練

### 注意事項

- 每個 Part 的源碼在 `code-中文/part*/`，對應音訊逐字稿在 `audio-transcripts/`
- 課程設計模式已穩定（4 Step 結構 + 本課重點 code block），下次建新 Part 沿用即可
- PostToolUse Write hook 會自動格式化 STEP-LOG.md 檔案，是正常行為
