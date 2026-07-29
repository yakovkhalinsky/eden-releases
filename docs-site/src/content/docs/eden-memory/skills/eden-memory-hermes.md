---
title: Hermes Agent
description: Agent skill for working with eden-memory.
---

# eden-memory + Hermes Agent

## Wire the MCP server

Add to your Hermes profile `config.yaml` under `mcp.servers`:

```yaml
mcp:
  servers:
    eden:
      command: eden-memory
      args:
        - --db
        - /home/yourname/.eden-memory/default.db
```

Use your real username and restart Hermes or reload the profile.

## Verify the server

At the start of every session, call `mcp__eden__eden_health`. If the call fails or returns `healthy: false`, stop and ask the user to check the install:

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```

Do not proceed with memory-dependent work until `eden_health` succeeds.

## Install this skill in Hermes

Copy this skill into your active Hermes profile so it loads automatically:

```bash
PROFILE=$(hermes profile active)
mkdir -p ~/.hermes/profiles/${PROFILE}/skills/eden-memory-hermes
cp skills/eden-memory-hermes/SKILL.md ~/.hermes/profiles/${PROFILE}/skills/eden-memory-hermes/SKILL.md
```

## Tool names in Hermes

Hermes exposes MCP tools as:

- `mcp__eden__eden_remember`
- `mcp__eden__eden_recall`
- `mcp__eden__eden_search`
- `mcp__eden__eden_search_semantic`
- `mcp__eden__eden_edit`
- `mcp__eden__eden_forget`
- `mcp__eden__eden_forget_expired`
- `mcp__eden__eden_health`
- `mcp__eden__eden_vacuum`

## Usage pattern

Add this to your profile or system prompt:

```text
MEMORY-FIRST RULES:
1. Immediately after the user gives a task, call mcp__eden__eden_recall with the task summary and kind "convention" or "preference".
2. Before any decision that touches user preferences, coding style, security, or tooling, call mcp__eden__eden_recall first.
3. After corrections, working solutions, or settled conventions, call mcp__eden__eden_remember.
4. At the end of every task, batch 3–5 durable takeaways into mcp__eden__eden_remember calls.
5. Do not remember secrets, tokens, raw command output, ephemeral reasoning, or unvalidated guesses.
6. If eden_recall/eden_remember tools are unavailable, ask the user to wire the eden-memory MCP server and stop.
```

## Calling tools from a skill

From inside a Hermes skill, call eden-memory tools directly:

```yaml
# inside your skill's reasoning
- tool: mcp__eden__eden_recall
  arguments:
    agent_id: "hermes"
    user_id: "{{user.id}}"
    kind: "convention"
    query: "project testing preferences"
```

## Subagent delegation

When spawning a subagent in Hermes, pass memory context in the prompt:

```yaml
delegate_task:
  goal: Refactor the auth module
  context: |
    User alice prefers table-driven tests with testify/require.
    Call eden_recall if you need more conventions.
```

## Remember / recall template

```json
{
  "agent_id": "hermes",
  "user_id": "alice",
  "kind": "convention",
  "content": "Use table-driven tests with testify/require.",
  "ttl_ms": null
}
```

```json
{
  "agent_id": "hermes",
  "user_id": "alice",
  "kind": "convention",
  "query": "testing preferences"
}
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
- Profile path: use an absolute path for `command` if Hermes runs from a different working directory.
