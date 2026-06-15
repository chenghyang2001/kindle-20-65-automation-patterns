# 第 6 課演練記錄：MCP 轉 Skill 削減開銷

> 對應文件：`code-中文/part6-cost/mcp-to-skill/SKILL.md`

## 課程目標

理解 MCP server 的 schema overhead 隱形成本，
學會判斷何時用 Skill 取代 MCP，以 `fetch-docs` 為範例。

## 工作目錄

`code-中文/part6-cost/demo/06-MCP轉Skill/`

---

## Step 1：理解 MCP Schema Overhead 問題

### Q1：每月 schema overhead 計算

```
23 工具 × 350 token × 100 輪/天 × 30 天 = 24,150,000 token/月
換算 Sonnet 費用：24.15M × $3/M = $72.45/月
```

**這是固定成本，不管有沒有用那些 MCP 工具，每輪都付。**

### Q2：對「只寫 Python 腳本」任務的影響

settings.json 啟用 80+ 個 MCP 工具（puppeteer、notebooklm、Gmail、Google Calendar...）。
當任務只是「寫解析 CSV 的 Python 腳本」，這 80+ 個工具的 schema 全部注入，
為「用不到的工具說明書」付 token。

**MCP 的隱性成本模型：按輪計費，不按使用計費。**

---

## Step 2：SKILL.md 的解法

### Q3：`fetch-docs` Skill 取代了什麼？

> 第 33 行：「這個 skill 取代了**只為簡單文件抓取而架 MCP server** 的需求」

傳統做法：需要抓文件 → 裝 fetch-mcp 或 browser-mcp → 又多了一個 MCP server → 又多了 N 個 schema 每輪注入。

Skill 解法：不裝 MCP，改用 Bash + curl。效果一樣，但 schema overhead = 0。

### Q4：`allowed-tools: Bash(curl *), Bash(npx *)` 的成本效益

Skill 觸發時，Claude 的工具清單從完整清單縮減為只有這兩個：

| 狀態 | 可用工具 | Context 裡的 schema |
|------|---------|-------------------|
| 一般對話 | 全部工具（80+個） | 全部 schema |
| `/fetch-docs` Skill 執行中 | `Bash(curl *)`, `Bash(npx *)` | 只有 2 條規則 |

好處雙重：輸入 token 大幅縮小 + 行為更聚焦（不會誤用其他工具）

---

## Step 3：何時用 Skill 取代 MCP？

| 情境 | 用 MCP | 用 Skill |
|------|--------|---------|
| 需要持久連線（OAuth、session）| ✅ | ✗ |
| 需要即時資料（日曆、郵件）| ✅ | ✗ |
| 只是執行指令（curl、bash）| ✗ | ✅ |
| 一次性操作（抓文件、轉格式）| ✗ | ✅ |
| 使用頻率低（每月幾次）| ✗ | ✅ |

**口訣：能用 Bash 做到的，就不裝 MCP。**

---

## 本課重點

```
MCP Schema Overhead 公式：
  工具數 × schema大小(token) × 對話輪數/天 × 天數 = 月總開銷

三種削減策略：
  1. 只開必要的 MCP server（disable 不常用的）
  2. 能用 Bash 做到的改寫成 Skill
  3. 用 deny 清單封掉高 schema 但低使用率的工具
```

| 方案 | schema overhead | 維護成本 | 適合情境 |
|------|----------------|---------|---------|
| MCP server | 每輪注入全部 schema | 需要認證維護 | 需要 session/即時資料 |
| SKILL.md | 只在觸發時生效 | 只是一個 .md 檔 | 可用 Bash 完成的任務 |
