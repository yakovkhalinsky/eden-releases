---
title: Skills registry
description: Discoverable agent skills and harness integrations for eden-memory.
template: doc
---

# eden-memory skills registry

These skills teach an agent how to use eden-memory. They declare which MCP tools they use,
how to install the binary, and which harness-specific skills to load next.

## I use…

- [Claude Code CLI](/eden-memory/skills/eden-memory-claude/)
- [Cursor](/eden-memory/skills/eden-memory-cursor/)
- [Hermes Agent](/eden-memory/skills/eden-memory-hermes/)
- [Another MCP client](/eden-memory/skills/eden-memory-mcp-usage/)

| Skill | Description |
|-------|-------------|
| [eden-memory MCP usage](/eden-memory/skills/eden-memory-mcp-usage/) | Use eden-memory as a persistent memory skill inside any stdio MCP client. |
| [Claude Code CLI](/eden-memory/skills/eden-memory-claude/) | Use eden-memory as a persistent skill inside Claude Code CLI. |
| [Cursor](/eden-memory/skills/eden-memory-cursor/) | Use eden-memory as a persistent skill inside Cursor. |
| [Hermes Agent](/eden-memory/skills/eden-memory-hermes/) | Use eden-memory as a persistent skill inside Hermes Agent. |

## Autodiscovery

Each skill file declares YAML frontmatter with `tools.discoverable: true` and a `tools.list`.
A compatible agent can scan this registry, surface the right tools, and suggest the matching
harness skill without the user memorizing tool names.

## Install hint

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```
