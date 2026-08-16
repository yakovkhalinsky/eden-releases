---
description: Resume an unfinished team goal from Eden-memory
argument-hint: "[goal_id]"
allowed-tools:
  - Bash
  - Agent
  - TaskCreate
  - TaskUpdate
  - TaskGet
  - TaskList
---

# /team-continue

Continue a team goal by rehydrating its state from Eden-memory and dispatching the correct next role. This is the canonical automatic continuation path: after any role subagent writes its durable record and returns to the parent assistant, the parent invokes `/team-continue ${GOAL_ID}` (or spawns the `router` subagent directly) to route to the next role without asking the user. It also works for resuming goals across sessions. If no `goal_id` is given, list active continueable goals first.

The router selects the **Lite** or **Full** lifecycle table based on the goal's `mode` metadata (`mode: lite | full`). If no `mode` is present, default to `full` to avoid breaking in-flight full-protocol goals.

## Steps

1. Parse `$ARGUMENTS`. If it looks like a UUID or contains a `-', treat it as a `goal_id`. Otherwise list active goals via `/team-status` and ask the user to pick one.
2. Resolve the Eden-memory workspace identity from the project `.env` or `~/.eden-memory/.env` before any call:
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
3. Search Eden-memory for the latest records of that `goal_id`:
   ```bash
   USER_ID="${USER:-$(id -un)}"
   EDEN_MEMORY_BIN="${EDEN_MEMORY_BIN:-$(command -v eden-memory || echo "${HOME}/.local/bin/eden-memory")}"
   "${EDEN_MEMORY_BIN}" search \
     --user-id "${USER_ID}" \
     --org-id "${EDEN_ORG_ID}" \
     --workspace-id "${EDEN_WORKSPACE_ID}" \
     --keywords "${GOAL_ID}" \
     --limit 50
   ```
4. Identify the latest non-terminal record and any `blocked` or `pending_authorisation` record.
5. Determine the goal's `mode`:
   - Prefer `metadata.mode` from the `goal_record`.
   - If any record is a `plan_record`, treat the goal as Lite.
   - If `mode` is absent, default to `full`.
6. If the goal is `blocked` or `pending_authorisation`, report the blocker or approval question to the user and stop.
7. If the latest record is an `archival_record` with no newer action record, report that the goal is already closed.
8. Identify the latest durable record ID for the `goal_id` (e.g., the latest `goal_record`, `plan_record`, `dispatch_instruction`, `action_record`, `verdict`, `hand_off_record`, etc.) from the search results. Store it as `LATEST_RECORD_ID`.
9. Extract the `claude_task_id` from the latest record's metadata (fall back to the `goal_record` or any record in the search results). Store it as `GOAL_TASK_ID`. If found, update the task via `TaskUpdate` to `in_progress` with a note that `/team-continue` is routing to the next role; if the task does not exist, create it.
10. Write a continuation `run_log` that references the latest stage record as its input, not the `goal_id`, and capture the new record ID:
   ```bash
   USER_ID="${USER:-$(id -un)}"
   EDEN_MEMORY_BIN="${EDEN_MEMORY_BIN:-$(command -v eden-memory || echo "${HOME}/.local/bin/eden-memory")}"
   ROUTER_LOG_ID=$("${EDEN_MEMORY_BIN}" remember \
     --agent-id router \
     --user-id "${USER_ID}" \
     --org-id "${EDEN_ORG_ID}" \
     --workspace-id "${EDEN_WORKSPACE_ID}" \
     --content "{\"kind\":\"run_log\",\"goal_id\":\"${GOAL_ID}\",\"stage\":\"routing_and_assignment\",\"owner_role\":\"router\",\"status\":\"in_progress\",\"input_record_ids\":[\"${LATEST_RECORD_ID}\"],\"output_record_ids\":[],\"claude_task_id\":\"${GOAL_TASK_ID}\",\"note\":\"Continued via /team-continue; router will write hand_off_record before spawning next role\"}" \
     --metadata '{"kind":"run_log","stage":"routing_and_assignment","goal_id":"'"${GOAL_ID}"'","owner_role":"router","claude_task_id":"'"${GOAL_TASK_ID}"'","org_id":"'"${EDEN_ORG_ID}"'","workspace_id":"'"${EDEN_WORKSPACE_ID}"'"}')
   ```
11. Spawn the `router` subagent with the goal context, `LATEST_RECORD_ID`, `ROUTER_LOG_ID`, `GOAL_TASK_ID`, and the detected `mode`. The router reads Eden-memory, writes a durable `hand_off_record` (or equivalent continuation `run_log`) with the full hand-off payload **before** spawning the next role, then spawns that role directly. When `/team-continue` is invoked by the parent assistant immediately after a role subagent returns, the user must not be asked "Shall I proceed?" unless the goal is `blocked`, `pending_authorisation`, or requires escalation.

## Behaviour by goal state

### Lite mode records

| Latest record | Behaviour |
|---|---|
| `goal_record` | Route to Dispatcher to produce a `plan_record`. |
| `plan_record` | Route to Builder. |
| `action_record` | Route to Verifier. |
| `cleanup_record` | Route to Verifier to verify claimed releases. |
| `verdict` green | Route to Archivist for closure. |
| `verdict` red | Route to Dispatcher for rework assignment. |
| `verdict` blocked / `blocked` record | Report blocker and wait. |
| `pending_authorisation` | Ask the recorded approval question; resume if approved. |
| `hand_off_record` | Route to the receiving role. |
| `archival_record` (no newer action) | Report goal is closed. |
| `archival_record` + newer `action_record` | Treat as superseded; route to Verifier. |

### Full protocol records

| Latest record | Behaviour |
|---|---|
| `goal_record` | Route to Dispatcher to produce a `dispatch_instruction`. |
| `dispatch_instruction` | Route to the assigned role. |
| `context_summary` | Route to Builder or Runtime per the Dispatcher plan. |
| `action_record` | Route to Verifier. |
| `cleanup_record` | Route to Verifier to verify claimed releases. |
| `verdict` green | Route to Archivist for closure. |
| `verdict` red | Route to Dispatcher for rework assignment. |
| `verdict` blocked / `blocked` record | Report blocker and wait. |
| `pending_authorisation` | Ask the recorded approval question; resume if approved. |
| `hand_off_record` | Route to the receiving role. |
| `archival_record` (no newer action) | Report goal is closed. |
| `archival_record` + newer `action_record` | Treat as superseded; route to Verifier. |
