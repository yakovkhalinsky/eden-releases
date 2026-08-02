---
title: Connect another MCP client
description: Generic JSON config and verification for any stdio MCP client.
content_type: tutorial
---

# Connect another MCP client

eden-memory speaks the Model Context Protocol (MCP) over stdio. This tutorial shows the generic server config for any MCP-compatible client, plus a quick verification.

## Prerequisites

- A Linux or macOS machine with shell access.
- An MCP client that supports stdio servers.
- The ability to edit the client's `mcpServers` JSON or server list.

## 1. Install the binary

Run the installer:

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```

This downloads the right binary for your platform, verifies its checksum, and installs it to `~/.local/bin/eden-memory`. Make sure the directory is on the PATH your client sees, or use the absolute binary path in the server config.

## 2. Add the server config

The server command is:

```bash
eden-memory --db /home/yourname/.eden-memory/default.db
```

Use your real username. The `--db` path must be absolute, and the parent directory must exist.

If your client uses a `mcpServers` JSON config, add this:

```json
{
  "mcpServers": {
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
}
```

Replace `/home/yourname` with your actual home path. If `eden-memory` is on the client's PATH, you can use the bare command name.

## 3. Restart your client

MCP servers are usually loaded when the client starts. Restart or reload the client after adding the server.

## 4. Verify the connection

Ask your agent to run `eden_health`. You should see a JSON health report. If it fails:

1. Re-run the install:
   ```bash
   curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
   ```
2. Confirm the `--db` path is absolute.
3. Confirm the parent directory for the database exists.
4. Check that the binary path in the server config is correct for the client's environment.

## 5. Test remember and recall

Ask your agent to store a fact:

```text
Remember that I use Python for examples and keep sentences short.
```

Then start a new conversation and ask:

```text
What do you know about my writing preferences?
```

The agent should recall the fact from the local store.

## Expected output

- `eden-memory version` prints a version string.
- `eden_health` returns `status: ok`.
- A stored fact is returned when asked in a new session.

## Tool names

The exact tool names depend on your client's MCP prefix. Common patterns are:

- `eden_remember`
- `eden_recall`
- `eden_search`
- `eden_search_semantic`
- `eden_edit`
- `eden_forget`
- `eden_forget_expired`
- `eden_health`
- `eden_vacuum`

See the [tools reference](/eden-memory/reference/tools/) for full schemas.

## Next steps

- [Connect Claude Code](/eden-memory/tutorials/connect-claude-code/)
- [Connect Cursor](/eden-memory/tutorials/connect-cursor/)
- [Sync two devices with a relay](/eden-memory/tutorials/sync-two-devices-relay/)
- [CLI reference](/eden-memory/reference/cli/)
