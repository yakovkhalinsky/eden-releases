---
title: Sidecar files
description: The .sync-keys.json and .root-key.json files next to an eden-memory database, their permissions, and how to back them up safely.
content_type: concept
---

# Sidecar files

Next to every eden-memory SQLite database there are optional sidecar files that hold keys and device identity. These files are separate from the `.db` so that the database can be backed up, migrated, and synced without carrying the private keys with it.

## File names

For a database at `~/.eden-memory/default.db`, the sidecars are:

```text
~/.eden-memory/default.db.sync-keys.json
~/.eden-memory/default.db.root-key.json
```

The sidecar names are formed by appending `.sync-keys.json` and `.root-key.json` to the database path.

## `<db>.sync-keys.json`

This file stores the Ed25519 and X25519 identity keys for this device:

- **Ed25519** signs every delta the device produces.
- **X25519** encrypts envelopes to peers and decrypts envelopes addressed to this device.
- A human-readable `device_name` is saved during pairing.
- The public keys of paired peers are also stored here.

If this file is lost, the device can no longer sign or decrypt sync traffic. Other peers will see a pending key change when the device creates new keys.

## `<db>.root-key.json`

This file stores the encrypted account root key. It is created or updated when:

- a device is initialized as the first peer in an account,
- a device accepts a relay pairing invitation,
- a new root key is generated.

The root key is encrypted with a passphrase. You can pass it with `--root-key-passphrase` or set `EDEN_ROOT_KEY_PASSPHRASE` in the environment. If the passphrase is lost, the root key cannot be recovered and any encrypted snapshots made with it cannot be restored.

## Permissions

The sidecar files contain private key material. They should be readable only by the user that runs eden-memory:

```text
chmod 600 ~/.eden-memory/default.db.sync-keys.json
chmod 600 ~/.eden-memory/default.db.root-key.json
```

eden-memory creates them with restrictive permissions when possible, but you should verify this on shared machines.

## Backup and restore implications

When you back up an eden-memory database, decide whether to include the sidecars:

| Backup type | Include sidecars? | Outcome |
|-------------|-------------------|---------|
| Full device restore | Yes | The restored device has the same identity and can sync immediately. |
| Database-only snapshot | No | The `.db` restores the memories, but the device needs new identity keys and re-pairing. |
| Encrypted snapshot (`eden_export_snapshot`) | N/A | The snapshot is a single encrypted file; sidecars must be backed up separately. |

A good backup strategy is:

1. Export an encrypted snapshot of the database with `eden_export_snapshot`.
2. Copy the two sidecar files to secure, separate storage.
3. Record the root-key and snapshot passphrases in your password manager.

See [Back up and restore a database](/eden-memory/how-to/backup-restore/) for step-by-step commands.

## Sync and sidecars

Sidecar files are **not** synced between devices. Each device has its own private keys. Only the public keys and signed deltas inside the database travel through sync. If a device loses its sidecar, it must create new keys and have peers approve the key change.

## See also

- [How sync works](/eden-memory/concepts/how-sync-works/)
- [Security model](/eden-memory/concepts/security-model/)
- [Back up and restore a database](/eden-memory/how-to/backup-restore/)
- [Approve a peer key rotation](/eden-memory/how-to/approve-peer-key-change/)
