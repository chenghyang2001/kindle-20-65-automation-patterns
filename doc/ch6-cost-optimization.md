# 第6章 Cost Engineering — 把 AI 寫程式帳單打一折

> Claude Code in Production | Yosuke Morikawa | Patterns 58–61

---

## 章節概覽

Claude Code 的成本有 4 個主要驅動因素：
**CLAUDE.md 大小 × 工具呼叫次數 × 模型選擇 × MCP server 數量**。
本章用數字說話，給出可立即執行的降本策略。

---

## 核心模式

### Pattern 58：Prompt Cache 設計

**CLAUDE.md 放對位置 = 直接少付 60-80% 的 input token 費用。**

```markdown
<!-- CLAUDE.md 推薦佈局（cache 最大化版本）-->

## 穩定區（頂部，不要動）
- 專案概述（1 段話）
- 技術棧（清單）
- 編碼規範（清單）
- 固定參考文件（@import 連結）

## 揮發區（底部，每天更新）
- 當前工作狀態
- 最近變更
- TODO 清單
```

**為什麼：** Anthropic prompt cache TTL 5 分鐘。頂部不變 → 每次對話都命中 cache → `cache_read_input_tokens` 大量累積 → 成本大降。

```bash
# 驗證 cache 效果
claude -p "test" --output-format json | jq '.usage'
# {
#   "input_tokens": 450,               ← 本次新增 token
#   "cache_read_input_tokens": 8900,   ← 從 cache 讀，幾乎免費
#   "cache_creation_input_tokens": 0   ← 建立 cache 的一次性費用
# }
```

---

### Pattern 59：MCP → Skill 遷移

**問題：** 每個 MCP server 是一個常駐 process，還沒做任何事就消耗 context。

**解法：** 簡單用途的 MCP → 改寫為 Skill（一個 .md 檔案）

| 面向 | MCP Server | Skill |
|------|-----------|-------|
| Setup | 需要 server process | 只需 .md 檔 |
| Context 佔用 | 工具描述都進 context | 只在被呼叫時佔 context |
| 維護 | 需要持續更新 | 自包含 |
| 適合 | 複雜 stateful 操作 | 單一 CLI 指令 / 公開文件查詢 |

**保留 MCP 的時機：** 需要狀態、OAuth 認證、streaming 大量資料、多專案共用。

**改成 Skill 的時機：** 只跑一個 CLI 指令、只抓公開文件、不需 server overhead。

---

### Pattern 60：模型選擇矩陣（成本視角）

```json
// model-matrix.json
{
  "taskModels": {
    "exploration":  "haiku",    // 探索、搜尋、讀檔 → 最便宜
    "review":       "haiku",    // 格式檢查、Pattern matching
    "implementation": "sonnet", // Bug 修復、功能實作 → 平衡
    "security_audit": "sonnet", // 需要高準確率
    "architecture": "sonnet",   // 複雜推理
    "main_chat":    "inherit"   // 跟使用者設定一致
  }
}
```

```bash
# effort-level.json — 用任務難度控制模型
{
  "defaultModel": "haiku",
  "effortLevels": {
    "low": "haiku",
    "medium": "sonnet",
    "high": "opus"
  }
}
```

---

### Pattern 61：成本監控 + Compact 觸發

#### 成本估算腳本

```bash
# estimate-cost.sh
TRANSCRIPT=${1:?"Usage: estimate-cost.sh <transcript.jsonl>"}
INPUT=$(grep -o '"input_tokens":[0-9]*' "$TRANSCRIPT" | awk -F: '{s+=$2} END {print s}')
OUTPUT=$(grep -o '"output_tokens":[0-9]*' "$TRANSCRIPT" | awk -F: '{s+=$2} END {print s}')

INPUT_COST=$(echo "scale=4; $INPUT * 3 / 1000000" | bc)     # Sonnet: $3/M
OUTPUT_COST=$(echo "scale=4; $OUTPUT * 15 / 1000000" | bc)  # Sonnet: $15/M
echo "Total: \$(echo "scale=4; $INPUT_COST + $OUTPUT_COST" | bc)"
```

#### Compact 觸發 Hook

```bash
# suggest-compact.sh（Stop Hook）
TOOL_COUNT=$(grep -c '"type":"tool_use"' "$TRANSCRIPT" 2>/dev/null || echo 0)

if [[ "$TOOL_COUNT" -gt 0 && $(( TOOL_COUNT % 50 )) -eq 0 ]]; then
  echo "⚠️ $TOOL_COUNT tool calls — consider /compact to reduce context cost" >&2
fi
```

每 50 次工具呼叫提示使用者執行 `/compact`。

---

#### 最小化 MCP 設定

```json
// minimal-mcp.json — 只啟用真正需要的 MCP
{
  "mcpServers": {
    "github": {"command": "npx", "args": ["-y", "@modelcontextprotocol/server-github"]}
  }
}
```

停用不用的 MCP server = 直接減少每次對話的 context 大小。

---

#### 停用 1M Context 視窗

```json
// disable-1m-context.json
{
  "maxContextWindowTokens": 200000
}
```

預設 1M context 對大部分任務是浪費。設定 200K 減少意外的長 context 費用。

---

## 成本優化優先順序

```
1. CLAUDE.md 佈局優化（穩定區頂部）       → 立即見效，0 成本
2. 停用不用的 MCP server                  → 立即見效，5 分鐘完成
3. 探索型 Sub-agent 換 haiku             → 60-80% 子代理成本
4. 定期 /compact（每 50 工具呼叫）        → 防止 context 膨脹
5. MCP → Skill 遷移（簡單用途）           → 一次性工作，長期省
```

---

## 如何套用到我的工作流

| 我的情況 | 優化行動 |
|---------|---------|
| 47 個 Skills + 75 個 Agents | 評估哪些 Agent 可換 haiku 模型 |
| MCP server 較多（14+） | 停用不常用的，簡單用途改 Skill |
| 每日 AIHCR 閉環長對話 | CLAUDE.md 穩定區/揮發區分離 |
| NotebookLM 批次作業 | 用 VPS cron（不佔 Max 配額），只用 `claude -p` |

---

## 最值得馬上借鑑

1. **CLAUDE.md 穩定區重新排版**
   - 把 TODO、當日進度搬到底部 → prompt cache 命中率立刻上升

2. **`suggest-compact.sh` 加到 Stop Hook**
   - 自動在 50 工具呼叫時提醒 `/compact`
   - 防止長 session 無感燒掉大量 token

---

## Sample Code 位置

```
code/part6-cost/
├── cost-monitoring.md            ← 成本監控全指南
├── model-selection-matrix.md     ← 模型選擇對照表
├── docs/cache-design-guide.md    ← Prompt cache 設計指南
├── mcp-to-skill/
│   ├── README.md                 ← MCP → Skill 遷移指南
│   └── SKILL.md                  ← Skill 範本
├── agents/code-explorer.md       ← haiku 探索型代理範本
├── hooks/suggest-compact.sh      ← Compact 觸發 Hook
└── settings/
    ├── disable-1m-context.json   ← 限制 context 視窗
    ├── effort-level.json         ← 任務難度對應模型
    ├── minimal-mcp.json          ← 最小 MCP 設定
    └── model-matrix.json         ← 模型矩陣設定
```
