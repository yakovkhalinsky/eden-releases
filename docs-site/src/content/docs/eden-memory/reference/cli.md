---
title: CLI reference
description: eden-memory command-line reference for sync, pairing, relay, and related flags.
content_type: reference
---

eden-memory is primarily an MCP server, but it also exposes a CLI for setup, maintenance, and multi-device sync. This page covers the sync, pairing, and relay subcommands. For day-to-day memory operations, use the MCP tools or the [fallback slash commands](/eden-memory/reference/fallback-slash-commands/) installed by `eden-memory setup claude`.

## `setup claude`

Wire the current project directory to Claude Code CLI. The helper writes the project `.env` file, registers the project in `~/.claude.json`, removes any stale `eden-memory` entry from `~/.claude/settings.json`, and installs fallback slash commands in `~/.claude/commands/`.

```bash
cd ~/project-a
eden-memory setup claude --db ~/.eden-memory/default.db --org-id your-org
```

| Flag | Required | Description |
|------|----------|-------------|
| `--db` | Yes* | SQLite database path. Defaults to `EDEN_DB_PATH` or `~/.eden-memory/default.db`. |
| `--org-id` | Yes* | Organization scope. Defaults to `EDEN_ORG_ID`. |
| `--workspace-id` | No | Workspace scope. Defaults to `EDEN_WORKSPACE_ID` or the project directory name / git remote. |
| `--agent-id` | No | Agent identity. Defaults to `EDEN_ATP_ROLE` or `claude-code-cli`. |
| `--user-id` | No | User identity. Defaults to `EDEN_USER_ID` or `USER`. |
| `--env-file` | No | Project-level `.env` path (default `./.env`). |
| `--no-env-file` | No | Skip writing the project-level `.env` file. |
| `--force-env` | No | Overwrite existing values in the project `.env` file. |
| `--dry-run` | No | Preview the configuration without writing any files. |
| `--setup-command` | No | Binary path used in generated configs (defaults to the running binary). |

\* Required values are prompted for in normal mode when missing. `--dry-run` aborts instead of prompting, so pass them explicitly.

### `--dry-run`

Use `--dry-run` to validate preflight checks and inspect what `setup claude` would configure before it writes anything:

```bash
eden-memory setup claude --db ~/.eden-memory/default.db --org-id your-org --dry-run
```

In dry-run mode the command:

- Runs the same preflight health and protocol-version checks as normal mode.
- Prints a JSON preview with `project_dir`, `db_path`, `command`, `org_id`, `workspace_id`, `agent_id`, `user_id`, `env_file`, `write_claude_json`, and `install_slash_commands`.
- Does **not** write the project `.env` file.
- Does **not** update `~/.claude.json`.
- Does **not** update `~/.claude/settings.json`.
- Does **not** install slash commands in `~/.claude/commands/`.
- Aborts with an error if `org_id` or `workspace_id` cannot be determined, instead of prompting interactively.

## Global flags

These flags can appear before or after the subcommand:

| Flag | Env var | Description |
|------|---------|-------------|
| `--db` | `EDEN_DB_PATH` | SQLite database path. Default: `~/.eden-memory/default.db`. |
| `--log-format` | `EDEN_LOG_FORMAT` | `text` or `json`. |
| `--log-level` | `EDEN_LOG_LEVEL` | `DEBUG`, `INFO`, `WARN`, or `ERROR`. |
| `--sync-disabled` | `EDEN_SYNC_DISABLED` | Skip the v3 sync schema and run local-only. |
| `--sync-interval` | `EDEN_SYNC_INTERVAL` | Background sync loop interval (default `30s`). |
| `--relay-url` | `EDEN_RELAY_URL` | Default relay URL for sync/pairing. |
| `--account-id` | `EDEN_ACCOUNT_ID` | Default fleet account ID for sync/pairing. |
| `--root-key-passphrase` | `EDEN_ROOT_KEY_PASSPHRASE` | Passphrase for the encrypted root-key sidecar. |
| `--device-name` | — | Human-readable name for this device, saved in the identity sidecar (used by `pair-device`, `pair create-invitation`, `pair accept-invitation`). |
| `--local-name` | — | Local display-name override for a peer (used by `sync set-peer-name`). |
| `--code` | — | Invitation code for `pair accept-invitation` (alternative to the positional argument). |
| `--start-sync-loop` | — | After `pair accept-invitation`, run the foreground sync loop in this process until SIGINT/SIGTERM. |

## `update`

Check for, download, and install a newer eden-memory binary. The command fetches the canonical `VERSION` file and the platform binary matching your OS and architecture, verifies the SHA-256 sidecar, backs up the existing binary to `~/.cache/eden-memory/backups/`, and atomically replaces it.

```bash
# Check whether a newer release exists
eden-memory update --check

# Download and install if newer (explicit)
eden-memory update

# Preview what would happen
eden-memory update --dry-run

# Restore the most recent backup
eden-memory update --rollback

# Use a different distribution URL
eden-memory update --prefix https://example.com/eden-memory/
```

| Flag | Env var | Description |
|------|---------|-------------|
| `--check` | — | Only report whether an update is available; do not download. |
| `--dry-run` | — | Print the remote version, download URL, and backup location without changing files. |
| `--rollback` | — | Restore the latest backup from `~/.cache/eden-memory/backups/`. |
| `--prefix` | `EDEN_UPDATE_PREFIX` | Base URL that hosts `VERSION` and platform binaries (default `https://0d3sa.com/eden-memory/`). |
| `--binary-path` | `EDEN_MEMORY_BIN` | Path to the binary to update (defaults to the running executable). |

## `packet`

Build a deterministic, scope-bound knowledge packet for the current workspace and print it to stdout. A packet is a self-contained snapshot of memories, stats, and optional semantic clusters. It is useful for exporting context, hand-offs between agents, or offline review.

```bash
eden-memory packet --format json --template default --limit 50
```

The packet is scope-bound to a single `org_id`/`workspace_id` pair. Pass identity explicitly, set `EDEN_ORG_ID` and `EDEN_WORKSPACE_ID`, or let `setup claude` persist them in the project config. See [Scopes and identity](/eden-memory/concepts/scopes-identity/) for precedence rules.

### Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--format` | `json` | Output format: `json` (canonical), `md`, or `html`. |
| `--template` | `default` | Consumer template: `default`, `compact`, `analytical`, or `full`. |
| `--include-content` | `false` | Emit full memory contents instead of 120-rune excerpts. Adds a privacy warning. |
| `--since` | — | RFC3339 timestamp; only include memories created or updated at or after this time. |
| `--limit` | `50` | Maximum number of memories to include. The `compact` template defaults to `10`. |
| `--enrich` | — | Optional enrichment pass: `cluster`. The `analytical` template defaults to `cluster`. |

### Templates and defaults

Templates are additive: they set defaults, and explicit flags win where they are non-zero (booleans such as `--include-content` are opt-in).

| Template | Default excerpt length | Default limit | Notable settings |
|----------|------------------------|---------------|------------------|
| `default` | 120 | 50 | Balanced stats + excerpts + clusters. |
| `compact` | 80 | 10 | Omits per-memory metadata; title becomes "Knowledge Brief". |
| `analytical` | 120 | 50 | Enables `enrich=cluster`; omits per-memory metadata. |
| `full` | full content | 50 | Sets `--include-content`; emits all memory text. |

### Examples

Default JSON packet:

```bash
eden-memory packet --org-id your-org --workspace-id eden-releases
```

Compact Markdown brief:

```bash
eden-memory packet --template compact --format md --limit 10
```

Analytical packet with semantic clusters:

```bash
eden-memory packet --template analytical --format html --enrich cluster
```

Full-content packet (includes a privacy warning in the output):

```bash
eden-memory packet --template full --format md --include-content
```

Only memories updated in the last 24 hours:

```bash
eden-memory packet --since "$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)" --format md
```

### Privacy note

By default, packets contain excerpts truncated to 120 runes and never include raw embedding vectors. Use `--include-content` or the `full` template only when the consumer is trusted; the rendered output will carry a warning that full memory contents are included.

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

### `sync list-pending-key-changes`

List staged pending Ed25519/X25519 key changes from peers.

```bash
eden-memory --db local.db sync list-pending-key-changes
```

### `sync approve-key-change`

Apply a staged pending key change after previewing fingerprints and public-key hex.

```bash
eden-memory --db local.db \
  sync approve-key-change --peer-id <device-id> --confirm
```

### `sync reject-key-change`

Discard a staged pending key change.

```bash
eden-memory --db local.db \
  sync reject-key-change --peer-id <device-id> --confirm
```

### `sync set-peer-name`

Set (or clear) a local-only display-name override for a peer. The signed name
from pairing is preserved.

```bash
eden-memory --db local.db \
  sync set-peer-name --peer-id <device-id> --local-name "Work Laptop"
```

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
| `--device-name` | No | Human-readable name saved in the identity sidecar. |
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
  --password "correct-horse-battery-staple" \
  --device-name "Studio Desktop" \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

Response includes an invitation code to share with the joining device, plus a
short rendezvous code used to look up the PAKE enrolment on the relay. The
pairing password must be shared separately and must be at least 10 characters
long with at least 40 bits estimated entropy.

| Flag | Required | Description |
|------|----------|-------------|
| `--relay-url` | Yes | Relay base URL. |
| `--account-id` | Yes | Fleet account ID. |
| `--password` | Yes* | Pairing password; prompted if omitted. |
| `--device-name` | No | Human-readable name saved in the identity sidecar. |
| `--root-key-passphrase` | Yes* | Root-key sidecar passphrase; prompted if omitted. |
| `--confirm` | Yes* | Confirm creating the enrolment. |
| `--dry-run` | No | Preview without publishing an enrolment. |

### `pair accept-invitation`

```bash
eden-memory --db local.db pair accept-invitation <code> \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

Or pass the code with `--code` and auto-start the foreground sync loop after
pairing completes:

```bash
eden-memory --db local.db pair accept-invitation \
  --code <code> \
  --start-sync-loop \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

The joining device receives the account root key, records the initiator as a
peer, and registers itself with the relay automatically. With `--start-sync-loop`
it also starts the foreground relay sync loop in the same process.

| Argument | Required | Description |
|----------|----------|-------------|
| `code` (positional) | Yes* | Compact invitation code from the initiator. |
| `--code` | Yes* | Alternative way to pass the invitation code. |
| `--device-name` | No | Human-readable name saved in the identity sidecar. |
| `--start-sync-loop` | No | Start the foreground sync loop after pairing completes. |
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

The same relay is also available as the dedicated `eden-relay` binary. It uses `--db` instead of `--relay-db`, has no `--confirm` guard, and exposes the same HTTP endpoints. See the [`eden-relay` section](#eden-relay) below.

## `eden-relay`

The dedicated `eden-relay` binary is a lightweight relay-only build from the `eden-memory` monorepo. It is useful on VPS or always-on hosts where you only need the relay and do not want the full `eden-memory` CLI or MCP server.

```bash
eden-relay \
  --db /var/lib/eden-relay/relay.db \
  --addr :8787
```

With TLS:

```bash
eden-relay \
  --db /var/lib/eden-relay/relay.db \
  --addr :443 \
  --tls-cert /path/to/cert.pem \
  --tls-key /path/to/key.pem
```

| Flag | Env var | Description |
|------|---------|-------------|
| `--db` | `EDEN_RELAY_DB` | Relay SQLite database path. |
| `--addr` | `EDEN_RELAY_ADDR` | Listen address (default `:8787`). |
| `--tls-cert` | `EDEN_TLS_CERT` | TLS certificate path. Must be supplied with `--tls-key`. |
| `--tls-key` | `EDEN_TLS_KEY` | TLS private-key path. Must be supplied with `--tls-cert`. |
| `--require-per-device-auth` | `EDEN_RELAY_REQUIRE_PER_DEVICE_AUTH` | Reject legacy account-derived auth tokens once every device has re-registered. |

The `eden-memory relay-server` subcommand remains available and exposes the same relay functionality inside the full binary.

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

Pass `--sync-disabled` (or set `EDEN_SYNC_DISABLED=1`) to skip the v3 sync schema migration and run the database in local-only mode. See [Environment variables](/eden-memory/reference/environment-variables/) for the full table and precedence rules.

## See also

- [Tools reference](/eden-memory/reference/tools/)
- [Environment variables](/eden-memory/reference/environment-variables/)
- [Fallback slash commands](/eden-memory/reference/fallback-slash-commands/)
- [Troubleshooting](/eden-memory/reference/troubleshooting/)
- [Knowledge packets](/eden-memory/concepts/knowledge-packets/)
- [Build a knowledge packet](/eden-memory/how-to/build-knowledge-packet/)
- [How sync works](/eden-memory/concepts/how-sync-works/)
- [Run your own relay server](/eden-relay/how-to/run-relay-server/)
- [Approve a peer key rotation](/eden-memory/how-to/approve-peer-key-change/)

