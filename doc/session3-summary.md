# Session 3 摘要

日期：2026-06-13

## 本 Session 完成項目

### Part 7 互動演練（延續上 session）

- 7 堂課全部完成（幻覺偵測 → Plugin 封裝）
- 補完 `my-workflow-plugin`（plugin.json + hooks.json）
- commit：c7102d0

### Part 6 成本最佳化

- 摘要第六章音頻逐字稿（kindle20-ch6-cost-optimization.txt）
- 建立 demo/ 目錄 + 7 個 STEP-LOG.md
- 完成 7 堂課互動演練（使用者動手 + 助理引導）：
  1. 看懂 Token 帳單（--output-format json / transcript grep / 估算腳本）
  2. 模型選擇矩陣（Haiku/Sonnet/Opus 判斷 + 計算省幅）
  3. Prompt 快取設計（穩定區頂部 / 動態區底部 / Exact Prefix Matching）
  4. 成本警示 Hook（suggest-compact.sh / 每 50 次工具呼叫觸發）
  5. Sub-agent Token 套利（Haiku 隔離 context / B/A 任務判斷）
  6. MCP 轉 Skill（每月 $72 schema overhead / deny playwright+magic）
  7. 組合拳（6 條策略整合成完整 settings.json）
- commit：2993c4a

## 關鍵學習

- transcript 路徑在 Windows 是 `~/.claude/projects/C--Users-user-*/...jsonl`（無 transcripts/ 子目錄）
- 壓縮後的 transcript 數字會失真（Input 608 / Output 219k 是壓縮殘骸）
- 56 次工具呼叫 = 已超過 Hook 門檻（第 4 課驗證）
- MCP schema overhead：23 工具 × 350 token × 100 輪/天 × 30 天 = 24.15M token/月 = $72.45

## 整合 settings.json（第 7 課產出）

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
    "PostToolUse": [{"matcher": ".*", "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/suggest-compact.sh"}]}]
  }
}
```

## 下一步

- Part 5 / Part 4 / 其他章節音頻逐字稿摘要 + 課程建立
