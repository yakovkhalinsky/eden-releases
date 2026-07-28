---
title: Install
description: Download eden-memory for your platform.
---

## Latest release

Download the latest static binary from the table below. Each file includes a SHA-256 checksum for verification.

| Platform | Architecture | Size | Download | Checksum |
|----------|--------------|------|----------|----------|
| Linux    | arm64        | ~71 MB | [eden-memory-linux-arm64](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-linux-arm64) | [sha256](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-linux-arm64.sha256) |

## Install with GitHub CLI

```bash
# Replace linux-arm64 with your platform when available
gh release download latest --repo yakovkhalinsky/eden-releases \
  --pattern 'eden-memory-linux-arm64' --clobber
chmod +x eden-memory-linux-arm64
mv eden-memory-linux-arm64 eden-memory
eden-memory version
```

## Verify

```bash
sha256sum -c eden-memory-linux-arm64.sha256
```

## Place on PATH

```bash
mv eden-memory ~/.local/bin/   # or /usr/local/bin, ~/bin, etc.
```

## First run

The binary is self-contained. On first launch it unpacks the bundled Python runtime and model weights to the platform cache:

- Linux: `~/.cache/eden-memory`
- macOS: `~/Library/Caches/eden-memory`

```bash
eden-memory --db ~/.eden-memory/default.db
```

See [Getting Started](/guides/getting-started/) for wiring it to an MCP client.

## Adding new platforms

New binaries are dropped into the `binaries/` directory of this repo and published on the next tag. If you build eden-memory for another OS/arch, name it `eden-memory-<os>-<arch>`, generate a `.sha256` file, and open a PR.
