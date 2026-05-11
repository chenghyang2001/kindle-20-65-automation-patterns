# Built-in Sub-agent Reference

A list of sub-agents included with Claude Code out of the box.

## Built-in Sub-agents

| Sub-agent | Model | Tools | Purpose |
|-----------|-------|-------|---------|
| Explore | Haiku | Read-only | Codebase exploration and search |
| Plan | Inherit | Read-only | Research during Plan mode |
| General-purpose | Inherit | All tools | Complex multi-step tasks |
| Bash | Inherit | Bash only | Independent terminal command execution |
| statusline-setup | Sonnet | Read/Write | /statusline configuration |
| Claude Code Guide | Haiku | Read | Q&A about Claude Code features |

## Explore Sub-agent Thoroughness Levels

| Level | Use Case |
|-------|----------|
| quick | Find a specific file, pinpoint confirmation |
| medium | Balanced exploration |
| very thorough | Comprehensive analysis of the entire codebase |

## Disabling Specific Sub-agents

```json
{
  "permissions": {
    "deny": [
      "Task(Explore)",
      "Task(general-purpose)"
    ]
  }
}
```

You can also specify this via CLI flag:

```bash
claude --disallowedTools "Task(Explore)"
```

## Listing Agents with /agents

```bash
# Interactive menu
/agents

# List from CLI
claude agents
```

## Notes

- Explore and Plan have only read-only tools enabled
- Sub-agents cannot spawn other sub-agents (no nesting)
- To avoid nesting, use Skills or chain execution from the main conversation
