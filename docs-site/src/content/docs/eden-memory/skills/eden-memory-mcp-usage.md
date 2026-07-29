---
title: eden-memory MCP usage
description: Use the eden-memory MCP server with any stdio MCP client.
---

## What this covers

This page explains the core usage loop. For per-client wiring, see:

- [Claude Code CLI](/eden-memory/skills/eden-memory-claude/)
- [Cursor](/eden-memory/skills/eden-memory-cursor/)
- [Hermes Agent](/eden-memory/skills/eden-memory-hermes/)

## Install the server

```bash
curl -fsSL https://0d3sa.com/install.sh | sh
```

The installer downloads the right binary, verifies its checksum, and places it in your PATH.

## CLI basics

```bash
# Start the MCP stdio server (requires --db)
eden-memory --db ~/.eden-memory/default.db

# Subcommands
eden-memory version
eden-memory health --db ~/.eden-memory/default.db
eden-memory forget-expired --db ~/.eden-memory/default.db
```

## Memory-first loop

1. **At task start.** Call `eden_recall` once after the user states their task.
2. **Before finalizing.** Recall when a decision touches preferences, conventions, security, or tooling.
3. **After a correction.** Recall related memories, then `eden_edit` or `eden_remember`.
4. **At task end.** Store at most 3–5 concise, durable takeaways.

## What to remember

- Preferences and conventions
- Corrections
- Working solutions
- Identity facts

Set `ttl_ms: null` for things that should persist until the user changes them.

## What not to remember

- Secrets, tokens, passwords
- Raw command output
- Ephemeral reasoning
- Generic knowledge already in docs
- Unvalidated guesses

## Tools

| Tool | Purpose |
|---|---|
| `eden_remember` | Store a durable fact |
| `eden_recall` | Semantic recall for this user |
| `eden_search` | Keyword search |
| `eden_search_semantic` | Semantic search with filters |
| `eden_edit` | Update a memory by ID |
| `eden_forget` | Delete a memory by ID |
| `eden_forget_expired` | Delete expired memories (manual/admin) |
| `eden_health` | Combined health snapshot |
| `eden_vacuum` | Compact the SQLite store (manual/admin) |

See the [tools reference](/eden-memory/reference/tools/) for full schemas.
