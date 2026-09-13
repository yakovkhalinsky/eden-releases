---
name: memory-cursor
title: Cursor
description: Use memory as a persistent skill inside Cursor.
version: 2.2.1
tags: [mcp, memory, cursor, skill, prompt, composer]
tools:
  discoverable: true
  inherits: memory-mcp-usage
  prefix: mcp__memory__
  list:
    - memory_remember
    - memory_recall
    - memory_search
    - memory_search_semantic
    - memory_lookup
    - memory_lookup_cross
    - memory_edit
    - memory_forget
    - memory_forget_expired
    - memory_health
    - memory_vacuum
    - memory_prune
    - memory_migrate
    - memory_packet
    - memory_packet_publish
    - memory_packet_list
    - memory_packet_export
    - memory_report
    - memory_document
    - memory_document_publish
    - memory_document_list
    - memory_document_export
    - memory_dream
    - memory_dream_apply
    - memory_export_snapshot
    - memory_import_snapshot
    - memory_sync
    - memory_pair_device
    - memory_sync_loop
    - memory_relay_server
    - memory_relay_register
    - memory_pair_create_invitation
    - memory_pair_accept_invitation
install_hint: curl -fsSL https://0d3sa.com/memory/install.sh | sh
harness: cursor
mcp_config:
  server_name: memory
  transport: stdio
  command: "${HOME}/.local/bin/memory"
  args:
    - --db
    - "${HOME}/.memory/default.db"
related_skills:
  - memory-mcp-usage
---

# memory + Cursor

## Install the binary

```bash
curl -fsSL https://0d3sa.com/memory/install.sh | sh
```

This installs the `memory` Go binary to `~/.local/bin/memory`.

## Wire the MCP server

In Cursor, open **Settings** → **MCP** and add a new stdio server:

| Field | Value |
|-------|-------|
| Name | `memory` |
| Command | `/home/yourname/.local/bin/memory` |
| Arguments | `--db /home/yourname/.memory/default.db` |

Use your real username and start a new chat.

If `memory` is not on the PATH that Cursor sees, use the absolute path:

```text
/home/yourname/.local/bin/memory
```

## Verify the server

At the start of a session, ask Cursor to call `memory_health`. If it fails, re-run the install:

```bash
curl -fsSL https://0d3sa.com/memory/install.sh | sh
```

## Usage pattern

Add this instruction to your project prompt or `.cursorrules`:

> At the start of each task, call `memory_recall` to load context about the user’s preferences and conventions. Before finishing, call `memory_remember` to store durable takeaways.

## Example `.cursorrules` snippet

```text
Memory conventions:
- Recall at task start with the task summary.
- Remember after corrections or working solutions.
- Do not remember secrets, raw output, or unvalidated guesses.
- Use kind: "preference" for lasting user preferences, kind: "convention" for project rules.
```

## Remember / recall template

```json
{
  "agent_id": "cursor-agent",
  "user_id": "alice",
  "kind": "preference",
  "content": "Keep frontend components under 200 lines. Split earlier rather than later.",
  "ttl_ms": null
}
```

```json
{
  "agent_id": "cursor-agent",
  "user_id": "alice",
  "kind": "preference",
  "query": "component size limits"
}
```

## Composer / agent delegation

When delegating to Cursor’s composer, include the memory context in the prompt:

```text
Context: Alice prefers small components. Use memory_recall if you need more conventions.
```

## Troubleshooting

- **Server exits**: ensure `--db` uses an absolute path and the parent directory exists.
- **Command not found**: add `~/.local/bin` to your PATH, or use the absolute binary path in the MCP config.
- **Config not picked up**: start a new Cursor chat after changing the MCP config.
- **Stale Python wrapper from an old install**: if `memory` fails with `ModuleNotFoundError: No module named 'memory_memory'`, remove the broken wrapper and reinstall:
  ```bash
  rm -f ~/.local/bin/memory
  curl -fsSL https://0d3sa.com/memory/install.sh | sh
  ```
- **Still not connecting**: run `memory --db ~/.memory/default.db` directly. If it prints usage and exits, the binary is healthy and the issue is the Cursor MCP config or PATH.
