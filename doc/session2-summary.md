# Session 2 摘要（2026-06-12）

## 主軸：全書 7 章「字稿 → 實跑 demo → 教學文件 → NotebookLM 多媒體」知識轉化

把《Claude Code in Production》7 章的 NotebookLM 語音字稿，逐章配合 `code/partN-*/`
範例碼做**實際執行的 demo**，再寫成教學文件，並各自建 NotebookLM notebook 生成
語音/影片/簡報三產物。

## 各章完成度

| 章 | 主題 | 教學對象 | Demo 重點 | commit | Notebook ID |
|----|------|---------|----------|--------|-------------|
| ch1 | 設計基礎 | 職場新鮮人 | monorepo 向上遍歷、!`command` 動態注入 | `4af24c6` | `8005576d-...` |
| ch2 | Hooks | 高中生 | 8 個 hook 全測（exit code/MCP guard）| `2b3810c` | `4bd98094-...` |
| ch3 | Sub-agents | 職場新鮮人 | 派真實代理審查、TC-01~03 TDD | `d1aac6a` | `6dc128a2-...` |
| ch4 | CI/CD | 職場新鮮人 | 真實 headless `claude -p` JSON 輸出 | `e1708db` | `0343616d-...` |
| ch5 | 權限安全 | 職場新鮮人 | secret-scanner 親身攔截、空格生死差異 | `49d67c1` | `015bb142-...` |
| ch6 | 成本最佳化 | 職場新鮮人 | 4 項成本量化（input 81%/快取 88%/套利 73%）| `9ea3ea3` | `59a28e3a-...` |
| ch7 | 進階工作流 | 職場新鮮人 | 自我進化迴圈、cascade worktree、confidence-check | `10b33f1` | `86231ab8-...` |

## 衍生修復（三 agent 流程）

- `db96572`：修 `save-session-state.sh` 的 `${INPUT:-{}}` jq 參數展開 bug（ch2 demo 抓到）
- `1b34c99`：新增 `.gitattributes` 強制 `.sh` 用 LF（跨平台修復，shellcheck SC1017 全消）

## Demo 過程的「活教材」彩蛋

- **ch2**：我自己環境的 PreToolUse:Bash hook 真的攔截了測試指令的 `rm -rf /`/`DROP TABLE`
- **ch3**：物理防禦 demo 中，registry security-reviewer 被「writer-qa 鐵律 hook」擋下（非工具白名單，殊途同歸 = 深度防禦）
- **ch4**：headless `claude -p` 一次花 $1.54（Opus 1M）→ 順帶印證 ch6「殺雞用牛刀」
- **ch5**：我環境真的部署了範例的 `secret-scanner.sh`，寫含 AWS key 的 fixture 時當場攔截我

## 抓到但未修的範例 bug

- `part5-security/hooks/secret-scanner.sh`：第 7 個 PRIVKEY pattern 以 `-----` 開頭，
  grep 誤判為選項（`grep: unknown option`）。使用者指示**不修**。

## 技術踩坑

- NotebookLM 本機 auth（MCP + CLI 兩層）過期 → 使用者跑 `nlm-login.sh` 重新登入後 CLI 復活
- `notebooklm download` 把 `/c/...` 路徑錯轉成 `\c\...` 沒寫檔 → 使用者後續指示不下載，只線上看
- NLM video 生成最慢（15-18 輪 ≈ 15-18 分鐘），audio/slide 約 9-13 輪

## NotebookLM 產物狀態（18 個）

- 已完成 12 個：ch2/ch3/ch4/ch6/ch7 各 3
- 生成中 6 個：ch1（`bt4xl242s`）、ch5（`buwvgl4nd`）各 3，背景輪詢中

## 待辦

- [ ] ch1/ch5 各 3 個 studio 完成後回報（不下載，只線上看）
- [ ] 考慮 session jsonl 已達 3MB，下次開新 session
