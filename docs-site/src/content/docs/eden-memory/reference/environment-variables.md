---
title: Environment variables
description: Complete reference for eden-memory environment variables, defaults, and precedence.
content_type: reference
---

# Environment variables

eden-memory reads several environment variables for defaults that are otherwise set by CLI flags or MCP tool arguments. This page lists every variable, its default, and how it interacts with flags.

## Precedence

1. CLI flag or explicit tool argument (highest).
2. Environment variable.
3. Built-in default (lowest).

For example, passing `--db local.db` on the command line overrides `EDEN_DB_PATH`.

## Global variables

| Variable | Maps to | Default | Description |
|----------|---------|---------|-------------|
| `EDEN_DB_PATH` | `--db` | `~/.eden-memory/default.db` | SQLite database path. |
| `EDEN_LOG_LEVEL` | `--log-level` | `INFO` | Log verbosity: `DEBUG`, `INFO`, `WARN`, `ERROR`. |
| `EDEN_LOG_FORMAT` | `--log-format` | `text` | `text` or `json`. |
| `EDEN_SYNC_DISABLED` | `--sync-disabled` | `0` / unset | Skip the v3 sync schema and run local-only. |

## Sync and pairing variables

| Variable | Maps to | Default | Description |
|----------|---------|---------|-------------|
| `EDEN_SYNC_INTERVAL` | `--sync-interval` | `30s` | Background relay sync loop interval. |
| `EDEN_RELAY_URL` | `--relay-url` | none | Default relay URL for sync and pairing. |
| `EDEN_ACCOUNT_ID` | `--account-id` | none | Default fleet account ID for sync and pairing. |
| `EDEN_ROOT_KEY_PASSPHRASE` | `--root-key-passphrase` | prompted | Passphrase for the encrypted root-key sidecar. |

## Scope defaults for MCP tools

| Variable | Used by | Default | Description |
|----------|---------|---------|-------------|
| `EDEN_ORG_ID` | MCP tools | none | Default `org_id` when a tool omits it. |
| `EDEN_WORKSPACE_ID` | MCP tools | none | Default `workspace_id` when a tool omits it. |

If a tool call does not pass `org_id` or `workspace_id`, the MCP server falls back to these environment variables. This is useful for project-scoped Claude Code processes that always tag memories with the current workspace.

The public installer creates or updates `~/.eden-memory/.env` with `EDEN_ORG_ID` when you enter one at the prompt (or when `EDEN_ORG_ID` is already set in the environment). `eden-memory setup` writes the per-project values into a project-local env file and the MCP server configuration in `~/.claude.json`.

## Agent identity

`eden-memory setup` resolves the identity it writes using this precedence:

1. Existing environment values (`EDEN_AGENT_ID`, `EDEN_USER_ID`) are respected and never overwritten.
2. Interactive prompts, shown when the values are unset.
3. Defaults: agent `claude-code-cli`, user `$USER`.

| Variable | Used by | Default | Description |
|----------|---------|---------|-------------|
| `EDEN_AGENT_ID` | `setup`, memory tools | `claude-code-cli` | Agent identity written to the project `.env` file. |
| `EDEN_USER_ID` | `setup`, memory tools | `$USER` | User identity written to the project `.env` file. |

## Authorization and cross-workspace access

eden-memory supports two authorization modes for cross-workspace access:

| Variable | Used by | Default | Description |
|----------|---------|---------|-------------|
| `EDEN_AUTHORIZATION_MODE` | `setup`, MCP tools, CLI | `easy` | `easy` allows cross-workspace lookups; `enterprise` is default-deny and requires an allowlist. |
| `EDEN_CROSS_WORKSPACE_IDS` | `enterprise` mode | none | Comma-separated allowlist of workspace IDs that may be accessed cross-workspace (hard cap 50). |

`setup` asks whether the project is personal or team/org and derives the mode from the answer (`personal` → `easy`, `team` → `enterprise`). In `enterprise` mode, cross-workspace lookups (`lookup-cross-workspace`, `eden_lookup_cross`) only succeed for workspaces in the allowlist.

## Preflight checks for `setup`

`eden-memory setup` runs two preflight checks before modifying `~/.claude.json`, `~/.claude/settings.json`, or `~/.claude/commands/`:

1. **Health check** — executes `eden-memory --db <path> health` against the target database and aborts if the reported status is not `ok`.
2. **MCP protocol version check** — verifies the compiled-in MCP server advertises the protocol version Claude Code expects (`2024-11-05`). If the binary advertises an incompatible version, setup aborts without writing config.

If either check fails, no config files are mutated. Fix the underlying issue (update `eden-memory`, create the database directory, or repair the binary path) and re-run `eden-memory setup`.

## Update variables

| Variable | Used by | Default | Description |
|----------|---------|---------|-------------|
| `EDEN_UPDATE_PREFIX` | `update` | `https://0d3sa.com/eden-memory/` | Base URL that hosts the `VERSION` file and platform binaries for `eden-memory update`. |
| `EDEN_MEMORY_BIN` | `update`, `setup` | running binary | Path to the binary to update; also written by `setup`. |

## Recall and search tuning

| Variable | Default | Description |
|----------|---------|-------------|
| `EDEN_FEEDBACK_RERANK` | disabled | Opt-in feedback-aware re-ranking of recall and search results. Set to `1`/`true` for defaults, or tune it, e.g. `EDEN_FEEDBACK_RERANK=boost=0.05,window=3`. |
| `EDEN_DREAM_FEEDBACK_SUPPRESS_THRESHOLD` | disabled | Positive integer net-feedback threshold at or below which memories are suppressed from dreaming candidates. |
| `EDEN_FTS5_BM25` | unset | Set to `1` to score keyword search with FTS5 BM25 instead of term frequency. |
| `EDEN_HNSW_SEED` | built-in | Deterministic seed for the HNSW vector index. |

## Relay variables (eden-relay)

The dedicated `eden-relay` binary reads these variables:

| Variable | Maps to | Default | Description |
|----------|---------|---------|-------------|
| `EDEN_RELAY_DB` | `--db` | none | Relay SQLite database path. Required to start the relay. |
| `EDEN_RELAY_ADDR` | `--addr` | `127.0.0.1:8787` | Listen address for the relay HTTP server. |
| `EDEN_RELAY_ALLOW_REMOTE_BIND` | `--allow-remote-bind` | `0` / unset | Set to `1`/`true` to allow binding to a non-loopback address. |
| `EDEN_TLS_CERT` | `--tls-cert` | none | TLS certificate path. Must be supplied with `EDEN_TLS_KEY`. |
| `EDEN_TLS_KEY` | `--tls-key` | none | TLS private-key path. Must be supplied with `EDEN_TLS_CERT`. |

`EDEN_LOG_LEVEL` and `EDEN_LOG_FORMAT` also apply to the relay output. See the [eden-relay reference](/eden-relay/reference/) for the full flag and endpoint list.

## Setting variables for Claude Code MCP

When you configure eden-memory as an MCP server in `~/.claude.json`, put the variables under `env`:

```json
{
  "eden-memory": {
    "command": "/home/yourname/.local/bin/eden-memory",
    "args": ["--db", "/home/yourname/.eden-memory/default.db"],
    "env": {
      "EDEN_LOG_LEVEL": "INFO",
      "EDEN_ORG_ID": "your-org",
      "EDEN_WORKSPACE_ID": "your-workspace"
    }
  }
}
```

Use absolute paths and restart Claude Code after editing the config.

## See also

- [CLI reference](/eden-memory/reference/cli/)
- [How sync works](/eden-memory/concepts/how-sync-works/)
- [Scopes and identity](/eden-memory/concepts/scopes-identity/)
- [Connect Claude Code](/eden-memory/tutorials/connect-claude-code/)
