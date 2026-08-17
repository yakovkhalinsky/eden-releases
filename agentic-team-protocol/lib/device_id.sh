#!/bin/sh
# device_id.sh — derive a stable, privacy-safe device identifier from the hostname.
#
# Usage:
#   export EDEN_DEVICE_ID=$(./agentic-team-protocol/lib/device_id.sh)
#
# The identifier is deterministic for the same hostname, stable across restarts,
# and contains no personal identifiers (usernames, MAC addresses, serials, IPs).
#
# Output format: <project-slug>-<sha256(hostname)[0:16]>
# Override the project slug with EDEN_DEVICE_ID_PROJECT_SLUG (default: "eden").

set -eu

_project_slug="${EDEN_DEVICE_ID_PROJECT_SLUG:-eden}"

# Prefer HOSTNAME if already set, otherwise ask the OS.
if [ -n "${HOSTNAME:-}" ]; then
    _hostname="$HOSTNAME"
else
    _hostname="$(hostname 2>/dev/null || uname -n || echo 'unknown')"
fi

# Compute a short SHA-256 hash of the hostname. Works on Linux (sha256sum)
# and macOS/BSD (shasum -a 256).
_hash() {
    if command -v sha256sum >/dev/null 2>&1; then
        printf '%s' "$1" | sha256sum | awk '{print $1}' | cut -c1-16
    elif command -v shasum >/dev/null 2>&1; then
        printf '%s' "$1" | shasum -a 256 | awk '{print $1}' | cut -c1-16
    else
        printf '0000000000000000'
    fi
}

printf '%s-%s\n' "$_project_slug" "$(_hash "$_hostname")"
