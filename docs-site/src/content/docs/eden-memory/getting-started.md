---
title: Quick start
description: Install eden-memory, verify it, and test your first remember/recall.
content_type: tutorial
---

Get eden-memory running locally and confirm that your agent can remember and recall a fact across sessions.

## Prerequisites

- A Linux or macOS machine.
- Shell access and `curl`.
- An MCP-compatible agent or editor.

## 1. Install

Run the installer:

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```

This downloads the right binary for your platform, verifies its checksum, and installs it to `~/.local/bin/eden-memory`. If your terminal is interactive, the installer will prompt you for an `EDEN_ORG_ID` and write it to `~/.eden-memory/.env`. You can leave it empty and configure it later.

For non-interactive installs, set the organization ID ahead of time:

```bash
export EDEN_ORG_ID=your-org
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```

If you prefer a manual install, see [Downloads and checksums](/eden-memory/reference/downloads/).

## 2. Verify

Check the binary:

```bash
eden-memory version
```

Check for updates without installing:

```bash
eden-memory update --check
```

Then confirm it can open its database:

```bash
eden-memory health
```

You should see a version string and a health report with `status: ok`. If either command fails, make sure `~/.local/bin` is on your PATH, or use the full binary path.

## 3. Connect your agent

eden-memory speaks MCP over stdio. Pick the tutorial for your client:

- [Connect Claude Code](/eden-memory/tutorials/connect-claude-code/)
- [Connect Cursor](/eden-memory/tutorials/connect-cursor/)
- [Connect another MCP client](/eden-memory/tutorials/connect-mcp-client/)

If you already know your client's `mcpServers` JSON, the server command is:

```bash
/home/yourname/.local/bin/eden-memory --db /home/yourname/.eden-memory/default.db
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

- `eden-memory version` prints a version string.
- `eden-memory health` returns `status: ok`.
- A remembered fact is returned when asked in a new session.

## What eden-memory does

eden-memory stores memories in a SQLite database at `~/.eden-memory/default.db`. Each memory gets a 256-dimensional embedding. When the agent runs `eden_recall`, eden-memory compares the query embedding to stored vectors and returns the closest matches.

> [!TIP]
> **Short answer**
> eden-memory is the required base for every user. If you work in Claude Code and want structured role-based collaboration, add the [Agentic Team Protocol](/agentic-team-protocol/getting-started/) on top.

## Next steps

- [Connect Claude Code](/eden-memory/tutorials/connect-claude-code/)
- [Connect Cursor](/eden-memory/tutorials/connect-cursor/)
- [Connect another MCP client](/eden-memory/tutorials/connect-mcp-client/)
- [Sync two devices with a relay](/eden-memory/tutorials/sync-two-devices-relay/)
- [Build a knowledge packet](/eden-memory/how-to/build-knowledge-packet/)
- [Tools reference](/eden-memory/reference/tools/)
- [CLI reference](/eden-memory/reference/cli/)
- [Skills registry](/eden-memory/skills/)
