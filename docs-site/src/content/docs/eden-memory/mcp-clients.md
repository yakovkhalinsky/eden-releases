---
title: Connect your MCP client
description: Add eden-memory to Claude Code, Cursor, Hermes, or any other MCP client.
---

eden-memory speaks MCP over stdio. The server command is:

```bash
eden-memory --db /home/yourname/.eden-memory/default.db
```

Use your real username. The `--db` path must be absolute.

## Specific clients

- [Claude Code CLI](/eden-memory/skills/eden-memory-claude/)
- [Cursor](/eden-memory/skills/eden-memory-cursor/)
- [Hermes Agent](/eden-memory/skills/eden-memory-hermes/)
- [eden-memory MCP usage skill](/eden-memory/skills/eden-memory-mcp-usage/) — generic patterns

## Generic JSON shape

If your client uses a `mcpServers` JSON config, add this:

```json
{
  "mcpServers": {
    "eden-memory": {
      "command": "eden-memory",
      "args": ["--db", "/home/yourname/.eden-memory/default.db"]
    }
  }
}
```

## Available tools

Once connected, your agent can call:

- `eden_remember` — store a memory
- `eden_recall` — semantic recall
- `eden_search` — keyword search
- `eden_search_semantic` — semantic search with filters
- `eden_edit` — update a memory
- `eden_forget` — delete a memory
- `eden_forget_expired` — remove expired memories
- `eden_health` — health and usage snapshot
- `eden_vacuum` — run a SQLite WAL checkpoint

See the [tools reference](/eden-memory/reference/tools/) for full schemas.

## Troubleshooting

- **Server exits** — make sure `--db` is an absolute path.
- **Command not found** — add `~/.local/bin` to your PATH, or use the full binary path.
- **Config not picked up** — restart the client after changing the config.
- **First recall is slow** — the embedding model loads on the first call. Subsequent calls are fast.
