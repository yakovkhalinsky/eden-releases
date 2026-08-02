---
title: Connect Claude Code
description: Install, wire MCP, and verify your first memory in Claude Code CLI.
content_type: tutorial
---

# Connect Claude Code

This tutorial walks through installing eden-memory and wiring it to Claude Code CLI so your agent can remember and recall facts across conversations.

## Prerequisites

- A Linux or macOS machine.
- Claude Code CLI installed and able to run `/mcp` or `/memory`.
- Shell access to run `curl` and `eden-memory`.

## 1. Install the binary

Run the installer:

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```

This downloads the right binary for your platform, verifies its checksum, and installs it to `~/.local/bin/eden-memory`. Make sure `~/.local/bin` is on your PATH, or use the full path in the next step.

## 2. Wire the MCP server

The easiest way is to run the setup helper from the project directory you launch Claude Code in:

```bash
cd ~/project-a
eden-memory --db ~/.eden-memory/default.db setup claude
```

This does three things:

1. Adds or updates the current project in `~/.claude.json` as a stdio MCP server.
2. Removes any stale `eden-memory` entry from `~/.claude/settings.json`.
3. Installs fallback slash commands in `~/.claude/commands/`.

If you prefer to edit `~/.claude.json` manually, add this under `projects["<cwd>"]["mcpServers"]`:

```json
{
  "eden-memory": {
    "command": "/home/yourname/.local/bin/eden-memory",
    "args": [
      "--db",
      "/home/yourname/.eden-memory/default.db"
    ],
    "env": {
      "EDEN_LOG_LEVEL": "INFO"
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
Run eden_health.
```

You can also use the fallback slash command if MCP tools are not yet loaded:

```text
/eden-health
```

You should see a JSON health report. If it fails, re-run the install:

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```

Do not proceed with memory-dependent work until `eden_health` succeeds.

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

- `eden-memory version` prints a version string.
- `eden_health` returns `status: ok`.
- A remembered fact is returned when you ask about it in a new session.

## Next steps

- [Connect another MCP client](/eden-memory/tutorials/connect-mcp-client/)
- [Sync two devices with a relay](/eden-memory/tutorials/sync-two-devices-relay/)
- [Tools reference](/eden-memory/reference/tools/)
- [CLI reference](/eden-memory/reference/cli/)
- [Skills registry](/eden-memory/skills/eden-memory-claude/)
