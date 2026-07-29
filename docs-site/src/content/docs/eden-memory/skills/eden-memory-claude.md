---
title: Eden Memory + Claude Code CLI
description: Wire eden-memory into Claude Code over MCP stdio.
---

## Add the server

Claude Code stores MCP servers in a JSON config. See the current value:

```bash
claude config get mcpServers
```

Then add eden-memory:

```bash
claude config set mcpServers '{"eden-memory":{"command":"eden-memory","args":["--db","/home/yourname/.eden-memory/default.db"]}}'
```

Use your real username. The `--db` path must be absolute.

## Verify

Start Claude Code and ask it to remember something, then recall it in a fresh session.

## Troubleshooting

- **Server exits** — ensure `--db` uses an absolute path.
- **Command not found** — add `~/.local/bin` to your PATH, or use the full binary path.
- **Config not picked up** — restart Claude Code after changing the config.
