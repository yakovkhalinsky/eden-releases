---
title: Install Eden Memory Cursor skill
description: Use eden-memory as a persistent skill inside Cursor.
content_type: reference
template: doc
skill_name: eden-memory-cursor
skill_version: 2.2.1
skill_tags: mcp, eden-memory, cursor, skill, prompt, composer
skill_discoverable: true
skill_tools: eden_remember, eden_recall, eden_search, eden_search_semantic, eden_edit, eden_forget, eden_forget_expired, eden_health, eden_vacuum, eden_prune, eden_migrate, eden_packet, eden_export_snapshot, eden_import_snapshot, eden_sync, eden_pair_device, eden_sync_loop, eden_relay_server, eden_relay_register, eden_pair_create_invitation, eden_pair_accept_invitation
skill_inherits: eden-memory-mcp-usage
skill_install_hint: 'curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh'
skill_related: eden-memory-mcp-usage
---

# Install Eden Memory Cursor skill

Use eden-memory as a persistent skill inside Cursor.

## Download this skill

The installable artifact is the raw `SKILL.md` file:

- [Download `eden-memory-cursor/SKILL.md`](/eden-memory/skills/eden-memory-cursor/SKILL.md)
- Or fetch it from the terminal:

  ```bash
  curl -fsSL https://0d3sa.com/eden-memory/skills/eden-memory-cursor/SKILL.md -o eden-memory-cursor/SKILL.md
  ```

## Install the binary

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```

## Verify

Call `eden_health` through your MCP client. If the call fails, re-run the install or check your MCP server configuration.

## Setup walkthrough

For step-by-step client wiring, see [Connect Cursor](/eden-memory/tutorials/connect-cursor/).

Other client tutorials:

- [Connect Claude Code](/eden-memory/tutorials/connect-claude-code/)
- [Connect Cursor](/eden-memory/tutorials/connect-cursor/)
- [Connect another MCP client](/eden-memory/tutorials/connect-mcp-client/)

## What this skill enforces

- **Health check first.** Call `eden_health` at the start of every session. Do not proceed with memory-dependent work until it succeeds.
- **Recall before acting.** Use `eden_recall` at task start and before decisions that touch preferences, conventions, security, or tooling.
- **Remember after learning.** After corrections, working solutions, or settled conventions, store durable takeaways with `eden_remember`.
- **Memory checkpoint.** Before finishing a task, confirm at least one recall happened at the start and at least one remember happened at the end.
- **Stop if tools are missing.** If the eden-memory tools are unavailable, tell the user to install and wire the MCP server, then stop.
- **Do not remember secrets.** Never store tokens, passwords, raw command output, ephemeral reasoning, or unvalidated guesses.

## Next steps

- Browse the [skills registry](/eden-memory/skills/)
- Read the [MCP clients guide](/eden-memory/mcp-clients/)
- See the [tools reference](/eden-memory/reference/tools/)
