---
title: Eden Memory + Cursor
description: Wire eden-memory into the Cursor editor over MCP stdio.
---

## Add the server

In Cursor, open **Settings** → **MCP** and add a new stdio server:

| Field | Value |
|---|---|
| Name | `eden-memory` |
| Command | `eden-memory` |
| Arguments | `--db /home/yourname/.eden-memory/default.db` |

Use your real username. The `--db` path must be absolute.

## Verify

Ask Cursor to remember something, then recall it in a fresh chat.

## Troubleshooting

- **Server exits** — ensure `--db` uses an absolute path.
- **Command not found** — add `~/.local/bin` to your PATH, or use the full binary path.
- **No tool calls** — open a fresh chat after adding the server.
- **First recall is slow** — the embedding model loads on the first semantic call.
