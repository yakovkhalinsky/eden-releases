---
title: Multi-device sync
content_type: concept
description: Map of memory sync options. Direct local sync, relay sync loop, pairing, and where to find the tutorial, how-to, concept, and reference pages.
---

memory can keep the same memory store in sync across multiple devices. Sync is peer-to-peer: devices exchange signed delta logs, and conflicts are resolved with logical clocks. You can sync two databases on the same host, or sync across different hosts through a lightweight relay.

## Start here

New to multi-device sync? Read the step-by-step tutorial:

- [Sync two devices with a relay](/memory/tutorials/sync-two-devices-relay/) (tutorial)

## Sync modes

| Mode | Use case | Pairing | Best for |
|------|----------|---------|----------|
| Direct sync | Two databases on the same machine or shared filesystem | Optional `pair-device` | One-shot local backup or shared store |
| Relay sync loop | Devices on different networks | Required | Continuous sync across laptops, desktops, or servers |

## Where the details live

### Tutorials
- [Sync two devices with a relay](/memory/tutorials/sync-two-devices-relay/) — full relay sync from install to verified loop.
- [Sync two databases locally](/memory/tutorials/sync-local-databases/) — direct one-shot sync on the same machine.
- [Connect your MCP client](/memory/mcp-clients/) — first-time client wiring for Claude Code, Cursor, Hermes, or any stdio MCP client.

### How-to guides
- [Run your own relay server](/relay/how-to/run-relay-server/) — stand up and secure a self-hosted relay.
- [Deploy on a public VPS](/relay/how-to/deploy-public-vps/) — full public-internet relay walkthrough with Let's Encrypt, systemd, and hardening.
- [Approve a peer key rotation](/memory/how-to/approve-peer-key-change/) — inspect and approve pending Ed25519/X25519 key changes.
- [Back up and restore a database](/memory/how-to/backup-restore/) — encrypted snapshots and sidecar backup strategy.
- [Prune old memories](/memory/how-to/prune-memories/) — scoped bulk deletion.

### Concepts
- [How sync works](/memory/concepts/how-sync-works/) — delta logs, logical clocks, conflict resolution, double envelope, PAKE pairing, and key rotation.
- [Sidecar files](/memory/concepts/sidecar-files/) — `<db>.sync-keys.json` and `<db>.root-key.json`.
- [Security model](/memory/concepts/security-model/) — relay threat model, password requirements, and what the relay can and cannot see.

### Reference
- [CLI reference](/memory/reference/cli/) — sync, pairing, relay, and global flags.
- [Tools reference](/memory/reference/tools/) — MCP tool schemas for sync and pairing.
- [Environment variables](/memory/reference/environment-variables/) — env vars and cascading precedence.
- [Troubleshooting](/memory/reference/troubleshooting/) — symptom → cause → fix matrix.

## Sync in one command

Direct sync between two local databases:

```bash
memory --db ~/.memory/local.db \
  sync --peer-db /mnt/shared/peer.db --confirm
```

Start a foreground relay sync loop:

```bash
memory --db ~/.memory/device.db \
  sync loop start \
  --relay-url http://relay.example.com:8787 \
  --account-id your-account \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

See the [CLI reference](/memory/reference/cli/) for every flag and subcommand.
