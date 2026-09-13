---
title: Fallback slash commands
description: Memory slash commands installed by memory setup claude, used when MCP tools are unavailable.
content_type: reference
---

# Fallback slash commands

When the MCP connection to memory is not working, `memory setup claude` installs a set of slash commands in `~/.claude/commands/`. These commands call the `memory` CLI directly and bypass the MCP layer.

## Installation

The setup helper installs the fallback commands automatically:

```bash
cd ~/project-a
memory setup claude
```

Restart Claude Code after running the helper so the commands appear.

## Available commands

| Command | What it does |
|---------|--------------|
| `/memory-remember <content>` | Store a memory. |
| `/memory-recall <query>` | Run a semantic recall. |
| `/memory-search <keywords>` | Run a keyword search. |
| `/memory-forget <id>` | Soft-delete a memory by ID. |
| `/memory-vacuum` | Run a SQLite WAL checkpoint. |
| `/memory-health` | Return a health, sync, and telemetry snapshot. |

## Usage examples

### Remember a fact

```text
/memory-remember User prefers Python examples and short sentences.
```

### Recall facts

```text
/memory-recall Python style preferences
```

### Search by keyword

```text
/memory-search Python
```

### Check health

```text
/memory-health
```

## Scope and identity

Fallback commands use the default database path and the scopes configured in the MCP server environment. If you need different scopes, use the MCP tools or call the `memory` CLI directly.

## When MCP is working

Prefer the MCP tools (`memory_remember`, `memory_recall`, `memory_search`, etc.) when they are available. The slash commands are a fallback for troubleshooting or when the MCP server is temporarily unreachable.

## Knowledge packets

Knowledge packets are available through the CLI (`memory packet`) and the `memory_packet` MCP tool. There is no fallback slash command for packets; use the CLI or MCP when you want to build or export a workspace snapshot.

## See also

- [Connect Claude Code](/memory/tutorials/connect-claude-code/)
- [Troubleshooting](/memory/reference/troubleshooting/)
- [Tools reference](/memory/reference/tools/)
