---
description: Escalate an Agentic Team Protocol goal to the appropriate authority
argument-hint: "[goal_id: reason and options]"
allowed-tools:
  - Bash
---

# /agentic-escalate

Collect goal, options, consulted roles, recommended default, specific question/authority requested, and risk of waiting. Write a structured `escalation_record` to Eden-memory and route according to escalation levels.

## Steps

1. Extract `goal_id` and escalation reason from `$ARGUMENTS`. If `$ARGUMENTS` is empty or missing a `goal_id`, ask the user for the required details before proceeding.
2. Search Eden-memory for the latest records about the goal to include context.
3. Write an `escalation_record`:
   ```bash
   USER_ID="${USER:-$(id -un)}"
   EDEN_MEMORY_BIN="${EDEN_MEMORY_BIN:-$(command -v eden-memory || echo "${HOME}/.local/bin/eden-memory")}"
   "${EDEN_MEMORY_BIN}" remember \
     --agent-id claude-code-cli \
     --user-id "${USER_ID}" \
     --content "Escalation for goal ${GOAL_ID}. Reason: ${REASON}. Consulted roles: dispatcher. Recommended default: ${RECOMMENDED}. Question/authority requested: ${QUESTION}. Risk of waiting: ${RISK}." \
     --metadata '{"kind":"escalation_record","stage":"escalation","goal_id":"'${GOAL_ID}'","owner_role":"dispatcher"}'
   ```
4. Route according to escalation levels and report the path to the user:
   1. Owning role to Dispatcher/Overseer within one status period.
   2. Dispatcher to Anchor Operations Chair same day.
   3. Chair to Founders' Circle within 48 hours for guardrail/risk issues.
   4. Final call by Founders' Circle or project owner.
5. Return the escalation record ID and the assigned routing level.
