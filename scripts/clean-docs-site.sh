#!/usr/bin/env bash
# clean-docs-site.sh — remove generated docs-site artifacts before committing.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/docs-site"
rm -rf .astro dist node_modules .vscode pnpm-lock.yaml pnpm-workspace.yaml 2>/dev/null || true
echo "Cleaned generated docs-site artifacts."
