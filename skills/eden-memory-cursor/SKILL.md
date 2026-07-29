---
name: eden-memory-cursor
description: Wire eden-memory into the Cursor editor over MCP stdio.
version: 1.0.0
tags: [mcp, eden-memory, cursor, integration]
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

# eden-memory + Cursor

## Add the server

In Cursor, open **Settings** → **MCP** and add a new stdio server:

| Field | Value |
|-------|-------|
| Name | `eden-memory` |
| Command | `eden-memory` |
| Arguments | `--db /home/yourname/.eden-memory/default.db` |

Use your real username.

## Verify

Ask Cursor to remember something, then recall it in a fresh chat.

## Troubleshooting

- Server exits: ensure `--db` uses an absolute path.
- Command not found: add `~/.local/bin` to your PATH, or use the full binary path.
- No tool calls: open a fresh chat after adding the server.
