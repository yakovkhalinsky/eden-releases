---
title: Fallback slash commands
description: Eden-memory slash commands installed by eden-memory setup claude, used when MCP tools are unavailable.
content_type: reference
---

# Fallback slash commands

When the MCP connection to eden-memory is not working, `eden-memory setup claude` installs a set of slash commands in `~/.claude/commands/`. These commands call the `eden-memory` CLI directly and bypass the MCP layer.

## Installation

The setup helper installs the fallback commands automatically:

```bash
cd ~/project-a
eden-memory --db ~/.eden-memory/default.db setup claude
```

Restart Claude Code after running the helper so the commands appear.

## Available commands

| Command | What it does |
|---------|--------------|
| `/eden-remember <content>` | Store a memory. |
| `/eden-recall <query>` | Run a semantic recall. |
| `/eden-search <keywords>` | Run a keyword search. |
| `/eden-forget <id>` | Soft-delete a memory by ID. |
| `/eden-vacuum` | Run a SQLite WAL checkpoint. |
| `/eden-health` | Return a health, sync, and telemetry snapshot. |

## Usage examples

### Remember a fact

```text
/eden-remember User prefers Python examples and short sentences.
```

### Recall facts

```text
/eden-recall Python style preferences
```

### Search by keyword

```text
/eden-search Python
```

### Check health

```text
/eden-health
```

## Scope and identity

Fallback commands use the default database path and the scopes configured in the MCP server environment. If you need different scopes, use the MCP tools or call the `eden-memory` CLI directly.

## When MCP is working

Prefer the MCP tools (`eden_remember`, `eden_recall`, `eden_search`, etc.) when they are available. The slash commands are a fallback for troubleshooting or when the MCP server is temporarily unreachable.

## See also

- [Connect Claude Code](/eden-memory/tutorials/connect-claude-code/)
- [Troubleshooting](/eden-memory/reference/troubleshooting/)
- [Tools reference](/eden-memory/reference/tools/)
