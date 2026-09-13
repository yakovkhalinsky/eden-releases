---
name: memory-claude
title: Claude Code CLI
description: Use memory as a persistent memory layer inside Claude Code CLI.
version: 3.0.2
tags: [mcp, memory, claude-code, skill, prompt, subagent]
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
harness: claude-code
mcp_config:
  server_name: memory
  transport: stdio
  command: "${HOME}/.local/bin/memory"
  args:
    - --db
    - "${HOME}/.memory/default.db"
  env:
    MEMORY_LOG_LEVEL: INFO
related_skills:
  - memory-mcp-usage
---

# memory + Claude Code CLI

> **MCP first.** Use the memory MCP server so Claude Code can invoke tools
> automatically. Use the `/memory-*` slash commands only if `/mcp` fails or the
> tools do not appear.

## Make Claude Code's local memory redundant

**Do not rely on Claude Code's built-in memory for durable facts.** Every
project convention, user preference, working solution, correction, or reusable
decision must be written to memory with `memory_remember`.

Rules:

1. **Read before deciding.** Before any decision that touches user preferences,
   coding style, security, tooling, architecture, or project conventions, call
   `mcp__memory__memory_recall` first.
2. **Write after settling.** After corrections, agreed solutions, or settled
   conventions, call `mcp__memory__memory_remember` immediately.
3. **End-of-task batch write.** At the end of every task, batch 3–5 durable
   takeaways into `mcp__memory__memory_remember` calls.
4. **No duplicates in Claude memory.** Do not ask Claude Code to "remember"
   something in its own memory. Route all memory requests to memory.
5. **No secrets.** Do not remember secrets, tokens, raw command output,
   ephemeral reasoning, or unvalidated guesses in memory.
6. **If tools are down, write later.** If memory MCP tools are unavailable,
   use the `/memory-remember` slash command. If that is also unavailable, note the
   missing takeaways and write them as soon as the tools are back.

This makes memory the single source of truth and makes Claude Code's local
memory redundant for project work.

## Install the binary

```bash
curl -fsSL https://0d3sa.com/memory/install.sh | sh
```

This installs the `memory` Go binary to `~/.local/bin/memory`.

## Wire the MCP server

Run the setup helper from each project directory you launch Claude Code in:

```bash
cd ~/project-a
memory setup claude
```

This does three things:

1. Adds/updates the current project in `~/.claude.json` as a stdio MCP server.
2. Removes any stale `memory` entry from `~/.claude/settings.json`.
3. Installs fallback slash commands in `~/.claude/commands/`.

Then restart Claude Code completely (`/exit`, then reopen).

If you prefer to edit `~/.claude.json` manually, add this under
`projects["<cwd>"]["mcpServers"]`:

```json
{
  "memory": {
    "command": "/home/yourname/.local/bin/memory",
    "args": [
      "--db",
      "/home/yourname/.memory/default.db"
    ],
    "env": {
      "MEMORY_LOG_LEVEL": "INFO"
    }
  }
}
```

Use absolute paths and replace `yourname` with your actual username. Do not add
`--mcp-stdio`; it is not a valid flag in the current binary.

## Verify the server

At the start of every session, call `mcp__memory__memory_health`. If the call
fails, stop and re-run the install:

```bash
curl -fsSL https://0d3sa.com/memory/install.sh | sh
```

Do not proceed with memory-dependent work until `memory_health` succeeds.

## Tool names in Claude Code

- `mcp__memory__memory_remember`
- `mcp__memory__memory_recall`
- `mcp__memory__memory_search`
- `mcp__memory__memory_search_semantic`
- `mcp__memory__memory_edit`
- `mcp__memory__memory_forget`
- `mcp__memory__memory_forget_expired`
- `mcp__memory__memory_health`
- `mcp__memory__memory_vacuum`
- `mcp__memory__memory_prune`
- `mcp__memory__memory_migrate`
- `mcp__memory__memory_packet`
- `mcp__memory__memory_export_snapshot`
- `mcp__memory__memory_import_snapshot`
- `mcp__memory__memory_sync`
- `mcp__memory__memory_pair_device`
- `mcp__memory__memory_sync_loop`
- `mcp__memory__memory_relay_server`
- `mcp__memory__memory_relay_register`
- `mcp__memory__memory_pair_create_invitation`
- `mcp__memory__memory_pair_accept_invitation`

## Using MCP tools (default)

Prompt naturally and let Claude invoke the right tool:

- "Remember that this project uses pytest."
- "What test framework does this project use?"
- "Search memory for anything about Tailscale."
- "Update the memory about deployment to mention Tailscale only."
- "Delete the memory with ID `<uuid>`."

If Claude does not invoke the tool automatically, explicitly ask:

- "Use the memory_remember tool to store ..."
- "Call memory_recall for ..."

## System prompt pattern

Add this to your project instructions:

```text
MEMORY-FIRST RULES:
1. Immediately after the user gives a task, call mcp__memory__memory_recall with the task summary.
2. Before any decision that touches user preferences, coding style, security, tooling, architecture, or project conventions, call mcp__memory__memory_recall first.
3. After corrections, agreed solutions, or settled conventions, call mcp__memory__memory_remember.
4. At the end of every task, batch 3–5 durable takeaways into mcp__memory__memory_remember calls.
5. Do not remember secrets, tokens, raw command output, ephemeral reasoning, or unvalidated guesses.
6. Do not ask Claude Code to remember anything in its own local memory. Route all memory requests to memory.
7. If memory_recall/memory_remember tools are unavailable, use the /memory-recall and /memory-remember slash commands instead, then migrate them to MCP once it is back.
```

## Example task prompt

```text
We are refactoring a Go service. Please:
1. Call memory_recall to see if there are preferences about Go style or testing.
2. Read the current code and propose a refactor.
3. After we agree on the changes, call memory_remember with the conventions we settled on.
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
Context: Alice prefers testify/require for assertions. Use memory_recall if you need more conventions.
```

The subagent can use the inherited MCP tools to recall and remember while it works.

## Fallback slash commands

If the MCP server is not connecting, `memory setup claude` installs these
personal slash commands in `~/.claude/commands/`:

- `/memory-remember <content>`
- `/memory-recall <query>`
- `/memory-search <keywords>`
- `/memory-forget <id>`
- `/memory-vacuum`
- `/memory-health`

They call the `memory` CLI directly and bypass MCP entirely. Restart Claude
Code after running `setup claude` for them to appear.

## If tools are missing

If you cannot call the memory tools:
1. Stop task execution.
2. Tell the user: "memory MCP server is not configured. Run the install and add the server config, then restart."
3. Provide the one-line wiring command or setup script from this skill.
4. Offer the fallback slash commands if MCP keeps failing.

## Troubleshooting

Run this first whenever memory feels broken:

```bash
memory --db ~/.memory/default.db health
```

A healthy install prints a JSON report with `"status":"ok"`. If this fails, fix the path or reinstall before debugging MCP or sync issues.

- **Server exits**: ensure `--db` uses an absolute path and the parent directory exists.
- **Command not found**: add `~/.local/bin` to your PATH, or use the absolute binary path in the MCP config.
- **Config not picked up**: restart Claude Code after changing the config. The `mcpServers` key lives in `~/.claude.json` per project directory.
- **Conflicting scopes**: if `/mcp` reports a conflict between `user` and `local`, remove the stale user-scope entry. `memory setup claude` does this automatically, or run:
  ```bash
  claude mcp remove memory -s user
  ```
- **Stale Python wrapper from an old install**: if `memory` fails with `ModuleNotFoundError: No module named 'memory_memory'`, remove the broken wrapper and reinstall:
  ```bash
  rm -f ~/.local/bin/memory
  curl -fsSL https://0d3sa.com/memory/install.sh | sh
  ```
- **Still not connecting**: run `memory health`. If it prints a JSON health report, the binary is healthy and the issue is Claude Code config or PATH.
- **Tools missing after `/mcp` connects:** fully exit Claude Code (`/exit`) and reopen it; agents often only load tools at startup.
- **Claude Code times out even though the binary works from your shell:**
  - On v0.3.28 and earlier the server expected `Content-Length` framing while
    Claude Code sends NDJSON. Upgrade to v0.3.29+.
  - If it still fails, you probably have a stale config using `--mcp-sse`, a
    stale Python process, or a missing restart.
