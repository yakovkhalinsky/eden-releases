---
description: Invoke the team protocol in full 6-role, 7-stage mode
argument-hint: "[goal or request]"
allowed-tools:
  - Agent
  - Bash
  - TaskCreate
  - TaskUpdate
  - TaskGet
  - TaskList
---

# /team-full

Top-level entry point for the **full team protocol**. Use it for complex, risky, or heavily-audited goals that benefit from the complete 6-role, 7-stage lifecycle: Dispatcher → Researcher → Builder/Runtime → Verifier → Archivist.

For everyday implementation tasks, use `/team` (Lite mode) instead.

## Steps

1. Parse `$ARGUMENTS`.
   - If empty or only contains help-like words (`help`, `?`, `status`), run `/team-status` and ask what the user wants to do next.
   - If it contains a `goal_id`, run `/team-continue ${GOAL_ID}` (the stored `mode` determines Lite or Full routing).
   - Otherwise, treat the text as a new **Full** goal request and spawn the `dispatcher` subagent with `mode: full`.
2. When starting a new goal, pass the full user request to the Dispatcher. The Dispatcher records a `goal_record` (with `metadata.mode: full`) and a `dispatch_instruction` in Eden-memory.
   - Before spawning the Dispatcher, create a Claude Code task for this goal via `TaskCreate` with status `in_progress`. Pass the task ID to the Dispatcher so it can store `metadata.claude_task_id` in the `goal_record`.
   - Resolve `EDEN_ORG_ID` and `EDEN_WORKSPACE_ID` from the project `.env`, `agentic-team-config.yaml`, or `~/.eden-memory/.env`, and pass them in the agent context so every Eden-memory call is scoped to this workspace.
   - On every subsequent hand-off, update the task via `TaskUpdate` to reflect the current stage and role.
3. When continuing an existing goal, let `/team-continue` or the `router` subagent rehydrate the goal from Eden-memory and dispatch the correct next role.

## Behaviour

| Input | Action |
|---|---|
| (none) | Show status, then ask for a goal or request. |
| `goal_id` or UUID-like argument | Resume the goal via `/team-continue`. |
| Any other request | Spawn the `dispatcher` subagent to record and route a new **Full** goal. |

## Examples

```text
/team-full
/team-full Audit production certificate rotation
/team-full 8d00dbcb-5eb8-42c4-9c33-6f451fcc9569
```

## Anti-patterns

- Do not perform role work directly in `/team-full`; always hand off to the Dispatcher, Router, or a lifecycle command.
- Do not invent new goals without recording a `goal_record` in Eden-memory.
- Do not rely on conversation context when continuing; use `/team-continue` or the `router` subagent.
- Do not use `/team-full` for trivial one-file edits when `/team` (Lite) is sufficient.
