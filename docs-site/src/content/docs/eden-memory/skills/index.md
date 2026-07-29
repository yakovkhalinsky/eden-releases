---
title: Skills registry
description: Install eden-memory skills for your agent or editor.
template: doc
---

# Install an eden-memory skill for your agent

The skill files below are installable prompts and rules. Download the raw `SKILL.md` for your harness and load it into your agent.

## I use…

- [Install for Claude Code CLI](/eden-memory/skills/eden-memory-claude/)
- [Install for Cursor](/eden-memory/skills/eden-memory-cursor/)
- [Install for Hermes Agent](/eden-memory/skills/eden-memory-hermes/)
- [Install for another MCP client](/eden-memory/skills/eden-memory-mcp-usage/)

## Download all skills

Fetch every skill as a tarball from the latest GitHub release:

```bash
curl -fsSL https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-skills.tar.gz | tar -xz
```

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
