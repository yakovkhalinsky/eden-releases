---
description: Ratify the project's team charter with an interactive checklist and confirmation
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - TaskUpdate
  - AskUserQuestion
---

# /team-charter

Read the project's `agentic-team-charter.md` (project-local first, then deliberate global fallback), walk the user through a staged ratification checklist, and store a `charter_ratification` record in Eden-memory only after explicit confirmation.

## Non-interactive bypass

If the user passes `--non-interactive` as an argument, or `ATP_NON_INTERACTIVE=1` / `CI=1` is set in the environment, skip all questions and execute the deterministic ratification path described in the **Non-interactive ratification** appendix at the end of this file.

## Helper functions

Embed these POSIX helpers near the top of the command and reuse them across phases.

```bash
# Locate the charter: project-local first, then global fallback.
_charter_path() {
  _local="${PROJECT_CLAUDE_DIR:-${PWD:-.}/.claude}/agentic-team-charter.md"
  _global="${HOME}/.claude/skills/team/CHARTER.md"
  if [ -f "$_local" ]; then
    printf '%s\n' "$_local"
  elif [ -f "$_global" ]; then
    printf '%s\n' "$_global"
  else
    printf ''
  fi
}

# Full SHA-256 of the charter file bytes.
_version_hash() {
  sha256sum "$1" | cut -d' ' -f1
}

# Short 16-character display hash.
_short_hash() {
  _version_hash "$1" | head -c 16
}

# Scan for common placeholder and template markers.
_scan_placeholders() {
  grep -nE '<(PROJECT_NAME|PROJECT_PATH|DEFAULT_BRANCH|ORG_ID|WORKSPACE_ID|Short description|One-sentence|Boundary [0-9]+|TODO|FIXME|EXAMPLE)' "$1" || true
}

# Best-effort extraction of a YAML value without external tools.
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

# Resolve Eden-memory identity from project config first, then .env files.
_resolve_identity_from_config_or_env() {
  _project_config="${PWD:-.}/.claude/agentic-team-config.yaml"
  _project_env="${PWD:-.}/.env"
  _global_env="${HOME}/.eden-memory/.env"

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
      eval "$((
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
      eval "$((
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

# Read active_roles from project config as a comma-separated list.
_active_roles_from_config() {
  _file="${PWD:-.}/.claude/agentic-team-config.yaml"
  if [ -f "$_file" ]; then
    awk '
      /^active_roles:/ { in_list = 1; next }
      in_list && /^[ \t]*-[ \t]*[a-z]/ {
        gsub(/^[ \t]*-[ \t]*/, "")
        gsub(/[ \t]+$/, "")
        if (line == "") line = $0; else line = line "," $0
      }
      in_list && !/^[ \t]*-[ \t]*/ && !/^[ \t]*$/ { exit }
      END { print line }
    ' "$_file"
  fi
}
```

## Phase A — Discovery

1. Check for non-interactive bypass:
   - If `$ARGUMENTS` contains `--non-interactive`, or
   - If `ATP_NON_INTERACTIVE=1` or `CI=1` is set, jump to the **Non-interactive ratification** appendix.

2. Locate the charter with `_charter_path`.
   - If no charter exists at either location, report the situation and ask the user whether to create a local charter from the template, ratify the global charter, or abort. Do not proceed without a charter file.
   - If only the global fallback exists, explicitly say so and ask for confirmation before using it.

3. Read the charter file and compute the full SHA-256 hash with `_version_hash` and a 16-character display hash with `_short_hash`.

4. Scan for placeholders with `_scan_placeholders`. Capture each line number and marker.

5. Resolve identity with `_resolve_identity_from_config_or_env`. Set `EDEN_AGENT_ID="${EDEN_AGENT_ID:-claude-code-cli}"`.
   - If `org_id` or `workspace_id` is empty, ask the user to run `eden-memory setup claude` and restart, or to set them in `.claude/agentic-team-config.yaml`. Abort if still unresolved.

6. Read active roles from `.claude/agentic-team-config.yaml` with `_active_roles_from_config`. Best-effort infer active roles from the charter (look for "Active roles", "Roles/seats", or the role list in the template). Compute the delta:
   - In config but not charter → charter incomplete.
   - In charter but not config → config incomplete.

7. Search Eden-memory for the most recent `charter_ratification` record for this workspace with `goal_id:charter-ratification`. If one exists, note its `charter_version` and `record_id` for the re-ratification diff.

## Phase B — Interactive checklist

Present a checklist to the user. For each item, report status (`OK`, `blocked`, or `warning`) and ask the user to confirm, defer with a reason, or edit the charter. Keep no durable state between turns; if the user edits, return to Phase A and recompute the hash.

Checklist items:

1. **Charter file located** at `<path>`.
2. **Version** `<short_hash>` (full hash in final summary).
3. **Placeholders** — list any `_scan_placeholders` hits with line numbers. Blocked until replaced or deferred.
4. **Template example text** — warn if example mission/boundary text from the template remains (e.g., "Ship observable, reversible changes safely..." or the template mission sentence).
5. **Active-role match** — show config roles vs charter roles; blocked on mismatch unless deferred.
6. **Runtime gating** — warn if Runtime is active in config but the charter does not explicitly authorise live operations, or vice versa.
7. **Default branch stated** — check that the charter/Branch discipline mentions a concrete default branch name rather than only `<DEFAULT_BRANCH>`.
8. **Eden-memory identity** — `org_id`, `workspace_id`, `agent_id` resolved.
9. **Re-ratification diff** — if a prior ratification exists, show old version hash and old vs new short hash. Ask the user to confirm they want to re-ratify.

Use `AskUserQuestion` with a multi-select or single-select question to let the user choose the next action:

- **Ratify now** (enabled only if no blockers remain, or if the user is willing to accept `no-proceed` due to deferrals).
- **Edit charter** — open the charter and let the user edit it; then restart Phase A.
- **Defer item(s)** — capture a deferral reason for each blocked/warning item; final status will be `no-proceed` if any blocker is deferred.
- **Abort** — no durable writes; report "Charter not ratified."

## Phase C — Ratification

1. Recompute the hash after any edits. Confirm the charter path and full version hash with the user.

2. Build the ratification summary:
   - `CHARTER_PATH`: absolute path.
   - `CHARTER_VERSION`: full SHA-256 hash.
   - `SHORT_VERSION`: 16-character display hash.
   - `RATER`: `${USER:-$(id -un)}`.
   - `DEFERRALS`: JSON array of `{item, reason}` objects; empty array if none.
   - `PROCEED`: `true` only if no blockers and no deferred blockers; otherwise `false`.
   - `PREVIOUS_RECORD_ID`: prior ratification record ID, if any.
   - `PREVIOUS_VERSION`: prior full hash, if any.

3. Ask final confirmation:
   > Ratify `<CHARTER_PATH>` at version `<SHORT_VERSION>`? Status will be `<proceed|no-proceed>`. Deferrals: `<list or none>`.

4. If the user does not confirm, abort with no durable writes.

5. Store the ratification record in Eden-memory:
   ```bash
   USER_ID="${USER:-$(id -un)}"
   RATER="${RATER:-${USER_ID}}"
   EDEN_MEMORY_BIN="${EDEN_MEMORY_BIN:-$(command -v eden-memory || echo "${HOME}/.local/bin/eden-memory")}"
   "${EDEN_MEMORY_BIN}" remember \
     --agent-id archivist \
     --user-id "${USER_ID}" \
     --org-id "${EDEN_ORG_ID}" \
     --workspace-id "${EDEN_WORKSPACE_ID}" \
     --content "Goal: charter-ratification | Record ID: <this_record_id> | Stage: charter_ratification | Owner: archivist | Charter: ${CHARTER_PATH} | Version: ${CHARTER_VERSION} | Short: ${SHORT_VERSION} | Rater: ${RATER} | Date: $(date -u +%Y-%m-%dT%H:%M:%SZ) | Mechanism: /team-charter | Proceed: ${PROCEED} | Deferrals: ${DEFERRALS} | Previous record: ${PREVIOUS_RECORD_ID:-none}" \
     --metadata "{\"kind\":\"charter_ratification\",\"stage\":\"charter_ratification\",\"goal_id\":\"charter-ratification\",\"owner_role\":\"archivist\",\"charter_path\":\"${CHARTER_PATH}\",\"charter_version\":\"${CHARTER_VERSION}\",\"proceed\":${PROCEED},\"deferrals\":${DEFERRALS},\"previous_record_id\":\"${PREVIOUS_RECORD_ID:-}\",\"org_id\":\"${EDEN_ORG_ID}\",\"workspace_id\":\"${EDEN_WORKSPACE_ID}\"}"
   ```
   If the MCP tools are available, use `mcp__eden-memory__eden_remember` with the same payload and explicit `org_id`/`workspace_id`.

6. If `claude_task_id` is available, update the associated task via `TaskUpdate` to `completed` with a note about the ratification outcome.

7. Report to the user:
   ```text
   Charter path: <CHARTER_PATH>
   Version: <SHORT_VERSION> (full SHA-256 in record metadata)
   Record ID: <uuid>
   Status: proceed | no-proceed
   Reason: <specific reason if no-proceed>
   ```

## Non-interactive ratification appendix

When non-interactive mode is triggered, run the original deterministic flow:

1. Determine the charter path (project-local first, then global fallback).
2. Read the charter.
3. Compute the version hash: `sha256sum "${CHARTER_PATH}" | cut -d' ' -f1`.
4. Verify the charter file exists, roles match, and no placeholders remain.
5. Resolve identity and abort if `EDEN_ORG_ID`, `EDEN_WORKSPACE_ID`, or `EDEN_AGENT_ID` is empty.
6. Store a ratification record in Eden-memory with the same metadata shape as Phase C.
7. Summarise path, version, record ID, and proceed/no-proceed status.
