---
title: Eden Memory Cursor
description: Wire eden-memory into the Cursor editor over MCP stdio.
template: doc
skill_name: eden-memory-cursor
skill_version: 1.0.0
skill_tags: mcp, eden-memory, cursor, integration
skill_discoverable: true
skill_tools: eden_remember, eden_recall, eden_search, eden_search_semantic, eden_edit, eden_forget, eden_forget_expired, eden_health, eden_vacuum
skill_inherits: eden-memory-mcp-usage
skill_install_hint: 'curl -fsSL https://0d3sa.com/install.sh | sh'
skill_related: eden-memory-mcp-usage
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