# Sub-agents vs Agent Teams Decision Guide

## Comparison

| Aspect | Sub-agents | Agent Teams |
|--------|-----------|-------------|
| Sessions | One main session | Multiple independent sessions |
| Communication | Through main agent only | Direct agent-to-agent |
| Coordination | Main agent manages all | Shared task list + autonomous claiming |
| Context | Results returned to main | Each instance holds its own |
| Token cost | Low (results summarized back) | High (multiple instances) |
| Status | Official feature | Experimental |

## Enabling Agent Teams

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## Decision Flow

```text
Is the task independent?
 ├─ Yes → Sub-agents are sufficient
 └─ No → Is agent-to-agent communication required?
           ├─ Yes → Consider Agent Teams
           └─ No → Sequential execution in main conversation
```

## When to Choose Sub-agents

- Exploration tasks (codebase investigation, log analysis)
- Specialized reviews (security, spec compliance)
- Processing where only results matter, not the intermediate steps
- When you want to minimize token cost

## When to Choose Agent Teams

- Multiple agents need to reference and discuss each other's findings
- Parallel validation of competing hypotheses (e.g., simultaneous multi-angle bug investigation)
- Long-running parallel implementations where each agent needs an independent context

## Notes

Agent Teams is experimental. Known limitations include: session resume (`/resume`) does
not work for in-process teammates (as of February 2026).
Avoid using Agent Teams in production workflows until stabilized.
Prefer Sub-agents for tasks that can be handled by them.
