---
name: eden-memory-skills-registry
description: Discoverable registry of eden-memory agent skills and harness integrations.
version: 1.0.0
tags: [eden-memory, skills, registry, mcp]
---

# eden-memory skills registry

This directory contains agent skills for the eden-memory MCP server.

## Skills

| Skill | Purpose |
|-------|---------|
| `eden-memory-mcp-usage` | Core usage loop and tool reference for any stdio MCP client |
| `eden-memory-claude` | Wiring for Claude Code CLI |
| `eden-memory-cursor` | Wiring for Cursor |
| `eden-memory-hermes` | Wiring for Hermes Agent |

## Autodiscovery

Each `SKILL.md` declares:

- `name`
- `description`
- `version`
- `tags`
- `tools.discoverable: true`
- `tools.list`: the MCP tools the skill uses
- `install_hint`: how to install the underlying binary
- `related_skills`: related skills in the registry

A compatible agent can read these files and surface the right tools and setup
instructions when the user asks about eden-memory.
