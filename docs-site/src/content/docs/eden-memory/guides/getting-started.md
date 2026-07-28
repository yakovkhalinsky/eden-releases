---
title: Getting Started
description: Download and run the eden-memory agent harness locally.
---

## Overview

eden-memory is a single-file Go binary that embeds its own Python runtime and embedding model. It exposes the Model Context Protocol (MCP) over stdio, so any MCP client can use it.

This guide gets you from download to a working memory store in a few minutes.

## 1. Download a binary

Visit the [install page](/eden-memory/guides/install/) and download the binary for your platform, or use the GitHub CLI:

```bash
gh release download latest --repo yakovkhalinsky/eden-releases \
  --pattern 'eden-memory-linux-arm64' --clobber
chmod +x eden-memory-linux-arm64
mv eden-memory-linux-arm64 eden-memory
```

Supported platforms are listed on the install page.

## 2. Verify the checksum

Each binary has a `.sha256` file in the same release:

```bash
sha256sum -c eden-memory-linux-arm64.sha256
```

## 3. Run the MCP server

eden-memory speaks MCP over stdio. Start it with a database path:

```bash
eden-memory --db ~/.eden-memory/default.db
```

On first run it extracts the bundled runtime and model weights to your platform cache directory (`~/.cache/eden-memory` on Linux).

## 4. Wire it to a client

See [MCP Clients](/eden-memory/guides/mcp-clients/) for copy-paste configuration for Claude Desktop, Cursor, Hermes, and others.

## 5. Test with a tool call

Once your client is connected, try asking it to remember something, then recall it in a fresh session:

```text
Remember that I prefer Python code examples and short sentences.
```

Then start a new conversation and ask:

```text
What do you know about my communication preferences?
```

The agent should recall the preference from the local store.

## Next steps

- [Install page](/eden-memory/guides/install/) — download links and platform table.
- [MCP clients](/eden-memory/guides/mcp-clients/) — per-client wiring.
- [Tools reference](/eden-memory/reference/tools/) — exact tool schemas and when to use each one.
