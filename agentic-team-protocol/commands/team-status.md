---
description: Show active Agentic Team Protocol goals and current stages
argument-hint: "[optional goal_id or role filter]"
allowed-tools:
  - Bash
---

# /team-status

List active goals, current stage, owner role, and latest record IDs. Optionally filter by `goal_id` or role.

## Steps

1. Parse `$ARGUMENTS` as an optional filter. If it looks like a UUID or contains a `-`, treat it as a `goal_id` filter; otherwise treat it as a role filter.
2. Search Eden-memory for recent `goal_record`, stage, `run_log`, `hand_off_record`, `pending_authorisation`, and `blocked` records:
   ```bash
   USER_ID="${USER:-$(id -un)}"
   EDEN_MEMORY_BIN="${EDEN_MEMORY_BIN:-$(command -v eden-memory || echo "${HOME}/.local/bin/eden-memory")}"
   "${EDEN_MEMORY_BIN}" search \
     --user-id "${USER_ID}" \
     --keywords "agentic-team-protocol goal_record stage run_log hand_off_record pending_authorisation blocked cleanup_record" \
     --limit 100
   ```
3. Group results by `goal_id` and find the latest stage per goal.
4. If a filter is provided, restrict the output to matching goals or roles.
5. Present a table with columns: goal_id, current stage, owner role, latest record ID, deadline (if recorded), confidence/escalation trigger, and state (`active`, `blocked`, `pending_authorisation`, `continueable`, `closed`).
6. Flag goals whose latest record is non-terminal and not `blocked` or `pending_authorisation` as `continueable` — these are candidates for `/team-continue`.
7. If no active goals are found, report that clearly and suggest starting a new task by spawning the Dispatcher subagent. Do not invent or reference a `/agentic-start` command, because no such command exists.
