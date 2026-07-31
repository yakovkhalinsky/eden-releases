#!/usr/bin/env sh
# Install the Agentic Team Protocol Claude Code primitives.
# Usage:
#   curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh
#   curl -fsSL ... | sh -s -- --local                 # project-local templates
#   curl -fsSL ... | sh -s -- --local --dry-run        # show what would be installed
#   curl -fsSL ... | sh -s -- --local --claude-md      # also write protocol rules into ./CLAUDE.md
#   ./install.sh --local                               # run from a local clone/package

set -eu

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

# If we are running from a curl pipe, the package directory is unknown.
# Try to download the canonical tarball; if it is not available yet, fall back
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
      echo "Note: tarball not yet published; installing individual files from public URLs."
      BASE_URL="https://0d3sa.com/agentic-team-protocol"
      mkdir -p "${TMPDIR}/files/agents" "${TMPDIR}/files/commands" "${TMPDIR}/files/templates"
      curl -fsSL "${BASE_URL}/skills/agentic-team-protocol/SKILL.md" -o "${TMPDIR}/files/SKILL.md"
      for agent in dispatcher builder runtime verifier researcher archivist; do
        curl -fsSL "${BASE_URL}/agents/${agent}.md" -o "${TMPDIR}/files/agents/${agent}.md"
      done
      for command in ratify-charter agentic-status agentic-escalate; do
        curl -fsSL "${BASE_URL}/commands/${command}.md" -o "${TMPDIR}/files/commands/${command}.md"
      done
      for template in agentic-team-charter.md agentic-team-config.yaml claude-md.md; do
        curl -fsSL "${BASE_URL}/templates/${template}" -o "${TMPDIR}/files/templates/${template}"
      done
      curl -fsSL "${BASE_URL}/CHARTER.md" -o "${TMPDIR}/files/CHARTER.md" || true
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

if [ "$DRY_RUN" = true ]; then
  echo "Would install to:"
  echo "  skill:    ${CLAUDE_DIR}/skills/agentic-team-protocol/SKILL.md"
  echo "  agents:   ${CLAUDE_DIR}/agents/{dispatcher,builder,runtime,verifier,researcher,archivist}.md"
  echo "  commands: ${CLAUDE_DIR}/commands/{ratify-charter,agentic-status,agentic-escalate}.md"
  if [ "$LOCAL_INSTALL" = true ]; then
    echo "  templates:${PWD:-.}/.claude/{agentic-team-charter.md,agentic-team-config.yaml}"
    [ "$CLAUDE_MD_INSTALL" = true ] && echo "  claude-md:${PWD:-.}/CLAUDE.md"
  fi
  exit 0
fi

mkdir -p "${CLAUDE_DIR}/skills"
mkdir -p "${CLAUDE_DIR}/agents"
mkdir -p "${CLAUDE_DIR}/commands"

echo "Installing Agentic Team Protocol global primitives..."

rm -rf "${CLAUDE_DIR}/skills/agentic-team-protocol"
mkdir -p "${CLAUDE_DIR}/skills/agentic-team-protocol"
cp "${PACKAGE_DIR}/SKILL.md" "${CLAUDE_DIR}/skills/agentic-team-protocol/SKILL.md"
# Global charter fallback, if present.
if [ -f "${PACKAGE_DIR}/CHARTER.md" ]; then
  cp "${PACKAGE_DIR}/CHARTER.md" "${CLAUDE_DIR}/skills/agentic-team-protocol/CHARTER.md"
fi

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

echo "Agentic Team Protocol installed."
echo "Restart Claude Code to load the new agents and commands."
