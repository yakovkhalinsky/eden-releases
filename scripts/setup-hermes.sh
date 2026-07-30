#!/usr/bin/env sh
# Append the eden-memory MCP server block to the active Hermes profile config.yaml.
# Run this script, then restart Hermes or reload the profile.

set -eu

if [ -z "${HOME:-}" ]; then
  echo "Error: HOME is not set." >&2
  exit 1
fi

if command -v hermes >/dev/null 2>&1; then
  PROFILE=$(hermes profile active 2>/dev/null || echo "default")
else
  PROFILE="default"
  echo "Warning: hermes not found; defaulting to profile '${PROFILE}'." >&2
fi

CONFIG_DIR="${HOME}/.hermes/profiles/${PROFILE}"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"
DB="${HOME}/.eden-memory/default.db"
BIN="${HOME}/.local/bin/eden-memory"

# Prefer absolute path if the binary is not on PATH.
if command -v eden-memory >/dev/null 2>&1; then
  COMMAND="eden-memory"
else
  COMMAND="${BIN}"
fi

mkdir -p "${CONFIG_DIR}"

if [ -f "${CONFIG_FILE}" ] && grep -q '^\s*eden:\s*$' "${CONFIG_FILE}"; then
  echo "MCP server 'eden' already present in ${CONFIG_FILE}; skipping."
  echo "Restart Hermes or reload the profile to apply changes."
  exit 0
fi

# Ensure the file exists so the append below works.
if [ ! -f "${CONFIG_FILE}" ]; then
  touch "${CONFIG_FILE}"
fi

# Append with a leading blank line if the file is not empty.
if [ -s "${CONFIG_FILE}" ]; then
  printf '\n' >> "${CONFIG_FILE}"
fi

cat >> "${CONFIG_FILE}" <<EOF
mcp:
  servers:
    eden:
      command: ${COMMAND}
      args:
        - --db
        - ${DB}
EOF

echo "Appended MCP server 'eden' to ${CONFIG_FILE} with command: ${COMMAND}"
echo "Database: ${DB}"
echo "Restart Hermes or reload the profile to apply changes."
