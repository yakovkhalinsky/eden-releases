---
title: Sync two databases on the same machine
description: Direct one-shot sync between two local databases, with optional local pairing.
content_type: tutorial
---

# Sync two databases on the same machine

This tutorial shows how to synchronize two eden-memory databases on the same host, or on a shared filesystem, without a relay. This is useful for local backups, shared project stores, or testing sync before moving to a relay.

## Prerequisites

- eden-memory installed.
- Two database paths. By default eden-memory uses `~/.eden-memory/default.db`.
- Both databases are readable and writable by the user running the command.

## 1. Create or identify the two databases

If you do not have a second database yet, eden-memory will create one when it is first opened. For this tutorial we will use:

- `~/.eden-memory/default.db` — the primary store.
- `/mnt/shared/peer.db` — the peer store (this can be any absolute path).

Make sure the peer database's parent directory exists:

```bash
mkdir -p /mnt/shared
```

## 2. Run a direct one-shot sync

The `sync` command performs a bidirectional merge of delta logs between the local database and a peer database.

```bash
eden-memory --db ~/.eden-memory/default.db \
  sync --peer-db /mnt/shared/peer.db --confirm
```

The first time you run this, eden-memory will create the peer database if it does not exist and exchange identity information. The `--confirm` flag is required because the command pushes data to the peer.

To preview what would happen without writing anything, add `--dry-run`:

```bash
eden-memory --db ~/.eden-memory/default.db \
  sync --peer-db /mnt/shared/peer.db --dry-run
```

## 3. Pair the databases for repeated sync (optional)

If you plan to sync the same two databases regularly, pair them once with SPAKE2 so each store pins the other's public key:

```bash
eden-memory --db ~/.eden-memory/default.db \
  pair-device \
  --peer-db /mnt/shared/peer.db \
  --account-id your-account \
  --password "shared-secret" \
  --confirm
```

Use the same `--account-id` on both stores and choose a strong password. After pairing, subsequent `sync` commands can optionally verify the peer by its pinned key.

To preview the pairing without writing peer records, add `--dry-run`.

## 4. Verify the sync

1. Store a memory in the primary database.
2. Run the `sync` command again.
3. Search the peer database for the same memory:

   ```bash
   eden-memory --db /mnt/shared/peer.db search "your memory content"
   ```

Or check the peer count through health on either database:

```bash
eden-memory --db ~/.eden-memory/default.db health
```

## Expected output

- `eden-memory sync` exits 0 and reports the number of deltas exchanged.
- A memory stored in the primary database is searchable in the peer database after sync.
- `eden_health` shows a non-zero `peer_count` after pairing.

## Using the MCP tool

If your agent is connected through MCP, you can also call `eden_sync`:

```json
{
  "peer_db_path": "/mnt/shared/peer.db",
  "confirm": true
}
```

And `eden_pair_device` for pairing:

```json
{
  "peer_db_path": "/mnt/shared/peer.db",
  "account_id": "your-account",
  "password": "shared-secret",
  "confirm": true
}
```

## Troubleshooting

- **Peer database is not writable** — ensure the user owns the peer database path and its parent directory.
- **Identity mismatch** — if the peer database was previously paired with a different account, run `pair-device` again or use a fresh peer database.
- **Deltas not propagating** — both databases must use the same sync schema version. Run `eden-memory health` and check the `version` and `sync` fields.

## Next steps

- [Sync two devices with a relay](/eden-memory/tutorials/sync-two-devices-relay/)
- [How sync works](/eden-memory/concepts/how-sync-works/)
- [Sidecar files](/eden-memory/concepts/sidecar-files/)
- [CLI reference](/eden-memory/reference/cli/)
