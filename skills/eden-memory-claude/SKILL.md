---
name: eden-memory-claude
title: Claude Code CLI
description: Use eden-memory as a persistent skill inside Claude Code CLI.
version: 2.2.0
tags: [mcp, eden-memory, claude-code, skill, prompt, subagent]
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
harness: claude-code
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

# eden-memory + Claude Code CLI

## Install the binary

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```

This installs the `eden-memory` Go binary to `~/.local/bin/eden-memory`.

## Wire the MCP server

Run this in your terminal (it expands `$HOME` automatically):

```bash
claude config set mcpServers "{\"eden-memory\":{\"command\":\"$HOME/.local/bin/eden-memory\",\"args\":[\"--db\",\"$HOME/.eden-memory/default.db\",\"--mcp-stdio\"]}}"
```

Then restart Claude Code completely (`/exit`, then reopen).

If `eden-memory` is not on the PATH that Claude Code sees, use the absolute path:

```bash
claude config set mcpServers "{\"eden-memory\":{\"command\":\"/home/yourname/.local/bin/eden-memory\",\"args\":[\"--db\",\"/home/yourname/.eden-memory/default.db\",\"--mcp-stdio\"]}}"
```

Replace `yourname` with your actual username.

## Verify the server

At the start of every session, call `mcp__eden-memory__eden_health`. If the call fails or returns `healthy: false`, stop and re-run the install:

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```

Do not proceed with memory-dependent work until `eden_health` succeeds.

## Tool names in Claude Code

- `mcp__eden-memory__eden_remember`
- `mcp__eden-memory__eden_recall`
- `mcp__eden-memory__eden_search`
- `mcp__eden-memory__eden_search_semantic`
- `mcp__eden-memory__eden_edit`
- `mcp__eden-memory__eden_forget`
- `mcp__eden-memory__eden_forget_expired`
- `mcp__eden-memory__eden_health`
- `mcp__eden-memory__eden_vacuum`

## System prompt pattern

Add this to your project instructions:

```text
MEMORY-FIRST RULES:
1. Immediately after the user gives a task, call mcp__eden-memory__eden_recall with the task summary and kind "convention" or "preference".
2. Before any decision that touches user preferences, coding style, security, or tooling, call mcp__eden-memory__eden_recall first.
3. After corrections, working solutions, or settled conventions, call mcp__eden-memory__eden_remember.
4. At the end of every task, batch 3–5 durable takeaways into mcp__eden-memory__eden_remember calls.
5. Do not remember secrets, tokens, raw command output, ephemeral reasoning, or unvalidated guesses.
6. If eden_recall/eden_remember tools are unavailable, ask the user to wire the eden-memory MCP server and stop.
```

## Example task prompt

```text
We are refactoring a Go service. Please:
1. Call eden_recall to see if Alice has preferences about Go style or testing.
2. Read the current code and propose a refactor.
3. After we agree on the changes, call eden_remember with the conventions we settled on.
```

## Remember / recall template

```json
{
  "agent_id": "claude-code-cli",
  "user_id": "alice",
  "kind": "convention",
  "content": "Prefer table-driven tests with testify/require.",
  "ttl_ms": null
}
```

```json
{
  "agent_id": "claude-code-cli",
  "user_id": "alice",
  "kind": "convention",
  "query": "testing style"
}
```

## Subagent delegation

If you spawn a subagent in Claude Code, pass memory context explicitly:

```text
Subagent: fix-lint-issues
Context: Alice prefers testify/require for assertions. Use eden_recall if you need more conventions.
```

The subagent can use the inherited MCP tools to recall and remember while it works.

## If tools are missing

If you cannot call the eden-memory tools:
1. Stop task execution.
2. Tell the user: "eden-memory MCP server is not configured. Run the install and add the server config, then restart."
3. Provide the one-line wiring command or setup script from this skill.
4. Do not silently continue without memory.

## Troubleshooting

- **Server exits**: ensure `--db` uses an absolute path and the parent directory exists.
- **Command not found**: add `~/.local/bin` to your PATH, or use the absolute binary path in the MCP config.
- **Config not picked up**: restart Claude Code after changing the config. The `mcpServers` key lives in `~/.claude.json`.
- **Stale Python wrapper from an old install**: if `eden-memory` fails with `ModuleNotFoundError: No module named 'eden_memory'`, remove the broken wrapper and reinstall:
  ```bash
  rm -f ~/.local/bin/eden-memory
  curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
  ```
- **Still not connecting**: run `eden-memory --db ~/.eden-memory/default.db` directly. If it prints usage and exits, the binary is healthy and the issue is Claude Code config or PATH.
