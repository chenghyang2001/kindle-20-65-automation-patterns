# Model Selection Matrix

## Choosing the Right Model

Match model capability to task complexity to optimize cost without sacrificing quality.

## Decision Matrix

| Task Type | Recommended Model | Rationale |
|-----------|-------------------|-----------|
| Codebase search and file exploration | haiku | Speed and cost priority |
| Format checks and pattern matching | haiku | Repetitive, structured tasks |
| Bug fixes and feature implementation | sonnet | Balanced capability and cost |
| Security audits | sonnet | Accuracy matters |
| Architecture design | sonnet or opus | Complex reasoning required |
| Production-critical generation | inherit | Follow main conversation setting |

## Sub-agent Model Configuration

### Per-agent model assignment

```markdown
---
name: file-explorer
description: High-speed agent for file search and codebase exploration.
tools: Read, Grep, Glob
model: haiku
---
```

### Global override for all sub-agents

```bash
export CLAUDE_CODE_SUBAGENT_MODEL=haiku
```

### Using `inherit`

```markdown
model: inherit
```

Inherits the model from the calling conversation.
Use for tasks requiring the same quality level as the main agent.

## Cost Comparison (approximate, per 1M tokens)

| Model | Input | Output | Best For |
|-------|-------|--------|----------|
| Claude Haiku | $0.80 | $4 | High-volume, simple tasks |
| Claude Sonnet | $3 | $15 | General-purpose tasks |
| Claude Opus | $15 | $75 | Complex reasoning, critical paths |

*Prices are approximate. Refer to https://anthropic.com/pricing for current rates.*

## Practical Strategy

1. Default all sub-agents to `haiku` for exploration and search tasks
2. Use `sonnet` for review agents where accuracy is important
3. Reserve `opus` for architecture decisions or critical security audits
4. Use `inherit` when sub-agent quality must match the main conversation
