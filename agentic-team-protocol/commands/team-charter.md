---
description: Ratify the project's team charter
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
5. Resolve the Eden-memory workspace identity from the project `agentic-team-config.yaml`, then `.env`, then `~/.eden-memory/.env` before storing the record. Abort if `EDEN_ORG_ID`, `EDEN_WORKSPACE_ID`, or `EDEN_AGENT_ID` would be empty.
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
6. Store a ratification record in Eden-memory:
   ```bash
   USER_ID="${USER:-$(id -un)}"
   RATER="${RATER:-${USER_ID}}"
   EDEN_MEMORY_BIN="${EDEN_MEMORY_BIN:-$(command -v eden-memory || echo "${HOME}/.local/bin/eden-memory")}"
   "${EDEN_MEMORY_BIN}" remember \
     --agent-id archivist \
     --user-id "${USER_ID}" \
     --org-id "${EDEN_ORG_ID}" \
     --workspace-id "${EDEN_WORKSPACE_ID}" \
     --content "Charter ratified for project ${EDEN_WORKSPACE_ID}. Version: ${VERSION}. Rater: ${RATER}. Date: $(date -u +%Y-%m-%dT%H:%M:%SZ). Mechanism: /team-charter. Deferrals: none." \
     --metadata '{"kind":"charter_ratification","stage":"charter_ratification","goal_id":"charter-ratification","owner_role":"archivist","org_id":"'"${EDEN_ORG_ID}"'","workspace_id":"'"${EDEN_WORKSPACE_ID}"'"}'
   ```
7. If this ratification is part of an active ATP goal and `claude_task_id` is available, update the task via `TaskUpdate` to note the charter outcome.
8. Summarise for the user: charter path, version, ratification record ID, and proceed/no-proceed status. If critical guardrails are deferred, placeholders remain, or the charter is missing, report no-proceed.
