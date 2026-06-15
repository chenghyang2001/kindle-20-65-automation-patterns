# Session 6 Summary — 2026-06-15

## 完成事項

### 1. 互動式 GitHub Pages 網站建立（Part 1–7 + Index）

為全書 7 個 Part 建立互動式 HTML 學習頁，部署至 GitHub Pages：

| 檔案 | 主題 | 互動元素 |
|------|------|---------|
| `docs/index.html` | 首頁（7 Part 導覽） | 統計卡、Part 卡格 × 7、學習路徑流程圖 |
| `docs/part1.html` | 設計基礎 | Context 三層視覺化、FrontMatter 建構器、CLAUDE.md 模組樹 |
| `docs/part2.html` | Hook 自動化 | Hook 時機卡切換、Exit Code 視覺卡、Matcher 即時 RegExp 測試器、10 Hook 卡格 |
| `docs/part3.html` | Sub-agents | 6 Agent 卡 + 共享詳情面板、模型矩陣表、反理由化紅色表、審查流水線 |
| `docs/part4.html` | CI/CD 流水線 | 三模式 tab（-p Flag / stdin / heredoc）、Auto-pilot PR 流程圖、5 CI 陷阱卡 |
| `docs/part5.html` | 資安與權限 | Deny>Ask>Allow 三層視覺、Permission 規則建構器、Secret Scanner 模擬器、安全 Checklist |
| `docs/part6.html` | 成本最佳化 | Token 計費四欄卡、成本計算機（Sonnet 4.6 定價）、模型比較表、Sub-agent 套利前後對比 |
| `docs/part7.html` | 進階工作流 | 直接自 doc/part7-interactive.html 轉移（851 行），插入頂部導航 |

**技術特點**：

- 純 vanilla JS + CSS，零外部依賴，GitHub Pages 直接托管
- 共享 CSS 變數（`--bg`, `--blue`, `--green` 等 16 個）保持視覺一致性
- 頂部固定導航（`.top-nav`，dark 背景 `var(--text)`），active 連結高亮

### 2. GitHub Actions 部署工作流（Writer+QA 鐵律走完）

- 建立 `.github/workflows/deploy-pages.yml`（SHA256: `573c01a...`，43 行）
- 觸發：push to main 且 `paths: docs/**`
- 步驟：checkout v4 → configure-pages v5 → upload-pages-artifact v3 → deploy-pages v4
- 遇到 GitHub Pages race condition：先啟用 Pages 後才推 workflow，第一次部署失敗；用 `gh api ... --method PUT --field 'build_type=workflow'` 切換 Actions 模式後再 push 一次成功
- 網站已上線：`https://chenghyang2001.github.io/kindle-20-65-automation-patterns/`

### 3. mermaid-viewer 新增 "65 Patterns 互動" Tab

在 `~/workspace/mermaid-viewer/index.html` 新增第 11 個 tab（索引 10）：

- Tab 標籤：「65 Patterns 互動」，badge 顯示「7」（7 個 Part）
- 顏色：綠色主題（`#14532d` 背景 + `#4ade80` 邊框），與其他藍色 tab 視覺區隔
- 使用延遲載入（`data-src` 模式），點擊時才填入 src
- 目標 URL：`https://chenghyang2001.github.io/kindle-20-65-automation-patterns/`
- commit：`996b0d5`，mermaid-viewer repo 已 push

---

## 關鍵技術筆記

### GitHub Pages 部署陷阱（Race Condition）

- **症狀**：先建立 `deploy-pages.yml` 並 push → 工作流跑起來但 Pages 還是 `build_type: legacy` → 報錯 `Get Pages site failed`
- **根因**：GitHub Actions Deploy Pages action 需要 repo 先設為 workflow 模式才能執行
- **修法**：`gh api repos/OWNER/REPO/pages --method PUT --field 'build_type=workflow'` → 再推一個小改動觸發重跑
- **心得**：「先切模式，再推 workflow 檔」的順序很重要

### `.yml` 走 Writer+QA 鐵律

- `.yml` 在觸發清單內 → 主 Claude 不可直接 Write
- 走 code-writer agent（寫檔 + 產 Manifest with SHA256）→ code-qa agent（5 層驗證：exists / hash / syntax / dynamic / lint），OVERALL: PASS 後使用
- `--no-verify` 不可用，鐵律保障 CI 關鍵配置品質

### mermaid-viewer Tab 延遲載入模式

- pane-0（Mermaid 書）直接填 `src="..."` 預載入
- pane-1 以後用 `data-src`，`switchTab()` 觸發時才把 `data-src` 搬到 `src` 並移除 `data-src` attribute
- 好處：10+ 個 site 同時以 iframe 載入會拖慢首頁；延遲載入避免不必要的網路請求

### part7.html 生成策略（不重寫，Python 腳本插入）

- `doc/part7-interactive.html` 已有 851 行完整互動內容
- 用 Python 腳本讀入 → 插入 `.top-nav` CSS + HTML → 輸出到 `docs/part7.html`
- 避免重新手寫 851 行造成錯誤；腳本執行後輸出 39,662 bytes

---

## 產出檔案

| 檔案 / Repo | 說明 | Commit |
|-----------|------|--------|
| `docs/index.html` | 首頁 | `4309d0b` |
| `docs/part1.html`–`part7.html` | 7 Part 互動頁 | `4309d0b` |
| `.github/workflows/deploy-pages.yml` | GitHub Pages Actions 工作流 | `4309d0b` |
| `docs/index.html`（footer 小修） | 觸發 Pages 重部署 | `1124cc7` |
| `mermaid-viewer/index.html` | 新增 65 Patterns 互動 tab | `996b0d5`（mermaid-viewer repo）|

---

## HANDOFF（下次 session 優先處理）

### 立即行動

- [ ] 驗證 GitHub Pages 網站各頁面互動功能正常（特別是 part7.html 的 JS 切換）
- [ ] （選做）為整本書建立最終 NotebookLM notebook，整合 Part 1–7 所有演練記錄
- [ ] MEMORY.md 中標記的 `secret-scanner.sh` PRIVKEY bug 仍維持「不修」狀態，注意不要被誤觸

### 進行中（需接續）

- 全書互動演練已全部完成（Part 1–7）
- GitHub Pages 網站已上線，mermaid-viewer 已整合，無待接續的緊急工作

### 注意事項

- `docs/part7.html` 是從 `doc/part7-interactive.html` 用 Python 腳本生成的，若原檔有改動需重新生成
- `deploy-pages.yml` 只在 `docs/**` 有改動時觸發，非 docs 的 commit 不會重新部署
- mermaid-viewer repo 已有 11 個 tab（索引 0–10），下次新增要記得更新 `ACTIVE_CLASS` 陣列長度
- GitHub Pages 首次切 workflow 模式有 race condition，記得先 `gh api ... build_type=workflow` 再 push
