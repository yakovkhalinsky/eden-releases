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

## Generic server command

If your client lets you enter a server command directly, use:

```bash
/home/yourname/.local/bin/memory --db /home/yourname/.memory/default.db
```

Replace `/home/yourname` with your actual home path. The `--db` path must be absolute, and the parent directory must exist.

## Generic JSON shape

If your client uses a `mcpServers` JSON config, add this:

```json
{
  "mcpServers": {
    "memory": {
      "command": "/home/yourname/.local/bin/memory",
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
