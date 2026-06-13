#!/bin/bash
# basic-ci.sh - claude -p 的基本使用模式
# 適用專案：kindle-20-65-automation-patterns
#
# 從專案根目錄執行：
#   cd C:/Users/B00332/workspace/kindle-20-65-automation-patterns
#   bash code/part4-cicd/scripts/basic-ci.sh

# ── 模式 1：直接傳入 prompt ──────────────────────────────────────────────────
echo -e "\n▶ 模式 1：直接傳入 prompt" >&2
claude -p "What is this project about? Look at the README or CLAUDE.md if available, otherwise infer from the directory structure. Answer in exactly 2 sentences." \
  --allowedTools "Read,Glob" \
  --max-turns 5 < /dev/null

# ── 模式 2：用管線傳入檔案內容 ────────────────────────────────────────────────
echo -e "\n▶ 模式 2：用管線傳入檔案內容" >&2
cat code/part2-hooks/quality/quality-gate.sh | \
  claude -p "Explain what this Claude Code Stop hook does and what it blocks. One sentence."

# ── 模式 3：CI/CD 模式 — 限制工具、限制回合數 ─────────────────────────────────
# 注意：在 GitHub Actions 中需加上：  env: ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
echo -e "\n▶ 模式 3：CI/CD — allowedTools + max-turns" >&2
claude -p "List all .sh files in code/part2-hooks/ grouped by subfolder. Just the file names, no explanation." \
  --allowedTools "Glob" \
  --max-turns 3 < /dev/null
