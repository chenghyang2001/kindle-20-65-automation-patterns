# 第 7 課演練記錄：組合拳 — 全面成本控制

> 對應文件：
>
>
> - `code-中文/part6-cost/settings/disable-1m-context.json`
> - `code-中文/part6-cost/settings/effort-level.json`
> - `code-中文/part6-cost/settings/minimal-mcp.json`
> - `code-中文/part6-cost/settings/model-matrix.json`

## 課程目標

把前六課學到的所有策略組合成一套完整的成本控制設定，
理解 `effortLevel`、`CLAUDE_CODE_DISABLE_1M_CONTEXT` 等護欄的作用，
設計並寫出你自己的成本最佳化 settings.json profile。

## 工作目錄

`code-中文/part6-cost/demo/07-組合拳全面控制/`

---

## Step 1：閱讀四個 settings 檔案，理解每個護欄

### 閱讀任務

依序打開四個 settings 檔案，填入說明：

**disable-1m-context.json**

```json
{ "env": { "CLAUDE_CODE_DISABLE_1M_CONTEXT": "1" } }
```

1. 這個環境變數的作用是什麼？（沒有它，Claude Code 在什麼情況下會升費率？）

   答：

2. 啟用後對工作流程有什麼影響？（強制做什麼？）

   答：

**effort-level.json**

```json
{ "effortLevel": "medium" }
```
1
1. `effortLevel` 有哪些可能的值？（猜測或查文件）

   答：
2
2. 設為 `medium` 和 `high` 對 token 消耗有什麼差異？

   答：

**minimal-mcp.json**（第 6 課已閱讀，這裡快速複習）
1
1. deny 的兩個 MCP 每月能省多少 token？（用第 6 課的計算方式估算）

   答：

**model-matrix.json**
1
1. 打開檔案，它設定了什麼？

   答：

### 實際結果

（演練時填入）

---

## Step 2：設計你的「成本控制 Profile」

### 任務

把前六課學到的所有策略整合，設計一個完整的 settings.json。

參考框架如下，把你認為應該加入的設定填進去：

```json
{
  "設定類型": "說明你的理由",

  // 模型控制（第 2 課）
  "env": {
    "CLAUDE_CODE_SUBAGENT_MODEL": "（填入）",
    "CLAUDE_CODE_DISABLE_1M_CONTEXT": "（填入）"
  },

  // 努力等級（第 7 課新學）
  "effortLevel": "（填入：low / medium / high）",

  // MCP 權限（第 6 課）
  "permissions": {
    "deny": [
      （填入你想 deny 的 MCP）
    ]
  },

  // Hook（第 4 課）
  "hooks": {
    "PostToolUse": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "（填入）"
          }
        ]
      }
    ]
  }
}
```

### 決策說明

填完後，對每個設定說明你的取捨：

| 設定 | 你的選擇 | 理由 | 代價 |
|------|---------|------|------|
| `CLAUDE_CODE_SUBAGENT_MODEL` | | | |
| `CLAUDE_CODE_DISABLE_1M_CONTEXT` | | | |
| `effortLevel` | | | |
| deny 的 MCP | | | |

### 實際結果

（演練時填入）

---

## Step 3：七堂課策略對比總覽

### 計算總節省量

假設你把所有策略都落地，估算每月節省的 token：

| 策略（課次） | 節省機制 | 估算節省 token/月 |
|------------|---------|-----------------|
| 1. 理解帳單 | 知道錢花哪裡，行為改變 | 無法量化，但是基礎 |
| 2. 模型降階 | sub-agent 從 Sonnet → Haiku | ？（依你的使用量） |
| 3. Prompt 快取 | CLAUDE.md 分層，命中率提升 | ？（依快取命中次數） |
| 4. 壓縮 Hook | 每 50 次提醒 /compact | ？（依壓縮頻率） |
| 5. Sub-agent 套利 | Haiku 讀大量檔案，主對話不承擔 | ？（依搜尋任務量） |
| 6. MCP deny | 砍掉 10 個不用的 MCP | 10 × 350 × 100輪/天 × 30天 = 10,500,000 |
| 7. 護欄設定 | 禁 1M context，強制壓縮習慣 | ？（防止意外超標） |

### 思考問題

1. 以上七個策略，哪個實作最簡單且效果最立竿見影？

   答：

2. 哪個策略需要最多設計工作，但長期效益最高？

   答：

3. 「Token 經濟學複雜度」作為一個新的工程指標，你會如何向同事解釋它的重要性？

   答：

### 實際結果

（演練時填入）

---

## Step 4：驗證你的 Profile 設定

### 操作步驟

1. 把你在 Step 2 設計的 settings 合併進 `~/.claude/settings.json`
2. 重啟 Claude Code session
3. 執行一個探索任務，觀察：
   - sub-agent 用的是哪個模型？
   - MCP 工具清單是否少了 deny 的那些？
   - 工具呼叫到 50 次時 Hook 有沒有提醒？

```bash
# 驗證設定是否生效
cat ~/.claude/settings.json | python -c "
import json, sys
data = json.load(sys.stdin)
print('effortLevel:', data.get('effortLevel', '未設定'))
env = data.get('env', {})
print('SUBAGENT_MODEL:', env.get('CLAUDE_CODE_SUBAGENT_MODEL', '未設定'))
print('DISABLE_1M:', env.get('CLAUDE_CODE_DISABLE_1M_CONTEXT', '未設定'))
deny = data.get('permissions', {}).get('deny', [])
print('deny 清單:', deny)
"
```

### 實際結果

（演練時填入）

---

## 七堂課總結

| 課次 | 主題 | 核心工具 | 節省類型 | 難度 |
|------|------|---------|---------|------|
| 01 | 看懂 Token 帳單 | `--output-format json` | 建立意識 | ★☆☆ |
| 02 | 模型選擇矩陣 | `model: haiku` frontmatter | Input 單價↓ | ★☆☆ |
| 03 | Prompt 快取設計 | CLAUDE.md 分層結構 | 快取折扣 | ★★☆ |
| 04 | 成本警示 Hook | `suggest-compact.sh` | 避免失控 | ★★☆ |
| 05 | Sub-agent 套利 | Haiku agent + 隔離 context | Input 量↓ | ★★★ |
| 06 | MCP 轉 Skill | `permissions.deny` + SKILL.md | Schema overhead↓ | ★★★ |
| 07 | 組合拳全面控制 | settings.json profile | 系統化 | ★★★★ |

```
最終結論：
Token Economics Complexity（TEC）= 以最少 token 消耗引導 AI 產出最高品質結果

這不只是省錢，而是：
  → 讓主對話 context 保持乾淨，AI 的推理品質更穩定
  → 讓昂貴的模型只做昂貴的事，便宜的模型承擔機械性工作
  → 讓整個系統可持續運行，而不是 token 爆炸後什麼都做不了

未來的頂尖工程師，會把 TEC 列入架構設計的第一考量。
```
