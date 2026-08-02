---
title: Connect your MCP client
description: Add eden-memory to Claude Code, Cursor, Hermes, or any other MCP client.
content_type: tutorial
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
- `eden_prune` — bulk soft-delete or hard-delete memories
- `eden_migrate` — remap `org_id`/`workspace_id` for a scope
- `eden_packet` — build a deterministic knowledge packet
- `eden_export_snapshot` / `eden_import_snapshot` — encrypted database snapshots
- `eden_sync` — one-shot sync with a peer database
- `eden_pair_device` — pair with a local peer database
- `eden_sync_loop` — background relay sync loop
- `eden_relay_server` — start/stop a local relay server
- `eden_relay_register` — register with a relay directory
- `eden_pair_create_invitation` / `eden_pair_accept_invitation` — relay-mediated pairing

See the [tools reference](/eden-memory/reference/tools/) for full schemas and the [multi-device sync guide](/eden-memory/multi-device-sync/) for how to use the sync and pairing tools.

## Built for teams?

If you use Claude Code, the [agentic-team-protocol](/agentic-team-protocol/) runs on top of eden-memory and adds role-based subagents (Dispatcher, Researcher, Builder, Verifier, Archivist) with a seven-stage goal lifecycle.

## Troubleshooting

- **Server exits** — make sure `--db` is an absolute path.
- **Command not found** — add `~/.local/bin` to your PATH, or use the full binary path.
- **Config not picked up** — restart the client after changing the config.
- **First recall is slow** — the embedding model loads on the first call. Subsequent calls are fast.
