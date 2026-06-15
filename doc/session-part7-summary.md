# Session Part 7 摘要：進階工作流（7 課全部完成）

**日期**：2026-06-15
**Session 主題**：Part 7 — 進階工作流（Plugin 開發）互動演練（第 6、7 課）

---

## 本次完成

本 session 完成了 Part 7 最後兩課，至此**全書 7 Part × 7 課 = 49 課互動演練全部結束**。

### Part 7 第 6 課：觀察 Hook + 自我進化

**核心概念**：PostToolUse Hook 把每次工具呼叫靜默寫入 JSONL，再用 `/analyze-patterns` Skill 找出重複模式。

| 元件 | 說明 |
|------|------|
| `observe-pattern.sh` | 12 行腳本，`cat` 讀 stdin → `jq` 解析 `tool_name`/`tool_input` → 追加至 `patterns.jsonl` |
| JSONL 路徑 | `${HOME}/.claude/logs/patterns.jsonl` |
| 信心分數公式 | `（出現次數 / 總操作數）× 100` |
| 門檻 | ≥70% = Skill 候選、40-70% = 持續觀察、<40% = 略過 |
| 本質 | 部落知識外顯化——把隱性工作習慣用資料自動提煉成可共享 Skill |

Commit：`61d7e6a`

### Part 7 第 7 課：Plugin 封裝

**核心概念**：把 Skills + Hooks 打包成有名稱、有版本的可安裝單元，讓個人工作流升格為團隊標準配置。

| 元件 | 說明 |
|------|------|
| `.claude-plugin/plugin.json` | Plugin 身分證（name / version / author / license） |
| `hooks/hooks.json` | 宣告 PostToolUse + matcher (`Write\|Edit`) + 腳本路徑 |
| `${CLAUDE_PLUGIN_ROOT}` | 動態注入實際路徑，等同 Python `Path.home()` 的跨機器設計 |
| `install-skill.sh` | 3 參數（skill_name / repo_url / scope），SCOPE=personal → `~/.claude/skills/`，SCOPE=project → `.claude/skills/`；目標已存在則 exit 1（fail-fast 設計） |
| Semantic Versioning | Hook 行為改變 → 主版本（1.0.0 → 2.0.0），新增功能 → 次版本，Bug 修復 → 修補版本 |

Commit：`f3e5414`

---

## Part 7 全 7 課回顧

| 課次 | 主題 | 核心概念 | 難度 |
|------|------|---------|------|
| 01 | 幻覺偵測 | `hallucination-detection.md`：5 類幻覺 + AI-generated 標記策略 | ★☆☆ |
| 02 | 實作前檢查清單 | `/confidence-check`：C1–C5 五項，≥4/5 才能動手 | ★★☆ |
| 03 | 動態編排 | `/orchestrate`：bugfix/feature/refactor/security 各自流程 | ★★☆ |
| 04 | 七階段工作流 + Checkpoint | S1–S7 防失敗護欄，Checkpoint vs Git Stash 雙重保護 | ★★★ |
| 05 | 多 Agent Worktree | `cascade-start.sh`：3 worktree + Opus/Sonnet/Haiku 成本梯度 | ★★★ |
| 06 | 觀察 Hook + 自我進化 | `observe-pattern.sh` + `/analyze-patterns`：行為資料 → Skill 候選 | ★★★★ |
| 07 | Plugin 封裝 | `plugin.json` + `install-skill.sh` + `${CLAUDE_PLUGIN_ROOT}` | ★★★★★ |

---

## 全書 7 Part 演練完成總覽

| Part | 主題 | 核心技術 |
|------|------|---------|
| Part 1 | CLAUDE.md 設計基礎 | 三層結構、魔法變數、記憶系統 |
| Part 2 | Hooks 系統 | PreToolUse/PostToolUse/Stop，settings.json matcher |
| Part 3 | Sub-agents | 角色分工、worktree 隔離、cost-aware 模型選擇 |
| Part 4 | CI/CD 自動化 | GitHub Actions auto-pilot，GH_PAT 觸發限制 |
| Part 5 | 權限與安全 | `--permission-mode plan`，secret-scanner.sh |
| Part 6 | 成本最佳化 | Haiku/Sonnet/Opus 矩陣、Prompt 快取、MCP → Skill |
| Part 7 | 進階工作流 | Plugin 生態系、自我進化迴路、七階段 + Worktree + 編排 |

---

## 技術踩坑記錄

- **Write 工具「File has not been read yet」錯誤**：hook 系統在 Read L6 STEP-LOG.md 後，自動觸發讀其他 STEP-LOG 導致 file read tracking 狀態被干擾。解法：Write 前再 Read 一次目標檔案。

---

## 下一步

- [ ] 全書互動演練完成後，可為 7 個 Part 各自建立 NotebookLM notebook，生成語音摘要（完整知識轉化流水線）
- [ ] `part5-security/hooks/secret-scanner.sh` PRIVKEY pattern 以 `-----` 開頭誤被 grep 當選項的 bug（使用者指示不修）
- [ ] auto-fix-pr.sh：git push 後應還原不含 token 的 remote URL，防 token 洩漏於 `git remote -v`
