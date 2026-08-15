---
description: Ratify the project's Agentic Team Protocol charter
allowed-tools:
  - Bash
  - Read
  - TaskUpdate
---

# /team-charter

Read the project's `agentic-team-charter.md` (project-local first, then global fallback), store a ratification record in Eden-memory, and report whether the team may proceed to production implementation.

## Steps

1. Determine the charter path:
   - Look for a project-local charter at `.claude/agentic-team-charter.md` relative to the current working directory (or `${PROJECT_CLAUDE_DIR}/agentic-team-charter.md` if set).
   - Otherwise fall back to `~/.claude/skills/team/CHARTER.md` if it exists.
2. Read the charter with `Read` or `cat`.
3. Compute a simple version hash from the file content:
   ```bash
   VERSION=$(sha256sum "${CHARTER_PATH}" | cut -d' ' -f1 | head -c 16)
   ```
4. Verify before recording:
   - Confirm the charter file exists.
   - Confirm the active roles in `agentic-team-config.yaml` match the charter.
   - If the charter still contains placeholder values such as `<PROJECT_NAME>`, report `no-proceed`.
5. Store a ratification record in Eden-memory:
   ```bash
   USER_ID="${USER:-$(id -un)}"
   RATER="${RATER:-${USER_ID}}"
   EDEN_MEMORY_BIN="${EDEN_MEMORY_BIN:-$(command -v eden-memory || echo "${HOME}/.local/bin/eden-memory")}"
   "${EDEN_MEMORY_BIN}" remember \
     --agent-id archivist \
     --user-id "${USER_ID}" \
     --content "Charter ratified for project. Version: ${VERSION}. Rater: ${RATER}. Date: $(date -u +%Y-%m-%dT%H:%M:%SZ). Mechanism: /team-charter. Deferrals: none." \
     --metadata '{"kind":"charter_ratification","stage":"charter_ratification","goal_id":"charter-ratification","owner_role":"archivist"}'
   ```
6. If this ratification is part of an active ATP goal and `claude_task_id` is available, update the task via `TaskUpdate` to note the charter outcome.
7. Summarise for the user: charter path, version, ratification record ID, and proceed/no-proceed status. If critical guardrails are deferred, placeholders remain, or the charter is missing, report no-proceed.
