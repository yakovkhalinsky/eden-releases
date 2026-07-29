---
title: Eden Memory + Hermes Agent
description: Wire eden-memory into Hermes Agent over MCP stdio.
---

## Add the server

In your Hermes Agent configuration, register an MCP server with this command:

```yaml
mcp_servers:
  eden-memory:
    command: eden-memory
    args:
      - --db
      - /home/yourname/.eden-memory/default.db
```

Use your real username. The `--db` path must be absolute.

## Verify

Ask your agent to remember something, then recall it in a fresh session.

## Troubleshooting

- **Server exits** — ensure `--db` uses an absolute path.
- **Command not found** — add `~/.local/bin` to your PATH, or use the full binary path.
- **Config not picked up** — restart the agent after changing the config.
- **First recall is slow** — the embedding model loads on the first semantic call.
