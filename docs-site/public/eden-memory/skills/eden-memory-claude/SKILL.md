---
name: eden-memory-claude
title: Claude Code CLI
description: Use eden-memory as a persistent memory layer inside Claude Code CLI.
version: 3.0.1
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
  env:
    EDEN_LOG_LEVEL: INFO
related_skills:
  - eden-memory-mcp-usage
---

# eden-memory + Claude Code CLI

> **MCP first.** Use the eden-memory MCP server so Claude Code can invoke tools
> automatically. Use the `/eden-*` slash commands only if `/mcp` fails or the
> tools do not appear.

## Install the binary

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```

This installs the `eden-memory` Go binary to `~/.local/bin/eden-memory`.

## Wire the MCP server

Run the setup helper from each project directory you launch Claude Code in:

```bash
cd ~/project-a
eden-memory --db ~/.eden-memory/default.db setup claude
```

This does three things:

1. Adds/updates the current project in `~/.claude.json` as a stdio MCP server.
2. Removes any stale `eden-memory` entry from `~/.claude/settings.json`.
3. Installs fallback slash commands in `~/.claude/commands/`.

Then restart Claude Code completely (`/exit`, then reopen).

If you prefer to edit `~/.claude.json` manually, add this under
`projects["<cwd>"]["mcpServers"]`:

```json
{
  "eden-memory": {
    "command": "/home/yourname/.local/bin/eden-memory",
    "args": [
      "--db",
      "/home/yourname/.eden-memory/default.db"
    ],
    "env": {
      "EDEN_LOG_LEVEL": "INFO"
    }
  }
}
```

Use absolute paths and replace `yourname` with your actual username. Do not add
`--mcp-stdio`; it is not a valid flag in the current binary.

## Verify the server

At the start of every session, call `mcp__eden-memory__eden_health`. If the call
fails, stop and re-run the install:

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

## Using MCP tools (default)

Prompt naturally and let Claude invoke the right tool:

- "Remember that this project uses pytest."
- "What test framework does this project use?"
- "Search eden-memory for anything about Tailscale."
- "Update the memory about deployment to mention Tailscale only."
- "Delete the memory with ID `<uuid>`."

If Claude does not invoke the tool automatically, explicitly ask:

- "Use the eden_remember tool to store ..."
- "Call eden_recall for ..."

## System prompt pattern

Add this to your project instructions:

```text
MEMORY-FIRST RULES:
1. Immediately after the user gives a task, call mcp__eden-memory__eden_recall with the task summary.
2. Before any decision that touches user preferences, coding style, security, or tooling, call mcp__eden-memory__eden_recall first.
3. After corrections, working solutions, or settled conventions, call mcp__eden-memory__eden_remember.
4. At the end of every task, batch 3–5 durable takeaways into mcp__eden-memory__eden_remember calls.
5. Do not remember secrets, tokens, raw command output, ephemeral reasoning, or unvalidated guesses.
6. If eden_recall/eden_remember tools are unavailable, use the /eden-remember, /eden-recall, and /eden-search slash commands instead.
```

## Example task prompt

```text
We are refactoring a Go service. Please:
1. Call eden_recall to see if there are preferences about Go style or testing.
2. Read the current code and propose a refactor.
3. After we agree on the changes, call eden_remember with the conventions we settled on.
```

## Remember / recall template

```json
{
  "agent_id": "claude-code-cli",
  "user_id": "alice",
  "content": "Prefer table-driven tests with testify/require.",
  "ttl_ms": null
}
```

```json
{
  "agent_id": "claude-code-cli",
  "user_id": "alice",
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

## Fallback slash commands

If the MCP server is not connecting, `eden-memory setup claude` installs these
personal slash commands in `~/.claude/commands/`:

- `/eden-remember <content>`
- `/eden-recall <query>`
- `/eden-search <keywords>`
- `/eden-forget <id>`
- `/eden-vacuum`
- `/eden-health`

They call the `eden-memory` CLI directly and bypass MCP entirely. Restart Claude
Code after running `setup claude` for them to appear.

## If tools are missing

If you cannot call the eden-memory tools:
1. Stop task execution.
2. Tell the user: "eden-memory MCP server is not configured. Run the install and add the server config, then restart."
3. Provide the one-line wiring command or setup script from this skill.
4. Offer the fallback slash commands if MCP keeps failing.

## Troubleshooting

- **Server exits**: ensure `--db` uses an absolute path and the parent directory exists.
- **Command not found**: add `~/.local/bin` to your PATH, or use the absolute binary path in the MCP config.
- **Config not picked up**: restart Claude Code after changing the config. The `mcpServers` key lives in `~/.claude.json` per project directory.
- **Conflicting scopes**: if `/mcp` reports a conflict between `user` and `local`, remove the stale user-scope entry. `eden-memory setup claude` does this automatically, or run:
  ```bash
  claude mcp remove eden-memory -s user
  ```
- **Stale Python wrapper from an old install**: if `eden-memory` fails with `ModuleNotFoundError: No module named 'eden_memory'`, remove the broken wrapper and reinstall:
  ```bash
  rm -f ~/.local/bin/eden-memory
  curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
  ```
- **Still not connecting**: run `eden-memory --db ~/.eden-memory/default.db health`. If it prints a JSON health report, the binary is healthy and the issue is Claude Code config or PATH.
- **Tools missing after `/mcp` connects:** fully exit Claude Code (`/exit`) and reopen it; agents often only load tools at startup.
- **Claude Code times out even though the binary works from your shell:**
  - On v0.3.28 and earlier the server expected `Content-Length` framing while
    Claude Code sends NDJSON. Upgrade to v0.3.29+.
  - If it still fails, you probably have a stale config using `--mcp-sse`, a
    stale Python process, or a missing restart.
