# Project instructions

<!-- AGENTIC TEAM PROTOCOL RULES -->

## Memory-first rules

1. Immediately after the user gives a task, call `mcp__eden-memory__eden_recall` with the task summary.
2. Before any decision that touches user preferences, coding style, security, or tooling, call `mcp__eden-memory__eden_recall` first.
3. After corrections, working solutions, or settled conventions, call `mcp__eden-memory__eden_remember`.
4. At the end of every task, batch 3–5 durable takeaways into `mcp__eden-memory__eden_remember` calls.
5. Do not remember secrets, tokens, raw command output, ephemeral reasoning, or unvalidated guesses.
6. If eden-memory tools are unavailable, use the `/eden-*` fallback slash commands.

## Agentic Team Protocol rules

1. For every non-trivial task, start with the Dispatcher subagent, record a goal receipt in Eden-memory, and obtain a dispatch instruction before any implementation work.
2. Do not begin implementation until the Researcher has gathered context and the plan is approved.
3. Builder (or Runtime) executes the action and records an action record; Verifier inspects the outcome and writes a verdict; Archivist closes and links all records.
4. Start each session by checking `/team-status`.
5. Escalate via `/team-escalate` when confidence is low, authority is missing, or scope expands.
6. The user can override any role decision.

## Parent assistant continuation rule

When an ATP role subagent returns after writing its durable record and `hand_off_record`, the parent assistant must immediately continue the goal by calling `/team-continue ${GOAL_ID}` or spawning the `router` subagent. Do not ask the user "Shall I proceed?" between normal lifecycle transitions.

## Task list synchronization

The parent assistant and every ATP role must keep the Claude Code task list aligned with the durable Eden-memory trail:

- One task represents the whole goal. Its `claude_task_id` is stored in Eden-memory record metadata.
- `/team` and `/team-full` create the goal task before spawning the Dispatcher.
- Each role updates the task to `in_progress` when it starts and `completed` when it finishes, using an `activeForm` that names the current stage.
- Verifier sets the task to `in_progress` with a rework or blocker note for `red`/`blocked` verdicts.
- Archivist marks the task `completed` when the goal is closed.
- In headless environments, task updates may be skipped and recorded in a `run_log`.

Pause and surface the situation to the user only when the latest Eden-memory record indicates one of:

- `blocked`
- `pending_authorisation`
- `escalation_record`
