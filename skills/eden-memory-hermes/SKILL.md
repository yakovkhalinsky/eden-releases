---
name: eden-memory-hermes
title: Hermes Agent
description: Use eden-memory as a persistent skill inside Hermes Agent.
version: 2.2.0
tags: [mcp, eden-memory, hermes, skill, prompt, subagent]
tools:
  discoverable: true
  inherits: eden-memory-mcp-usage
  prefix: mcp__eden__
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
harness: hermes
mcp_config:
  server_name: eden
  transport: stdio
  command: "${HOME}/.local/bin/eden-memory"
  args:
    - --db
    - "${HOME}/.eden-memory/default.db"
related_skills:
  - eden-memory-mcp-usage
---

# eden-memory + Hermes Agent

## Install the binary

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```

This installs the `eden-memory` Go binary to `~/.local/bin/eden-memory`.

## Wire the MCP server

Add to your Hermes profile `config.yaml` under `mcp.servers`:

```yaml
mcp:
  servers:
    eden:
      command: /home/yourname/.local/bin/eden-memory
      args:
        - --db
        - /home/yourname/.eden-memory/default.db
```

Replace `yourname` with your actual username and restart Hermes or reload the profile.

If `eden-memory` is on your PATH, you can use the bare command name:

```yaml
mcp:
  servers:
    eden:
      command: eden-memory
      args:
        - --db
        - /home/yourname/.eden-memory/default.db
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
  goal: Refactor the auth service
  context: Alice prefers table-driven tests with testify/require. Use eden_recall if you need more conventions.
```

## Troubleshooting

- **Tools not appearing:** Restart Hermes. MCP servers are loaded at profile startup.
- **Server exits:** Ensure `--db` uses an absolute path and the parent directory exists.
- **Command not found:** Use the absolute path to the binary, or add its directory to the Hermes environment PATH.
- **Stale Python wrapper from an old install**: if `eden-memory` fails with `ModuleNotFoundError: No module named 'eden_memory'`, remove the broken wrapper and reinstall:
  ```bash
  rm -f ~/.local/bin/eden-memory
  curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
  ```
- **Still not connecting**: run `eden-memory --db ~/.eden-memory/default.db` directly. If it prints usage and exits, the binary is healthy and the issue is the Hermes MCP config or PATH.
