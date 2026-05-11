# Prompt Cache Design Guide

## CLAUDE.md Design Principles for Higher Cache Hit Rates

```markdown
<!-- Stabilization pattern for CLAUDE.md -->

## Stable Information (place at the top)
- Project overview
- Tech stack
- Coding conventions
- Fixed reference documents

## Volatile Information (place at the bottom)
- Current work status
- Recent changes
- TODO list
```

Avoid modifying the top portion of CLAUDE.md to keep that section cached.
Place frequently changing information at the bottom so the stable
top section stays cached longer.

## Debug: Disabling Prompt Cache

```bash
# Disable caching for all models
export DISABLE_PROMPT_CACHING=1

# Disable per model
export DISABLE_PROMPT_CACHING_HAIKU=1
export DISABLE_PROMPT_CACHING_SONNET=1
export DISABLE_PROMPT_CACHING_OPUS=1
```

## Leveraging Cache with Session Continuation

```bash
# Reconnect from the same project directory
claude --continue  # continue previous conversation (maximizes cache use)
```

## Notes

- The cache does not cache conversation content itself
- The "fixed portion" sent as context (CLAUDE.md, system prompt) is what gets cached
- Conversation history changes each turn and is not cached
- Only `1` is valid for DISABLE_PROMPT_CACHING
