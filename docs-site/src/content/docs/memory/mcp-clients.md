---
title: Connect your MCP client
description: Hub page for connecting memory to Claude Code, Cursor, Hermes, or any other stdio MCP client.
content_type: concept
---

memory speaks the Model Context Protocol (MCP) over stdio. Once you add it as a server, your agent can call `memory_remember`, `memory_recall`, `memory_search`, and the rest of the memory tool set.

## Per-client setup

Follow the tutorial for your harness:

- [Connect Claude Code](/memory/tutorials/connect-claude-code/)
- [Connect Cursor](/memory/tutorials/connect-cursor/)
- [Connect another MCP client](/memory/tutorials/connect-mcp-client/)
- [Install the Hermes skill](/memory/skills/memory-hermes/)

## HTTP transport

If your MCP client supports Streamable HTTP instead of stdio, you can run memory as a self-hosted HTTP server:

- [Run a local HTTP MCP server](/memory/tutorials/streamable-http-local/)

The HTTP server binds to a local address (default `127.0.0.1:8788`), requires bearer-token authentication, and exposes a server-card endpoint for auto-discovery.

## Generate a config snippet

The setup command can print a paste-ready JSON snippet with absolute paths:

```bash
od3sa-memory setup --print-mcp-json
```

This prints an `mcpServers` JSON block with the resolved binary path and database path. If you have set `MEMORY_ORG_ID` or `MEMORY_WORKSPACE_ID` (or run `setup claude` in a project directory first), the snippet includes those in the `env` block as well.

The command prints to stdout — it does **not** write any config files automatically.

## Generic server command

If your client lets you enter a server command directly, use the `command` and `args` from the generated snippet, or construct them manually:

```bash
/home/yourname/.local/bin/od3sa-memory --db /home/yourname/.memory/default.db
```

Replace `/home/yourname` with your actual home path. The `--db` path must be absolute, and the parent directory must exist.

## Generic JSON shape

If your client uses a `mcpServers` JSON config, paste the output from `setup --print-mcp-json`, or add this manually:

```json
{
  "mcpServers": {
    "memory": {
      "command": "/home/yourname/.local/bin/od3sa-memory",
      "args": [
        "--db",
        "/home/yourname/.memory/default.db"
      ],
      "env": {
        "MEMORY_LOG_LEVEL": "INFO"
      }
    }
  }
}
```

Use absolute paths and restart the client after adding the server.

**Note**: Claude Code CLI uses a different config file (`~/.claude.json`) with project-scoped MCP entries — see [Connect Claude Code](/memory/tutorials/connect-claude-code/). Most other MCP clients (Cursor, generic harnesses) use the `mcpServers` JSON shape shown above.

## Available tools

Once connected, your agent can call tools such as:

- `memory_remember` / `memory_recall` — store and retrieve memories
- `memory_search` / `memory_search_semantic` — keyword and semantic search
- `memory_edit` / `memory_forget` — update and delete memories
- `memory_health` / `memory_vacuum` — health and maintenance
- `memory_sync` / `memory_pair_device` / `memory_sync_loop` — sync and pairing

See the [tools reference](/memory/reference/tools/) for full schemas and the [multi-device sync overview](/memory/multi-device-sync/) for sync walkthroughs.

## Troubleshooting

- **Server exits** — make sure `--db` is an absolute path and the parent directory exists.
- **Command not found** — add `~/.local/bin` to your PATH, or use the full binary path.
- **Config not picked up** — restart the client after changing the config.
- **First recall is slow** — the embedding model loads on the first call. Subsequent calls are fast.

## Next steps

- [Quick start](/memory/getting-started/)
- [Connect Claude Code](/memory/tutorials/connect-claude-code/)
- [Connect Cursor](/memory/tutorials/connect-cursor/)
- [Connect another MCP client](/memory/tutorials/connect-mcp-client/)
- [Skills registry](/memory/skills/)
