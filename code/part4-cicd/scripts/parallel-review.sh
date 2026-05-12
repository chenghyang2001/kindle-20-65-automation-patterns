#!/bin/bash
# parallel-review.sh - Run 3 independent reviews simultaneously with -w (named worktree)
# Adapted for: kindle-20-65-automation-patterns project
#
# Run from the project root:
#   cd C:/Users/B00332/workspace/kindle-20-65-automation-patterns
#   bash code/part4-cicd/scripts/parallel-review.sh
#
# Key concept: -w assigns a named workspace per instance.
# All 3 run in parallel (&), then wait collects them.
# Outputs go to temp files to prevent interleaving.

REPORT_DIR=$(mktemp -d)
echo -e "\n▶ Launching 3 parallel reviews (outputs buffered to: $REPORT_DIR)..." >&2

# ── Worker 1: Security review ─────────────────────────────────────────────────
claude -p \
  "Review all scripts in code/part2-hooks/ for security issues: command injection via unsanitized hook JSON input, unsafe dynamic command construction from jq values, missing exit code handling. Report each issue as Critical / High / Medium with file:line." \
  --allowedTools "Read,Grep,Glob" < /dev/null > "$REPORT_DIR/security.txt" &
PID1=$!

# ── Worker 2: Code quality review ────────────────────────────────────────────
claude -p \
  "Review all hook scripts in code/part2-hooks/ for code quality: hardcoded paths (must use \$HOME not /c/Users/...), missing error handling, duplicate stdin consumption logic, unclear naming. Report as Critical / Warning / Suggestion." \
  --allowedTools "Read,Grep,Glob" < /dev/null > "$REPORT_DIR/quality.txt" &
PID2=$!

# ── Worker 3: Spec compliance review ─────────────────────────────────────────
claude -p \
  "Verify hook scripts in code/part2-hooks/ follow Claude Code hook spec: (1) exit 0=allow, exit 2=hard block, (2) Stop hooks read INPUT=\$(cat) first, (3) Stop hooks check stop_hook_active to prevent loops, (4) MCP guards output hookSpecificOutput JSON. Report PASS/FAIL per hook file." \
  --allowedTools "Read,Grep,Glob" < /dev/null > "$REPORT_DIR/spec.txt" &
PID3=$!

wait $PID1 $PID2 $PID3

echo -e "\n════════════ Security Review ════════════" >&2
cat "$REPORT_DIR/security.txt"

echo -e "\n════════════ Quality Review  ════════════" >&2
cat "$REPORT_DIR/quality.txt"

echo -e "\n════════════ Spec Compliance ════════════" >&2
cat "$REPORT_DIR/spec.txt"

echo -e "\n▶ Parallel review complete." >&2
