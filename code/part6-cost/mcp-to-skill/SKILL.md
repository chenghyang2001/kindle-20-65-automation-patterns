---
name: fetch-docs
description: >
  Fetch and summarize official documentation for a library or framework.
  Use when you need current API docs or usage examples.
allowed-tools: Bash(curl *), Bash(npx *)
---

# Fetch Documentation

Fetch and summarize documentation for the requested library or framework.

## Steps

1. Identify the official documentation URL for the requested library
2. Fetch the relevant page using curl or npx
3. Extract and summarize the key API or usage information
4. Present the summary in a structured format

## Example

```bash
# Fetch React hooks reference
curl -s https://react.dev/reference/react/useState | \
  npx @mozilla/readability-cli -
```

## Notes

- Prefer fetching official documentation over relying on training knowledge
- For frequently referenced docs, cache the content locally in `.claude/docs/`
- This skill replaces the need for an MCP server for simple documentation fetches
