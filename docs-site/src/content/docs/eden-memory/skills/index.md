---
title: Skills registry
description: Agent skills and harness integrations for eden-memory.
---

# eden-memory skills registry

These skills teach an agent how to *use* eden-memory inside a specific harness. Each page includes:

- How to wire the MCP server
- When to remember and recall
- Tool-call names and examples
- Prompt / subagent patterns

| Skill | Description |
|-------|-------------|
| [Eden Memory MCP Usage](/eden-memory/skills/eden-memory-mcp-usage/) | Core memory-first loop and tool examples for any MCP client. |
| [Eden Memory Claude](/eden-memory/skills/eden-memory-claude/) | Use eden-memory inside Claude Code CLI with prompts and subagent patterns. |
| [Eden Memory Cursor](/eden-memory/skills/eden-memory-cursor/) | Use eden-memory inside Cursor Composer/Agent with `.cursorrules` hints. |
| [Eden Memory Hermes](/eden-memory/skills/eden-memory-hermes/) | Use eden-memory inside Hermes Agent, including skill and subagent delegation. |

## Install hint

```bash
curl -fsSL https://0d3sa.com/install.sh | sh
```

Each skill declares the eden-memory tools it uses. A compatible agent can read this registry and surface the right skill and tool names for the harness it is running in.
