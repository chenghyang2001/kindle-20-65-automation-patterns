# Sub-agent Model Selection Matrix

Use the right model for each task type to optimize cost.

## Model Selection Table

| Task Type | Recommended Model | Reason |
|-----------|-------------------|--------|
| File exploration and search | haiku | Speed and cost priority |
| Code review (format check) | haiku | Pattern matching focused |
| Bug fixes and implementation | sonnet | Balanced capability |
| Security audit | sonnet | High accuracy required |
| Architecture design | sonnet or opus | Complex reasoning required |
| Large-scale refactoring | inherit | Use main conversation setting |

## Example: Haiku Agent Configuration

```markdown
---
name: file-explorer
description: >
  High-speed agent specialized for file search, listing, and content inspection.
  Use proactively for codebase exploration tasks.
tools: Read, Grep, Glob
model: haiku
---

As a file exploration expert, efficiently collect and report
the requested information. Do not make any modifications.
Return only what you find.
```

## Setting Model for All Sub-agents at Once

```bash
# Set all sub-agents to Haiku
export CLAUDE_CODE_SUBAGENT_MODEL=haiku
```

## When to Use `inherit`

`model: inherit` inherits the model setting from the main conversation.
Use it for production-quality tasks or when you want sub-agents to follow
the main conversation's model configuration.

## Notes

Model aliases (e.g., `haiku`) resolve to the latest supported model at runtime.
Specifying a model ID directly pins the version — use aliases for most cases.
