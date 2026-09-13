---
title: Continuation and recovery runbook
description: Recover when a role or session does not continue, using durable Memory hand-off records.
---

# Continuation and recovery runbook

This runbook covers the practical recovery pattern when an Agentic Team Protocol goal stalls because a role did not continue, a session ended, or a hand-off record was never written.

It applies after the durable hand-off mechanics added in P0: every role transition must leave a `hand_off_record` (or equivalent continuation `run_log` with full payload) in Memory before the next role is spawned.

## When to use this runbook

- A goal appears in `/team-status` as `active` or `continueable` but no role has acted for a while.
- A role subagent was spawned but produced no durable record for the goal.
- A session ended between a hand-off and the receiving role's action record.
- You need to decide between `/team-continue`, `/team-handoff`, and a manual `router` spawn.

## What to check in Memory

Search for the `goal_id` first to see the full timeline:

```bash
# Resolve identity from project config first, then .env files in subshells.
_resolve_identity() {
  _project_config="${PWD:-.}/.claude/agentic-team-config.yaml"
  _project_env="${PWD:-.}/.env"
  _global_env="${HOME}/.memory/.env"

  _yaml_value() {
    _file="$1"
    _key="$2"
    if [ -f "$_file" ]; then
      awk -v key="$_key" '
        /^---$/ { in_frontmatter = !in_frontmatter; next }
        {
          line = $0
          gsub(/#.*$/, "", line)
          pattern = "^[ \t]*" key "[ \t]*:[ \t]*"
          if (line ~ pattern) {
            sub(pattern, "", line)
            gsub(/^[ \t]+/, "", line)
            gsub(/[ \t]+$/, "", line)
            gsub(/^"+|"$/, "", line)
            gsub(/^'"'"'+|'"'"'$/, "", line)
            if (line != "") {
              print line
              exit
            }
          }
        }
      ' "$_file"
    fi
  }

  if [ -f "$_project_config" ]; then
    _cfg_org="$(_yaml_value "$_project_config" org_id)"
    _cfg_workspace="$(_yaml_value "$_project_config" workspace_id)"
    if [ -n "$_cfg_org" ] && [ -n "$_cfg_workspace" ]; then
      MEMORY_ORG_ID="$_cfg_org"
      MEMORY_WORKSPACE_ID="$_cfg_workspace"
      return
    fi
  fi

  if [ -z "${MEMORY_ORG_ID:-}" ] || [ -z "${MEMORY_WORKSPACE_ID:-}" ]; then
    if [ -f "$_project_env" ]; then
      eval "$(
        (
        set +u
        set -a
        . "$_project_env"
        set +a
        printf 'MEMORY_ORG_ID=%s\n' "${MEMORY_ORG_ID:-}"
        printf 'MEMORY_WORKSPACE_ID=%s\n' "${MEMORY_WORKSPACE_ID:-}"
        printf 'MEMORY_AGENT_ID=%s\n' "${MEMORY_AGENT_ID:-}"
      ))"
    fi
  fi

  if [ -z "${MEMORY_ORG_ID:-}" ] || [ -z "${MEMORY_WORKSPACE_ID:-}" ]; then
    if [ -f "$_global_env" ]; then
      eval "$(
        (
        set +u
        set -a
        . "$_global_env"
        set +a
        printf 'MEMORY_ORG_ID=%s\n' "${MEMORY_ORG_ID:-}"
        printf 'MEMORY_WORKSPACE_ID=%s\n' "${MEMORY_WORKSPACE_ID:-}"
        printf 'MEMORY_AGENT_ID=%s\n' "${MEMORY_AGENT_ID:-}"
      ))"
    fi
  fi
}

USER_ID="${USER:-$(id -un)}"
MEMORY_AGENT_ID="${MEMORY_AGENT_ID:-claude-code-cli}"
_resolve_identity

if [ -z "${MEMORY_ORG_ID:-}" ] || [ -z "${MEMORY_WORKSPACE_ID:-}" ] || [ -z "${MEMORY_AGENT_ID:-}" ]; then
  echo "Error: MEMORY_ORG_ID, MEMORY_WORKSPACE_ID, and MEMORY_AGENT_ID must be non-empty." >&2
  echo "Run 'memory setup claude' in this project, or set them in .claude/agentic-team-config.yaml / .env." >&2
  exit 1
fi

MEMORY_BIN="${MEMORY_BIN:-$(command -v memory || echo "${HOME}/.local/bin/memory")}"
"${MEMORY_BIN}" search \
  --agent-id "${MEMORY_AGENT_ID}" \
  --user-id "${USER_ID}" \
  --org-id "${MEMORY_ORG_ID}" \
  --workspace-id "${MEMORY_WORKSPACE_ID}" \
  --keywords "${GOAL_ID}" \
  --limit 50
```

Look for these record types, ordered by `stored_at`:

| Record type | What it tells you |
|---|---|
| `goal_record` | Original request and constraints. |
| `dispatch_instruction` | Who was assigned, success criteria, deadline, escalation trigger. |
| `context_summary` | Research findings and chosen path. Check `metadata.plan_file_path` for any written plan. |
| `action_record` | What Builder or Runtime did. Check `metadata.plan_file_path` for the implementation plan. |
| `cleanup_record` | Resources a role claims to have released before handing off to Verifier. |
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
| `/team-continue` cannot determine the next role, the lifecycle state is ambiguous, or you need a human-in-the-loop decision before routing. | Manual `router` subagent spawn | Lets a human inspect Memory and instruct the router directly. |

The Router must always write a durable hand-off record before spawning the next role. If you spawn a role manually without going through `/team-continue` or `/team-handoff`, ensure the receiving role first recalls the latest records and that a `hand_off_record` or continuation `run_log` is written as the activation signal.

## Recovery checklist

1. **Confirm the goal state with `/team-status ${GOAL_ID}`**.
2. **Search Memory for the `goal_id`** and list records by timestamp.
3. **Identify the latest non-terminal record** and the expected next role from the lifecycle table in `SKILL.md`.
4. **Check for a `blocked` or `pending_authorisation` record**. If found, stop and surface it to the user.
5. **If the latest record is a `cleanup_record`**, route to Verifier so the claimed resource releases are verified before the goal proceeds.
6. **Check that a durable hand-off record exists** linking the latest record to the expected next role.
   - If missing, run `/team-continue ${GOAL_ID}` so the router writes one before spawning the next role.
7. **Check for `plan_file_path` in `context_summary` or `action_record` metadata** to locate the latest plan file, and verify the file still exists before continuing.
8. **If the next role was already spawned but produced no record**, the router (or you) should write a recovery `hand_off_record` or `run_log` noting the missing downstream record, then re-invoke `/team-continue` or `/team-escalate`.
9. **If ownership must change**, use `/team-handoff` with a clear reason and the full goal context.
10. **After recovery, verify the next record appears in Memory** before ending the session.

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
