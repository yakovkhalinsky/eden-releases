#!/usr/bin/env bash
# secret-guard.sh — quick scan for common secrets and internal identifiers.
# Exit 0 if nothing suspicious is found; exit 1 if manual review is needed.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Running secret guard in $ROOT ..."

# Files and directories that are part of the repository's own tooling or docs
# and should not be scanned for secret-like patterns.
EXCLUDE_PATHS=(
  'scripts/secret-guard.sh'
  'GOVERNANCE.md'
  'CHANGELOG.md'
  '.github/pull_request_template.md'
  '.github/ISSUE_TEMPLATE'
)

PATTERNS=(
  # API keys / tokens / secrets
  'api[_-]?key\s*[:=]\s*["'\''`]?[a-zA-Z0-9_-]{16,}'
  'api[_-]?secret\s*[:=]\s*["'\''`]?[a-zA-Z0-9_-]{16,}'
  'token\s*[:=]\s*["'\''`]?[a-zA-Z0-9_-]{16,}'
  'password\s*[:=]\s*["'\''`]?[^\s"'\''`]{8,}'
  'bearer\s+[a-zA-Z0-9_\-\.]+'
  'sk-[a-zA-Z0-9]{20,}'
  'ghp_[a-zA-Z0-9]{20,}'
  'github_pat_[a-zA-Z0-9_]+'
  'AKIA[0-9A-Z]{16}'
  'tskey-[a-zA-Z0-9]+'
  # Internal network identifiers (Tailscale IPs, RFC 1918, common tailnet names)
  '100\.(64|68|99|100|116|127)\.[0-9]+\.[0-9]+'
  '(10|172\.(1[6-9]|2[0-9]|3[01])|192\.168)\.[0-9]+\.[0-9]+'
  'tail[0-9a-z]+\.ts\.net'
  'tailscale\.com:[0-9]+'
)

build_excludes() {
  local args=()
  for path in "${EXCLUDE_PATHS[@]}"; do
    if command -v rg >/dev/null 2>&1; then
      args+=("-g" "!$path")
    else
      args+=("--exclude=$path")
    fi
  done
  printf '%s\n' "${args[@]}"
}

FOUND=0
EXCLUDE_ARGS=("$(build_excludes)")

for P in "${PATTERNS[@]}"; do
  if command -v rg >/dev/null 2>&1; then
    if rg -i -n --hidden -g '!.git' "${EXCLUDE_ARGS[@]}" "$P" "$ROOT"; then
      FOUND=1
    fi
  else
    if grep -RiIn --exclude-dir=.git "${EXCLUDE_ARGS[@]}" "$P" "$ROOT"; then
      FOUND=1
    fi
  fi
done

# Reject any .env files or private key files. Only check tracked/expected files,
# not dependency caches or build output.
if find "$ROOT" -maxdepth 3 -type f \( -name '.env*' -o -name '*.pem' -o -name '*.p12' -o -name '*.pfx' \) -not -path '*/.git/*' | grep -q .; then
  echo 'Found potential credential files (.env, .pem, .p12, .pfx). Remove or add to .gitignore with care.'
  FOUND=1
fi

if [ "$FOUND" -eq 0 ]; then
  echo 'No obvious secrets or internal identifiers detected.'
  exit 0
else
  echo 'Secret guard flagged items. Review the matches before committing.'
  exit 1
fi
