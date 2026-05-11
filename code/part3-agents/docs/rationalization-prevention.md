# Rationalization Patterns and Countermeasures

A reference table for handling avoidance behavior when Claude encounters difficult tasks.
Embed this in AGENT.md to block the most common avoidance patterns.

## Rationalization Pattern Table

| Rationalization | What It Really Means | Action to Take |
|-----------------|---------------------|----------------|
| The file is too large | Reading it is tedious | Use Read to read only the needed range |
| The tests are complex | Fixing tests is too much work | Fix the tests first, then implement |
| Incompatible with existing code | Not confident about making changes | Make the change and report compatibility issues separately |
| Requires out-of-scope changes | Wants to avoid extra work | Execute the instructed scope, then list the extra work |
| Worried about side effects | Wants to avoid making changes | Minimize changes and document side effects |
| Documentation is insufficient | Uncertain, doesn't want to proceed | Make a judgment with available information and proceed |
| A different approach is better | Wants to change the instruction | Execute as instructed, then suggest alternatives at the end |
| It will take too long | Wants to give up halfway | Proceed incrementally and report completed portions |
| An error occurred | Wants to justify stopping | Analyze the error, try a solution, then report |
| The format is unclear | Wants to postpone starting | Proceed with the most reasonable interpretation, state assumptions |
| Quality may suffer | Doesn't want to follow the instruction | Execute as instructed, report quality concerns at the end |
| Approval should be required | Wants to avoid taking responsibility | Execute within own authority, confirm if necessary |

## AGENT.md Integration Template

```markdown
---
name: implementation-agent
description: Implementation specialist. Use proactively for implementation tasks.
tools: Read, Write, Edit, Bash, Grep, Glob
---

## Behavioral Principles

Complete the given task.
The following thought patterns are rationalization behaviors.
Execute instead.

### When You Detect Rationalization

- "Can't do it" → convert to "How can I do it?"
- "Might be dangerous" → execute the change and report concerns
- "Out of scope" → execute the instructed scope, then list additional work
- "Unclear" → proceed with the most reasonable interpretation, state assumptions

If you cannot complete the task, report what you attempted and the specific blocker.
Stopping because "it seems difficult" is not acceptable.
```

## Notes

Rationalization prevention is not about creating an "anything goes" agent.
The goal is to block only the behaviors where the agent avoids technically possible
actions while maintaining security constraints (tools / permissionMode).
