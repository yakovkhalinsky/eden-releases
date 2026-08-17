#!/usr/bin/env sh
# Install the Team Protocol Claude Code primitives.
# Usage:
#   curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh
#   curl -fsSL ... | sh -s -- --local                 # project-local templates
#   curl -fsSL ... | sh -s -- --local --dry-run        # show what would be installed
#   curl -fsSL ... | sh -s -- --local --claude-md      # also write protocol rules into ./CLAUDE.md
#   ./install.sh --local                               # run from a local clone/package

set -eu

# Extract the `version:` value from a YAML-frontmatter SKILL.md file.
# Returns the empty string if the file is missing or has no version key.
_extract_version() {
  _file="$1"
  if [ -f "$_file" ]; then
    awk '
      /^---$/ { in_frontmatter = !in_frontmatter; next }
      in_frontmatter && /^[ \t]*version:/ {
        sub(/^[ \t]*version:[ \t]*/, "")
        sub(/[ \t]*$/, "")
        gsub(/^"+|"$/, "")
        gsub(/^'"'"'+|'"'"'$/, "")
        print
        exit
      }
    ' "$_file"
  fi
}

# Extract a simple key: value from a YAML file without external tools.
# Handles optional quotes, inline comments, and frontmatter delimiters.
_extract_yaml_value() {
  _file="$1"
  _key="$2"
  if [ -f "$_file" ]; then
    awk -v key="$_key" '
      /^---$/ { in_frontmatter = !in_frontmatter; next }
      {
        line = $0
        # Strip inline comments outside quotes (best-effort).
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

# Resolve org_id and workspace_id from the project config first, then .env files.
# Uses a subshell when sourcing .env so `set -a` does not leak into this process.
_resolve_identity() {
  _project_config="${PWD:-.}/.claude/agentic-team-config.yaml"
  _project_env="${PWD:-.}/.env"
  _global_env="${HOME}/.eden-memory/.env"

  if [ -f "$_project_config" ]; then
    _cfg_org="$(_extract_yaml_value "$_project_config" org_id)"
    _cfg_workspace="$(_extract_yaml_value "$_project_config" workspace_id)"
    if [ -n "$_cfg_org" ] && [ -n "$_cfg_workspace" ]; then
      EDEN_ORG_ID="$_cfg_org"
      EDEN_WORKSPACE_ID="$_cfg_workspace"
      return
    fi
  fi

  if [ -z "${EDEN_ORG_ID:-}" ] || [ -z "${EDEN_WORKSPACE_ID:-}" ]; then
    if [ "$LOCAL_INSTALL" = true ] && [ -n "${PWD:-}" ] && [ -f "$_project_env" ]; then
      eval "$(
        (
          set +u
          set -a
          . "$_project_env"
          set +a
          printf 'EDEN_ORG_ID=%s\n' "${EDEN_ORG_ID:-}"
          printf 'EDEN_WORKSPACE_ID=%s\n' "${EDEN_WORKSPACE_ID:-}"
        )
      )"
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
        )
      )"
    fi
  fi
}

LOCAL_INSTALL=false
CLAUDE_MD_INSTALL=false
DRY_RUN=false
CHECK=false
VERSION_URL="https://0d3sa.com/agentic-team-protocol/VERSION"
while [ $# -gt 0 ]; do
  case "$1" in
    --local) LOCAL_INSTALL=true; shift ;;
    --claude-md) CLAUDE_MD_INSTALL=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --check) CHECK=true; shift ;;
    -h|--help)
      echo "Usage: $0 [--local] [--claude-md] [--dry-run] [--check]"
      echo "  --local       Also copy project-local templates into ./.claude/"
      echo "  --claude-md   Also write protocol enforcement rules into ./CLAUDE.md"
      echo "  --dry-run     Show what would be installed without copying"
      echo "  --check       Compare the installed version with the latest remote VERSION"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [ "$CLAUDE_MD_INSTALL" = true ] && [ "$LOCAL_INSTALL" != true ]; then
  echo "Warning: --claude-md requires --local; enabling --local automatically." >&2
  LOCAL_INSTALL=true
fi

if [ -z "${HOME:-}" ]; then
  echo "Error: HOME is not set." >&2
  exit 1
fi

# Resolve the identity and binary path dynamically.
USER_ID="${USER:-${LOGNAME:-$(id -un)}}"
EDEN_MEMORY_BIN="${EDEN_MEMORY_BIN:-$(command -v eden-memory || true)}"
if [ -z "${EDEN_MEMORY_BIN}" ]; then
  EDEN_MEMORY_BIN="${HOME}/.local/bin/eden-memory"
fi

# Resolve Eden-memory workspace identity before installing.
# Prefer project-local agentic-team-config.yaml, then .env files, then the global env.
if [ -z "${EDEN_ORG_ID:-}" ] || [ -z "${EDEN_WORKSPACE_ID:-}" ]; then
  _resolve_identity
fi
EDEN_ORG_ID="${EDEN_ORG_ID:-}"
EDEN_WORKSPACE_ID="${EDEN_WORKSPACE_ID:-}"
echo "Eden-memory identity: org_id='${EDEN_ORG_ID}' workspace_id='${EDEN_WORKSPACE_ID}'"

# The eden-memory CLI currently accepts empty --org-id/--workspace-id values and
# reads/writes unscoped records. ATP refuses to proceed with empty scope for a
# project-local install; the permanent fix requires an eden-memory binary update.
if [ "$LOCAL_INSTALL" = true ]; then
  if [ -z "${EDEN_ORG_ID}" ] || [ -z "${EDEN_WORKSPACE_ID}" ]; then
    echo "Error: EDEN_ORG_ID and EDEN_WORKSPACE_ID must be non-empty for a project-local install." >&2
    echo "Run 'eden-memory setup claude' in this project first, or set them in .claude/agentic-team-config.yaml / .env." >&2
    echo "If the values are set but empty, escalate or file an issue against eden-memory; the CLI should reject empty scope." >&2
    exit 1
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_DIR="${SCRIPT_DIR}"
CLAUDE_DIR="${HOME}/.claude"

# Determine the previously installed version, if any.
OLD_VERSION=""
if [ "$LOCAL_INSTALL" = true ] && [ -n "${PWD:-}" ]; then
  OLD_VERSION="$(_extract_version "${PWD}/.claude/skills/agentic-team-protocol/SKILL.md")"
else
  OLD_VERSION="$(_extract_version "${CLAUDE_DIR}/skills/team/SKILL.md")"
fi
[ -z "$OLD_VERSION" ] && OLD_VERSION="none"

# --check reports whether the installed version is current and exits.
if [ "$CHECK" = true ]; then
  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: --check requires curl." >&2
    exit 1
  fi
  REMOTE_VERSION="$(curl -fsSL "${VERSION_URL}" 2>/dev/null || true)"
  REMOTE_VERSION="$(printf '%s' "${REMOTE_VERSION}" | tr -d '[:space:]')"
  if [ -z "${REMOTE_VERSION}" ]; then
    echo "Could not fetch remote version from ${VERSION_URL}."
    exit 1
  fi
  if [ "$OLD_VERSION" = "none" ]; then
    echo "Team Protocol is not installed. Latest version is ${REMOTE_VERSION}."
  elif [ "$OLD_VERSION" = "$REMOTE_VERSION" ]; then
    echo "Team Protocol is up to date (${OLD_VERSION})."
  else
    echo "Team Protocol update available: ${OLD_VERSION} → ${REMOTE_VERSION}"
  fi
  exit 0
fi

# If we are running from a curl pipe, the package directory is unknown.
# Try to download the canonical tarball; if it is unavailable, fall back
# to installing from the raw public URLs so the curl path still works.
if [ ! -d "${PACKAGE_DIR}/agents" ] || [ ! -f "${PACKAGE_DIR}/SKILL.md" ]; then
  if command -v curl >/dev/null 2>&1; then
    TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR"' EXIT
    echo "Downloading Team Protocol package..."
    TARBALL_URL="https://0d3sa.com/agentic-team-protocol/agentic-team-protocol.tar.gz"
    if curl -fsSL "${TARBALL_URL}" -o "${TMPDIR}/agentic-team-protocol.tar.gz" 2>/dev/null; then
      tar -xzf "${TMPDIR}/agentic-team-protocol.tar.gz" -C "$TMPDIR"
      PACKAGE_DIR="${TMPDIR}/agentic-team-protocol"
    else
      echo "Note: tarball unavailable; installing individual files from public URLs."
      BASE_URL="https://0d3sa.com/agentic-team-protocol"
      mkdir -p "${TMPDIR}/files/agents" "${TMPDIR}/files/commands" "${TMPDIR}/files/templates"
      # Download with explicit failure messages so a 404 is obvious.
      _download() {
        url="$1"
        dest="$2"
        if ! curl -fsSL "${url}" -o "${dest}"; then
          echo "Error: failed to download ${url}" >&2
          rm -rf "${TMPDIR}"
          exit 1
        fi
      }
      _download "${BASE_URL}/SKILL.md" "${TMPDIR}/files/SKILL.md"
      for agent in dispatcher builder runtime verifier researcher archivist router; do
        _download "${BASE_URL}/agents/${agent}.md" "${TMPDIR}/files/agents/${agent}.md"
      done
      for command in team-charter team-status team-escalate team-continue team-handoff; do
        _download "${BASE_URL}/commands/${command}.md" "${TMPDIR}/files/commands/${command}.md"
      done
      for template in agentic-team-charter.md agentic-team-config.yaml claude-md.md; do
        _download "${BASE_URL}/templates/${template}" "${TMPDIR}/files/templates/${template}"
      done
      mkdir -p "${TMPDIR}/files/templates/skills/agentic-team-protocol"
      _download "${BASE_URL}/templates/skills/agentic-team-protocol/SKILL.md" "${TMPDIR}/files/templates/skills/agentic-team-protocol/SKILL.md"
      _download "${BASE_URL}/CHARTER.md" "${TMPDIR}/files/CHARTER.md"
      PACKAGE_DIR="${TMPDIR}/files"
    fi
  else
    echo "Error: cannot locate package files and curl is unavailable." >&2
    exit 1
  fi
fi

if [ ! -d "${PACKAGE_DIR}/agents" ] || [ ! -f "${PACKAGE_DIR}/SKILL.md" ]; then
  echo "Error: could not locate package files." >&2
  exit 1
fi

NEW_VERSION="$(_extract_version "${PACKAGE_DIR}/SKILL.md")"
[ -z "$NEW_VERSION" ] && NEW_VERSION="unknown"

if [ "$DRY_RUN" = true ]; then
  echo "Would install to:"
  echo "  skill:    ${CLAUDE_DIR}/skills/team/SKILL.md"
  echo "  agents:   ${CLAUDE_DIR}/agents/{dispatcher,builder,runtime,verifier,researcher,archivist,router}.md"
  echo "  commands: ${CLAUDE_DIR}/commands/{team-charter,team-status,team-escalate,team-continue,team-handoff}.md"
  if [ "$LOCAL_INSTALL" = true ]; then
    echo "  templates:${PWD:-.}/.claude/{agentic-team-charter.md,agentic-team-config.yaml}"
    echo "  skill:   ${PWD:-.}/.claude/skills/agentic-team-protocol/SKILL.md"
    [ "$CLAUDE_MD_INSTALL" = true ] && echo "  claude-md:${PWD:-.}/CLAUDE.md"
  fi
  if [ "$OLD_VERSION" = "none" ]; then
    echo "[dry-run] Team Protocol installed at ${NEW_VERSION}. Restart Claude Code to load the new agents and commands."
  else
    echo "[dry-run] Team Protocol updated from ${OLD_VERSION} to ${NEW_VERSION}. Restart Claude Code to load the new agents and commands."
  fi
  exit 0
fi

mkdir -p "${CLAUDE_DIR}/skills"
mkdir -p "${CLAUDE_DIR}/agents"
mkdir -p "${CLAUDE_DIR}/commands"

echo "Installing Team Protocol global primitives..."

rm -rf "${CLAUDE_DIR}/skills/agentic-team-protocol"
rm -rf "${CLAUDE_DIR}/skills/team"
mkdir -p "${CLAUDE_DIR}/skills/team"
cp "${PACKAGE_DIR}/SKILL.md" "${CLAUDE_DIR}/skills/team/SKILL.md"
# Global charter fallback, if present.
if [ -f "${PACKAGE_DIR}/CHARTER.md" ]; then
  cp "${PACKAGE_DIR}/CHARTER.md" "${CLAUDE_DIR}/skills/team/CHARTER.md"
fi

for agent in dispatcher builder runtime verifier researcher archivist router; do
  cp "${PACKAGE_DIR}/agents/${agent}.md" "${CLAUDE_DIR}/agents/${agent}.md"
done

for command in team-charter team-status team-escalate team-continue team-handoff; do
  cp "${PACKAGE_DIR}/commands/${command}.md" "${CLAUDE_DIR}/commands/${command}.md"
done

if [ "$LOCAL_INSTALL" = true ]; then
  if [ -z "${PWD:-}" ]; then
    echo "Warning: PWD not set; skipping project-local install." >&2
  else
    PROJECT_CLAUDE_DIR="${PWD}/.claude"
    mkdir -p "$PROJECT_CLAUDE_DIR"
    echo "Installing project-local templates into ${PROJECT_CLAUDE_DIR}..."
    if [ ! -f "${PROJECT_CLAUDE_DIR}/agentic-team-charter.md" ]; then
      cp "${PACKAGE_DIR}/templates/agentic-team-charter.md" "${PROJECT_CLAUDE_DIR}/agentic-team-charter.md"
    else
      echo "  Skipping agentic-team-charter.md (already exists)"
    fi
    if [ ! -f "${PROJECT_CLAUDE_DIR}/agentic-team-config.yaml" ]; then
      cp "${PACKAGE_DIR}/templates/agentic-team-config.yaml" "${PROJECT_CLAUDE_DIR}/agentic-team-config.yaml"
    else
      echo "  Skipping agentic-team-config.yaml (already exists)"
      # Warn users whose existing config predates worktree_policy so they know
      # they remain on the legacy single-checkout flow until they opt in.
      if ! grep -q '^worktree_policy:' "${PROJECT_CLAUDE_DIR}/agentic-team-config.yaml"; then
        echo "  Note: your existing agentic-team-config.yaml does not contain worktree_policy."
        echo "        Worktree-per-goal isolation is disabled until you add the worktree_policy block."
        echo "        See https://0d3sa.com/agentic-team-protocol/how-to/parallel-goals/"
      fi
    fi

    LOCAL_SKILL_DIR="${PROJECT_CLAUDE_DIR}/skills/agentic-team-protocol"
    mkdir -p "$LOCAL_SKILL_DIR"
    if [ ! -f "${LOCAL_SKILL_DIR}/SKILL.md" ]; then
      cp "${PACKAGE_DIR}/templates/skills/agentic-team-protocol/SKILL.md" "${LOCAL_SKILL_DIR}/SKILL.md"
    else
      echo "  Skipping .claude/skills/agentic-team-protocol/SKILL.md (already exists)"
    fi

    if [ "$CLAUDE_MD_INSTALL" = true ]; then
      CLAUDE_MD_PATH="${PWD}/CLAUDE.md"
      if [ ! -f "$CLAUDE_MD_PATH" ]; then
        echo "  Writing protocol rules to ${CLAUDE_MD_PATH}..."
        cp "${PACKAGE_DIR}/templates/claude-md.md" "$CLAUDE_MD_PATH"
      elif grep -q '<!-- AGENTIC TEAM PROTOCOL RULES -->' "$CLAUDE_MD_PATH"; then
        echo "  Skipping CLAUDE.md (protocol rules already present)"
      else
        echo "  Appending protocol rules to ${CLAUDE_MD_PATH}..."
        {
          echo ""
          echo ""
          cat "${PACKAGE_DIR}/templates/claude-md.md"
        } >> "$CLAUDE_MD_PATH"
      fi
    fi
  fi
fi

if [ "$OLD_VERSION" = "none" ]; then
  echo "Team Protocol installed at ${NEW_VERSION}."
else
  echo "Team Protocol updated from ${OLD_VERSION} to ${NEW_VERSION}."
fi
echo ""
echo "To enable team mode in a project, run:"
echo "  cd ~/your-project"
echo "  eden-memory setup claude"
echo ""
echo "Restart Claude Code to load the new agents and commands."
