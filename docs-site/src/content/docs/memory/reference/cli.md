---
title: CLI reference
description: memory command-line reference for sync, pairing, relay, and related flags.
content_type: reference
---

memory is primarily an MCP server, but it also exposes a CLI for setup, maintenance, and multi-device sync. This page covers the setup, sync, pairing, and relay subcommands. For day-to-day memory operations, use the MCP tools or the [fallback slash commands](/memory/reference/fallback-slash-commands/) installed by `od3sa-memory setup claude`.

## `setup`

Bare `setup` creates or updates the identity file at `~/.memory/.env` with `MEMORY_ORG_ID`. Run it once after the installer to configure your organization scope.

```bash
od3sa-memory setup
```

This is identity-only and does not wire any MCP client.

### `--print-mcp-json`

Print a JSON snippet suitable for MCP clients that accept `mcpServers` configuration (Cursor, generic harnesses). The snippet includes the absolute binary path, absolute `--db` path, and any resolved identity environment variables (`MEMORY_ORG_ID`, `MEMORY_WORKSPACE_ID`).

```bash
od3sa-memory setup --print-mcp-json
```

This prints to stdout and exits — it does **not** write any files. Use it to generate paste-ready config for Cursor or other MCP clients that don't use Claude Code's `~/.claude.json` format. See [Connect Cursor](/memory/tutorials/connect-cursor/) and [MCP clients](/memory/mcp-clients/).

## `setup claude`

Wire the current project directory to Claude Code CLI. The helper prompts for an agent identity and a user identity, asks whether the project is personal or team/org (which derives `MEMORY_AUTHORIZATION_MODE`), writes a project-local `.env` file, registers the project in `~/.claude.json`, removes any stale user-level `memory` MCP entry, and installs fallback slash commands in `~/.claude/commands/`.

```bash
cd ~/project-a
od3sa-memory setup claude
```

| Flag | Required | Description |
|------|----------|-------------|
| `--db` | Yes* | SQLite database path. Defaults to `MEMORY_DB_PATH` or `~/.memory/default.db`. |
| `--org-id` | Yes* | Organization scope. Defaults to `MEMORY_ORG_ID`. |
| `--workspace-id` | No | Workspace scope. Defaults to `MEMORY_WORKSPACE_ID` or the project directory name / git remote. |
| `--agent-id` | No | Agent identity. Defaults to `MEMORY_AGENT_ID`, else prompted. |
| `--user-id` | No | User identity. Defaults to `MEMORY_USER_ID`, then `USER`. |
| `--env-file` | No | Project-level `.env` path (default `./.env`). |
| `--no-env-file` | No | Skip writing the project-level `.env` file. |
| `--force-env` | No | Overwrite existing values in the project `.env` file. |
| `--dry-run` | No | Preview the configuration without writing any files. |
| `--setup-command` | No | Binary path used in generated configs (defaults to the running binary). |

\* Required values are prompted for in normal mode when missing. `--dry-run` aborts instead of prompting, so pass them explicitly.

The project `.env` file (default `./.env`) receives `MEMORY_DB_PATH`, `MEMORY_AGENT_ID`, `MEMORY_USER_ID`, `MEMORY_ORG_ID`, `MEMORY_WORKSPACE_ID`, `MEMORY_AUTHORIZATION_MODE`, `MEMORY_BIN`, and `MEMORY_LOG_LEVEL`. Setup adds the file to `.gitignore` and warns if git already tracks it. In team/org (`enterprise`) mode it also seeds an empty `MEMORY_CROSS_WORKSPACE_IDS`.

### `--dry-run`

Use `--dry-run` to validate preflight checks and inspect what `setup claude` would configure before it writes anything:

```bash
od3sa-memory setup claude --db ~/.memory/default.db --org-id your-org --dry-run
```

In dry-run mode the command:

- Runs the same preflight health and protocol-version checks as normal mode.
- Prints a JSON preview with `project_dir`, `db_path`, `command`, `org_id`, `workspace_id`, `agent_id`, `user_id`, `authorization_mode`, `env_file`, `write_claude_json`, and `install_slash_commands`.
- Does **not** write the project `.env` file.
- Does **not** update `~/.claude.json`.
- Does **not** update `~/.claude/settings.json`.
- Does **not** install slash commands in `~/.claude/commands/`.
- Aborts with an error if `org_id` or `workspace_id` cannot be determined, instead of prompting interactively.

## `mcp`

Start the MCP server. By default, memory runs as a stdio MCP server. With `--http`, it runs as a self-hosted Streamable HTTP server instead.

### Stdio mode (default)

Running `od3sa-memory --db ~/.memory/default.db` with no subcommand starts the stdio MCP server. MCP clients spawn this process and communicate over stdin/stdout.

### HTTP mode

```bash
od3sa-memory --db ~/.memory/default.db mcp --http 127.0.0.1:8788 \
  --api-key-file ~/.memory/mcp-api-key.txt
```

| Flag | Env var | Description |
|------|---------|-------------|
| `--http` | — | Listen address for the HTTP server (e.g., `127.0.0.1:8788`). Required for HTTP mode. |
| `--api-key-file` | `MEMORY_MCP_API_KEY` | Path to a file containing the bearer token (must have `0600` or `0400` permissions). Required for HTTP mode. |

The HTTP server exposes:

- `GET /.well-known/mcp/server-card.json` — server card for auto-discovery (no auth required).
- `POST /` — MCP protocol endpoint (requires `Authorization: Bearer <token>`).

:::caution[Self-hosted only]
The HTTP MCP server is self-hosted. This is **not** a managed, hosted, or multi-tenant service — you run and operate the server yourself.
:::

:::caution[Binding to all interfaces]
Passing `:8788` or `0.0.0.0:8788` exposes the server to your network. Only do this behind a firewall, VPN, or TLS terminator. For local development, bind to `127.0.0.1:8788`.
:::

See [Run a local HTTP MCP server](/memory/tutorials/streamable-http-local/) for a full walkthrough.

## Global flags

These flags can appear before or after the subcommand:

| Flag | Env var | Description |
|------|---------|-------------|
| `--db` | `MEMORY_DB_PATH` | SQLite database path. Default: `~/.memory/default.db`. |
| `--log-format` | `MEMORY_LOG_FORMAT` | `text` or `json`. |
| `--log-level` | `MEMORY_LOG_LEVEL` | `DEBUG`, `INFO`, `WARN`, or `ERROR`. |
| `--sync-disabled` | `MEMORY_SYNC_DISABLED` | Skip the v3 sync schema and run local-only. |
| `--sync-interval` | `MEMORY_SYNC_INTERVAL` | Background sync loop interval (default `30s`). |
| `--relay-url` | `MEMORY_RELAY_URL` | Default relay URL for sync/pairing. |
| `--account-id` | `MEMORY_ACCOUNT_ID` | Default fleet account ID for sync/pairing. |
| `--root-key-passphrase` | `MEMORY_ROOT_KEY_PASSPHRASE` | Passphrase for the encrypted root-key sidecar. Prefer `--root-key-passphrase-file`. |
| `--root-key-passphrase-file` | — | Path to a file containing the root-key passphrase (must have `0600` or `0400` permissions). Preferred over `--root-key-passphrase`. |
| `--device-name` | — | Human-readable name for this device, saved in the identity sidecar (used by `pair-device`, `pair create-invitation`, `pair accept-invitation`). |
| `--local-name` | — | Local display-name override for a peer (used by `sync set-peer-name`). |
| `--code` | — | Invitation code for `pair accept-invitation` (alternative to the positional argument). Prefer `--code-file`. |
| `--code-file` | — | Path to a file containing the invitation code (must have `0600` or `0400` permissions). Preferred over `--code` to avoid exposing secrets in `ps`. |
| `--password-file` | — | Path to a file containing the pairing password (must have `0600` or `0400` permissions). Preferred over `--password` to avoid exposing secrets in `ps`. |
| `--start-sync-loop` | — | After `pair accept-invitation`, run the foreground sync loop in this process until SIGINT/SIGTERM. |

## `update`

Check for, download, and install a newer memory binary. The command fetches the canonical `VERSION` file and the platform binary matching your OS and architecture, verifies the SHA-256 sidecar, backs up the existing binary to `~/.cache/memory/backups/`, and atomically replaces it.

```bash
# Check whether a newer release exists
od3sa-memory update --check

# Download and install if newer (explicit)
od3sa-memory update

# Preview what would happen
od3sa-memory update --dry-run

# Restore the most recent backup
od3sa-memory update --rollback

# Use a different distribution URL
od3sa-memory update --prefix https://example.com/memory/
```

| Flag | Env var | Description |
|------|---------|-------------|
| `--check` | — | Only report whether an update is available; do not download. |
| `--dry-run` | — | Print the remote version, download URL, and backup location without changing files. |
| `--rollback` | — | Restore the latest backup from `~/.cache/memory/backups/`. |
| `--prefix` | `MEMORY_UPDATE_PREFIX` | Base URL that hosts `VERSION` and platform binaries (default `https://0d3sa.com/memory/`). |
| `--binary-path` | `MEMORY_BIN` | Path to the binary to update (defaults to the running executable). |

## `packet`

Build a deterministic, scope-bound knowledge packet for the current workspace and print it to stdout. A packet is a self-contained snapshot of memories, stats, and optional semantic clusters. It is useful for exporting context, hand-offs between agents, or offline review.

```bash
od3sa-memory packet --format json --template default --limit 50
```

The packet is scope-bound to a single `org_id`/`workspace_id` pair. Pass identity explicitly, set `MEMORY_ORG_ID` and `MEMORY_WORKSPACE_ID`, or let `setup claude` persist them in the project config. See [Scopes and identity](/memory/concepts/scopes-identity/) for precedence rules.

### Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--format` | `json` | Output format: `json` (canonical), `md`, or `html`. |
| `--template` | `default` | Consumer template: `default`, `compact`, `analytical`, or `full`. |
| `--audience` | `human` | Consumer audience: `human` or `agent`. Agent packets default to 20 excerpts of 80 runes and retain metadata. |
| `--include-content` | `false` | Emit full memory contents instead of 120-rune excerpts. Adds a privacy warning. |
| `--since` | — | RFC3339 timestamp; only include memories created or updated at or after this time. |
| `--limit` | `50` | Maximum number of memories to include. The `compact` template defaults to `10`. |
| `--enrich` | — | Optional enrichment pass: `cluster`. The `analytical` template defaults to `cluster`. |
| `--title` | — | Stable title used when publishing the packet. |
| `--version` | — | Semantic version recorded for the published packet. |
| `--publish` | `false` | Persist and publish the packet in addition to printing it. |
| `--redact` | `false` | Hash content and strip sensitive metadata keys. |

### Publish, list, and export

Published packets are stored as durable records so you can re-export them later:

```bash
# Build and publish in one step
od3sa-memory packet --template compact --format md --title "Week 34 brief" --publish

# List published packets
od3sa-memory packet list

# Export a published packet by ID
od3sa-memory packet export <packet-id> --format md > brief.md
```

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
od3sa-memory packet --org-id your-org --workspace-id eden-releases
```

Compact Markdown brief:

```bash
od3sa-memory packet --template compact --format md --limit 10
```

Analytical packet with semantic clusters:

```bash
od3sa-memory packet --template analytical --format html --enrich cluster
```

Full-content packet (includes a privacy warning in the output):

```bash
od3sa-memory packet --template full --format md --include-content
```

Only memories updated in the last 24 hours:

```bash
od3sa-memory packet --since "$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)" --format md
```

### Privacy note

By default, packets contain excerpts truncated to 120 runes and never include raw embedding vectors. Use `--include-content` or the `full` template only when the consumer is trusted; the rendered output will carry a warning that full memory contents are included.

## `report`

Generate an audience-aware narrative report over a time window of memories in the current scope.

```bash
od3sa-memory report --period weekly --audience human --format md
od3sa-memory report --since 2026-08-01T00:00:00Z --template weekly-manager --redact --output report.md
```

| Flag | Default | Description |
|------|---------|-------------|
| `--since` | — | RFC3339 start of the report window. |
| `--period` | `weekly` | Report period alias: `daily`, `weekly`, or `monthly`. |
| `--audience` | `human` | Report audience: `human`, `agent`, or `manager`. |
| `--format` | `markdown` | Output format: `json`, `md`/`markdown`, or `html`. |
| `--template` | — | Template hint: `default`, `weekly-manager`, or `compact` (overrides the audience default). |
| `--include` / `--exclude` | — | Comma-separated sections to include or suppress. |
| `--title` | — | Report title. |
| `--redact` | `false` | Hash content and strip sensitive metadata keys. |
| `--publish` | `false` | Persist the report as a published memory (returns a `report_id`). |
| `--output` | stdout | Destination file. |
| `--max-sources` | — | Maximum source memories to include. |

## `document`

Generate a structured document (decision log, runbook, or changelog) from a window of memories. Flags mirror `report`, plus:

```bash
od3sa-memory document --mode decision-log --since 2026-08-01T00:00:00Z --format md
od3sa-memory document list
od3sa-memory document publish <document-id>
od3sa-memory document export <document-id> --format md > runbook.md
```

| Flag | Default | Description |
|------|---------|-------------|
| `--mode` | `decision-log` | Document mode: `decision-log`, `runbook`, or `changelog`. |
| `--since` / `--until` | — | RFC3339 window bounds. |
| `--period` | `weekly` | Period alias: `daily`, `weekly`, or `monthly`. |
| `--audience` | `human` | `human`, `agent`, or `manager`. |
| `--format` | `markdown` | `json`, `md`/`markdown`, or `html`. |
| `--goal-id` | — | Goal ID filter. |
| `--publish` | `false` | Persist the document as a published memory. |
| `--redact` | `false` | Hash content and strip sensitive metadata keys. |

`document list` accepts `--published` (default `true`) to only list published documents.

## `dream`

Run the LLM-first dreaming curator over a scoped memory corpus. Requires a reachable OpenAI-compatible endpoint (`MEMORY_LLM_BASE_URL`, default `http://localhost:11434/v1`) and `MEMORY_LLM_MODEL` or `--llm-model`.

### `dream preview`

Read-only by default:

```bash
od3sa-memory dream preview --topic "deployment friction" --output-format md
od3sa-memory dream preview --query "Tailscale" --limit 30 --output-format json
od3sa-memory dream preview --persist --ttl-ms 604800000   # store the dream_record
```

### `dream apply`

Apply a previous dream's staged actions to the store. This is the only dreaming command that modifies memories, and it is gated:

```bash
# Safe actions only
od3sa-memory dream apply <dream-id> --confirm

# Include destructive actions (merge_duplicates, improve, propose_forget)
od3sa-memory dream apply <dream-id> --approve-forget --confirm

# Preview what would change
od3sa-memory dream apply <dream-id> --dry-run
```

| Flag | Required | Description |
|------|----------|-------------|
| `dream-id` | Yes | ID of the persisted `dream_record` to apply. |
| `--confirm` | Yes | Confirm the apply. |
| `--approve-forget` | No | Approve destructive actions (`merge_duplicates`, `improve`, `propose_forget`). |
| `--apply-safe-only` | No | Skip actions that require human review. |
| `--dry-run` | No | Preview the actions without mutating memories. |

See [Dreaming](/memory/concepts/dreaming/) for the full lifecycle and safety model.

## `lookup-cross-workspace`

Look up a single memory in another workspace of the same org. Behavior depends on the authorization mode: in `easy` mode any cross-workspace lookup is allowed; in `enterprise` mode the target workspace must appear in `MEMORY_CROSS_WORKSPACE_IDS`.

```bash
od3sa-memory lookup-cross-workspace \
  --org-id your-org \
  --workspace-id other-project \
  --record-id <uuid> \
  --include-metadata
```

| Flag | Required | Description |
|------|----------|-------------|
| `--org-id` | Yes | Target organization scope. |
| `--workspace-id` | Yes | Target workspace scope. |
| `--record-id` | Yes | Target memory row ID. |
| `--source-record-id` | No | Referring memory ID for provenance tagging. |
| `--include-metadata` | No | Include the target's metadata in the response. |
| `--authorization-mode` | No | Override the cross-workspace authorization mode: `easy` or `enterprise`. |

`search`, `recall`, and `search-semantic` also accept `--authorization-mode`, and `--cross-workspace-ids` for comma-separated multi-workspace search.

## `sync`

One-shot bidirectional sync with a local peer database.

```bash
od3sa-memory --db local.db sync --peer-db peer.db --confirm
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
od3sa-memory --db local.db sync loop start \
  --relay-url https://relay.example.com \
  --account-id your-account \
  --root-key-passphrase-file ~/.memory/root-key-passphrase.txt \
  --confirm

# Single round
od3sa-memory --db local.db sync loop once \
  --relay-url https://relay.example.com \
  --account-id your-account \
  --root-key-passphrase-file ~/.memory/root-key-passphrase.txt

# Status / stop
od3sa-memory --db local.db sync loop status
od3sa-memory --db local.db sync loop stop
```

| Flag | Required | Description |
|------|----------|-------------|
| `action` | Yes | `start`, `once`, `stop`, or `status`. |
| `--relay-url` | For `start`/`once` | Relay base URL. |
| `--account-id` | For `start`/`once` | Fleet account ID. |
| `--root-key-passphrase-file` | For `start`/`once` | File containing the passphrase (must have `0600`/`0400` permissions). Preferred over `--root-key-passphrase`. |
| `--root-key-passphrase` | For `start`/`once` | Passphrase; prompted if omitted. Prefer `--root-key-passphrase-file`. |
| `--sync-interval` | No | Loop interval (default `30s`). |
| `--batch-size` | No | Maximum deltas per batch (default 1000). |
| `--confirm` | For `start` | Confirm starting the background goroutine. |

### `sync list-pending-key-changes`

List staged pending Ed25519/X25519 key changes from peers.

```bash
od3sa-memory --db local.db sync list-pending-key-changes
```

### `sync approve-key-change`

Apply a staged pending key change after previewing fingerprints and public-key hex.

```bash
od3sa-memory --db local.db \
  sync approve-key-change --peer-id <device-id> --confirm
```

### `sync reject-key-change`

Discard a staged pending key change.

```bash
od3sa-memory --db local.db \
  sync reject-key-change --peer-id <device-id> --confirm
```

### `sync set-peer-name`

Set (or clear) a local-only display-name override for a peer. The signed name
from pairing is preserved.

```bash
od3sa-memory --db local.db \
  sync set-peer-name --peer-id <device-id> --local-name "Work Laptop"
```

## `pair-device`

Pair the local database with a peer database in the same process using SPAKE2.

```bash
od3sa-memory --db local.db pair-device \
  --peer-db peer.db \
  --account-id your-account \
  --password-file ~/.memory/pairing-password.txt \
  --confirm
```

| Flag | Required | Description |
|------|----------|-------------|
| `--peer-db` | Yes | Path to the peer SQLite database. |
| `--account-id` | Yes | Fleet account ID. |
| `--password-file` | Yes* | Path to a file containing the pairing password (must have `0600`/`0400` permissions). Preferred over `--password`. |
| `--password` | Yes* | Pairing password; prompted if omitted. Avoid — secrets on argv are visible to `ps`. |
| `--device-name` | No | Human-readable name saved in the identity sidecar. |
| `--confirm` | Yes* | Confirm pairing. |
| `--dry-run` | No | Preview without writing peer records. |

\* `pair-device` aborts unless `--confirm` or `--dry-run` is passed. The password is prompted if omitted. Use `--password-file` instead of `--password` to keep secrets off the command line.

## `pair`

Relay-mediated PAKE pairing for devices on different hosts.

### `pair create-invitation`

```bash
od3sa-memory --db local.db pair create-invitation \
  --relay-url https://relay.example.com \
  --account-id your-account \
  --password-file ~/.memory/pairing-password.txt \
  --device-name "Studio Desktop" \
  --root-key-passphrase-file ~/.memory/root-key-passphrase.txt \
  --confirm
```

Response includes an invitation code to share with the joining device, plus a
short rendezvous code used to look up the PAKE enrolment on the relay.

:::warning[Share on separate channels]
The invitation code and pairing password must be shared through **different trusted channels**. Never send both on the same channel — if that channel is compromised, an attacker can complete the pairing.
:::

The pairing password must be at least 10 characters long with at least 40 bits estimated entropy.

| Flag | Required | Description |
|------|----------|-------------|
| `--relay-url` | Yes | Relay base URL. |
| `--account-id` | Yes | Fleet account ID. |
| `--password-file` | Yes* | Path to a file containing the pairing password (must have `0600`/`0400` permissions). Preferred over `--password`. |
| `--password` | Yes* | Pairing password; prompted if omitted. Avoid — secrets on argv are visible to `ps`. |
| `--device-name` | No | Human-readable name saved in the identity sidecar. |
| `--root-key-passphrase` | Yes* | Root-key sidecar passphrase; prompted if omitted. |
| `--confirm` | Yes* | Confirm creating the enrolment. |
| `--dry-run` | No | Preview without publishing an enrolment. |

### `pair accept-invitation`

```bash
od3sa-memory --db local.db pair accept-invitation \
  --code-file ~/.memory/invitation-code.txt \
  --password-file ~/.memory/pairing-password.txt \
  --root-key-passphrase-file ~/.memory/root-key-passphrase.txt \
  --confirm
```

Or auto-start the foreground sync loop after pairing completes:

```bash
od3sa-memory --db local.db pair accept-invitation \
  --code-file ~/.memory/invitation-code.txt \
  --password-file ~/.memory/pairing-password.txt \
  --start-sync-loop \
  --root-key-passphrase-file ~/.memory/root-key-passphrase.txt \
  --confirm
```

The joining device receives the account root key, records the initiator as a
peer, and registers itself with the relay automatically. With `--start-sync-loop`
it also starts the foreground relay sync loop in the same process.

| Argument | Required | Description |
|----------|----------|-------------|
| `code` (positional) | Yes* | Compact invitation code from the initiator. Prefer `--code-file`. |
| `--code-file` | Yes* | Path to a file containing the invitation code (must have `0600`/`0400` permissions). Preferred over `--code`. |
| `--code` | Yes* | Alternative way to pass the invitation code. Avoid — secrets on argv are visible to `ps`. |
| `--password-file` | Yes* | Path to a file containing the pairing password (must have `0600`/`0400` permissions). Preferred over `--password`. |
| `--password` | Yes* | Pairing password; prompted if omitted. Avoid — secrets on argv are visible to `ps`. |
| `--device-name` | No | Human-readable name saved in the identity sidecar. |
| `--start-sync-loop` | No | Start the foreground sync loop after pairing completes. |
| `--root-key-passphrase-file` | Yes* | File containing the passphrase (must have `0600`/`0400` permissions). Preferred over `--root-key-passphrase`. |
| `--root-key-passphrase` | Yes* | Passphrase; prompted if omitted. Prefer `--root-key-passphrase-file`. |
| `--confirm` | Yes* | Confirm accepting the invitation. |
| `--dry-run` | No | Preview without mutating the store. |

## `od3sa-relay`

The dedicated `od3sa-relay` binary is a lightweight relay-only build from the 0d3sa monorepo. It is useful on VPS or always-on hosts where you only need the relay and do not want the full `od3sa-memory` CLI or MCP server.

```bash
od3sa-relay \
  --db /var/lib/relay/relay.db \
  --addr 127.0.0.1:8787
```

The relay binds to loopback by default; add `--allow-remote-bind` with a non-loopback `--addr` to accept off-host connections.

For **non-loopback without TLS** (trusted LAN / private mesh only), also add `--insecure-bind`:

```bash
od3sa-relay \
  --db /var/lib/relay/relay.db \
  --addr 192.168.1.10:8787 \
  --allow-remote-bind \
  --insecure-bind
```

For **public internet** or untrusted networks, use TLS:

```bash
od3sa-relay \
  --db /var/lib/relay/relay.db \
  --addr 0.0.0.0:443 \
  --allow-remote-bind \
  --tls-cert /path/to/cert.pem \
  --tls-key /path/to/key.pem
```

| Flag | Env var | Description |
|------|---------|-------------|
| `--db` | `MEMORY_RELAY_DB` | Relay SQLite database path (required). |
| `--addr` | `MEMORY_RELAY_ADDR` | Listen address (default `127.0.0.1:8787`). |
| `--allow-remote-bind` | `MEMORY_RELAY_ALLOW_REMOTE_BIND` | Allow binding to a non-loopback address. Required for any non-loopback `--addr`. |
| `--insecure-bind` | `MEMORY_RELAY_INSECURE_BIND` | Allow serving plain HTTP to off-host clients. Required for non-loopback without TLS. **Never use on public internet.** |
| `--tls-cert` | `MEMORY_TLS_CERT` | TLS certificate path. Must be supplied with `--tls-key`. |
| `--tls-key` | `MEMORY_TLS_KEY` | TLS private-key path. Must be supplied with `--tls-cert`. |
| `--log-format` | `MEMORY_LOG_FORMAT` | `text` or `json`. |
| `--log-level` | `MEMORY_LOG_LEVEL` | `DEBUG`, `INFO`, `WARN`, `ERROR`. |

:::danger[Never use `--insecure-bind` on the public internet]
`--insecure-bind` is for trusted LANs and private meshes only. On public networks, always use `--tls-cert`/`--tls-key` or put the relay behind a reverse proxy that terminates TLS.
:::

See the [relay reference](/relay/reference/) for endpoints and deployment guidance.

Devices register with a relay through `pair create-invitation` / `pair accept-invitation`, or through the `memory_relay_register` MCP tool.

## Disabling sync

Pass `--sync-disabled` (or set `MEMORY_SYNC_DISABLED=1`) to skip the v3 sync schema migration and run the database in local-only mode. See [Environment variables](/memory/reference/environment-variables/) for the full table and precedence rules.

## See also

- [Tools reference](/memory/reference/tools/)
- [Environment variables](/memory/reference/environment-variables/)
- [Fallback slash commands](/memory/reference/fallback-slash-commands/)
- [Troubleshooting](/memory/reference/troubleshooting/)
- [Run a local HTTP MCP server](/memory/tutorials/streamable-http-local/)
- [Knowledge packets](/memory/concepts/knowledge-packets/)
- [Build a knowledge packet](/memory/how-to/build-knowledge-packet/)
- [How sync works](/memory/concepts/how-sync-works/)
- [Run your own relay server](/relay/how-to/run-relay-server/)
- [relay reference](/relay/reference/)
- [Approve a peer key rotation](/memory/how-to/approve-peer-key-change/)

