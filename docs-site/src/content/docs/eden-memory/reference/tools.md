---
title: Tools reference
description: What each eden-memory MCP tool does, the inputs it accepts, and when to use it.
content_type: reference
---

All inputs are JSON objects. Tools that read or write memories require `agent_id` and `user_id`. Most tools also accept `org_id` and `workspace_id`, which default to the server environment variables `EDEN_ORG_ID` and `EDEN_WORKSPACE_ID`.

## Quick reference

| Tool | Purpose | Mutates data |
|------|---------|--------------|
| `eden_remember` | Store a durable memory | Yes |
| `eden_recall` | Semantic recall | No |
| `eden_search` | Keyword search | No |
| `eden_search_semantic` | Semantic search with metadata filters | No |
| `eden_edit` | Update a memory by ID | Yes |
| `eden_forget` | Soft-delete a memory by ID | Yes |
| `eden_forget_expired` | Delete all expired memories | Yes |
| `eden_health` | Health, sync, usage, and telemetry snapshot | No |
| `eden_vacuum` | SQLite WAL checkpoint | Yes (store maintenance) |
| `eden_prune` | Bulk soft-delete or hard-delete memories | Yes |
| `eden_migrate` | Remap `org_id`/`workspace_id` for a scope | Yes |
| `eden_packet` | Build a deterministic knowledge packet | No |
| `eden_export_snapshot` | Export an encrypted database snapshot | No |
| `eden_import_snapshot` | Import an encrypted snapshot | Yes (replaces DB) |
| `eden_sync` | One-shot bidirectional sync with a peer DB | Yes |
| `eden_pair_device` | Pair with a local peer DB using SPAKE2 | Yes |
| `eden_sync_loop` | Start/stop/status/once for relay sync loop | Yes (when running) |
| `eden_relay_server` | Start/stop/status a local relay server | Yes (when starting) |
| `eden_relay_register` | Register this device with a relay | Yes (relay directory) |
| `eden_pair_create_invitation` | Create a relay-mediated PAKE invitation | Yes (relay enrolment) |
| `eden_pair_accept_invitation` | Accept a relay-mediated PAKE invitation | Yes |

Tools that mutate data either require an explicit confirmation (`confirm: true`) or default to dry-run mode.

## Memory tools

### `eden_remember`

Store a durable memory.

```json
{
  "agent_id": "my-client",
  "user_id": "yakov",
  "content": "User prefers Python examples and concise sentences.",
  "metadata": {"source": "direct-statement", "domain": "style"},
  "ttl_ms": null,
  "workspace_id": "eden-releases",
  "org_id": "your-org"
}
```

- `agent_id` and `user_id` are required.
- `ttl_ms: null` means the memory never expires. A positive integer sets an expiry in milliseconds.
- `workspace_id` scopes the memory to a project; `org_id` is for fleet contexts.
- Legacy aliases: `observer_id` → `agent_id`, `observed_id` → `user_id`, `fact` → `content`.

Response:

```json
{"id": "a1b2c3d4-...", "status": "remembered"}
```

### `eden_recall`

Semantic recall for this user. Call once at task start and before finalizing decisions that could contradict past preferences.

```json
{
  "agent_id": "my-client",
  "user_id": "yakov",
  "workspace_id": "eden-releases",
  "query": "style and tone preferences",
  "limit": 5
}
```

Response:

```json
{
  "results": [
    {
      "id": "a1b2c3d4-...",
      "content": "User prefers Python examples and concise sentences.",
      "metadata": {"source": "direct-statement", "domain": "style"},
      "score": 0.92
    }
  ]
}
```

Legacy aliases: `topic` / `top_k` → `query` / `limit`.

See [Scopes and identity](/eden-memory/concepts/scopes-identity/) for how `agent_id`, `user_id`, `org_id`, and `workspace_id` filter results.

### `eden_search`

Keyword search over stored memory content.

```json
{
  "agent_id": "my-client",
  "user_id": "yakov",
  "query": "Python examples",
  "limit": 10
}
```

### `eden_search_semantic`

Semantic search with optional metadata filters.

```json
{
  "agent_id": "my-client",
  "user_id": "yakov",
  "query": "What style does the user prefer?",
  "filters": {"domain": "style"},
  "limit": 5
}
```

The first semantic call may load the bundled embedding model. Subsequent calls are fast.

### `eden_edit`

Update an existing memory by ID. Use this when a fact changes instead of storing a duplicate.

```json
{
  "id": "a1b2c3d4-...",
  "content": "User prefers Python examples, concise sentences, and explicit types.",
  "metadata": {"source": "user-correction", "domain": "style"},
  "ttl_ms": null
}
```

### `eden_forget`

Delete a specific memory by ID.

```json
{"id": "a1b2c3d4-..."}
```

### `eden_forget_expired`

Remove all memories past their TTL. This is a housekeeping tool; do not call it automatically.

```json
{}
```

Optional: `agent_id`, `user_id`, `org_id`, `workspace_id` to scope the cleanup.

### `eden_health`

Return a combined health, sync, usage, and telemetry snapshot.

```json
{}
```

The `total` count is global and not affected by scoping.

### `eden_vacuum`

Compact the SQLite store. Call only when explicitly asked to perform maintenance.

```json
{}
```

## Maintenance and data-management tools

### `eden_prune`

Scoped bulk soft-delete (default) or hard-delete of memories. Runs as dry-run unless `confirm: true` and `dry_run: false` are passed.

```json
{
  "org_id": "your-org",
  "workspace_id": "old-ws",
  "keywords": "deprecated",
  "expired_only": false,
  "dry_run": false,
  "confirm": true
}
```

Use `hard: true` with `yes_i_really_want_to_delete: true` for permanent deletion. Use `org_empty`, `workspace_empty`, `agent_empty`, or `user_empty` to match rows with empty/NULL scope values. See [Prune old memories](/eden-memory/how-to/prune-memories/) for a step-by-step guide.

### `eden_migrate`

In-place remapping of `org_id`/`workspace_id` for a scope. Dry-run by default; requires `confirm: true` and `dry_run: false` to mutate. Set `backup: true` to copy the database first. See [Migrate a workspace](/eden-memory/how-to/migrate-workspace/).

```json
{
  "from_org_id": "your-org",
  "from_workspace_id": "old-ws",
  "to_org_id": "your-org",
  "to_workspace_id": "new-ws",
  "confirm": true,
  "dry_run": false
}
```

### `eden_packet`

Build a deterministic, scope-bound knowledge packet. Never emits raw vectors.

```json
{
  "format": "md",
  "template": "compact",
  "since": "2026-07-01T00:00:00Z",
  "limit": 50
}
```

- `format`: `json`, `md`, or `html`.
- `template`: `default`, `compact`, `analytical`, or `full`.
- `include_content: true` emits full memory text with a privacy warning.
- `enrich: "cluster"` adds semantic clusters without raw vectors.

### `eden_export_snapshot`

Export an encrypted AES-256-GCM + scrypt snapshot of the database. See [Back up and restore a database](/eden-memory/how-to/backup-restore/).

```json
{
  "path": "/path/to/backup.bin",
  "passphrase": "a strong passphrase"
}
```

### `eden_import_snapshot`

Import an encrypted snapshot, replacing the current database. Requires both confirmations. See [Back up and restore a database](/eden-memory/how-to/backup-restore/).

```json
{
  "path": "/path/to/backup.bin",
  "passphrase": "a strong passphrase",
  "confirm": true,
  "yes_i_really_want_to_replace": true
}
```

## Sync, pairing, and relay tools

These tools were added to support multi-device sync. See the [multi-device sync guide](/eden-memory/multi-device-sync/) for a map, the [Sync two devices with a relay](/eden-memory/tutorials/sync-two-devices-relay/) tutorial, and [How sync works](/eden-memory/concepts/how-sync-works/) for protocol details.

### `eden_sync`

One-shot bidirectional sync with a peer database via `DirectTransport`. Requires `peer_db_path` and `confirm: true` because pushing mutates the peer.

```json
{
  "peer_db_path": "/path/to/peer.db",
  "peer_device_id": "optional-device-id",
  "batch_size": 1000,
  "confirm": true
}
```

### `eden_pair_device`

Pair the local store with a peer database using in-process SPAKE2. Stores pinned peer public keys in both stores.

```json
{
  "peer_db_path": "/path/to/peer.db",
  "account_id": "your-account",
  "password": "shared-secret",
  "confirm": true
}
```

Use `dry_run: true` to preview without writing peer records.

### `eden_sync_loop`

Start, stop, run once, or check status of the background relay sync loop.

```json
{
  "action": "start",
  "relay_url": "http://relay.example.com:8787",
  "account_id": "your-account",
  "passphrase": "root-key-passphrase",
  "interval_ms": 30000,
  "batch_size": 1000,
  "confirm": true
}
```

- `action`: `start`, `stop`, `status`, or `once`.
- `start` requires `relay_url`, `account_id`, and a root-key passphrase.
- `passphrase` falls back to `EDEN_ROOT_KEY_PASSPHRASE` in the server environment.

### `eden_relay_server`

Start or stop a local HTTP relay server.

```json
{
  "action": "start",
  "addr": ":8787",
  "relay_db_path": "/path/to/relay.db",
  "confirm": true
}
```

- `action`: `start`, `stop`, or `status`.
- `start` requires `relay_db_path`.

### `eden_relay_register`

Register the current device with a relay directory so peers can discover it.

```json
{
  "relay_url": "http://relay.example.com:8787",
  "account_id": "your-account",
  "passphrase": "root-key-passphrase",
  "confirm": true
}
```

### `eden_pair_create_invitation`

Create a relay-mediated PAKE pairing invitation.

```json
{
  "relay_url": "http://relay.example.com:8787",
  "account_id": "your-account",
  "password": "shared-secret",
  "passphrase": "root-key-passphrase",
  "confirm": true
}
```

The response includes an `invitation_code` to share out-of-band with the responder. `dry_run: true` previews without publishing an enrolment.

### `eden_pair_accept_invitation`

Accept a relay-mediated PAKE pairing invitation. Persists the account root key sidecar and records the initiator as a peer.

```json
{
  "code": "abc123...",
  "passphrase": "root-key-passphrase",
  "confirm": true
}
```

Use `dry_run: true` to preview without mutating the store or sidecar.

## Usage tips

- **Recall before deciding.** Before answering a question about user preferences, recall first.
- **Edit, don't duplicate.** When a fact changes, find the existing memory and edit it.
- **Confirm mutations.** Tools that write to a peer DB or perform bulk operations require `confirm: true` or default to dry-run.
- **What not to store.** Avoid secrets, command output, session IDs, and temporary state.
- **Housekeeping is manual.** `eden_forget_expired`, `eden_vacuum`, `eden_prune`, and sync-loop management are admin tools, not automatic routines.
