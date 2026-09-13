---
description: Transfer ownership of a team goal to another role or instance in a durable, searchable record
argument-hint: "goal_id: to_role [reason]"
allowed-tools:
  - Bash
  - Agent
  - TaskCreate
  - TaskUpdate
  - TaskGet
  - TaskList
---

# /team-handoff

Transfer ownership of a team goal to another role or instance. The transfer is stored as a `hand_off_record` in Memory so the receiving role can resume without relying on chat history.

## Steps

1. Parse `$ARGUMENTS` for `goal_id`, `to_role`, and optional `reason`. If any are missing, ask the user.
2. Search Memory for the latest records of the `goal_id` to capture:
   - current stage
   - current owner role and instance (if known)
   - latest `dispatch_instruction` (for success criteria, deadline, escalation trigger)
   - latest action/context/verdict record IDs
   - `worktree_path` and `branch_name` from the latest action record, if present
3. Determine the transferring role. If the hand-off is triggered by `/team-continue` or the Router, `FROM_ROLE` is `router`; otherwise it is the current owner role (e.g., `builder`, `verifier`, `archivist`).
4. Extract `claude_task_id` from the latest record metadata. Update the task via `TaskUpdate` to `in_progress` with a description naming `to_role` and `CURRENT_STAGE` (or create a new task if none exists).
5. Resolve the Memory workspace identity from the project `agentic-team-config.yaml`, then `.env`, then `~/.memory/.env`. Abort if `MEMORY_ORG_ID`, `MEMORY_WORKSPACE_ID`, or `MEMORY_AGENT_ID` would be empty.
   ```bash
   # Resolve identity from project config first, then .env files in subshells.
   _resolve_identity_from_config_or_env() {
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
   _resolve_identity_from_config_or_env

   MEMORY_ORG_ID="${MEMORY_ORG_ID:-}"
   MEMORY_WORKSPACE_ID="${MEMORY_WORKSPACE_ID:-}"
   MEMORY_AGENT_ID="${MEMORY_AGENT_ID:-claude-code-cli}"
   if [ -z "${MEMORY_ORG_ID}" ] || [ -z "${MEMORY_WORKSPACE_ID}" ] || [ -z "${MEMORY_AGENT_ID}" ]; then
     echo "Error: MEMORY_ORG_ID, MEMORY_WORKSPACE_ID, and MEMORY_AGENT_ID must be non-empty." >&2
     echo "Run 'memory setup claude' in this project, or set them in .claude/agentic-team-config.yaml / .env." >&2
     exit 1
   fi
   ```
6. Write a `hand_off_record`:
   ```bash
   USER_ID="${USER:-$(id -un)}"
   MEMORY_BIN="${MEMORY_BIN:-$(command -v memory || echo "${HOME}/.local/bin/memory")}"
   HAND_OFF_ID=$("${MEMORY_BIN}" remember \
     --agent-id "${FROM_ROLE}" \
     --user-id "${USER_ID}" \
     --org-id "${MEMORY_ORG_ID}" \
     --workspace-id "${MEMORY_WORKSPACE_ID}" \
     --content "{\"kind\":\"hand_off_record\",\"goal_id\":\"${GOAL_ID}\",\"stage\":\"${CURRENT_STAGE}\",\"from_role\":\"${FROM_ROLE}\",\"to_role\":\"${TO_ROLE}\",\"reason\":\"${REASON}\",\"input_record_ids\":[\"${LATEST_RECORD_ID}\"],\"output_record_ids\":[],\"claude_task_id\":\"${CLAUDE_TASK_ID}\",\"success_criteria\":\"${SUCCESS_CRITERIA}\",\"deadline\":\"${DEADLINE}\",\"escalation_trigger\":\"${ESCALATION_TRIGGER}\",\"worktree_path\":\"${WORKTREE_PATH}\",\"branch_name\":\"${BRANCH_NAME}\"}" \
     --metadata '{"kind":"hand_off_record","stage":"hand_off_or_closure","goal_id":"'"${GOAL_ID}"'","owner_role":"'"${FROM_ROLE}"'","claude_task_id":"'"${CLAUDE_TASK_ID}"'","org_id":"'"${MEMORY_ORG_ID}"'","workspace_id":"'"${MEMORY_WORKSPACE_ID}"'"}')
   ```
7. Spawn the receiving role subagent with the hand-off payload, `HAND_OFF_ID`, `CLAUDE_TASK_ID`, and the full goal context.

## Required fields

- `goal_id` — the goal being transferred.
- `to_role` — dispatcher | researcher | builder | runtime | verifier | archivist | router.
- `reason` — why ownership is changing (e.g., skill mismatch, session end, user request).
- `success_criteria`, `deadline`, `escalation_trigger` — copied from the latest dispatch instruction or updated by the current owner.

## Anti-patterns

- Do not hand off implicitly through chat.
- Do not hand off without recording the latest input/output record IDs.
- Do not hand off to a role that lacks the tools or charter authority to continue.
