#!/bin/bash
# json-output-patterns.sh - --output-format json 的使用模式
# 適用專案：kindle-20-65-automation-patterns
#
# 從專案根目錄執行：
#   cd C:/Users/B00332/workspace/kindle-20-65-automation-patterns
#   bash code/part4-cicd/scripts/json-output-patterns.sh

# ── 模式 1：只擷取回應文字 ────────────────────────────────────────────────────
echo -e "\n▶ 模式 1：--output-format json | jq -r '.result'" >&2
claude -p "List all hook scripts in code/part2-hooks/ and what each one does in one sentence each." \
  --allowedTools "Glob,Read" \
  --output-format json < /dev/null | jq -r '.result'

# ── 模式 2：儲存 session ID 供後續步驟使用 ───────────────────────────────────
echo -e "\n▶ 模式 2：儲存 session_id 供 --resume 使用" >&2
SESSION=$(claude -p "Analyze all hook scripts in code/part2-hooks/ and understand their purpose and trigger events." \
  --allowedTools "Glob,Read" \
  --output-format json < /dev/null | jq -r '.session_id')
echo "已擷取 session_id：$SESSION" >&2
echo "（用法：claude -p \"...\" --resume \$SESSION 即可延續此上下文）" >&2

# ── 模式 3：用 --json-schema 強制輸出格式 ────────────────────────────────────
echo -e "\n▶ 模式 3：--json-schema 強制結構化輸出" >&2
claude -p "List all .sh hook script filenames found in code/part2-hooks/ recursively. Return only filenames, no paths." \
  --allowedTools "Glob" \
  --output-format json \
  --json-schema '{
    "type": "object",
    "properties": {
      "hooks": {
        "type": "array",
        "items": {"type": "string"}
      }
    },
    "required": ["hooks"]
  }' < /dev/null | jq '.structured_output'

# ── 模式 4：用 stream-json 即時處理 ──────────────────────────────────────────
echo -e "\n▶ 模式 4：--output-format stream-json（即時 token 串流）" >&2
claude -p "Read code/part2-hooks/quality/quality-gate.sh and explain what it does in 3 sentences." \
  --allowedTools "Read" \
  --output-format stream-json \
  --verbose \
  --include-partial-messages < /dev/null | \
  jq -rj 'select(.type == "stream_event" and
    .event.delta.type? == "text_delta") |
    .event.delta.text'
echo "" >&2
