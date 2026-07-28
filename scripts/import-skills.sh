#!/usr/bin/env bash
# import-skills.sh
#
# Copies selected Hermes skills from a local source tree into the
# eden-releases/skills/ directory so they can be bundled into the public
# release archive.
#
# By default it imports Adam's agent-harness-rollout skill. Adjust
# SKILL_NAMES and SOURCE_ROOT to import more skills.
#
# Usage:
#   ./scripts/import-skills.sh [--source-root PATH] [skill-name ...]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Default Hermes profile tree on this workstation.
SOURCE_ROOT="${SOURCE_ROOT:-/home/yakov/.hermes/profiles/adam/skills}"
DEST_ROOT="${REPO_ROOT}/skills"

# Default skills to bundle.
DEFAULT_SKILLS=(
  "software-development/agent-harness-rollout"
)

SKILL_NAMES=("$@")
if [ ${#SKILL_NAMES[@]} -eq 0 ]; then
  SKILL_NAMES=("${DEFAULT_SKILLS[@]}")
fi

mkdir -p "$DEST_ROOT"

for skill in "${SKILL_NAMES[@]}"; do
  src="${SOURCE_ROOT}/${skill}"
  if [ ! -d "$src" ]; then
    echo "ERROR: skill not found at ${src}" >&2
    exit 1
  fi

  dest="${DEST_ROOT}/${skill}"
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -r "$src" "$dest"
  echo "Imported ${skill} -> ${dest}"
done

echo "Done. Skills staged under ${DEST_ROOT}:"
find "$DEST_ROOT" -type f | sort
