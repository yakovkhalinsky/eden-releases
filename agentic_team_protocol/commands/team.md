---
description: Invoke the team protocol to start or continue a goal
argument-hint: "[goal or request]"
allowed-tools:
  - Agent
  - Bash
  - TaskCreate
  - TaskUpdate
  - TaskGet
  - TaskList
---

# /team

Top-level entry point for the team protocol **Lite mode** (default). Use it to kick off a new goal, ask for help with the lifecycle, or route an existing request through the Dispatcher.

In Lite mode, the dispatcher also performs everyday context gathering and writes a `plan_record`. The full 6-role, 7-stage protocol is available via `/team-full`.

This command is intentionally thin: it interprets the user's input and delegates to the right lifecycle command or subagent. It does not do role work itself.

## Steps

1. Parse `$ARGUMENTS`.
   - If empty or only contains help-like words (`help`, `?`, `status`), run `/team-status` and ask what the user wants to do next.
   - If it contains a `goal_id`, run `/team-continue ${GOAL_ID}` (the stored `mode` determines Lite or Full routing).
   - Otherwise, treat the text as a new **Lite** goal request and spawn the `dispatcher` subagent with `mode: lite`.
2. When starting a new goal, pass the full user request to the Dispatcher. The Dispatcher records a `goal_record` (with `metadata.mode: lite`) and a `plan_record` in Eden-memory, then routes directly to `builder` for everyday tasks.
   - Before spawning the Dispatcher, create a Claude Code task for this goal via `TaskCreate` with status `in_progress`. Pass the task ID to the Dispatcher so it can store `metadata.claude_task_id` in the `goal_record`.
   - Resolve `EDEN_ORG_ID` and `EDEN_WORKSPACE_ID` from the project `.env`, `agentic-team-config.yaml`, or `~/.eden-memory/.env`, and pass them in the agent context so every Eden-memory call is scoped to this workspace.
   - The task `subject` should be the user request (or a concise summary); the `description` should include `goal_id` placeholder and a note that it will be filled in after the Dispatcher stores the `goal_record`.
   - On every subsequent hand-off, update the task via `TaskUpdate` to reflect the current stage and role.
3. When continuing an existing goal, let `/team-continue` or the `router` subagent rehydrate the goal from Eden-memory and dispatch the correct next role.

## Behaviour

| Input | Action |
|---|---|
| (none) | Show status, then ask for a goal or request. |
| `goal_id` or UUID-like argument | Resume the goal via `/team-continue`. |
| Any other request | Spawn the `dispatcher` subagent to record and route a new **Lite** goal. |

For non-trivial `build` or `run` goals, the assigned role may create a dedicated git worktree under `.claude/worktrees/atp/` if `worktree_policy.enabled` is true.

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
- Multi-step or non-trivial goals must not be planned outside Eden-memory; if plan mode is used, the resulting plan file path must be recorded in a `plan_record`, `context_summary`, or `action_record`.
- Do not start goals in Lite mode that obviously need research, runtime, or formal escalation; use `/team-full` for those.
