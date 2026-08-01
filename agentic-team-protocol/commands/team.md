---
description: Invoke the Agentic Team Protocol skill to start or continue a goal
argument-hint: "[goal or request]"
allowed-tools:
  - Agent
  - Bash
---

# /team

Top-level entry point for the Agentic Team Protocol. Use it to kick off a new goal, ask for help with the lifecycle, or route an existing request through the Dispatcher.

This command is intentionally thin: it interprets the user's input and delegates to the right lifecycle command or subagent. It does not do role work itself.

## Steps

1. Parse `$ARGUMENTS`.
   - If empty or only contains help-like words (`help`, `?`, `status`), run `/team-status` and ask what the user wants to do next.
   - If it contains a `goal_id`, run `/team-continue ${GOAL_ID}`.
   - Otherwise, treat the text as a new goal request and spawn the `dispatcher` subagent.
2. When starting a new goal, pass the full user request to the Dispatcher. The Dispatcher records a `goal_record` and `dispatch_instruction` in Eden-memory.
3. When continuing an existing goal, let `/team-continue` or the `router` subagent rehydrate the goal from Eden-memory and dispatch the correct next role.

## Behaviour

| Input | Action |
|---|---|
| (none) | Show status, then ask for a goal or request. |
| `goal_id` or UUID-like argument | Resume the goal via `/team-continue`. |
| Any other request | Spawn the `dispatcher` subagent to record and route a new goal. |

## Examples

```text
/team
/team Add a runbook for continuation recovery
/team goal-atp-router-continuation-reliability-p1-2026-08-01
```

## Anti-patterns

- Do not perform role work directly in `/team`; always hand off to the Dispatcher, Router, or a lifecycle command.
- Do not invent new goals without recording a `goal_record` in Eden-memory.
- Do not rely on conversation context when continuing; use `/team-continue` or the `router` subagent.
