---
description: Show active Agentic Team Protocol goals and current stages
argument-hint: "[optional goal_id or role filter]"
allowed-tools:
  - Bash
---

# /agentic-status

List active goals, current stage, owner role, and latest record IDs. Optionally filter by `goal_id` or role.

## Steps

1. Parse `$ARGUMENTS` as an optional filter. If it looks like a UUID or contains a `-`, treat it as a `goal_id` filter; otherwise treat it as a role filter.
2. Search Eden-memory for recent `goal_record` and stage records:
   ```bash
   /home/yakov/.local/bin/eden-memory search \
     --agent-id claude-code-cli \
     --user-id yakov \
     --keywords "agentic-team-protocol goal_record stage" \
     --limit 50
   ```
3. Group results by `goal_id` and find the latest stage per goal.
4. If a filter is provided, restrict the output to matching goals or roles.
5. Present a table with columns: goal_id, current stage, owner role, latest record ID, deadline (if recorded), and confidence/escalation trigger.
6. If no active goals are found, report that clearly.
