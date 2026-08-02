---
title: Install Eden Memory MCP Usage skill
description: Use eden-memory as a persistent memory skill inside any stdio MCP client.
content_type: reference
template: doc
skill_name: eden-memory-mcp-usage
skill_version: 3.0.1
skill_tags: mcp, eden-memory, memory-first, stdio, skill
skill_discoverable: true
skill_tools: eden_remember, eden_recall, eden_search, eden_search_semantic, eden_edit, eden_forget, eden_forget_expired, eden_health, eden_vacuum, eden_prune, eden_migrate, eden_packet, eden_export_snapshot, eden_import_snapshot, eden_sync, eden_pair_device, eden_sync_loop, eden_relay_server, eden_relay_register, eden_pair_create_invitation, eden_pair_accept_invitation
skill_install_hint: 'curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh'
skill_related: eden-memory-claude, eden-memory-cursor, eden-memory-hermes
---

# Install Eden Memory MCP Usage skill

Use eden-memory as a persistent memory skill inside any stdio MCP client.

## Download this skill

The installable artifact is the raw `SKILL.md` file:

- [Download `eden-memory-mcp-usage/SKILL.md`](/eden-memory/skills/eden-memory-mcp-usage/SKILL.md)
- Or fetch it from the terminal:

  ```bash
  curl -fsSL https://0d3sa.com/eden-memory/skills/eden-memory-mcp-usage/SKILL.md -o eden-memory-mcp-usage/SKILL.md
  ```

## Install for any stdio MCP client

1. Install the binary:

   ```bash
   curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
   ```

2. Register the server with your MCP client. The exact command depends on the client; the server config is:

   ```json
   {
     "command": "/home/yourname/.local/bin/eden-memory",
     "args": ["--db", "/home/yourname/.eden-memory/default.db"]
   }
   ```

   Replace `/home/yourname` with your actual home path. If `eden-memory` is on the client's PATH, you can use the bare command name.

3. Download the skill file:

   ```bash
   curl -fsSL https://0d3sa.com/eden-memory/skills/eden-memory-mcp-usage/SKILL.md -o eden-memory-mcp-usage/SKILL.md
   ```

4. Paste the contents of the skill file into your agent's system prompt or project instructions, or load it as a custom skill if your client supports skill files.

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
