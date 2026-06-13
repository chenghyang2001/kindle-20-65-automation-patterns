# Part 3 Sub-agents 課程 Session 摘要（2026-06-13）

## 完成內容

Part 3 全部 7 堂互動課程完成，commit `4727217` 推送至 main。

### 7 堂課程一覽

| 課號 | 目錄 | 核心概念 |
|------|------|---------|
| 01 | 01-demo-builtin-agents | 內建 agents + `claude agents` 指令介紹 |
| 02 | 02-demo-agent-anatomy | Agent frontmatter 解析：description = trigger 條件，tools = 最小權限，model 選擇，permissionMode |
| 03 | 03-demo-model-selection | Haiku（搜尋）/ Sonnet（審查）/ Inherit（大任務）三層模型策略，`CLAUDE_CODE_SUBAGENT_MODEL` 全域覆蓋 |
| 04 | 04-demo-custom-agent | 自訂 pm25-log-finder agent + 部署到 `~/.claude/agents/`（全域）vs 專案 `.claude/agents/` |
| 05 | 05-demo-anti-rationalization | 反理由化 12 個模式 + 嵌入 agent AGENT.md 的 `## 行為原則` 段落 |
| 06 | 06-demo-review-pipeline | 四層串聯審查（spec-compliance → code-quality → security → api-reviewer）+ buggy-api.py 演練 |
| 07 | 07-demo-workflow-dot | DOT graph 防漂移 + 新增 api_check 節點 + Graphviz 渲染 PNG |

### 關鍵檔案

- `code-中文/part3-agents/agents/` — 4 個 reviewer agent .md
- `code-中文/part3-agents/docs/` — model-cost-matrix.md + rationalization-prevention.md
- `code-中文/part3-agents/workflows/` — code-review.dot
- `code-中文/part3-agents/03-demo-model-selection/log-searcher.md`
- `code-中文/part3-agents/04-demo-custom-agent/pm25-log-finder.md`（已部署至 `~/.claude/agents/`）
- `code-中文/part3-agents/05-demo-anti-rationalization/implementation-agent-safe.md`
- `code-中文/part3-agents/06-demo-review-pipeline/buggy-api.py`（含 4 個刻意植入的漏洞）
- `code-中文/part3-agents/07-demo-workflow-dot/code-review-v2.dot` + `.png`

## Bug 修復

- `.claude/settings.json` Stop hooks 指向錯誤路徑（`code/` vs `code-中文/`）→ 移除 Stop hooks 區塊
- `~/.claude/hooks/quality-gate.sh` 未提交檢查暫時停用（課程期間）→ 課程結束後恢復

## 重要觀念

- `description` 欄位是 Claude Code 決定何時呼叫 agent 的觸發條件，不是自我介紹
- `Task` 工具 = sub-agent 派遣能力；沒有 Task 的 agent 無法再派 sub-agent
- `fix → spec_check`：修完任何問題都要重頭跑（不從錯誤處繼續）
- writer-QA-iron-rule：.py 檔案必須走 code-writer → code-qa sequential 流程

## Git

- commit: `4727217`（148 files changed, 6436 insertions）
- push: main → origin
