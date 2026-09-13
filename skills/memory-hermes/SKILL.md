---
name: memory-hermes
title: Hermes Agent
description: Use memory as a persistent skill inside Hermes Agent.
version: 2.2.1
tags: [mcp, memory, hermes, skill, prompt, subagent]
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
harness: hermes
mcp_config:
  server_name: memory
  transport: stdio
  command: "${HOME}/.local/bin/memory"
  args:
    - --db
    - "${HOME}/.memory/default.db"
related_skills:
  - memory-mcp-usage
---

# memory + Hermes Agent

## Install the binary

```bash
curl -fsSL https://0d3sa.com/memory/install.sh | sh
```

This installs the `memory` Go binary to `~/.local/bin/memory`.

## Wire the MCP server

Add to your Hermes profile `config.yaml` under `mcp.servers`:

```yaml
mcp:
  servers:
    memory:
      command: /home/yourname/.local/bin/memory
      args:
        - --db
        - /home/yourname/.memory/default.db
```

Replace `yourname` with your actual username and restart Hermes or reload the profile.

If `memory` is on your PATH, you can use the bare command name:

```yaml
mcp:
  servers:
    memory:
      command: memory
      args:
        - --db
        - /home/yourname/.memory/default.db
```

## Tool names in Hermes

Hermes exposes MCP tools as:

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

## Usage pattern

Add this to your profile or system prompt:

> At task start, call `memory_recall` with the task summary. After corrections or working solutions, call `memory_remember`. Do not remember secrets, raw output, or unvalidated guesses.

## Calling tools from a skill

From inside a Hermes skill, call memory tools directly:

```yaml
# inside your skill's reasoning
- tool: mcp__memory__memory_recall
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
  context: Alice prefers table-driven tests with testify/require. Use memory_recall if you need more conventions.
```

## Troubleshooting

- **Tools not appearing:** Restart Hermes. MCP servers are loaded at profile startup.
- **Server exits:** Ensure `--db` uses an absolute path and the parent directory exists.
- **Command not found:** Use the absolute path to the binary, or add its directory to the Hermes environment PATH.
- **Stale Python wrapper from an old install**: if `memory` fails with `ModuleNotFoundError: No module named 'memory_memory'`, remove the broken wrapper and reinstall:
  ```bash
  rm -f ~/.local/bin/memory
  curl -fsSL https://0d3sa.com/memory/install.sh | sh
  ```
- **Still not connecting**: run `memory --db ~/.memory/default.db` directly. If it prints usage and exits, the binary is healthy and the issue is the Hermes MCP config or PATH.
