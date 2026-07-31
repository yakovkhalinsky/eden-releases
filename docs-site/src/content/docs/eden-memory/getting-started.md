---
title: Install & get started
description: Download eden-memory, verify it, connect a client, and test memory.
---

## Install

Run the installer:

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```

This downloads the right binary for your platform, verifies its checksum, and installs it to `~/.local/bin`.

If you prefer to install by hand, use the download table below.

## Verify

```bash
eden-memory version
```

You should see a version string. If you do not, make sure `~/.local/bin` is on your PATH.

Then check that the binary can open its database:

```bash
eden-memory health
```

## Connect a client

eden-memory speaks MCP over stdio. The exact setup depends on your client:

- [Claude Code CLI](/eden-memory/skills/eden-memory-claude/)
- [Cursor](/eden-memory/skills/eden-memory-cursor/)
- [Hermes Agent](/eden-memory/skills/eden-memory-hermes/)

For any other client, add a server with this command:

```bash
eden-memory --db /home/yourname/.eden-memory/default.db
```

Use your real username. The JSON shape is:

```json
{
  "mcpServers": {
    "eden-memory": {
      "command": "eden-memory",
      "args": ["--db", "/home/yourname/.eden-memory/default.db"]
    }
  }
}
```

Restart your client after adding the server.

## Test it

Ask your agent to remember something:

```text
Remember that I prefer Python examples and short sentences.
```

Then start a new conversation and ask:

```text
What do you know about my communication preferences?
```

The agent should recall the preference from the local store.

## What it does

eden-memory stores memories in a SQLite database at `~/.eden-memory/default.db`. Each memory gets a 256-dimensional embedding. When the agent runs `eden_recall`, eden-memory compares the query embedding to stored vectors and returns the closest matches.

## Manual download

Pick your OS and architecture. Each download includes a SHA-256 checksum file.

| OS | Architecture | Download | Checksum |
|---|---|---|---|
| Linux | amd64 | [eden-memory-linux-amd64](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-linux-amd64) | [sha256](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-linux-amd64.sha256) |
| Linux | arm64 | [eden-memory-linux-arm64](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-linux-arm64) | [sha256](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-linux-arm64.sha256) |
| macOS | amd64 | [eden-memory-darwin-amd64](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-darwin-amd64) | [sha256](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-darwin-amd64.sha256) |
| macOS | arm64 | [eden-memory-darwin-arm64](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-darwin-arm64) | [sha256](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-darwin-arm64.sha256) |

### Manual install

```bash
curl -LO https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-linux-arm64
curl -LO https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-linux-arm64.sha256
sha256sum -c eden-memory-linux-arm64.sha256
chmod +x eden-memory-linux-arm64
mv eden-memory-linux-arm64 ~/.local/bin/eden-memory
```

Replace `linux-arm64` with your platform.

## Built for teams?

If you use Claude Code, the [agentic-team-protocol](/agentic-team-protocol/) runs on top of eden-memory and adds role-based subagents (Dispatcher, Researcher, Builder, Verifier, Archivist) with a seven-stage goal lifecycle.

## Next steps

- [Connect your client](/eden-memory/mcp-clients/)
- [Tools reference](/eden-memory/reference/tools/)
- [Skills registry](/eden-memory/skills/)
- [Agentic team protocol](/agentic-team-protocol/)
