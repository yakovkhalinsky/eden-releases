---
description: Resume an unfinished Agentic Team Protocol goal from Eden-memory
argument-hint: "[goal_id]"
allowed-tools:
  - Bash
  - Agent
---

# /team-continue

Resume an unfinished Agentic Team Protocol goal by rehydrating its state from Eden-memory and dispatching the correct next role. If no `goal_id` is given, list active continueable goals first.

## Steps

1. Parse `$ARGUMENTS`. If it looks like a UUID or contains a `-`, treat it as a `goal_id`. Otherwise list active goals via `/team-status` and ask the user to pick one.
2. Search Eden-memory for the latest records of that `goal_id`:
   ```bash
   USER_ID="${USER:-$(id -un)}"
   EDEN_MEMORY_BIN="${EDEN_MEMORY_BIN:-$(command -v eden-memory || echo "${HOME}/.local/bin/eden-memory")}"
   "${EDEN_MEMORY_BIN}" search \
     --agent-id claude-code-cli \
     --user-id "${USER_ID}" \
     --keywords "${GOAL_ID}" \
     --limit 50
   ```
3. Identify the latest non-terminal record and any `blocked` or `pending_authorisation` record.
4. If the goal is `blocked` or `pending_authorisation`, report the blocker or approval question to the user and stop.
5. If the latest record is an `archival_record` with no newer action record, report that the goal is already closed.
6. Write a `run_log`:
   ```bash
   "${EDEN_MEMORY_BIN}" remember \
     --agent-id claude-code-cli \
     --user-id "${USER_ID}" \
     --content "{\"kind\":\"run_log\",\"goal_id\":\"${GOAL_ID}\",\"stage\":\"routing_and_assignment\",\"owner_role\":\"router\",\"status\":\"in_progress\",\"input_record_ids\":[\"${GOAL_ID}\"],\"output_record_ids\":[],\"note\":\"Continued via /team-continue\"}" \
     --metadata '{"kind":"run_log","stage":"routing_and_assignment","goal_id":"'"${GOAL_ID}"'","owner_role":"router"}'
   ```
7. Spawn the `router` subagent with the goal context. The router reads Eden-memory, determines the next required role, and spawns that role directly.

## Behaviour by goal state

| Latest record | Behaviour |
|---|---|
| `goal_record` | Route to Dispatcher to produce a `dispatch_instruction`. |
| `dispatch_instruction` | Route to the assigned role. |
| `context_summary` | Route to Builder or Runtime per the Dispatcher plan. |
| `action_record` | Route to Verifier. |
| `verdict` green | Route to Archivist for closure. |
| `verdict` red | Route to Dispatcher for rework assignment. |
| `verdict` blocked / `blocked` record | Report blocker and wait. |
| `pending_authorisation` | Ask the recorded approval question; resume if approved. |
| `hand_off_record` | Route to the receiving role. |
| `archival_record` (no newer action) | Report goal is closed. |
| `archival_record` + newer `action_record` | Treat as superseded; route to Verifier. |
