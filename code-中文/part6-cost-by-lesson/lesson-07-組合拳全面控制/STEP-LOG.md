# 第 7 課演練記錄：組合拳 — 全面成本控制

> 對應文件：
>
>
> - `code-中文/part6-cost/settings/disable-1m-context.json`
> - `code-中文/part6-cost/settings/effort-level.json`
> - `code-中文/part6-cost/settings/minimal-mcp.json`
> - `code-中文/part6-cost/settings/model-matrix.json`
> - `code-中文/part6-cost/demo/07-組合拳全面控制/settings.json`（整合版本）

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

   答：**防止 Claude Code 在對話 context 變長時自動切換到 1M context 視窗模型。**
   沒有這個設定時，當 context 逼近上限，Claude Code 會自動升級使用 1M token 容量的模型版本。
   1M context 模型的費率更高，且通常不需要這麼大的視窗，純粹是意外升費。

2. 啟用後對工作流程有什麼影響？（強制做什麼？）

   答：**強制使用者執行 `/compact` 壓縮 context，而不是依賴模型自動升級。**
   結果是省錢（保持在便宜模型）且 context 更乾淨（壓縮後推理品質更穩定）。

**effort-level.json**

```json
{ "effortLevel": "medium" }
```

1. `effortLevel` 有哪些可能的值？（猜測或查文件）

   答：`low`、`medium`、`high`（三檔，對應 Claude 的推理深度）

2. 設為 `medium` 和 `high` 對 token 消耗有什麼差異？

   答：

   | 等級 | 行為 | Output token 消耗 |
   |------|------|-----------------|
   | `high`（預設）| 深度思考、多角度分析、詳細回應 | 多 |
   | `medium` | 足夠的推理、簡潔回應 | 省 20–40% |

   對日常任務（debug、寫腳本、查資料）medium 完全夠用。

**minimal-mcp.json**（第 6 課已閱讀，這裡快速複習）

1. deny 的兩個 MCP 每月能省多少 token？（用第 6 課的計算方式估算）

   答：

   ```
   playwright：假設 25 個工具 × 350 token = 8,750 token/輪
   magic：假設 15 個工具 × 350 token = 5,250 token/輪
   合計：14,000 token/輪 × 100 輪/天 × 30 天 = 42,000,000 token/月
   Sonnet 費用：42M × $3/M = $126/月（這兩個 MCP 不用的話就省了）
   ```

**model-matrix.json**

1. 打開檔案，它設定了什麼？

   答：`{ "model": "sonnet" }` — 鎖定主模型為 Sonnet，
   防止 Claude Code 因 inherit 或其他原因誤用 Opus（費用 5× 差距）。

### 實際結果

4 個設定片段各自鎖定一個成本維度：

- `model-matrix.json` → 主模型單價控制
- `effort-level.json` → 輸出 token 量控制
- `disable-1m-context.json` → context 視窗大小控制
- `minimal-mcp.json` → schema overhead 控制

---

## Step 2：設計你的「成本控制 Profile」

### 完整整合 settings.json（已儲存至 `settings.json`）

```json
{
  "model": "sonnet",
  "effortLevel": "medium",
  "env": {
    "CLAUDE_CODE_SUBAGENT_MODEL": "haiku",
    "CLAUDE_CODE_DISABLE_1M_CONTEXT": "1"
  },
  "permissions": {
    "deny": ["mcp__playwright__*", "mcp__magic__*"]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/suggest-compact.sh"
          }
        ]
      }
    ]
  }
}
```

### 決策說明

| 設定 | 選擇 | 理由 | 代價 |
|------|------|------|------|
| `model` | sonnet | 禁止意外升 Opus（5×費用）| 無：Opus 只在手動指定時才用 |
| `CLAUDE_CODE_SUBAGENT_MODEL` | haiku | sub-agent 探索省 73% 費用 | Haiku 複雜推理能力有限 |
| `CLAUDE_CODE_DISABLE_1M_CONTEXT` | 1 | 阻止自動升 1M 模型 | 對話長時需手動 /compact |
| `effortLevel` | medium | 省 20-40% output token | 詳細分析任務時稍差一點 |
| deny playwright | 是 | 砍掉 ~25 個 schema × 每輪 | 需要瀏覽器操作時無 MCP，要用 Skill |
| deny magic | 是 | 砍掉 ~15 個 schema × 每輪 | 需要 magic 功能時要另開 |
| suggest-compact.sh | 是 | 自動化提醒 /compact | 無，只是提醒不中斷 |

### 實際結果

6 個策略整合成一個 settings.json，每個策略作用於不同的 token 類型，不互相抵消而是**疊加省錢**：

```
Input token 單價  ← model: sonnet（不用 Opus）
Output token 量   ← effortLevel: medium
Sub-agent 費率    ← CLAUDE_CODE_SUBAGENT_MODEL: haiku
Context 大小      ← DISABLE_1M_CONTEXT: 1 → 強制 /compact
Schema overhead   ← deny playwright + magic
壓縮觸發          ← suggest-compact.sh hook
```

---

## Step 3：七堂課策略對比總覽

### 計算總節省量

| 策略（課次） | 節省機制 | 估算節省 token/月 |
|------------|---------|-----------------|
| 1. 理解帳單 | 知道錢花哪裡，行為改變 | 無法量化，但是基礎 |
| 2. 模型降階 | sub-agent 從 Sonnet → Haiku | 依使用量，每個 agent call 省 73% |
| 3. Prompt 快取 | CLAUDE.md 分層，命中率提升 | 命中時省 90% input（快取折扣） |
| 4. 壓縮 Hook | 每 50 次提醒 /compact | 壓縮後省 50-80% 後續 input token |
| 5. Sub-agent 套利 | Haiku 讀大量檔案，主對話不承擔 | 探索階段省 73%，整體省 40–60% |
| 6. MCP deny | 砍掉 playwright + magic | ~42M token/月 = ~$126/月（Sonnet 計） |
| 7. 護欄設定 | 禁 1M context，effortLevel medium | 防意外超標 + output 省 20–40% |

### 思考問題

1. 以上七個策略，哪個實作最簡單且效果最立竿見影？

   答：**第 6 課：MCP deny**。
   只要在 settings.json 加兩行 deny，立刻生效，不需要寫任何程式碼，
   且效果是每輪固定省 schema overhead，沒有任何條件限制。

2. 哪個策略需要最多設計工作，但長期效益最高？

   答：**第 3 課：Prompt 快取設計**。
   需要仔細分析哪些內容「穩定」（放 CLAUDE.md 上層）、哪些「動態」（放底部），
   還要定期調整結構讓快取命中率維持高水準。
   但命中快取時省 90% input，是所有策略中折扣最大的。

3. 「Token 經濟學複雜度」作為一個新的工程指標，你會如何向同事解釋它的重要性？

   答：
   > 「以前我們說程式碼要有「時間複雜度意識」，O(n²) 和 O(n log n) 的差異。
   > 現在用 AI 工具也一樣——同樣一個任務，用 4 行 CLAUDE.md 分層或 1 行 deny，
   > 可能差了 10 倍的 token 消耗。Token 不只是錢，context 效率直接影響 AI 推理品質。
   > 學會 TEC（Token Economics Complexity）設計，就像學會演算法分析——
   > 這是 AI 原生時代的基礎工程素養。」

### 實際結果

七課縱覽：每課都針對帳單的一個欄位（input / output / schema / cache）設計精準的優化。
組合拳讓各維度同時受控，總節省效果遠超任何單一策略。

---

## Step 4：驗證你的 Profile 設定

### 操作步驟

把 Step 2 的 settings 整合進 `~/.claude/settings.json`（PostToolUse suggest-compact.sh 已在第 4 課加入），
其餘設定（effortLevel / DISABLE_1M_CONTEXT / deny）按需合併。

### 驗證指令

```bash
PYTHONUTF8=1 python -c "
import json, sys
with open('$(cygpath -w ~/.claude/settings.json)', encoding='utf-8') as f:
    data = json.load(f)
print('effortLevel:', data.get('effortLevel', '未設定'))
env = data.get('env', {})
print('SUBAGENT_MODEL:', env.get('CLAUDE_CODE_SUBAGENT_MODEL', '未設定'))
print('DISABLE_1M:', env.get('CLAUDE_CODE_DISABLE_1M_CONTEXT', '未設定'))
deny = data.get('permissions', {}).get('deny', [])
print('deny 清單:', deny[:5])
"
```

### 實際結果

全域 `~/.claude/settings.json` 已在第 4 課加入 suggest-compact.sh hook。
本課的 `settings.json` 作為**示範 Profile**保存在 `demo/07-組合拳全面控制/settings.json`，
供讀者照此格式合併到自己的全域設定。

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
