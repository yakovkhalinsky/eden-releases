---
title: Install
description: Download eden-memory for your platform.
---

## Latest release

Download the latest static binary from the table below. Each file includes a SHA-256 checksum for verification.

| OS      | Architecture | Size    | Download | Checksum |
|---------|--------------|---------|----------|----------|
| Linux   | amd64        | ~108 MB | [eden-memory-linux-amd64](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-linux-amd64) | [sha256](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-linux-amd64.sha256) |
| Linux   | arm64        | ~65 MB  | [eden-memory-linux-arm64](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-linux-arm64) | [sha256](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-linux-arm64.sha256) |
| macOS   | amd64        | ~62 MB  | [eden-memory-darwin-amd64](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-darwin-amd64) | [sha256](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-darwin-amd64.sha256) |
| macOS   | arm64        | ~62 MB  | [eden-memory-darwin-arm64](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-darwin-arm64) | [sha256](https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-darwin-arm64.sha256) |

## Install with GitHub CLI

Replace the platform suffix with your OS/arch:

```bash
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

New binaries are published as GitHub Release assets. Update `binaries/manifest.json`, run `./scripts/generate-download-metadata.py --assets-dir <dir>`, commit the changes, and cut a new release.
