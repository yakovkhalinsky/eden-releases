#!/usr/bin/env sh
# Install the Agentic Team Protocol Claude Code primitives.
# Usage:
#   curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh
#   curl -fsSL ... | sh -s -- --local   # also install project-local templates in cwd/.claude/

set -eu

LOCAL_INSTALL=false
while [ $# -gt 0 ]; do
  case "$1" in
    --local) LOCAL_INSTALL=true; shift ;;
    -h|--help)
      echo "Usage: $0 [--local]"
      echo "  --local   Also copy project-local templates into ./.claude/"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [ -z "${HOME:-}" ]; then
  echo "Error: HOME is not set." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_DIR="${SCRIPT_DIR}"
CLAUDE_DIR="${HOME}/.claude"

# If we are running from a curl pipe, the package directory is unknown.
# Download the canonical tarball in that case.
if [ ! -d "${PACKAGE_DIR}/agents" ] || [ ! -f "${PACKAGE_DIR}/SKILL.md" ]; then
  if command -v curl >/dev/null 2>&1; then
    TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR"' EXIT
    echo "Downloading Agentic Team Protocol package..."
    curl -fsSL "https://0d3sa.com/agentic-team-protocol/agentic-team-protocol.tar.gz" -o "${TMPDIR}/agentic-team-protocol.tar.gz"
    tar -xzf "${TMPDIR}/agentic-team-protocol.tar.gz" -C "$TMPDIR"
    PACKAGE_DIR="${TMPDIR}/agentic-team-protocol"
  else
    echo "Error: cannot locate package files and curl is unavailable." >&2
    exit 1
  fi
fi

mkdir -p "${CLAUDE_DIR}/skills"
mkdir -p "${CLAUDE_DIR}/agents"
mkdir -p "${CLAUDE_DIR}/commands"

echo "Installing Agentic Team Protocol global primitives..."

rm -rf "${CLAUDE_DIR}/skills/agentic-team-protocol"
mkdir -p "${CLAUDE_DIR}/skills/agentic-team-protocol"
cp "${PACKAGE_DIR}/SKILL.md" "${CLAUDE_DIR}/skills/agentic-team-protocol/SKILL.md"

for agent in dispatcher builder runtime verifier researcher archivist; do
  cp "${PACKAGE_DIR}/agents/${agent}.md" "${CLAUDE_DIR}/agents/${agent}.md"
done

for command in ratify-charter agentic-status agentic-escalate; do
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
  fi
fi

echo "Agentic Team Protocol installed."
echo "Restart Claude Code to load the new agents and commands."
