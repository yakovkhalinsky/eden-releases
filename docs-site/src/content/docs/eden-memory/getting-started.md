---
title: Install & get started
description: Download eden-memory, verify it, connect a client, and test memory.
---

## Install

The installer downloads the right binary for your platform, verifies the checksum, and installs it to `~/.local/bin`:

```bash
curl -fsSL https://0d3sa.com/install.sh | sh
```

If you prefer to install by hand, see the [download table](#manual-download) below.

## Verify

```bash
eden-memory version
```

You should see a version string. If not, make sure `~/.local/bin` is on your PATH.

## Connect a client

eden-memory speaks MCP over stdio. We publish [agent skills](/eden-memory/skills/) for popular clients:

- [Claude Code CLI](/eden-memory/skills/eden-memory-claude/)
- [Cursor](/eden-memory/skills/eden-memory-cursor/)
- [Hermes Agent](/eden-memory/skills/eden-memory-hermes/)

For other clients the server command is:

```bash
eden-memory --db /home/yourname/.eden-memory/default.db
```

## Test it

Once your client is connected, ask it to remember something:

```text
Remember that I prefer Python examples and short sentences.
```

Then start a new conversation and ask:

```text
What do you know about my communication preferences?
```

The client should recall the preference from the local store.

## What eden-memory does

eden-memory lets your AI agent remember things across conversations. It runs locally, stores memories in a SQLite database, and connects to any MCP client over stdio.

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

## Next steps

- [Skills registry](/eden-memory/skills/) — agent skills for every harness with autodiscoverable tools.
- [Tools reference](/eden-memory/reference/tools/) — what each tool does and when to use it.
