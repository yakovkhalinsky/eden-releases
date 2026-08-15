#!/usr/bin/env bash
# package-release.sh
#
# Takes downloaded eden-memory binaries and staged agent-harness skills,
# packages per-platform archives, computes SHA-256 checksums, and writes a
# manifest file suitable for the GitHub Release.
#
# Usage:
#   package-release.sh \
#     --source dist/source \
#     --skills dist/skills \
#     --version 2026.0728.1601 \
#     --release-tag v2026.0728.1601-eden-releases.1 \
#     --platforms "linux-amd64 linux-arm64 darwin-amd64 darwin-arm64" \
#     --out dist/packages

set -euo pipefail

SOURCE_DIR=""
SKILLS_DIR=""
VERSION=""
RELEASE_TAG=""
PLATFORMS="linux-amd64 linux-arm64 darwin-amd64 darwin-arm64"
OUT_DIR="dist/packages"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) SOURCE_DIR="$2"; shift 2 ;;
    --skills) SKILLS_DIR="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --release-tag) RELEASE_TAG="$2"; shift 2 ;;
    --platforms) PLATFORMS="$2"; shift 2 ;;
    --out) OUT_DIR="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 --source DIR --skills DIR --version VERSION --release-tag TAG [--platforms ...] [--out DIR]"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$SOURCE_DIR" ] || [ -z "$SKILLS_DIR" ] || [ -z "$VERSION" ] || [ -z "$RELEASE_TAG" ]; then
  echo "ERROR: --source, --skills, --version and --release-tag are required" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

# Normalise platform string to space-separated.
PLATFORMS="${PLATFORMS//,/ }"

for platform in $PLATFORMS; do
  binary_name="eden-memory-${platform}"
  binary_path="${SOURCE_DIR}/${binary_name}"

  if [ ! -f "$binary_path" ]; then
    echo "ERROR: missing source binary: $binary_path" >&2
    exit 1
  fi

  # Build a per-platform staging directory.
  stage_name="eden-memory-${VERSION}-${platform}"
  stage_dir="${OUT_DIR}/${stage_name}"
  rm -rf "$stage_dir"
  mkdir -p "$stage_dir"

  cp "$binary_path" "${stage_dir}/eden-memory"
  chmod +x "${stage_dir}/eden-memory"

  if [ -d "$SKILLS_DIR" ] && [ "$(find "$SKILLS_DIR" -mindepth 1 -print -quit 2>/dev/null)" ]; then
    cp -r "$SKILLS_DIR" "${stage_dir}/agent-harness-skills"
  fi

  # Add a small README inside the archive.
  cat > "${stage_dir}/README.txt" <<EOF
eden-memory ${RELEASE_TAG}
Platform: ${platform}
Source: yakovkhalinsky/eden-memory ${VERSION}

This archive contains the eden-memory static binary plus bundled
agent-harness skills. Place the binary on your PATH and import the skills
into your Hermes skill directory.
EOF

  # Create .tar.gz archive.
  archive_name="${stage_name}.tar.gz"
  tar -czf "${OUT_DIR}/${archive_name}" -C "$OUT_DIR" "$stage_name"
  rm -rf "$stage_dir"
  echo "Created ${OUT_DIR}/${archive_name}"
done

# Compute checksums for all generated archives and the skills tree.
(
  cd "$OUT_DIR"
  sha256sum *.tar.gz > CHECKSUMS.sha256
  if [ -d "$SKILLS_DIR" ] && [ "$(find "$SKILLS_DIR" -mindepth 1 -print -quit 2>/dev/null)" ]; then
    find "$SKILLS_DIR" -type f -print0 | sort -z | xargs -0 sha256sum >> CHECKSUMS.sha256
  fi
)

# Write a manifest JSON for the release tooling.
cat > "${OUT_DIR}/manifest.json" <<EOF
{
  "release_tag": "${RELEASE_TAG}",
  "base_version": "${VERSION}",
  "platforms": [$(echo "$PLATFORMS" | sed 's/[^ ]*/"&"/g' | sed 's/ /, /g')],
  "archives": [$(ls -1 "${OUT_DIR}"/*.tar.gz | xargs -n1 basename | sed 's/.*/"&"/' | paste -sd', -')],
  "bundled_skills_dir": "agent-harness-skills"
}
EOF

echo "Packaged release in ${OUT_DIR}:"
ls -lh "${OUT_DIR}"
