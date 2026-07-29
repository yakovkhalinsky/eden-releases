---
title: Eden Memory Claude
description: Use eden-memory as a persistent skill inside Claude Code CLI.
template: doc
skill_name: eden-memory-claude
skill_version: 2.0.0
skill_tags: mcp, eden-memory, claude-code, skill, prompt, subagent
skill_discoverable: true
skill_tools: eden_remember, eden_recall, eden_search, eden_search_semantic, eden_edit, eden_forget, eden_forget_expired, eden_health, eden_vacuum
skill_inherits: eden-memory-mcp-usage
skill_install_hint: 'curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh'
skill_related: eden-memory-mcp-usage
---

# eden-memory + Claude Code CLI

## Wire the MCP server

```bash
claude config set mcpServers '{"eden-memory":{"command":"eden-memory","args":["--db","/home/yourname/.eden-memory/default.db"]}}'
```

Use your real username and restart Claude Code.

## Tool names in Claude Code

- `mcp__eden-memory__eden_remember`
- `mcp__eden-memory__eden_recall`
- `mcp__eden-memory__eden_search`
- `mcp__eden-memory__eden_search_semantic`
- `mcp__eden-memory__eden_edit`
- `mcp__eden-memory__eden_forget`
- `mcp__eden-memory__eden_health`

## System prompt pattern

Add this to your project instructions:

> At the start of every task, call `eden_recall` with the user’s task summary. Before finishing, call `eden_remember` for any durable preferences, conventions, or working solutions you learned.

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

## Troubleshooting

- Server exits: ensure `--db` uses an absolute path.
- Command not found: add `~/.local/bin` to your PATH, or use the full binary path.
- Config not picked up: restart Claude Code after changing the config.