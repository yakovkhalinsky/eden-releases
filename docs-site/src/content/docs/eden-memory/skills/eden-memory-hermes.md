---
title: Eden Memory Hermes
description: Use eden-memory as a persistent skill inside Hermes Agent.
template: doc
skill_name: eden-memory-hermes
skill_version: 2.0.0
skill_tags: mcp, eden-memory, hermes, skill, prompt, subagent
skill_discoverable: true
skill_tools: eden_remember, eden_recall, eden_search, eden_search_semantic, eden_edit, eden_forget, eden_forget_expired, eden_health, eden_vacuum
skill_inherits: eden-memory-mcp-usage
skill_install_hint: 'curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh'
skill_related: eden-memory-mcp-usage
---

# eden-memory + Hermes Agent

## Wire the MCP server

Add to your Hermes profile `config.yaml` under `mcp.servers`:

```yaml
mcp:
  servers:
    eden-memory:
      command: eden-memory
      args:
        - --db
        - /home/yourname/.eden-memory/default.db
```

Use your real username and restart Hermes or reload the profile.

## Tool names in Hermes

Hermes exposes MCP tools as:

- `mcp__eden__eden_remember`
- `mcp__eden__eden_recall`
- `mcp__eden__eden_search`
- `mcp__eden__eden_search_semantic`
- `mcp__eden__eden_edit`
- `mcp__eden__eden_forget`
- `mcp__eden__eden_health`

## Usage pattern

Add this to your profile or system prompt:

> At task start, call `eden_recall` with the task summary. After corrections or working solutions, call `eden_remember`. Do not remember secrets, raw output, or unvalidated guesses.

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

## Troubleshooting

- Server exits: ensure `--db` uses an absolute path.
- Command not found: add `~/.local/bin` to your PATH, or use the full binary path.
- Profile path: use an absolute path for `command` if Hermes runs from a different working directory.