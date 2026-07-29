---
title: Cursor
description: Agent skill for working with eden-memory.
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

## Verify the server

At the start of every session, call `mcp__eden-memory__eden_health`. If the call fails or returns `healthy: false`, stop and ask the user to check the install:

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```

Do not proceed with memory-dependent work until `eden_health` succeeds.

## Tool names in Cursor

Cursor exposes MCP tools as:

- `mcp__eden-memory__eden_remember`
- `mcp__eden-memory__eden_recall`
- `mcp__eden-memory__eden_search`
- `mcp__eden-memory__eden_search_semantic`
- `mcp__eden-memory__eden_edit`
- `mcp__eden-memory__eden_forget`
- `mcp__eden-memory__eden_forget_expired`
- `mcp__eden-memory__eden_health`
- `mcp__eden-memory__eden_vacuum`

## Usage pattern

Add this instruction to your project prompt or `.cursorrules`:

```text
MEMORY-FIRST RULES:
1. Immediately after the user gives a task, call mcp__eden-memory__eden_recall with the task summary and kind "convention" or "preference".
2. Before any decision that touches user preferences, coding style, security, or tooling, call mcp__eden-memory__eden_recall first.
3. After corrections, working solutions, or settled conventions, call mcp__eden-memory__eden_remember.
4. At the end of every task, batch 3–5 durable takeaways into mcp__eden-memory__eden_remember calls.
5. Do not remember secrets, tokens, raw command output, ephemeral reasoning, or unvalidated guesses.
6. If eden_recall/eden_remember tools are unavailable, ask the user to wire the eden-memory MCP server and stop.
```

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

## If tools are missing

If you cannot call the eden-memory tools:
1. Stop task execution.
2. Tell the user: "eden-memory MCP server is not configured. Run the install and add the server config, then restart."
3. Provide the one-line wiring command or setup script from this skill.
4. Do not silently continue without memory.

## Troubleshooting

- Server exits: ensure `--db` uses an absolute path.
- Command not found: add `~/.local/bin` to your PATH, or use the full binary path.
- No tool calls: open a fresh chat after adding the server.
