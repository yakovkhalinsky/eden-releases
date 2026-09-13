---
title: Quick start
description: Install memory, verify it, and test your first remember/recall.
content_type: tutorial
---

Get memory running locally and confirm that your agent can remember and recall a fact across sessions.

## Prerequisites

- A Linux or macOS machine.
- Shell access and `curl`.
- An MCP-compatible agent or editor.

## 1. Install

Run the installer:

```bash
curl -fsSL https://0d3sa.com/memory/install.sh | sh
```

This downloads the right binary for your platform, verifies its checksum, and installs it to `~/.local/bin/memory`. If your terminal is interactive, the installer will prompt you for an `MEMORY_ORG_ID` and write it to `~/.memory/.env`. You can leave it empty and configure it later.

For non-interactive installs, set the organization ID ahead of time:

```bash
export MEMORY_ORG_ID=your-org
curl -fsSL https://0d3sa.com/memory/install.sh | sh
```

If you prefer a manual install, see [Downloads and checksums](/memory/reference/downloads/).

## 2. Verify

Check the binary:

```bash
memory version
```

Check for updates without installing:

```bash
memory update --check
```

Then confirm it can open its database:

```bash
memory health
```

You should see a version string and a health report with `status: ok`. If either command fails, make sure `~/.local/bin` is on your PATH, or use the full binary path.

## 3. Connect your agent

If you use Claude Code, the fastest path is the built-in setup helper, run from your project directory:

```bash
cd ~/my-project && memory setup
```

It prompts for an agent identity and a personal-vs-team scope, then writes a project-local `.env`, registers the MCP server, and installs `/memory-*` slash commands. See [Connect Claude Code](/memory/tutorials/connect-claude-code/) for the full walkthrough.

For other clients, memory speaks MCP over stdio. Pick the tutorial for your client:

- [Connect Claude Code](/memory/tutorials/connect-claude-code/)
- [Connect Cursor](/memory/tutorials/connect-cursor/)
- [Connect another MCP client](/memory/tutorials/connect-mcp-client/)

If you already know your client's `mcpServers` JSON, the server command is:

```bash
/home/yourname/.local/bin/memory --db /home/yourname/.memory/default.db
```

Replace `/home/yourname` with your actual home path and use absolute paths. Then restart your client.

## 4. Remember and recall

Ask your agent to remember something:

```text
Remember that I prefer Python examples and short sentences.
```

Then start a new conversation and ask:

```text
What do you know about my communication preferences?
```

The agent should recall the preference from the local store.

## Expected output

- `memory version` prints a version string.
- `memory health` returns `status: ok`.
- A remembered fact is returned when asked in a new session.

## What memory does

memory stores memories in a SQLite database at `~/.memory/default.db`. Each memory gets a 256-dimensional embedding. When the agent runs `memory_recall`, memory compares the query embedding to stored vectors and returns the closest matches.

## Next steps

- [Connect Claude Code](/memory/tutorials/connect-claude-code/)
- [Connect Cursor](/memory/tutorials/connect-cursor/)
- [Connect another MCP client](/memory/tutorials/connect-mcp-client/)
- [Sync two devices with a relay](/memory/tutorials/sync-two-devices-relay/)
- [Build a knowledge packet](/memory/how-to/build-knowledge-packet/)
- [Tools reference](/memory/reference/tools/)
- [CLI reference](/memory/reference/cli/)
- [Skills registry](/memory/skills/)
