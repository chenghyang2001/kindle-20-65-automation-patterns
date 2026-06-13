# 成本監控指南

## 用量資料來源

Claude Code 透過數個管道揭露成本與用量資料。

### 1. Session 層級用量（--output-format json）

```bash
claude -p "analyze this codebase" \
  --output-format json | jq '.usage'
```

輸出範例：


```json
{
  "input_tokens": 12450,
  "output_tokens": 3200,
  "cache_read_input_tokens": 8900,
  "cache_creation_input_tokens": 0
}
```

### 2. 逐字稿（Transcript）分析

```bash
# 計算 session 逐字稿中的工具呼叫次數
grep -c '"type":"tool_use"' ~/.claude/projects/*/transcripts/*.jsonl
```

### 3. 成本估算腳本

```bash
#!/bin/bash
# estimate-cost.sh — 從逐字稿粗估成本
TRANSCRIPT=${1:?"用法：estimate-cost.sh <transcript.jsonl>"}

INPUT=$(grep -o '"input_tokens":[0-9]*' "$TRANSCRIPT" | \
  awk -F: '{s+=$2} END {print s}')
OUTPUT=$(grep -o '"output_tokens":[0-9]*' "$TRANSCRIPT" | \
  awk -F: '{s+=$2} END {print s}')

# Sonnet 4 定價（每百萬 token）
INPUT_COST=$(echo "scale=4; $INPUT * 3 / 1000000" | bc)
OUTPUT_COST=$(echo "scale=4; $OUTPUT * 15 / 1000000" | bc)
TOTAL=$(echo "scale=4; $INPUT_COST + $OUTPUT_COST" | bc)

echo "輸入：  $INPUT tokens (\$$INPUT_COST)"
echo "輸出：  $OUTPUT tokens (\$$OUTPUT_COST)"
echo "總計：  \$$TOTAL"
```

## 以 Hook 為基礎的成本警示

當工具呼叫次數跨越門檻時觸發警告：

```bash
# 在 suggest-compact.sh 中（PreToolUse 或 SubagentStop hook）
if [[ "$TOOL_COUNT" -gt 0 && $(( TOOL_COUNT % 50 )) -eq 0 ]]; then
  echo "建議執行 /compact（工具呼叫次數：${TOOL_COUNT}）" >&2
fi
```

## 用 Prompt 快取降低成本

把穩定的內容放在 CLAUDE.md 的頂部。詳見 `docs/cache-design-guide.md`。

## 依專案分配成本

每個專案使用獨立的 CLAUDE.md，讓每個 session 的 context 只反映
相關專案的內容，避免無關指示造成不必要的 token 消耗。
