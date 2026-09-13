---
name: memory-skills-registry
description: Discoverable registry of memory agent skills and harness integrations.
version: 1.0.0
tags: [memory, skills, registry, mcp]
---

# memory skills registry

This directory contains agent skills for the memory MCP server.

## Skills

| Skill | Purpose |
|-------|---------|
| `memory-mcp-usage` | Core usage loop and tool reference for any stdio MCP client |
| `memory-claude` | Wiring for Claude Code CLI |
| `memory-cursor` | Wiring for Cursor |
| `memory-hermes` | Wiring for Hermes Agent |

Each harness-specific `SKILL.md` includes an install/setup section for its agent.

## Install hints

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
instructions when the user asks about memory.
