---
title: Eden Memory Claude
description: Wire eden-memory into Claude Code or any CLI MCP agent.
template: doc
skill_name: eden-memory-claude
skill_version: 1.0.0
skill_tags: mcp, eden-memory, claude-code, cli, integration
skill_discoverable: true
skill_tools: eden_remember, eden_recall, eden_search, eden_search_semantic, eden_edit, eden_forget, eden_forget_expired, eden_health, eden_vacuum
skill_inherits: eden-memory-mcp-usage
skill_install_hint: 'curl -fsSL https://0d3sa.com/install.sh | sh'
skill_related: eden-memory-mcp-usage
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