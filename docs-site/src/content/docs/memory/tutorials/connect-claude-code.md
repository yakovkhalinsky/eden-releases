---
title: Connect Claude Code
description: Install, wire MCP, and verify your first memory in Claude Code CLI.
content_type: tutorial
---

# Connect Claude Code

This tutorial walks through installing memory and wiring it to Claude Code CLI so your agent can remember and recall facts across conversations.

## Prerequisites

- A Linux or macOS machine.
- Claude Code CLI installed and able to run `/mcp` or `/memory`.
- Shell access to run `curl` and `memory`.

## 1. Install the binary

Run the installer:

```bash
curl -fsSL https://0d3sa.com/memory/install.sh | sh
```

This downloads the right binary for your platform, verifies its checksum, and installs it to `~/.local/bin/memory`. If your terminal is interactive, the installer prompts for `MEMORY_ORG_ID` and writes it to `~/.memory/.env`. Leave it empty to configure later, or pre-set it for non-interactive installs:

```bash
export MEMORY_ORG_ID=your-org
curl -fsSL https://0d3sa.com/memory/install.sh | sh
```

Make sure `~/.local/bin` is on your PATH, or use the full path in the next step.

## 2. Wire the MCP server

The easiest way is to run the setup helper from the project directory you launch Claude Code in:

```bash
cd ~/project-a
memory setup
```

Setup prompts for an agent identity (`MEMORY_AGENT_ID`) and a user identity (`MEMORY_USER_ID`), then asks whether the project is personal or team/org — the answer sets `MEMORY_AUTHORIZATION_MODE` (`easy` for personal, `enterprise` for default-deny cross-workspace access).

This does four things:

1. Writes a project-local `.env` with the database path, identity, scope, and authorization mode, and adds it to `.gitignore`.
2. Adds or updates the current project in `~/.claude.json` as a stdio MCP server.
3. Removes any stale user-level `memory` MCP entry.
4. Installs fallback slash commands in `~/.claude/commands/`.

If you prefer to edit `~/.claude.json` manually, add this under `projects["<cwd>"]["mcpServers"]`:

```json
{
  "memory": {
    "command": "/home/yourname/.local/bin/memory",
    "args": [
      "--db",
      "/home/yourname/.memory/default.db"
    ],
    "env": {
      "MEMORY_LOG_LEVEL": "INFO"
    }
  }
}
```

Use absolute paths and replace `yourname` with your actual username. Do not add `--mcp-stdio`; it is not a valid flag.

## 3. Restart Claude Code

A full restart is required for tool discovery. Exit completely and reopen Claude Code.

## 4. Verify the connection

At the start of a session, ask Claude to check health:

```text
Run memory_health.
```

You can also use the fallback slash command if MCP tools are not yet loaded:

```text
/memory-health
```

You should see a JSON health report. If it fails, re-run the install:

```bash
curl -fsSL https://0d3sa.com/memory/install.sh | sh
```

Do not proceed with memory-dependent work until `memory_health` succeeds.

## 5. Remember and recall your first fact

Ask Claude to store a preference:

```text
Remember that I prefer Python examples and short sentences.
```

Then start a new conversation and ask:

```text
What do you know about my communication preferences?
```

Claude should recall the preference from the local store.

## Expected output

- `memory version` prints a version string.
- `memory_health` returns `status: ok`.
- A remembered fact is returned when you ask about it in a new session.

## Next steps

- [Connect another MCP client](/memory/tutorials/connect-mcp-client/)
- [Sync two devices with a relay](/memory/tutorials/sync-two-devices-relay/)
- [Tools reference](/memory/reference/tools/)
- [CLI reference](/memory/reference/cli/)
- [Skills registry](/memory/skills/memory-claude/)
