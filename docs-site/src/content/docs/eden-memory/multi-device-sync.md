---
title: Multi-device sync
description: Sync eden-memory databases across devices using direct local sync or a self-hosted relay.
---

eden-memory can keep the same memory store in sync across multiple devices. Sync is peer-to-peer: devices exchange signed delta logs, and conflicts are resolved with logical clocks. You can sync two databases on the same host, or sync across different hosts through a lightweight relay.

## Sync modes

| Mode | Use case | Pairing required |
|------|----------|------------------|
| Direct sync | Two databases on the same machine or shared filesystem | Optional (`pair-device`) |
| Relay sync loop | Devices on different networks | Yes (`pair` or out-of-band key exchange) |

## Direct sync

The simplest way to sync two databases is a one-shot direct sync. Both stores must be reachable as local files.

```bash
eden-memory --db ~/.eden-memory/local.db \
  sync --peer-db /mnt/shared/peer.db --confirm
```

What happens:

1. Each store opens and reads its device identity from ``<db>.sync-keys.json``.
2. Each store creates a peer record for the other device if one does not exist.
3. A bidirectional anti-entropy round pulls and pushes deltas in both directions.
4. The result is printed as JSON with `local_to_peer` and `peer_to_local` counts.

Optional flags:

- `--peer-id <device-id>` — use a specific peer device ID instead of reading it from the peer store.
- `--batch-size 500` — cap the number of deltas per batch (default 1000).
- `--dry-run` — preview without mutating either store.

### Direct pairing

Direct sync does not require public-key authentication, but you can pin public keys first so future sync rounds can verify deltas:

```bash
eden-memory --db ~/.eden-memory/local.db \
  pair-device \
  --peer-db /mnt/shared/peer.db \
  --account-id your-account \
  --password "shared-secret" \
  --confirm
```

Both devices run SPAKE2 in the same process and record each other's Ed25519/X25519 public keys.

## Relay sync across devices

For devices that are not on the same filesystem, use a self-hosted relay. The relay only stores opaque, encrypted envelopes — it cannot decrypt contents or impersonate devices.

### 1. Run a relay

On a server both devices can reach:

```bash
eden-memory relay-server \
  --relay-db /var/lib/eden-relay/relay.db \
  --addr :8787 \
  --confirm
```

The relay exposes `/health`, `/v1/register`, `/v1/peers`, `/v1/push`, `/v1/pull`, `/v1/ack`, and PAKE rendezvous endpoints.

### 2. Create an account root key

Each device stores its own copy of the account root key in ``<db>.root-key.json``, encrypted with a passphrase. The first command that needs the root key will create the sidecar automatically.

### 3. Pair the first device manually (optional)

If you already have a second device in the same account, you can pair it with a relay-mediated PAKE invitation:

**Device A (already in the fleet):**

```bash
eden-memory --db ~/.eden-memory/device-a.db \
  pair create-invitation \
  --relay-url http://relay.example.com:8787 \
  --account-id your-account \
  --password "shared-secret" \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

This prints an invitation code to share with device B.

**Device B (joining the fleet):**

```bash
eden-memory --db ~/.eden-memory/device-b.db \
  pair accept-invitation <code> \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

Device B receives the account root key, records device A as a peer, and registers itself with the relay.

### 4. Register with the relay

If a device is already paired, register it so peers can discover it:

```bash
eden-memory --db ~/.eden-memory/device.db \
  relay-register \
  --relay-url http://relay.example.com:8787 \
  --account-id your-account \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

`eden sync loop start` also registers automatically.

### 5. Start the background sync loop

Run a foreground loop that discovers peers from the relay and runs anti-entropy rounds on an interval:

```bash
eden-memory --db ~/.eden-memory/device.db \
  sync loop start \
  --relay-url http://relay.example.com:8787 \
  --account-id your-account \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

Use `sync loop once` for a single round, `sync loop status` to inspect state, and `sync loop stop` (or `SIGINT`/`SIGTERM`) to stop the foreground loop.

The loop:

1. Loads or creates the account root-key sidecar and derives the account sync key.
2. Loads or creates the device identity sidecar (``<db>.sync-keys.json``).
3. Registers the device with the relay directory.
4. Discovers peers from the relay every five minutes.
5. Runs anti-entropy rounds against every non-revoked peer on `--sync-interval` (default 30s).
6. Backs off individual peers on error, up to a maximum of 5 minutes.

## Sidecar files

Sync creates two sidecar files next to your database:

- ``<db>.sync-keys.json`` — device Ed25519/X25519 identity keys. Created automatically with `0o600` permissions.
- ``<db>.root-key.json`` — account root key encrypted with scrypt + XChaCha20-Poly1305. Created when you first run a command that needs it.

Keep these files as safe as the database itself. If you lose the root-key passphrase, other devices in the same account cannot recover it for you.

## Security notes

- Deltas are signed by the originating device and verified by the recipient.
- Relay traffic uses a double envelope: inner encryption with the account sync key, outer ECDH encryption between devices, plus an Ed25519 outer signature.
- The relay cannot read message contents or forge device identities.
- Pairing uses SPAKE2 with a shared password; the password itself is never sent over the wire.

## Disabling sync

To run a database in local-only mode and skip the v2 sync schema, start the binary with `--sync-disabled` or set `EDEN_SYNC_DISABLED=1`.
