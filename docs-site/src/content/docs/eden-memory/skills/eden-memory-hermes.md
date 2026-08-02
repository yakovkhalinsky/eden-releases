---
title: Install Eden Memory Hermes skill
description: Use eden-memory as a persistent skill inside Hermes Agent.
template: doc
skill_name: eden-memory-hermes
skill_version: 2.2.1
skill_tags: mcp, eden-memory, hermes, skill, prompt, subagent
skill_discoverable: true
skill_tools: eden_remember, eden_recall, eden_search, eden_search_semantic, eden_edit, eden_forget, eden_forget_expired, eden_health, eden_vacuum, eden_prune, eden_migrate, eden_packet, eden_export_snapshot, eden_import_snapshot, eden_sync, eden_pair_device, eden_sync_loop, eden_relay_server, eden_relay_register, eden_pair_create_invitation, eden_pair_accept_invitation
skill_inherits: eden-memory-mcp-usage
skill_install_hint: 'curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh'
skill_related: eden-memory-mcp-usage
---

# Install Eden Memory Hermes skill

Use eden-memory as a persistent skill inside Hermes Agent.

## Download this skill

The installable artifact is the raw `SKILL.md` file:

- [Download `eden-memory-hermes/SKILL.md`](/eden-memory/skills/eden-memory-hermes/SKILL.md)
- Or fetch it from the terminal:

  ```bash
  curl -fsSL https://0d3sa.com/eden-memory/skills/eden-memory-hermes/SKILL.md -o eden-memory-hermes/SKILL.md
  ```

## Install for Hermes Agent

1. Install the binary:

   ```bash
   curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
   ```

2. Add the MCP server to your active Hermes profile `config.yaml` under `mcp.servers`:

   ```yaml
   mcp:
     servers:
       eden:
         command: ${HOME}/.local/bin/eden-memory
         args:
           - --db
           - ${HOME}/.eden-memory/default.db
   ```

3. Download the skill file:

   ```bash
   curl -fsSL https://0d3sa.com/eden-memory/skills/eden-memory-hermes/SKILL.md -o eden-memory-hermes/SKILL.md
   ```

4. Copy it into your active Hermes profile so it loads automatically:

   ```bash
   PROFILE=$(hermes profile active)
   mkdir -p ~/.hermes/profiles/${PROFILE}/skills/eden-memory-hermes
   cp eden-memory-hermes/SKILL.md ~/.hermes/profiles/${PROFILE}/skills/eden-memory-hermes/SKILL.md
   ```

Restart Hermes or reload the profile after changing `config.yaml`.

If `eden-memory` is on your PATH, you can use the bare command name. If you see `ModuleNotFoundError: No module named 'eden_memory'`, you have a stale Python wrapper; remove it with `rm -f ~/.local/bin/eden-memory` and re-run the install.

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
