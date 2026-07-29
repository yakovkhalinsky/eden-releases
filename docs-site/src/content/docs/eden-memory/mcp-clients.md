---
title: Connect your MCP client
description: Add eden-memory to any MCP client.
---

eden-memory speaks MCP over stdio. We publish agent skills that teach specific
clients how to wire it up:

- [Claude Code CLI](/eden-memory/skills/eden-memory-claude/)
- [Cursor](/eden-memory/skills/eden-memory-cursor/)
- [Hermes Agent](/eden-memory/skills/eden-memory-hermes/)

For the full memory-first usage loop and tool list, see the
[eden-memory MCP usage skill](/eden-memory/skills/eden-memory-mcp-usage/).

## Generic client shape

If your client is not listed, use this JSON shape:

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

The server command is always:

```bash
eden-memory --db /home/yourname/.eden-memory/default.db
```

## Available tools

- `eden_remember`
- `eden_recall`
- `eden_search`
- `eden_search_semantic`
- `eden_edit`
- `eden_forget`
- `eden_forget_expired`
- `eden_health`
- `eden_vacuum`

See the [tools reference](/eden-memory/reference/tools/) for full schemas.
