---
title: Eden Memory Cursor
description: Use eden-memory as a persistent skill inside Cursor.
template: doc
skill_name: eden-memory-cursor
skill_version: 2.0.0
skill_tags: mcp, eden-memory, cursor, skill, prompt, composer
skill_discoverable: true
skill_tools: eden_remember, eden_recall, eden_search, eden_search_semantic, eden_edit, eden_forget, eden_forget_expired, eden_health, eden_vacuum
skill_inherits: eden-memory-mcp-usage
skill_install_hint: 'curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh'
skill_related: eden-memory-mcp-usage
---

# eden-memory + Cursor

## Wire the MCP server

In Cursor, open **Settings** → **MCP** and add a new stdio server:

| Field | Value |
|-------|-------|
| Name | `eden-memory` |
| Command | `eden-memory` |
| Arguments | `--db /home/yourname/.eden-memory/default.db` |

Use your real username and start a new chat.

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
Build a settings page. Alice prefers small components and Tailwind. Recall if you need more details.
```

## Troubleshooting

- Server exits: ensure `--db` uses an absolute path.
- Command not found: add `~/.local/bin` to your PATH, or use the full binary path.
- No tool calls: open a fresh chat after adding the server.