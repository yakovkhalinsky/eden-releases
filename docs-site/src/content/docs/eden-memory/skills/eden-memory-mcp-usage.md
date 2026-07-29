---
title: Eden Memory MCP Usage
description: Wire the eden-memory Go binary's MCP server into any stdio MCP client and follow the memory-first usage loop.
template: doc
skill_name: eden-memory-mcp-usage
skill_version: 2.1.0
skill_tags: mcp, eden-memory, memory-first, stdio, integration
skill_discoverable: true
skill_tools: eden_remember, eden_recall, eden_search, eden_search_semantic, eden_edit, eden_forget, eden_forget_expired, eden_health, eden_vacuum
skill_install_hint: 'curl -fsSL https://0d3sa.com/install.sh | sh'
skill_related: eden-memory-claude, eden-memory-cursor, eden-memory-hermes
---

# eden-memory MCP usage

## Overview

`eden-memory` is a self-contained Go binary that embeds a Python runtime and an
embedding model. It exposes the Model Context Protocol (MCP) over stdio. Any MCP
client that can spawn a subprocess can use it.

This skill covers the core usage loop. For per-harness wiring, load the child
skill matching your client.

## Install the server

```bash
curl -fsSL https://0d3sa.com/install.sh | sh
```

The installer detects your OS/architecture, downloads the matching binary from
the latest GitHub release, verifies the SHA-256 checksum, and installs it to
`~/.local/bin` (or `/usr/local/bin`).

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
2. **Before finalizing.** Recall when a decision touches preferences, conventions,
   security, or tooling.
3. **After a correction.** Recall related memories, then `eden_edit` or
   `eden_remember`.
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
|------|---------|
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