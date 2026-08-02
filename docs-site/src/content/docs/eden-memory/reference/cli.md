---
title: CLI reference
description: eden-memory command-line reference for sync, pairing, relay, and related flags.
---

eden-memory is primarily an MCP server, but it also exposes a CLI for setup, maintenance, and multi-device sync. This page covers the sync, pairing, and relay subcommands. For day-to-day memory operations, use the MCP tools or the fallback slash commands installed by `eden-memory setup claude`.

## Global flags

These flags can appear before or after the subcommand:

| Flag | Env var | Description |
|------|---------|-------------|
| `--db` | `EDEN_DB_PATH` | SQLite database path. Default: `~/.eden-memory/default.db`. |
| `--log-format` | `EDEN_LOG_FORMAT` | `text` or `json`. |
| `--log-level` | `EDEN_LOG_LEVEL` | `DEBUG`, `INFO`, `WARN`, or `ERROR`. |
| `--sync-disabled` | `EDEN_SYNC_DISABLED` | Skip the v2 sync schema and run local-only. |
| `--sync-interval` | `EDEN_SYNC_INTERVAL` | Background sync loop interval (default `30s`). |
| `--relay-url` | `EDEN_RELAY_URL` | Default relay URL for sync/pairing. |
| `--account-id` | `EDEN_ACCOUNT_ID` | Default fleet account ID for sync/pairing. |
| `--root-key-passphrase` | `EDEN_ROOT_KEY_PASSPHRASE` | Passphrase for the encrypted root-key sidecar. |

## `sync`

One-shot bidirectional sync with a local peer database.

```bash
eden-memory --db local.db sync --peer-db peer.db --confirm
```

| Flag | Required | Description |
|------|----------|-------------|
| `--peer-db` | Yes | Path to the peer SQLite database. |
| `--peer-id` | No | Peer device ID; read from the peer store if omitted. |
| `--batch-size` | No | Maximum deltas per batch (default 1000). |
| `--confirm` | Yes* | Confirm the operation. |
| `--dry-run` | No | Preview without mutating the peer. |

\* `sync` aborts unless `--confirm` or `--dry-run` is passed.

## `sync loop`

Start, run once, stop, or check status of the background relay sync loop.

```bash
# Start a foreground loop
eden-memory --db local.db sync loop start \
  --relay-url http://relay.example.com:8787 \
  --account-id your-account \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm

# Single round
eden-memory --db local.db sync loop once \
  --relay-url http://relay.example.com:8787 \
  --account-id your-account \
  --root-key-passphrase "$(cat passphrase.txt)"

# Status / stop
eden-memory --db local.db sync loop status
eden-memory --db local.db sync loop stop
```

| Flag | Required | Description |
|------|----------|-------------|
| `action` | Yes | `start`, `once`, `stop`, or `status`. |
| `--relay-url` | For `start`/`once` | Relay base URL. |
| `--account-id` | For `start`/`once` | Fleet account ID. |
| `--root-key-passphrase` | For `start`/`once` | Passphrase; prompted if omitted. |
| `--sync-interval` | No | Loop interval (default `30s`). |
| `--batch-size` | No | Maximum deltas per batch (default 1000). |
| `--confirm` | For `start` | Confirm starting the background goroutine. |

## `pair-device`

Pair the local database with a peer database in the same process using SPAKE2.

```bash
eden-memory --db local.db pair-device \
  --peer-db peer.db \
  --account-id your-account \
  --password "shared-secret" \
  --confirm
```

| Flag | Required | Description |
|------|----------|-------------|
| `--peer-db` | Yes | Path to the peer SQLite database. |
| `--account-id` | Yes | Fleet account ID. |
| `--password` | Yes* | Pairing password; prompted if omitted. |
| `--confirm` | Yes* | Confirm pairing. |
| `--dry-run` | No | Preview without writing peer records. |

\* `pair-device` aborts unless `--confirm` or `--dry-run` is passed. The password is prompted if omitted.

## `pair`

Relay-mediated PAKE pairing for devices on different hosts.

### `pair create-invitation`

```bash
eden-memory --db local.db pair create-invitation \
  --relay-url http://relay.example.com:8787 \
  --account-id your-account \
  --password "shared-secret" \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

Response includes an invitation code to share with the joining device.

| Flag | Required | Description |
|------|----------|-------------|
| `--relay-url` | Yes | Relay base URL. |
| `--account-id` | Yes | Fleet account ID. |
| `--password` | Yes* | Pairing password; prompted if omitted. |
| `--root-key-passphrase` | Yes* | Root-key sidecar passphrase; prompted if omitted. |
| `--confirm` | Yes* | Confirm creating the enrolment. |
| `--dry-run` | No | Preview without publishing an enrolment. |

### `pair accept-invitation`

```bash
eden-memory --db local.db pair accept-invitation <code> \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

The joining device receives the account root key, records the initiator as a peer, and registers with the relay.

| Argument | Required | Description |
|----------|----------|-------------|
| `code` | Yes | Compact invitation code from the initiator. |
| `--root-key-passphrase` | Yes* | Passphrase to encrypt the new root-key sidecar; prompted if omitted. |
| `--confirm` | Yes* | Confirm accepting the invitation. |
| `--dry-run` | No | Preview without mutating the store. |

## `relay-server`

Run a local HTTP relay server for account peer discovery and encrypted envelope forwarding.

```bash
eden-memory relay-server \
  --relay-db /var/lib/eden-relay/relay.db \
  --addr :8787 \
  --confirm
```

| Flag | Required | Description |
|------|----------|-------------|
| `--relay-db` | Yes | Relay SQLite database path. |
| `--addr` | No | Listen address (default `:8787`). |
| `--confirm` | Yes | Confirm starting the server. |

## `relay-register`

Register the current device with a relay directory.

```bash
eden-memory --db local.db relay-register \
  --relay-url http://relay.example.com:8787 \
  --account-id your-account \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

| Flag | Required | Description |
|------|----------|-------------|
| `--relay-url` | Yes | Relay base URL. |
| `--account-id` | Yes | Fleet account ID. |
| `--root-key-passphrase` | Yes* | Passphrase; prompted if omitted. |
| `--confirm` | Yes* | Confirm registration. |
| `--dry-run` | No | Preview without writing to the relay. |

## Disabling sync

Pass `--sync-disabled` (or set `EDEN_SYNC_DISABLED=1`) to skip the v2 sync schema migration and run the database in local-only mode.
