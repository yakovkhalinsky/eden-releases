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
2. Resolve the Eden-memory workspace identity from the project `agentic-team-config.yaml`, then `.env`, then `~/.eden-memory/.env`. Abort if `EDEN_ORG_ID`, `EDEN_WORKSPACE_ID`, or `EDEN_AGENT_ID` would be empty.
   ```bash
   # Resolve identity from project config first, then .env files in subshells.
   _resolve_identity_from_config_or_env() {
     _project_config="${PWD:-.}/.claude/agentic-team-config.yaml"
     _project_env="${PWD:-.}/.env"
     _global_env="${HOME}/.eden-memory/.env"

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
         EDEN_ORG_ID="$_cfg_org"
         EDEN_WORKSPACE_ID="$_cfg_workspace"
         return
       fi
     fi

     if [ -z "${EDEN_ORG_ID:-}" ] || [ -z "${EDEN_WORKSPACE_ID:-}" ]; then
       if [ -f "$_project_env" ]; then
         eval "$(
           (
           set +u
           set -a
           . "$_project_env"
           set +a
           printf 'EDEN_ORG_ID=%s\n' "${EDEN_ORG_ID:-}"
           printf 'EDEN_WORKSPACE_ID=%s\n' "${EDEN_WORKSPACE_ID:-}"
           printf 'EDEN_AGENT_ID=%s\n' "${EDEN_AGENT_ID:-}"
         ))"
       fi
     fi

     if [ -z "${EDEN_ORG_ID:-}" ] || [ -z "${EDEN_WORKSPACE_ID:-}" ]; then
       if [ -f "$_global_env" ]; then
         eval "$(
           (
           set +u
           set -a
           . "$_global_env"
           set +a
           printf 'EDEN_ORG_ID=%s\n' "${EDEN_ORG_ID:-}"
           printf 'EDEN_WORKSPACE_ID=%s\n' "${EDEN_WORKSPACE_ID:-}"
           printf 'EDEN_AGENT_ID=%s\n' "${EDEN_AGENT_ID:-}"
         ))"
       fi
     fi
   }
   _resolve_identity_from_config_or_env

   EDEN_ORG_ID="${EDEN_ORG_ID:-}"
   EDEN_WORKSPACE_ID="${EDEN_WORKSPACE_ID:-}"
   EDEN_AGENT_ID="${EDEN_AGENT_ID:-claude-code-cli}"
   if [ -z "${EDEN_ORG_ID}" ] || [ -z "${EDEN_WORKSPACE_ID}" ] || [ -z "${EDEN_AGENT_ID}" ]; then
     echo "Error: EDEN_ORG_ID, EDEN_WORKSPACE_ID, and EDEN_AGENT_ID must be non-empty." >&2
     echo "Run 'eden-memory setup claude' in this project, or set them in .claude/agentic-team-config.yaml / .env." >&2
     exit 1
   fi
   ```
3. Search Eden-memory for recent `goal_record`, stage, `run_log`, `hand_off_record`, `pending_authorisation`, and `blocked` records:
   ```bash
   USER_ID="${USER:-$(id -un)}"
   EDEN_AGENT_ID="${EDEN_AGENT_ID:-claude-code-cli}"
   EDEN_MEMORY_BIN="${EDEN_MEMORY_BIN:-$(command -v eden-memory || echo "${HOME}/.local/bin/eden-memory")}"
   "${EDEN_MEMORY_BIN}" search \
     --agent-id "${EDEN_AGENT_ID}" \
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
