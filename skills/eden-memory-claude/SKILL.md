---
name: eden-memory-claude
description: Wire eden-memory into Claude Code or any CLI MCP agent.
version: 1.0.0
tags: [mcp, eden-memory, claude-code, cli, integration]
tools:
  discoverable: true
  inherits: eden-memory-mcp-usage
  list:
    - eden_remember
    - eden_recall
    - eden_search
    - eden_search_semantic
    - eden_edit
    - eden_forget
    - eden_forget_expired
    - eden_health
    - eden_vacuum
install_hint: curl -fsSL https://0d3sa.com/install.sh | sh
related_skills:
  - eden-memory-mcp-usage
---

# eden-memory + Claude Code CLI

## Config

Claude Code stores MCP servers in a JSON config. Run:

```bash
claude config get mcpServers
```

to see the current value. To add eden-memory, run:

```bash
claude config set mcpServers '{"eden-memory":{"command":"eden-memory","args":["--db","/home/yourname/.eden-memory/default.db"]}}'
```

Use your real username.

## Verify

Start Claude Code and ask it to remember something, then recall it in a fresh
session.

## Troubleshooting

- Server exits: ensure `--db` uses an absolute path.
- Command not found: add `~/.local/bin` to your PATH, or use the full binary path.
- Config not picked up: restart Claude Code after changing the config.
