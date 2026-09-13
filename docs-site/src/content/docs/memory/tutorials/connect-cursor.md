---
title: Connect Cursor
description: Add memory as an MCP server in Cursor and test recall.
content_type: tutorial
---

# Connect Cursor

This tutorial walks through adding memory as a stdio MCP server in Cursor so Composer and agent features can recall durable memories.

## Prerequisites

- Cursor installed and signed in.
- A Linux or macOS machine with shell access.
- The ability to add MCP servers in Cursor settings.

## 1. Install the binary

Run the installer:

```bash
curl -fsSL https://0d3sa.com/memory/install.sh | sh
```

This downloads the right binary for your platform, verifies its checksum, and installs it to `~/.local/bin/memory`. Make sure `~/.local/bin` is on the PATH Cursor sees, or use the full binary path in step 2.

## 2. Add the MCP server in Cursor

Open **Settings** → **MCP** and add a new stdio server:

| Field | Value |
|-------|-------|
| Name | `memory` |
| Command | `/home/yourname/.local/bin/memory` |
| Arguments | `--db /home/yourname/.memory/default.db` |

Replace `/home/yourname` with your actual home path. If `memory` is on the PATH that Cursor sees, you can use the bare command name instead of the absolute path.

## 3. Start a fresh chat

Cursor discovers tools when a chat starts. Open a new Composer or agent chat so the memory tools are loaded.

## 4. Verify the connection

Ask Cursor to check health:

```text
Call memory_health.
```

You should see a JSON health report. If it fails, re-run the install:

```bash
curl -fsSL https://0d3sa.com/memory/install.sh | sh
```

Then check that the command path in the MCP settings is absolute and that the parent directory for the database exists.

## 5. Test recall

Ask Cursor to remember a preference:

```text
Remember that I keep frontend components under 200 lines.
```

Then start a new chat and ask:

```text
What do you know about my component size preferences?
```

Cursor should recall the fact from the local store.

## Expected output

- `memory version` prints a version string.
- `memory_health` returns `status: ok`.
- A remembered preference is returned when asked in a new chat.

## Troubleshooting

- **Server exits** — ensure `--db` uses an absolute path and the parent directory exists.
- **Command not found** — add `~/.local/bin` to your PATH, or use the absolute binary path.
- **Config not picked up** — start a new Cursor chat after changing the MCP config.
- **Stale Python wrapper from an old install** — if `memory` fails with `ModuleNotFoundError: No module named 'memory_memory'`, remove the broken wrapper and reinstall:
  ```bash
  rm -f ~/.local/bin/memory
  curl -fsSL https://0d3sa.com/memory/install.sh | sh
  ```

## Next steps

- [Connect another MCP client](/memory/tutorials/connect-mcp-client/)
- [Sync two devices with a relay](/memory/tutorials/sync-two-devices-relay/)
- [Tools reference](/memory/reference/tools/)
- [Skills registry](/memory/skills/memory-cursor/)
