---
title: Eden Memory Hermes
description: Wire eden-memory into the Hermes Agent MCP harness.
template: doc
skill_name: eden-memory-hermes
skill_version: 1.0.0
skill_tags: mcp, eden-memory, hermes, integration
skill_discoverable: true
skill_tools: eden_remember, eden_recall, eden_search, eden_search_semantic, eden_edit, eden_forget, eden_forget_expired, eden_health, eden_vacuum
skill_inherits: eden-memory-mcp-usage
skill_install_hint: 'curl -fsSL https://0d3sa.com/install.sh | sh'
skill_related: eden-memory-mcp-usage
---

# eden-memory + Hermes Agent

## Add the server

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

Use your real username.

## Verify

Restart Hermes or reload the profile. In Hermes, the tools appear as
`mcp__eden__eden_remember`, `mcp__eden__eden_recall`, etc.

## Troubleshooting

- Server exits: ensure `--db` uses an absolute path.
- Command not found: add `~/.local/bin` to your PATH, or use the full binary path.
- Profile path: use an absolute path for `command` if Hermes runs from a different working directory.