#!/usr/bin/env sh
# Install the Agentic Team Protocol Claude Code primitives.
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

LOCAL_INSTALL=false
CLAUDE_MD_INSTALL=false
DRY_RUN=false
while [ $# -gt 0 ]; do
  case "$1" in
    --local) LOCAL_INSTALL=true; shift ;;
    --claude-md) CLAUDE_MD_INSTALL=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help)
      echo "Usage: $0 [--local] [--claude-md] [--dry-run]"
      echo "  --local       Also copy project-local templates into ./.claude/"
      echo "  --claude-md   Also write protocol enforcement rules into ./CLAUDE.md"
      echo "  --dry-run     Show what would be installed without copying"
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

# If we are running from a curl pipe, the package directory is unknown.
# Try to download the canonical tarball; if it is unavailable, fall back
# to installing from the raw public URLs so the curl path still works.
if [ ! -d "${PACKAGE_DIR}/agents" ] || [ ! -f "${PACKAGE_DIR}/SKILL.md" ]; then
  if command -v curl >/dev/null 2>&1; then
    TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR"' EXIT
    echo "Downloading Agentic Team Protocol package..."
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
    echo "[dry-run] Agentic Team Protocol installed at ${NEW_VERSION}. Restart Claude Code to load the new agents and commands."
  else
    echo "[dry-run] Agentic Team Protocol updated from ${OLD_VERSION} to ${NEW_VERSION}. Restart Claude Code to load the new agents and commands."
  fi
  exit 0
fi

mkdir -p "${CLAUDE_DIR}/skills"
mkdir -p "${CLAUDE_DIR}/agents"
mkdir -p "${CLAUDE_DIR}/commands"

echo "Installing Agentic Team Protocol global primitives..."

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
  echo "Agentic Team Protocol installed at ${NEW_VERSION}."
else
  echo "Agentic Team Protocol updated from ${OLD_VERSION} to ${NEW_VERSION}."
fi
echo ""
echo "In each project where you will use ATP, run:"
echo "  cd ~/your-project"
echo "  eden-memory setup claude"
echo "  curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh -s -- --local"
echo ""
echo "Restart Claude Code to load the new agents and commands."
