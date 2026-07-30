#!/usr/bin/env sh
# Set up the eden-memory MCP server for Claude Code CLI.
# Usage: curl -fsSL https://0d3sa.com/eden-memory/setup-claude.sh | sh

set -eu

if [ -z "${HOME:-}" ]; then
  echo "Error: HOME is not set." >&2
  exit 1
fi

DB="${HOME}/.eden-memory/default.db"
BIN="${HOME}/.local/bin/eden-memory"

# If the binary is not on PATH, fall back to a direct absolute-path config.
if command -v eden-memory >/dev/null 2>&1; then
  COMMAND="eden-memory"
else
  COMMAND="${BIN}"
fi

CONFIG="{\"eden-memory\":{\"command\":\"${COMMAND}\",\"args\":[\"--db\",\"${DB}\"]}}"

claude config set mcpServers "${CONFIG}"

echo "Configured Claude Code MCP server 'eden-memory' with command: ${COMMAND}"
echo "Database: ${DB}"
echo "Restart Claude Code to pick up the new MCP server."
