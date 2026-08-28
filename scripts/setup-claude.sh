#!/usr/bin/env sh
# Set up the eden-memory MCP server for Claude Code CLI.
# Usage: curl -fsSL https://0d3sa.com/eden-memory/setup-claude.sh | sh
# Usage with explicit agent_id: curl -fsSL https://0d3sa.com/eden-memory/setup-claude.sh | sh -s -- my-agent
#
# Agent identity precedence:
# 1. Explicit positional argument (e.g. `sh -s -- my-agent`).
# 2. Fallback `claude-code-cli`.

set -eu

if [ -z "${HOME:-}" ]; then
  echo "Error: HOME is not set." >&2
  exit 1
fi

DB="${HOME}/.eden-memory/default.db"
BIN="${HOME}/.local/bin/eden-memory"

# Derive the agent_id to advertise to Claude Code.
# Precedence: explicit positional arg > claude-code-cli.
AGENT_ID_FROM_ARG="${1:-}"

if [ -n "${AGENT_ID_FROM_ARG}" ]; then
  AGENT_ID="${AGENT_ID_FROM_ARG}"
else
  AGENT_ID="claude-code-cli"
fi

# If the binary is not on PATH, fall back to a direct absolute-path config.
if command -v eden-memory >/dev/null 2>&1; then
  COMMAND="eden-memory"
else
  COMMAND="${BIN}"
fi

CONFIG="{\"eden-memory\":{\"command\":\"${COMMAND}\",\"args\":[\"--db\",\"${DB}\"],\"env\":{\"EDEN_LOG_LEVEL\":\"INFO\",\"EDEN_AGENT_ID\":\"${AGENT_ID}\"}}}"

claude config set mcpServers "${CONFIG}"

echo "Configured Claude Code MCP server 'eden-memory' with command: ${COMMAND}"
echo "Database: ${DB}"
echo "Agent ID: ${AGENT_ID}"
echo "Restart Claude Code to pick up the new MCP server."
