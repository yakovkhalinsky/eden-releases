---
description: Escalate a team goal to the appropriate authority
argument-hint: "[goal_id: reason and options]"
allowed-tools:
  - Bash
  - TaskUpdate
---

# /team-escalate

Collect goal, options, consulted roles, recommended default, specific question/authority requested, and risk of waiting. Write a structured `escalation_record` to Eden-memory and route according to escalation levels.

In **Lite mode**, escalation typically means the goal needs to be promoted to the **Full protocol** (e.g., research is required, live-system runtime is involved, or the risk profile demands the 6-role lifecycle). Record this promotion intent in the `escalation_record` metadata.

## Steps

1. Extract `goal_id` and escalation reason from `$ARGUMENTS`. If `$ARGUMENTS` is empty or missing a `goal_id`, ask the user for the required details before proceeding.
2. Search Eden-memory for the latest records about the goal to determine its `mode` and context.
3. Decide whether the escalation should:
   - Promote a Lite goal to Full protocol (`metadata.promote_to_full: true`), or
   - Escalate within the current mode to a higher authority (`metadata.promote_to_full: false`).
4. If `claude_task_id` is known from the goal metadata, update the task via `TaskUpdate` to `in_progress` with a note that the goal is escalated and awaiting user/authority input.
5. Resolve the Eden-memory workspace identity from the project `.env` or `~/.eden-memory/.env`:
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
6. Write an `escalation_record`:
   ```bash
   USER_ID="${USER:-$(id -un)}"
   EDEN_MEMORY_BIN="${EDEN_MEMORY_BIN:-$(command -v eden-memory || echo "${HOME}/.local/bin/eden-memory")}"
   "${EDEN_MEMORY_BIN}" remember \
     --agent-id dispatcher \
     --user-id "${USER_ID}" \
     --org-id "${EDEN_ORG_ID}" \
     --workspace-id "${EDEN_WORKSPACE_ID}" \
     --content "Escalation for goal ${GOAL_ID}. Reason: ${REASON}. Mode: ${MODE}. Promote to full: ${PROMOTE_TO_FULL}. Consulted roles: dispatcher. Recommended default: ${RECOMMENDED}. Question/authority requested: ${QUESTION}. Risk of waiting: ${RISK}." \
     --metadata '{"kind":"escalation_record","stage":"escalation","goal_id":"'${GOAL_ID}'","owner_role":"dispatcher","mode":"'${MODE}'","promote_to_full":"'${PROMOTE_TO_FULL}'","claude_task_id":"'${CLAUDE_TASK_ID}'","org_id":"'${EDEN_ORG_ID}'","workspace_id":"'${EDEN_WORKSPACE_ID}'"}'
   ```
7. Route according to escalation levels and report the path to the user:
   1. Owning role to Dispatcher/Overseer within one status period.
   2. Dispatcher to Anchor Operations Chair same day.
   3. Chair to Founders' Circle within 48 hours for guardrail/risk issues.
   4. Final call by Founders' Circle or project owner.
8. If `promote_to_full` is true, instruct the user to resume the goal with `/team-full` or `/team-continue ${GOAL_ID}` so the full lifecycle takes over.
9. Return the escalation record ID and the assigned routing level.
