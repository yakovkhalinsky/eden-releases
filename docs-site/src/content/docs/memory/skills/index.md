---
title: Skills registry
description: Install memory skills for your agent or editor.
content_type: reference
template: doc
---

# Install an memory skill for your agent

The skill files below are installable prompts and rules. Download the raw `SKILL.md` for your harness and load it into your agent.

## I use…

- [Install for Claude Code CLI](/memory/skills/memory-claude/)
- [Install for Cursor](/memory/skills/memory-cursor/)
- [Install for Hermes Agent](/memory/skills/memory-hermes/)
- [Install for another MCP client](/memory/skills/memory-mcp-usage/)

## Download all skills

Fetch every skill as a tarball from the latest GitHub release:

```bash
curl -fsSL https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/memory-skills.tar.gz | tar -xz
```

| Skill | Description |
|-------|-------------|
| [memory MCP usage](/memory/skills/memory-mcp-usage/) | Use memory as a persistent memory skill inside any stdio MCP client. |
| [Claude Code CLI](/memory/skills/memory-claude/) | Use memory as a persistent memory layer inside Claude Code CLI. |
| [Cursor](/memory/skills/memory-cursor/) | Use memory as a persistent skill inside Cursor. |
| [Hermes Agent](/memory/skills/memory-hermes/) | Use memory as a persistent skill inside Hermes Agent. |

## Autodiscovery

Each skill file declares YAML frontmatter with `tools.discoverable: true` and a `tools.list`.
A compatible agent can scan this registry, surface the right tools, and suggest the matching
harness skill without the user memorizing tool names.

## Install hint

```bash
curl -fsSL https://0d3sa.com/memory/install.sh | sh
```
