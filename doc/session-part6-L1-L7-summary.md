# Session 摘要：Part 6 成本最佳化（第 1-7 課全部完成）

日期：2026-06-15

## 本 Session 完成項目

### Part 6 成本最佳化 — 7 堂課互動演練（跨兩次 session 完成）

| 課 | 主題 | 核心工具/概念 | commit |
|----|------|-------------|--------|
| 1 | 看懂 Token 帳單 | `--output-format json` / transcript grep / token 估算 | d6138d1 |
| 2 | 模型選擇矩陣 | Haiku/Sonnet/Opus 分工 + `inherit` 風險 | 70e652b |
| 3 | Prompt 快取設計 | 前綴匹配 + CLAUDE.md 三層結構（系統/專案/用戶） | a7a3558 |
| 4 | 成本警示 Hook | `suggest-compact.sh` / PostToolUse / 每 50 次工具呼叫門檻 | 9ba5359 |
| 5 | Sub-agent Token 套利 | `model: haiku` agent + 隔離 context + 只回傳路徑（省 299×） | 1a5c79c |
| 6 | MCP 轉 Skill | Schema overhead 計算（$72.45/月）+ `allowed-tools` 工具縮減 | 25a2552 |
| 7 | 組合拳全面控制 | 六策略整合 settings.json profile | 本 session |

## 第 7 課核心學習

### 四個護欄設定片段

| 設定 | 控制什麼 | 對應課次 |
|------|---------|---------|
| `model-matrix.json` | 主模型鎖 Sonnet，防誤用 Opus（5×費用）| 第 2 課 |
| `effort-level.json` | 推理深度 medium，省 20-40% output token | 第 2 課 |
| `disable-1m-context.json` | 禁止自動升 1M context 模型 | 第 1 課 |
| `minimal-mcp.json` | deny playwright + magic，省 ~$126/月 schema overhead | 第 6 課 |

### 整合版 settings.json（存於 `demo/07-組合拳全面控制/settings.json`）

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
        "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/suggest-compact.sh"}]
      }
    ]
  }
}
```

### 組合拳為何有效

6 個策略各作用於不同的 token 類型，**疊加省錢而非互相抵消**：

```
Input 單價  ← model: sonnet（避免 Opus）
Output 量   ← effortLevel: medium
Sub 費率    ← CLAUDE_CODE_SUBAGENT_MODEL: haiku
視窗大小    ← DISABLE_1M_CONTEXT: 1
Schema      ← deny playwright + magic
壓縮時機    ← suggest-compact.sh Hook
```

理論節省：全開所有策略可省 **70-85%** API 費用。

### Token Economics Complexity（TEC）

> 以最少 token 消耗引導 AI 產出最高品質結果。
> 這是 AI 原生時代的基礎工程素養，等同演算法分析之於傳統工程師。

## 產出檔案清單

```
code-中文/part6-cost/demo/07-組合拳全面控制/
  ├── settings.json    ← 整合六策略的 demo profile（新增）
  └── STEP-LOG.md      ← 第 7 課完整解答（更新）
```

## 下一步

- Part 7：進階工作流（Plugin 開發等）
- 或接續其他章節演練
