---
title: Tools reference
description: What each memory MCP tool does, the inputs it accepts, and when to use it.
content_type: reference
---

All inputs are JSON objects. Tools that read or write memories require `agent_id` and `user_id`. Most tools also accept `org_id` and `workspace_id`, which default to the server environment variables `MEMORY_ORG_ID` and `MEMORY_WORKSPACE_ID`.

## Quick reference

| Tool | Purpose | Mutates data |
|------|---------|--------------|
| `memory_remember` | Store a durable memory | Yes |
| `memory_recall` | Semantic recall | No |
| `memory_search` | Keyword search | No |
| `memory_search_semantic` | Semantic search with metadata filters | No |
| `memory_lookup_cross` | Look up one memory in another workspace | No |
| `memory_edit` | Update a memory by ID | Yes |
| `memory_forget` | Soft-delete a memory by ID | Yes |
| `memory_forget_expired` | Delete all expired memories | Yes |
| `memory_health` | Health, sync, usage, and telemetry snapshot | No |
| `memory_vacuum` | SQLite WAL checkpoint | Yes (store maintenance) |
| `memory_prune` | Bulk soft-delete or hard-delete memories | Yes |
| `memory_migrate` | Remap `org_id`/`workspace_id` for a scope | Yes |
| `memory_packet` | Build a deterministic knowledge packet | No |
| `memory_packet_publish` | Publish a packet as a stable artifact | Yes |
| `memory_packet_list` | List published packets | No |
| `memory_packet_export` | Re-render a published packet | No |
| `memory_report` | Build an audience-aware narrative report | No (Yes with `publish`) |
| `memory_document` | Build a decision log, runbook, or changelog | No (Yes with `publish`) |
| `memory_document_publish` | Publish a document as a stable artifact | Yes |
| `memory_document_list` | List published documents | No |
| `memory_document_export` | Re-render a published document | No |
| `memory_dream` | Run the dreaming curator (preview) | No (Yes with `dry_run=false`) |
| `memory_dream_apply` | Apply a persisted dream's staged actions | Yes |
| `memory_export_snapshot` | Export an encrypted database snapshot | No |
| `memory_import_snapshot` | Import an encrypted snapshot | Yes (replaces DB) |
| `memory_sync` | One-shot bidirectional sync with a peer DB | Yes |
| `memory_pair_device` | Pair with a local peer DB using SPAKE2 | Yes |
| `memory_sync_loop` | Start/stop/status/once for relay sync loop | Yes (when running) |
| `memory_relay_server` | Start/stop/status a local relay server | Yes (when starting) |
| `memory_relay_register` | Register this device with a relay | Yes (relay directory) |
| `memory_pair_create_invitation` | Create a relay-mediated PAKE invitation | Yes (relay enrolment) |
| `memory_pair_accept_invitation` | Accept a relay-mediated PAKE invitation | Yes |

Tools that mutate data either require an explicit confirmation (`confirm: true`) or default to dry-run mode.

## Memory tools

### `memory_remember`

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

### `memory_recall`

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

See [Scopes and identity](/memory/concepts/scopes-identity/) for how `agent_id`, `user_id`, `org_id`, and `workspace_id` filter results.

### `memory_search`

Keyword search over stored memory content.

```json
{
  "agent_id": "my-client",
  "user_id": "yakov",
  "query": "Python examples",
  "limit": 10
}
```

### `memory_search_semantic`

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

### `memory_lookup_cross`

Look up a single memory in another workspace of the same org. In `easy` authorization mode any cross-workspace lookup is allowed; in `enterprise` mode the target workspace must appear in `MEMORY_CROSS_WORKSPACE_IDS`. See [Security model](/memory/concepts/security-model/).

```json
{
  "org_id": "your-org",
  "workspace_id": "other-project",
  "record_id": "a1b2c3d4-...",
  "include_metadata": true
}
```

Optional `source_record_id` tags the referring memory for provenance.

### `memory_edit`

Update an existing memory by ID. Use this when a fact changes instead of storing a duplicate.

```json
{
  "id": "a1b2c3d4-...",
  "content": "User prefers Python examples, concise sentences, and explicit types.",
  "metadata": {"source": "user-correction", "domain": "style"},
  "ttl_ms": null
}
```

### `memory_forget`

Delete a specific memory by ID.

```json
{"id": "a1b2c3d4-..."}
```

### `memory_forget_expired`

Remove all memories past their TTL. This is a housekeeping tool; do not call it automatically.

```json
{}
```

Optional: `agent_id`, `user_id`, `org_id`, `workspace_id` to scope the cleanup.

### `memory_health`

Return a combined health, sync, usage, and telemetry snapshot.

```json
{}
```

The `total` count is global and not affected by scoping.

### `memory_vacuum`

Compact the SQLite store. Call only when explicitly asked to perform maintenance.

```json
{}
```

## Maintenance and data-management tools

### `memory_prune`

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

Use `hard: true` with `yes_i_really_want_to_delete: true` for permanent deletion. Use `org_empty`, `workspace_empty`, `agent_empty`, or `user_empty` to match rows with empty/NULL scope values. See [Prune old memories](/memory/how-to/prune-memories/) for a step-by-step guide.

### `memory_migrate`

In-place remapping of `org_id`/`workspace_id` for a scope. Dry-run by default; requires `confirm: true` and `dry_run: false` to mutate. Set `backup: true` to copy the database first. See [Migrate a workspace](/memory/how-to/migrate-workspace/).

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

### `memory_packet`

Build a deterministic, scope-bound knowledge packet for a single workspace. Never emits raw vectors.

```json
{
  "format": "md",
  "template": "compact",
  "since": "2026-07-01T00:00:00Z",
  "limit": 50
}
```

Input fields:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `format` | string | `json` | Output format: `json`, `md`, or `html`. |
| `template` | string | `default` | Consumer template: `default`, `compact`, `analytical`, or `full`. |
| `include_content` | boolean | `false` | Emit full memory contents instead of excerpts. Adds a privacy warning. |
| `since` | string | — | RFC3339 timestamp; only include memories created or updated at or after this time. |
| `limit` | integer | `50` | Maximum memories to include. The `compact` template defaults to `10`. |
| `enrich` | string | — | Optional enrichment pass: `cluster`. The `analytical` template defaults to `cluster`. |
| `org_id` | string | `MEMORY_ORG_ID` env | Organization scope. Required if not configured. |
| `workspace_id` | string | `MEMORY_WORKSPACE_ID` env | Workspace scope. Required if not configured. |

Response shape:

```json
{
  "format": "md",
  "packet": "# Knowledge Brief\n\n...",
  "warnings": [
    "Full memory contents are included in this packet. Share it only with trusted consumers."
  ]
}
```

- `format` echoes the requested format.
- `packet` is the rendered output as a single string.
- `warnings` is empty unless full contents are emitted, in which case it contains the privacy warning.

Templates and defaults:

| Template | Excerpt length | Default limit | Enrichment | Notes |
|----------|----------------|---------------|------------|-------|
| `default` | 120 runes | 50 | — | Balanced stats + excerpts + optional clusters. |
| `compact` | 80 runes | 10 | — | Omits per-memory metadata; title is "Knowledge Brief". |
| `analytical` | 120 runes | 50 | `cluster` | Omits per-memory metadata; emphasizes semantic clusters. |
| `full` | full content | 50 | — | Sets `include_content=true` automatically. |

The canonical JSON packet uses schema version `1.1.0`. Excerpts are deterministic: most recently updated memories appear first, then ties are broken by memory ID. Clusters, when enabled, are derived from scoped vector similarity using a 0.75 cosine threshold and a cap of eight clusters. No raw embeddings are ever included.

See [Knowledge packets](/memory/concepts/knowledge-packets/) and [Build a knowledge packet](/memory/how-to/build-knowledge-packet/) for more detail.

### `memory_packet_publish`

Publish an existing packet row as a stable artifact.

```json
{
  "packet_id": "a1b2c3d4-...",
  "title": "Week 34 brief",
  "version": "1.0.0",
  "audience": "human"
}
```

Optional `expires_at` (RFC3339) and `goal_id`.

### `memory_packet_list`

List published packet artifacts in the workspace.

```json
{"audience": "human", "limit": 50}
```

### `memory_packet_export`

Re-render a published packet artifact.

```json
{"packet_id": "a1b2c3d4-...", "format": "md", "redact": false}
```

`format` is `json`, `md` (default), or `html`; `redact: true` hashes content and strips sensitive metadata. Response mirrors `memory_packet`: `{"format": "...", "packet": "..."}`.

## Reporting and document tools

### `memory_report`

Build an audience-aware narrative report over a time window of workspace memories. Returns the rendered text and, with `publish: true`, a `report_id`.

```json
{
  "period": "weekly",
  "audience": "human",
  "format": "md",
  "redact": true,
  "publish": false
}
```

Input fields: `period` (`daily`/`weekly`/`monthly`), `since` (RFC3339), `audience` (`human`/`agent`/`manager`), `format` (`json`/`md`/`html`), `include`/`exclude` (comma-separated sections), `title`, `redact`, `publish`, `goal_id`, and `limit` (maximum source memories). `agent_id`/`user_id` default to `claude`/`yakov` when omitted.

### `memory_document`

Build a deterministic, mode-specific narrative document. Modes: `decision-log`, `runbook`, or `changelog`. Flags mirror `memory_report`, plus `mode`, `since`/`until`, and `goal_id`.

```json
{
  "mode": "decision-log",
  "since": "2026-08-01T00:00:00Z",
  "format": "md",
  "publish": true
}
```

### `memory_document_publish`

Publish an existing document row as a stable artifact (same fields as `memory_packet_publish`, with `document_id`).

### `memory_document_list`

List published documents in the workspace: `{"audience": "human", "limit": 50}`.

### `memory_document_export`

Re-render a published document: `{"document_id": "...", "format": "md", "redact": false}`.

## Dreaming tools

### `memory_dream`

Run the LLM-first dreaming curator over a scoped memory corpus and return a preview report. Read-only by default.

```json
{
  "topic": "deployment friction",
  "output_format": "md"
}
```

- `topic` or `query` selects the corpus; `limit` caps memories considered.
- `output_format` is `json` (default `md`), or `html`.
- Pass `dry_run: false` to persist the result as a `dream_record` for later review by `memory_dream_apply`.

Requires a reachable OpenAI-compatible endpoint (`MEMORY_LLM_BASE_URL`, default `http://localhost:11434/v1`) and `MEMORY_LLM_MODEL`. See [Dreaming](/memory/concepts/dreaming/).

### `memory_dream_apply`

Apply the staged actions of a persisted `dream_record`. This is the only dreaming tool that modifies memories.

```json
{
  "dream_id": "a1b2c3d4-...",
  "confirm": true,
  "approve_forget": false,
  "apply_safe_only": false
}
```

- `confirm: true` materializes mutations.
- `approve_forget: true` is required for destructive actions (`merge_duplicates`, `improve`, `propose_forget`).
- `apply_safe_only: true` skips actions that require human review.

### `memory_export_snapshot`

Export an encrypted AES-256-GCM + scrypt snapshot of the database. See [Back up and restore a database](/memory/how-to/backup-restore/).

```json
{
  "path": "/path/to/backup.bin",
  "passphrase": "a strong passphrase"
}
```

### `memory_import_snapshot`

Import an encrypted snapshot, replacing the current database. Requires both confirmations. See [Back up and restore a database](/memory/how-to/backup-restore/).

```json
{
  "path": "/path/to/backup.bin",
  "passphrase": "a strong passphrase",
  "confirm": true,
  "yes_i_really_want_to_replace": true
}
```

## Sync, pairing, and relay tools

These tools were added to support multi-device sync. See the [multi-device sync guide](/memory/multi-device-sync/) for a map, the [Sync two devices with a relay](/memory/tutorials/sync-two-devices-relay/) tutorial, and [How sync works](/memory/concepts/how-sync-works/) for protocol details.

### `memory_sync`

One-shot bidirectional sync with a peer database via `DirectTransport`. Requires `peer_db_path` and `confirm: true` because pushing mutates the peer.

```json
{
  "peer_db_path": "/path/to/peer.db",
  "peer_device_id": "optional-device-id",
  "batch_size": 1000,
  "confirm": true
}
```

### `memory_pair_device`

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

### `memory_sync_loop`

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
- `passphrase` falls back to `MEMORY_ROOT_KEY_PASSPHRASE` in the server environment.

### `memory_relay_server`

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

### `memory_relay_register`

Register the current device with a relay directory so peers can discover it.

```json
{
  "relay_url": "http://relay.example.com:8787",
  "account_id": "your-account",
  "passphrase": "root-key-passphrase",
  "confirm": true
}
```

### `memory_pair_create_invitation`

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

### `memory_pair_accept_invitation`

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
- **Housekeeping is manual.** `memory_forget_expired`, `memory_vacuum`, `memory_prune`, and sync-loop management are admin tools, not automatic routines.
