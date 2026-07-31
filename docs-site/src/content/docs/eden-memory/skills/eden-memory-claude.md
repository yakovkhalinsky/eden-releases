---
title: Install Eden Memory Claude skill
description: Use eden-memory as a persistent memory layer inside Claude Code CLI.
template: doc
skill_name: eden-memory-claude
skill_version: 3.0.1
skill_tags: mcp, eden-memory, claude-code, skill, prompt, subagent
skill_discoverable: true
skill_tools: eden_remember, eden_recall, eden_search, eden_search_semantic, eden_edit, eden_forget, eden_forget_expired, eden_health, eden_vacuum
skill_inherits: eden-memory-mcp-usage
skill_install_hint: 'curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh'
skill_related: eden-memory-mcp-usage
---

# Install Eden Memory Claude skill

Use eden-memory as a persistent memory layer inside Claude Code CLI.

## Download this skill

The installable artifact is the raw `SKILL.md` file:

- [Download `eden-memory-claude/SKILL.md`](/eden-memory/skills/eden-memory-claude/SKILL.md)
- Or fetch it from the terminal:

  ```bash
  curl -fsSL https://0d3sa.com/eden-memory/skills/eden-memory-claude/SKILL.md -o eden-memory-claude/SKILL.md
  ```

## Install for Claude Code CLI

1. Install the binary:

   ```bash
   curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
   ```

2. Wire the MCP server. This command expands `$HOME` automatically:

   ```bash
   claude config set mcpServers "{\"eden-memory\":{\"command\":\"$HOME/.local/bin/eden-memory\",\"args\":[\"--db\",\"$HOME/.eden-memory/default.db\"]}}"
   ```

3. Download the skill file:

   ```bash
   curl -fsSL https://0d3sa.com/eden-memory/skills/eden-memory-claude/SKILL.md -o eden-memory-claude/SKILL.md
   ```

4. Add it as a **project instruction** in Claude Code:
   - Run `/memory` (or open **Settings → Project Instructions**) and paste the contents of `eden-memory-claude/SKILL.md`.
   - The file contains the memory-first rules and tool usage patterns for Claude Code CLI.

Restart Claude Code after changing configuration. The `mcpServers` key is written to `~/.claude.json`. If `eden-memory` is not on the PATH that Claude Code sees, replace `$HOME` with the absolute path (e.g., `/home/yourname/.local/bin/eden-memory`).

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
