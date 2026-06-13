# 第 6 課演練記錄：MCP 轉 Skill 削減開銷

> 對應文件：
>
> - `code-中文/part6-cost/mcp-to-skill/README.md`
> - `code-中文/part6-cost/mcp-to-skill/SKILL.md`
> - `code-中文/part6-cost/settings/minimal-mcp.json`

## 課程目標

理解 MCP 工具的隱形成本：每次請求都強制附上所有 MCP 工具的 JSON schema，
就算只是改個 CSS 顏色也一樣。
學會判斷哪些 MCP 應該換成 Skill，哪些必須保留，
並用 `permissions.deny` 關掉不需要的 MCP。

## 工作目錄

`code-中文/part6-cost/demo/06-MCP轉Skill/`

---

## Step 1：理解 MCP 的隱形 Token 成本

### 概念說明

每次你和 Claude Code 對話，系統會把「所有已啟用的 MCP 工具的 JSON schema」附在請求裡。

```
一次對話請求的 Input token 組成：
  CLAUDE.md                 ≈ 2,000 token
  對話歷史                  ≈ 10,000 token
  你的問題                  ≈ 100 token
  MCP 工具說明（23 個工具）  ≈ 8,000 token   ← 你可能完全沒意識到
  ────────────────────────────────────────
  總計                      ≈ 20,100 token
```

### 計算練習

假設你有 23 個 MCP 工具（包含 Playwright、Magic UI 等），
每個工具的 JSON schema 平均 350 token，
你每天和 Claude Code 對話 100 輪：

1. MCP schema 每天消耗多少 token？

   答：

2. 一個月（30 天）消耗多少 token？

   答：

3. 如果你用 Sonnet（$3/M token），MCP schema 每月花多少錢？

   答：

4. 如果你有 10 個 MCP 根本不常用，把它們 deny 掉後能省多少？

   答：

### 實際結果

（演練時填入）

---

## Step 2：閱讀 MCP 轉 Skill 的判斷標準

### 閱讀任務

打開 `mcp-to-skill/README.md`，填入判斷表格：

**什麼時候該保留 MCP**（填入 README 中的 4 個條件）：

| # | 條件 |
|---|------|
| 1 | |
| 2 | |
| 3 | |
| 4 | |

**什麼時候該改用 Skill**（填入 README 中的 4 個條件）：

| # | 條件 |
|---|------|
| 1 | |
| 2 | |
| 3 | |
| 4 | |

### 情境判斷

對於以下工具，你會選擇「保留 MCP」還是「改用 Skill」？

| 工具描述 | 你的選擇 | 原因 |
|---------|---------|------|
| 抓取 React 官方文件的某個頁面 | | |
| 管理 Slack workspace（需要 OAuth + 訊息歷史） | | |
| 截圖驗證 UI（需要 Chromium + session） | | |
| 用 curl 取得某個 REST API 的公開資料 | | |
| 把 Markdown 轉成 HTML（一行 CLI 指令）| | |

### 實際結果

（演練時填入）

---

## Step 3：閱讀 fetch-docs Skill，理解轉換成果

### 閱讀任務

打開 `mcp-to-skill/SKILL.md`，回答：

1. 這個 Skill 的 `allowed-tools` 限制了什麼？為什麼要限制？

   答：

2. 這個 Skill 取代了什麼樣的 MCP server？

   答：

3. 「優先抓取官方文件，而非依賴訓練知識」這條注意事項的背後邏輯是什麼？

   答：

### 比較成本

| 方式 | 每次請求的 token 開銷 |
|------|---------------------|
| 架一個 fetch-docs MCP server | schema ≈ 500 token × 每次請求 |
| 換成 SKILL.md | 只在呼叫 /fetch-docs 時載入，其餘請求 0 overhead |

### 實際結果

（演練時填入）

---

## Step 4：使用 minimal-mcp.json 關掉不需要的 MCP

### 閱讀任務

打開 `settings/minimal-mcp.json`，回答：

1. 這個設定 deny 了哪兩個 MCP 的所有工具？

   答：

2. `mcp__playwright__*` 中的 `*` 是什麼意思？

   答：

3. 你如何在自己的 `~/.claude/settings.json` 加入這個設定？

   （寫出合併後的 JSON 結構）

   ```json
   {
     （填入）
   }
   ```

### 操作步驟

確認你目前有哪些 MCP 工具（若有的話）：

```bash
# 查看 settings.json 中的 mcpServers 設定
cat ~/.claude/settings.json | python -c "
import json, sys
data = json.load(sys.stdin)
servers = data.get('mcpServers', {})
print(f'已安裝的 MCP server：{len(servers)} 個')
for name in servers:
    print(f'  - {name}')
"
```

回答：你有幾個 MCP server？哪些是真正常用的？

答：

### 實際結果

（演練時填入）

---

## 本課重點

```
MCP 的隱形成本公式：
  每次請求的 MCP overhead = 工具數量 × 每個工具 schema 大小
  23 個工具 × 350 token = 8,050 token / 每次請求

  100 輪/天 × 8,050 token × 30 天 = 24,150,000 token/月
  用 Sonnet 計算 = 約 $72/月（只是 MCP schema）

三種削減方式：
  1. deny 不常用的 MCP（立即生效，最簡單）
  2. 把簡單的 MCP 換成 Skill（長期最優解）
  3. 只在需要時動態啟用特定 MCP（高階）

判斷原則：
  需要狀態 / OAuth / 串流 → 保留 MCP
  只是 CLI 指令 / 公開文件 / 簡單處理 → 換成 Skill
```

| 操作 | 難度 | 效果 |
|------|------|------|
| deny 不用的 MCP | ★☆☆ | 立即省 X × 350 token/次 |
| MCP 改寫成 Skill | ★★☆ | 長期：只有呼叫時才有開銷 |
| 重新設計 MCP 架構 | ★★★★ | 最大化節省，但需要時間 |
