#!/usr/bin/env sh
# Set up the eden-memory MCP server for Claude Code CLI.
# Paste the resulting JSON into Claude Code's MCP settings, or run this script
# and restart Claude Code.

set -eu

if [ -z "${HOME:-}" ]; then
  echo "Error: HOME is not set." >&2
  exit 1
fi

DB="${HOME}/.eden-memory/default.db"
CONFIG='{"eden-memory":{"command":"eden-memory","args":["--db","'"${DB}"'"]}}'

claude config set mcpServers "${CONFIG}"

echo "Configured Claude Code MCP server 'eden-memory' with DB: ${DB}"
echo "Restart Claude Code to pick up the new MCP server."
