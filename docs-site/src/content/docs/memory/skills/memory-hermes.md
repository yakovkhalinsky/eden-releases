---
title: Install Memory Hermes skill
description: Use memory as a persistent skill inside Hermes Agent.
content_type: reference
template: doc
skill_name: memory-hermes
skill_version: 2.2.1
skill_tags: mcp, memory, hermes, skill, prompt, subagent
skill_discoverable: true
skill_tools: memory_remember, memory_recall, memory_search, memory_search_semantic, memory_lookup, memory_lookup_cross, memory_edit, memory_forget, memory_forget_expired, memory_health, memory_vacuum, memory_prune, memory_migrate, memory_packet, memory_packet_publish, memory_packet_list, memory_packet_export, memory_report, memory_document, memory_document_publish, memory_document_list, memory_document_export, memory_dream, memory_dream_apply, memory_export_snapshot, memory_import_snapshot, memory_sync, memory_pair_device, memory_sync_loop, memory_relay_server, memory_relay_register, memory_pair_create_invitation, memory_pair_accept_invitation
skill_inherits: memory-mcp-usage
skill_install_hint: 'curl -fsSL https://0d3sa.com/memory/install.sh | sh'
skill_related: memory-mcp-usage
---

# Install Memory Hermes skill

Use memory as a persistent skill inside Hermes Agent.

## Download this skill

The installable artifact is the raw `SKILL.md` file:

- [Download `memory-hermes/SKILL.md`](/memory/skills/memory-hermes/SKILL.md)
- Or fetch it from the terminal:

  ```bash
  curl -fsSL https://0d3sa.com/memory/skills/memory-hermes/SKILL.md -o memory-hermes/SKILL.md
  ```

## Install the binary

```bash
curl -fsSL https://0d3sa.com/memory/install.sh | sh
```

## Verify

Call `memory_health` through your MCP client. If the call fails, re-run the install or check your MCP server configuration.

## Setup walkthrough

For step-by-step client wiring, see [Connect another MCP client](/memory/tutorials/connect-mcp-client/).

Other client tutorials:

- [Connect Claude Code](/memory/tutorials/connect-claude-code/)
- [Connect Cursor](/memory/tutorials/connect-cursor/)
- [Connect another MCP client](/memory/tutorials/connect-mcp-client/)

## What this skill enforces

- **Health check first.** Call `memory_health` at the start of every session. Do not proceed with memory-dependent work until it succeeds.
- **Recall before acting.** Use `memory_recall` at task start and before decisions that touch preferences, conventions, security, or tooling.
- **Remember after learning.** After corrections, working solutions, or settled conventions, store durable takeaways with `memory_remember`.
- **Memory checkpoint.** Before finishing a task, confirm at least one recall happened at the start and at least one remember happened at the end.
- **Stop if tools are missing.** If the memory tools are unavailable, tell the user to install and wire the MCP server, then stop.
- **Do not remember secrets.** Never store tokens, passwords, raw command output, ephemeral reasoning, or unvalidated guesses.

## Next steps

- Browse the [skills registry](/memory/skills/)
- Read the [MCP clients guide](/memory/mcp-clients/)
- See the [tools reference](/memory/reference/tools/)
