# Compact Instructions Sample

Sample compact instructions to add to the end of CLAUDE.md.

## Compact Instructions

When compressing context, always preserve:

- Full paths of all modified files
- Build commands executed and their success/failure status
- Bugs discovered and planned fixes
- Design decisions made during this session
- Incomplete tasks (what remains to be done)

---

# Combining with a PreCompact Hook

A PreCompact Hook lets you save session state to a file before compression.

```json
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "auto",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/save-session-state.sh"
          }
        ]
      }
    ]
  }
}
```

## Session State Save Script

```bash
#!/bin/bash
SESSION_FILE=".claude/session-state.md"
DATE=$(date '+%Y-%m-%d %H:%M')

cat > "$SESSION_FILE" << EOF
# Session State (auto-saved: ${DATE})

## Modified Files
$(git diff --name-only)
$(git diff --name-only --cached)

## Uncommitted Change Summary
$(git diff --stat | tail -5)

## Recent Commits
$(git log --oneline -5)
EOF
```
