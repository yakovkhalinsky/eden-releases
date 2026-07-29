---
title: Skills registry
description: Discoverable agent skills and harness integrations for eden-memory.
template: doc
---

# eden-memory skills registry

These skills teach an agent how to use eden-memory. They declare which MCP tools they use,
how to install the binary, and which harness-specific skills to load next.

| Skill | Description |
|-------|-------------|
| [Eden Memory Claude](/eden-memory/skills/eden-memory-claude/) | Wire eden-memory into Claude Code or any CLI MCP agent. |
| [Eden Memory Cursor](/eden-memory/skills/eden-memory-cursor/) | Wire eden-memory into the Cursor editor over MCP stdio. |
| [Eden Memory Hermes](/eden-memory/skills/eden-memory-hermes/) | Wire eden-memory into the Hermes Agent MCP harness. |
| [Eden Memory MCP Usage](/eden-memory/skills/eden-memory-mcp-usage/) | Wire the eden-memory Go binary's MCP server into any stdio MCP client and follow the memory-first usage loop. |

## Autodiscovery

Each skill file declares YAML frontmatter with `tools.discoverable: true` and a `tools.list`.
A compatible agent can scan this registry, surface the right tools, and suggest the matching
harness skill without the user memorizing tool names.

## Install hint

```bash
curl -fsSL https://0d3sa.com/install.sh | sh
```
