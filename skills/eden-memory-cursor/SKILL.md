---
name: eden-memory-cursor
title: Cursor
description: Use eden-memory as a persistent skill inside Cursor.
version: 2.2.0
tags: [mcp, eden-memory, cursor, skill, prompt, composer]
tools:
  discoverable: true
  inherits: eden-memory-mcp-usage
  prefix: mcp__eden-memory__
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
install_hint: curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
harness: cursor
mcp_config:
  server_name: eden-memory
  transport: stdio
  command: "${HOME}/.local/bin/eden-memory"
  args:
    - --db
    - "${HOME}/.eden-memory/default.db"
    - --mcp-stdio
related_skills:
  - eden-memory-mcp-usage
---

# eden-memory + Cursor

## Install the binary

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```

This installs the `eden-memory` Go binary to `~/.local/bin/eden-memory`.

## Wire the MCP server

In Cursor, open **Settings** → **MCP** and add a new stdio server:

| Field | Value |
|-------|-------|
| Name | `eden-memory` |
| Command | `/home/yourname/.local/bin/eden-memory --mcp-stdio` |
| Arguments | `--db /home/yourname/.eden-memory/default.db` |

Use your real username and start a new chat.

If `eden-memory` is not on the PATH that Cursor sees, use the absolute path:

```text
/home/yourname/.local/bin/eden-memory
```

## Verify the server

At the start of a session, ask Cursor to call `eden_health`. If it fails, re-run the install:

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```

## Usage pattern

Add this instruction to your project prompt or `.cursorrules`:

> At the start of each task, call `eden_recall` to load context about the user’s preferences and conventions. Before finishing, call `eden_remember` to store durable takeaways.

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
Context: Alice prefers small components. Use eden_recall if you need more conventions.
```

## Troubleshooting

- **Server exits**: ensure `--db` uses an absolute path and the parent directory exists.
- **Command not found**: add `~/.local/bin` to your PATH, or use the absolute binary path in the MCP config.
- **Config not picked up**: start a new Cursor chat after changing the MCP config.
- **Stale Python wrapper from an old install**: if `eden-memory` fails with `ModuleNotFoundError: No module named 'eden_memory'`, remove the broken wrapper and reinstall:
  ```bash
  rm -f ~/.local/bin/eden-memory
  curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
  ```
- **Still not connecting**: run `eden-memory --db ~/.eden-memory/default.db` directly. If it prints usage and exits, the binary is healthy and the issue is the Cursor MCP config or PATH.
