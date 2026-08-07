---
title: Connect your MCP client
description: Hub page for connecting eden-memory to Claude Code, Cursor, Hermes, or any other stdio MCP client.
content_type: concept
---

eden-memory speaks the Model Context Protocol (MCP) over stdio. Once you add it as a server, your agent can call `eden_remember`, `eden_recall`, `eden_search`, and the rest of the eden-memory tool set.

## Per-client setup

Follow the tutorial for your harness:

- [Connect Claude Code](/eden-memory/tutorials/connect-claude-code/)
- [Connect Cursor](/eden-memory/tutorials/connect-cursor/)
- [Connect another MCP client](/eden-memory/tutorials/connect-mcp-client/)
- [Install the Hermes skill](/eden-memory/skills/eden-memory-hermes/)

## Generic server command

If your client lets you enter a server command directly, use:

```bash
/home/yourname/.local/bin/eden-memory --db /home/yourname/.eden-memory/default.db
```

Replace `/home/yourname` with your actual home path. The `--db` path must be absolute, and the parent directory must exist.

## Generic JSON shape

If your client uses a `mcpServers` JSON config, add this:

```json
{
  "mcpServers": {
    "eden-memory": {
      "command": "/home/yourname/.local/bin/eden-memory",
      "args": [
        "--db",
        "/home/yourname/.eden-memory/default.db"
      ],
      "env": {
        "EDEN_LOG_LEVEL": "INFO"
      }
    }
  }
}
```

Use absolute paths and restart the client after adding the server.

## Available tools

Once connected, your agent can call tools such as:

- `eden_remember` / `eden_recall` — store and retrieve memories
- `eden_search` / `eden_search_semantic` — keyword and semantic search
- `eden_edit` / `eden_forget` — update and delete memories
- `eden_health` / `eden_vacuum` — health and maintenance
- `eden_sync` / `eden_pair_device` / `eden_sync_loop` — sync and pairing

See the [tools reference](/eden-memory/reference/tools/) for full schemas and the [multi-device sync overview](/eden-memory/multi-device-sync/) for sync walkthroughs.

## Troubleshooting

- **Server exits** — make sure `--db` is an absolute path and the parent directory exists.
- **Command not found** — add `~/.local/bin` to your PATH, or use the full binary path.
- **Config not picked up** — restart the client after changing the config.
- **First recall is slow** — the embedding model loads on the first call. Subsequent calls are fast.

## Next steps

- [Quick start](/eden-memory/getting-started/)
- [Connect Claude Code](/eden-memory/tutorials/connect-claude-code/)
- [Connect Cursor](/eden-memory/tutorials/connect-cursor/)
- [Connect another MCP client](/eden-memory/tutorials/connect-mcp-client/)
- [Skills registry](/eden-memory/skills/)
