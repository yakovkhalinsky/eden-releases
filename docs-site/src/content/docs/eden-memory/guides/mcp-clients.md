---
title: MCP Clients
description: Wire eden-memory into Claude Desktop, Cursor, Hermes, and other MCP clients.
---

eden-memory exposes the Model Context Protocol over stdio. Any client that can spawn a subprocess and speak MCP can use it.

The server command is always:

```bash
eden-memory --db ~/.eden-memory/default.db
```

You can also set `EDEN_DB`, `EDEN_LOG_LEVEL`, or `EDEN_LOG_FORMAT` environment variables. Use absolute paths so the client can find them reliably.

## Claude Desktop

Add to `claude_desktop_config.json`:

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

Restart Claude Desktop after saving.

## Cursor

In Cursor Settings → MCP, add a new stdio server:

- **Name:** `eden-memory`
- **Command:** `eden-memory`
- **Arguments:** `--db /home/yourname/.eden-memory/default.db`

## Hermes Agent

Add to your Hermes profile `config.yaml` under `mcp.servers`:

```yaml
mcp:
  servers:
    eden-memory:
      command: eden-memory
      args:
        - --db
        - /home/yourname/.eden-memory/default.db
```

## Claude Code / Codex CLI

For CLI agents that accept MCP servers via environment or config:

```bash
export EDEN_DB=/home/yourname/.eden-memory/default.db
# then start the agent, or add the server in the agent's MCP config
```

## Custom clients

Connect to the subprocess and send MCP initialize messages. The server advertises these tools:

- `eden_remember`
- `eden_recall`
- `eden_search`
- `eden_search_semantic`
- `eden_edit`
- `eden_forget`
- `eden_forget_expired`
- `eden_health`
- `eden_vacuum`

See the [tools reference](/reference/tools/) for exact input schemas and response shapes.

## Troubleshooting

- **Server exits immediately:** Make sure `--db` points to an absolute path and the directory exists.
- **First run is slow:** The binary extracts the embedded runtime and model weights on first launch; subsequent starts are fast.
- **Client cannot find `eden-memory`:** Use the full path to the binary, or place it on a directory in `$PATH`.
