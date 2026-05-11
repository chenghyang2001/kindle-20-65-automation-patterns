# Checkpointing Guide

## Basic Operations

```text
# Open the rewind menu
Esc + Esc  or  /rewind

# Actions available in the menu
1. Restore code and conversation
   → Restore both code and conversation history to that point
2. Restore conversation
   → Roll back only the conversation history; keep code changes
3. Restore code
   → Revert only file changes; continue the conversation
4. Summarize from here
   → Convert messages from this point into a compressed summary to free context
5. Never mind
   → Cancel and close the menu
```

## Creating Checkpoints Before Risky Changes

```markdown
# Example prompt before starting a major change

Please record the current state as a checkpoint.
I will then attempt the following refactoring.
If it fails, I will use Esc+Esc to return to this point.

[Planned change]
Rewrite the class-based code under src/auth/
as function-based code.
```

## Using Summarize

```markdown
# Free context after a long debugging session

After a lengthy debugging session:
1. Open /rewind
2. Select the message where debugging began
3. Choose "Summarize from here"
4. Enter instructions for the summary:
   "Record only the root cause of the bug and the final fix applied."
```

## How It Works

- Checkpointing tracks only changes made by Claude Code's file editing tools (Write/Edit)
- A snapshot is created automatically at each user prompt submission
- Snapshots are retained for 30 days after the session ends (as of February 2026)

## Notes

- File changes made via bash commands (rm, mv, cp, etc.) are not tracked
- For scripts that modify many files, create a manual checkpoint with a Git commit
- Checkpointing is a complement to Git, not a replacement
