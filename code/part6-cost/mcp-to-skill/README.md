# MCP to Skill Migration Example

This directory demonstrates replacing a simple MCP server with a Claude Code Skill.

## The Problem

An MCP server that only fetches documentation or runs a single CLI tool adds
infrastructure overhead (server process, configuration, maintenance) for minimal value.

## The Solution

Replace it with a Skill file (`SKILL.md`) that uses built-in tools like `Bash(curl *)`.

## Trade-offs

| Aspect | MCP Server | Skill |
|--------|-----------|-------|
| Setup | Requires server process | Just a `.md` file |
| Maintenance | Ongoing updates needed | Self-contained |
| Capabilities | Arbitrary code | Limited to allowed tools |
| Best for | Complex stateful operations | Simple, focused tasks |

## When to Keep MCP

- The tool needs to maintain state between calls
- The tool requires OAuth or complex authentication
- The tool needs to stream large amounts of data
- Multiple projects share the same server

## When to Use a Skill Instead

- The tool runs a single CLI command
- The tool fetches public documentation
- The tool does simple text processing
- The overhead of a server isn't justified
