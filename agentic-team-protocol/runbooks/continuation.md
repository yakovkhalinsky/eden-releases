---
title: Continuation and recovery runbook
description: Recover when a role or session does not continue, using durable Eden-memory hand-off records.
---

# Continuation and recovery runbook

This runbook covers the practical recovery pattern when an Agentic Team Protocol goal stalls because a role did not continue, a session ended, or a hand-off record was never written.

It applies after the durable hand-off mechanics added in P0: every role transition must leave a `hand_off_record` (or equivalent continuation `run_log` with full payload) in Eden-memory before the next role is spawned.

## When to use this runbook

- A goal appears in `/team-status` as `active` or `continueable` but no role has acted for a while.
- A role subagent was spawned but produced no durable record for the goal.
- A session ended between a hand-off and the receiving role's action record.
- You need to decide between `/team-continue`, `/team-handoff`, and a manual `router` spawn.

## What to check in Eden-memory

Search for the `goal_id` first to see the full timeline:

```bash
USER_ID="${USER:-$(id -un)}"
EDEN_MEMORY_BIN="${EDEN_MEMORY_BIN:-$(command -v eden-memory || echo "${HOME}/.local/bin/eden-memory")}"
"${EDEN_MEMORY_BIN}" search \
  --agent-id claude-code-cli \
  --user-id "${USER_ID}" \
  --keywords "${GOAL_ID}" \
  --limit 50
```

Look for these record types, ordered by `stored_at`:

| Record type | What it tells you |
|---|---|
| `goal_record` | Original request and constraints. |
| `dispatch_instruction` | Who was assigned, success criteria, deadline, escalation trigger. |
| `context_summary` | Research findings and chosen path. |
| `action_record` | What Builder or Runtime did. |
| `verdict` | Verifier's green/red/blocked decision. |
| `hand_off_record` | Explicit ownership transfer between roles. |
| `run_log` | Coarse-grained event, often written by the router at continuation. |
| `blocked` or `pending_authorisation` | A stop condition that must be cleared before work continues. |
| `archival_record` | Closure. A newer action record supersedes it. |

If a `blocked` or `pending_authorisation` record is the most recent non-terminal record, the goal is not ready for automatic continuation. Surface the blocker or approval question to the user and wait.

## How to identify the latest non-terminal record

1. Filter out terminal/closure records (`archival_record`) unless a newer action record exists.
2. Pick the record with the latest `stored_at` timestamp among the remaining types.
3. Note its `stage`, `owner_role`, and `input_record_ids`/`output_record_ids`.
4. If the latest durable record has no corresponding downstream record from the expected next role, the previous hand-off likely failed or the receiving role did not act.

A durable hand-off should always look like this:

- `input_record_ids` points to the latest stage record(s), not the raw `goal_id`.
- `output_record_ids` includes the new `hand_off_record` or continuation `run_log`.
- The receiving role is named in `to_role` or `next_role`.
- Success criteria, deadline, and escalation trigger are present.

If any of those fields are missing, the hand-off is incomplete and the goal may stall.

## `/team-continue` vs `/team-handoff` vs manual Router spawn

Use the right tool for the recovery situation:

| Situation | Tool | Why |
|---|---|---|
| The latest record is a normal lifecycle record and the next role has not yet acted, but there is no active blocker. | `/team-continue ${GOAL_ID}` | The router rehydrates the goal, writes a durable continuation record, and spawns the correct next role. |
| You need to transfer ownership deliberately (e.g., session end, skill mismatch, user request). | `/team-handoff ${GOAL_ID}: ${TO_ROLE} ${REASON}` | Creates an explicit `hand_off_record` with full payload before spawning the target role. |
| `/team-continue` cannot determine the next role, the lifecycle state is ambiguous, or you need a human-in-the-loop decision before routing. | Manual `router` subagent spawn | Lets a human inspect Eden-memory and instruct the router directly. |

The Router must always write a durable hand-off record before spawning the next role. If you spawn a role manually without going through `/team-continue` or `/team-handoff`, ensure the receiving role first recalls the latest records and that a `hand_off_record` or continuation `run_log` is written as the activation signal.

## Recovery checklist

1. **Confirm the goal state with `/team-status ${GOAL_ID}`**.
2. **Search Eden-memory for the `goal_id`** and list records by timestamp.
3. **Identify the latest non-terminal record** and the expected next role from the lifecycle table in `SKILL.md`.
4. **Check for a `blocked` or `pending_authorisation` record**. If found, stop and surface it to the user.
5. **Check that a durable hand-off record exists** linking the latest record to the expected next role.
   - If missing, run `/team-continue ${GOAL_ID}` so the router writes one before spawning the next role.
6. **If the next role was already spawned but produced no record**, the router (or you) should write a recovery `hand_off_record` or `run_log` noting the missing downstream record, then re-invoke `/team-continue` or `/team-escalate`.
7. **If ownership must change**, use `/team-handoff` with a clear reason and the full goal context.
8. **After recovery, verify the next record appears in Eden-memory** before ending the session.

## Escalation path

If recovery is not clear:

1. Re-read `SKILL.md` Hand-off format and Router obligation sections.
2. Re-read `agents/router.md` Procedure and Lifecycle decision table.
3. Use `/team-escalate ${GOAL_ID}: cannot determine next role or missing downstream record`.
4. Do not silently spawn a role without a durable activation record.

## See also

- `SKILL.md` — Hand-off format and Router obligation.
- `agents/router.md` — Full router contract and recovery step.
- `commands/team-continue.md` — Resume an unfinished goal.
- `commands/team-handoff.md` — Explicit ownership transfer.
