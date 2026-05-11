# 第4章 CI/CD Automation — 打造無人值守 AI 開發管線

> Claude Code in Production | Yosuke Morikawa | Patterns 45–52

---

## 章節概覽

把 Claude Code 插入 CI/CD 管線，讓 AI 在每次 PR / commit 自動執行審查、修復、測試，
達到**完全無人值守**的 AI 開發流程。

---

## 核心模式

### Pattern 45–46：GitHub Actions 自動 PR 審查

```yaml
# pr-review.yml
name: AI Code Review
on:
  pull_request:
    types: [opened, synchronize]
jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0          # 取完整 git 歷史
      - name: Install Claude Code
        run: npm install -g @anthropic-ai/claude-code
      - name: Run AI Review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: bash .github/scripts/review.sh ${{ github.event.pull_request.number }}
```

每次 PR open 或更新 → 自動觸發 AI 審查 → 把評論貼到 PR。

---

### Pattern 47：自動安全掃描

```yaml
# security-scan.yml
on:
  push:
    branches: [main]
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: AI Security Scan
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude -p "Scan this codebase for security vulnerabilities.
                     Focus on: SQL injection, XSS, exposed credentials, 
                     insecure dependencies. Output JSON." \
            --allowedTools "Read,Grep,Glob" \
            --output-format json > security-report.json
```

---

### Pattern 48：自動修復 CI

```yaml
# auto-fix.yml
on:
  workflow_run:
    workflows: [CI]
    types: [completed]
    
jobs:
  auto-fix:
    if: ${{ github.event.workflow_run.conclusion == 'failure' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Auto-fix failures
        run: bash .github/scripts/auto-fix.sh
```

CI 失敗後自動呼叫 Claude Code 嘗試修復，成功則自動 commit + push。

---

### Pattern 49–50：基礎 CI 腳本

#### basic-ci.sh

```bash
#!/bin/bash
# basic-ci.sh — 最簡 Claude Code CI 流程
set -euo pipefail

RESULT=$(claude -p "Review this PR for bugs and security issues.
  Output as JSON: {issues: [{severity, file, line, description}]}" \
  --allowedTools "Read,Grep,Glob" \
  --output-format json 2>/dev/null)

CRITICAL=$(echo "$RESULT" | jq '[.issues[] | select(.severity=="critical")] | length')

if [ "$CRITICAL" -gt 0 ]; then
  echo "❌ Found $CRITICAL critical issues" >&2
  echo "$RESULT" | jq '.issues[] | select(.severity=="critical")'
  exit 1
fi
echo "✅ No critical issues found"
```

#### json-output-patterns.sh

```bash
# Claude Code 輸出結構化 JSON 的標準模式
claude -p "Analyze and return JSON with fields: status, issues, suggestions" \
  --output-format json \
  --allowedTools "Read,Grep" | jq '.issues[]'
```

---

### Pattern 51：多步驟 CI 管線

```bash
# multi-step-ci.sh
set -euo pipefail

echo "Step 1: Lint..."
claude -p "Fix all lint errors" \
  --allowedTools "Read,Edit,Bash(npm run lint)" \
  --output-format json

echo "Step 2: Type check..."
claude -p "Fix all TypeScript errors" \
  --allowedTools "Read,Edit,Bash(npm run typecheck)" \
  --output-format json

echo "Step 3: Tests..."
claude -p "Fix failing tests without changing test logic" \
  --allowedTools "Read,Edit,Bash(npm test)" \
  --output-format json

echo "✅ All steps passed"
```

---

### Pattern 52：平行 Review 腳本

```bash
# parallel-review.sh
claude -w review-security -p "Security review" --allowedTools "Read,Grep,Glob" &
PID1=$!

claude -w review-perf -p "Performance issues" --allowedTools "Read,Grep,Glob" &
PID2=$!

claude -w review-tests -p "Test coverage gaps" --allowedTools "Read,Grep,Glob" &
PID3=$!

wait $PID1 $PID2 $PID3
echo "Parallel review complete"
```

三個方向同時審查，時間從 3× 縮短為 1×。

---

### Pattern 52b：自動 Commit

```bash
# auto-commit.sh
CHANGES=$(git diff --name-only)
if [ -n "$CHANGES" ]; then
  MSG=$(claude -p "Write a concise commit message for these changes: $CHANGES" \
    --output-format text 2>/dev/null)
  git add -A
  git commit -m "$MSG"
fi
```

---

## 如何套用到我的工作流

| CI/CD 需求 | 對應 Pattern |
|-----------|------------|
| PR 自動審查 | `pr-review.yml` + `parallel-review.sh` |
| Push 到 main 安全掃描 | `security-scan.yml` |
| CI 失敗自動修復 | `auto-fix.yml` |
| 產出結構化 JSON 給下游 | `json-output-patterns.sh` |

**對於我的 n8n workflow 管線：**
- `claude -p "..." --output-format json` 的結果可以直接被 n8n 的 HTTP Request 消費
- 搭配 `Bash(claude ...)` 的 VPS cron → 排程 AI 稽核

---

## 最值得馬上借鑑

1. **`parallel-review.sh` 模式用在我的 AIHCR 報告**
   - 3 個維度同時分析（場域狀況 / 異常偵測 / 控制建議）
   - 實作：3 個 `claude -w` 背景執行 + `wait`

2. **`--output-format json` 作為 CI/CD 介面**
   - Claude Code 輸出 JSON → n8n / shell 消費
   - 讓 AI 分析結果進入自動化流程，不再只靠人讀

---

## Sample Code 位置

```
code/part4-cicd/
├── github-actions/
│   ├── pr-review.yml       ← 自動 PR 審查 workflow
│   ├── security-scan.yml   ← Push 時安全掃描
│   └── auto-fix.yml        ← CI 失敗自動修復
└── scripts/
    ├── basic-ci.sh          ← 最簡 Claude CI 流程
    ├── json-output-patterns.sh ← JSON 輸出模式
    ├── multi-step-ci.sh     ← 多步驟管線
    ├── parallel-review.sh   ← 平行三維度審查
    └── auto-commit.sh       ← 自動 commit
```
