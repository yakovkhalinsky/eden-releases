---
description: Show active team goals and current stages
argument-hint: "[optional goal_id or role filter]"
allowed-tools:
  - Bash
  - TaskList
---

# /team-status

List active goals, current stage, owner role, and latest record IDs. Optionally filter by `goal_id` or role.

## Steps

1. Parse `$ARGUMENTS` as an optional filter. If it looks like a UUID or contains a `-`, treat it as a `goal_id` filter; otherwise treat it as a role filter.
2. Resolve the Eden-memory workspace identity from the project `.env` or `~/.eden-memory/.env`:
   ```bash
   if [ -f "${PWD:-.}/.env" ]; then
     set -a
     . "${PWD:-.}/.env"
     set +a
   fi
   EDEN_ORG_ID="${EDEN_ORG_ID:-}"
   EDEN_WORKSPACE_ID="${EDEN_WORKSPACE_ID:-}"
   if [ -z "${EDEN_ORG_ID}" ] || [ -z "${EDEN_WORKSPACE_ID}" ]; then
     if [ -f "${HOME}/.eden-memory/.env" ]; then
       set -a
       . "${HOME}/.eden-memory/.env"
       set +a
     fi
   fi
   ```
3. Search Eden-memory for recent `goal_record`, stage, `run_log`, `hand_off_record`, `pending_authorisation`, and `blocked` records:
   ```bash
   USER_ID="${USER:-$(id -un)}"
   EDEN_MEMORY_BIN="${EDEN_MEMORY_BIN:-$(command -v eden-memory || echo "${HOME}/.local/bin/eden-memory")}"
   "${EDEN_MEMORY_BIN}" search \
     --user-id "${USER_ID}" \
     --org-id "${EDEN_ORG_ID}" \
     --workspace-id "${EDEN_WORKSPACE_ID}" \
     --keywords "agentic-team-protocol goal_record stage run_log hand_off_record pending_authorisation blocked cleanup_record" \
     --limit 100
   ```
4. Group results by `goal_id` and find the latest stage per goal.
5. If a filter is provided, restrict the output to matching goals or roles.
6. Present a table with columns: goal_id, current stage, owner role, **mode** (`lite` or `full`), latest record ID, deadline (if recorded), confidence/escalation trigger, and state (`active`, `blocked`, `pending_authorisation`, `continueable`, `closed`).
7. Determine each goal's `mode` from the `goal_record` metadata; if absent, inspect the records for a `plan_record` (Lite) or `dispatch_instruction`/`context_summary` (Full). Default to `full` when uncertain.
8. Flag goals whose latest record is non-terminal and not `blocked` or `pending_authorisation` as `continueable` — these are candidates for `/team-continue`.
9. Optionally call `TaskList` to surface any Claude Code tasks associated with active goals and report stale or orphaned tasks.
10. If no active goals are found, report that clearly and suggest starting a new task via `/team` (Lite) or `/team-full` (Full). Do not invent or reference a `/agentic-start` command, because no such command exists.
