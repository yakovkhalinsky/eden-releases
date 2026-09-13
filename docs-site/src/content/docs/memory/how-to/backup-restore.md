---
title: Back up and restore a database
description: Back up an memory database with the memory_export_snapshot tool and keep the sidecar files safe.
content_type: how-to
---

# Back up and restore a database

This guide walks through creating an encrypted snapshot of an memory database with the `memory_export_snapshot` MCP tool, restoring it with `memory_import_snapshot`, and handling the sidecar files that hold your device identity.

## Prerequisites

- memory installed and running as an MCP server.
- The database path (default `~/.memory/default.db`).
- A strong, unique passphrase for the snapshot.
- A secure place to store the sidecar files and passphrase separately.

## 1. Export an encrypted snapshot

Call `memory_export_snapshot` from your MCP client. The snapshot is encrypted with AES-256-GCM + scrypt.

```json
{
  "path": "/home/yourname/backups/memory-2026-08-02.bin",
  "passphrase": "a strong unique passphrase"
}
```

The tool returns the output path and a checksum. The snapshot contains the database contents but **not** the sidecar files.

## 2. Copy the sidecar files

Copy the two files next to your database to the same backup location:

```bash
cp ~/.memory/default.db.sync-keys.json ~/backups/
cp ~/.memory/default.db.root-key.json ~/backups/
```

Restrict their permissions:

```bash
chmod 600 ~/backups/default.db.sync-keys.json
chmod 600 ~/backups/default.db.root-key.json
```

## 3. Store the passphrases separately

Keep the snapshot passphrase and the root-key passphrase in your password manager. Do not store them in the same folder as the backup files.

## 4. Restore the database

On the target machine, place the snapshot file where you want it and call `memory_import_snapshot`. This replaces the database at `--db`.

```json
{
  "path": "/home/yourname/backups/memory-2026-08-02.bin",
  "passphrase": "a strong unique passphrase",
  "confirm": true,
  "yes_i_really_want_to_replace": true
}
```

Both confirmations are required because the import overwrites the current database.

## 5. Restore the sidecars

If you want the restored device to keep the same identity and sync peer keys, copy the sidecar files back next to the database:

```bash
cp ~/backups/default.db.sync-keys.json ~/.memory/default.db.sync-keys.json
cp ~/backups/default.db.root-key.json ~/.memory/default.db.root-key.json
chmod 600 ~/.memory/default.db.sync-keys.json
chmod 600 ~/.memory/default.db.root-key.json
```

If you omit the sidecars, the restored database keeps the memories but the device gets a new identity. Peers will see a pending key change and must approve it before sync resumes.

## 6. Verify the restore

Check health and list any pending key changes:

```json
{}
```

Use `memory_health` and `memory_sync list-pending-key-changes`. If there are pending key changes, approve them as described in [Approve a peer key rotation](/memory/how-to/approve-peer-key-change/).

## Expected outcome

- The snapshot file is created and is not readable without the passphrase.
- The restored database contains the same memories as the source.
- With sidecars restored, the device identity and peer keys are preserved.
- Sync resumes after any pending key changes are approved.

## See also

- [Sidecar files](/memory/concepts/sidecar-files/)
- [Migrate a workspace](/memory/how-to/migrate-workspace/)
- [Tools reference](/memory/reference/tools/)
