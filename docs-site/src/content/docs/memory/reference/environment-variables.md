---
title: Environment variables
description: Complete reference for memory environment variables, defaults, and precedence.
content_type: reference
---

# Environment variables

memory reads several environment variables for defaults that are otherwise set by CLI flags or MCP tool arguments. This page lists every variable, its default, and how it interacts with flags.

## Precedence

1. CLI flag or explicit tool argument (highest).
2. Environment variable.
3. Built-in default (lowest).

For example, passing `--db local.db` on the command line overrides `MEMORY_DB_PATH`.

## Global variables

| Variable | Maps to | Default | Description |
|----------|---------|---------|-------------|
| `MEMORY_DB_PATH` | `--db` | `~/.memory/default.db` | SQLite database path. |
| `MEMORY_LOG_LEVEL` | `--log-level` | `INFO` | Log verbosity: `DEBUG`, `INFO`, `WARN`, `ERROR`. |
| `MEMORY_LOG_FORMAT` | `--log-format` | `text` | `text` or `json`. |
| `MEMORY_SYNC_DISABLED` | `--sync-disabled` | `0` / unset | Skip the v3 sync schema and run local-only. |

## Sync and pairing variables

| Variable | Maps to | Default | Description |
|----------|---------|---------|-------------|
| `MEMORY_SYNC_INTERVAL` | `--sync-interval` | `30s` | Background relay sync loop interval. |
| `MEMORY_RELAY_URL` | `--relay-url` | none | Default relay URL for sync and pairing. |
| `MEMORY_ACCOUNT_ID` | `--account-id` | none | Default fleet account ID for sync and pairing. |
| `MEMORY_ROOT_KEY_PASSPHRASE` | `--root-key-passphrase` | prompted | Passphrase for the encrypted root-key sidecar. |

## Scope defaults for MCP tools

| Variable | Used by | Default | Description |
|----------|---------|---------|-------------|
| `MEMORY_ORG_ID` | MCP tools | none | Default `org_id` when a tool omits it. |
| `MEMORY_WORKSPACE_ID` | MCP tools | none | Default `workspace_id` when a tool omits it. |

If a tool call does not pass `org_id` or `workspace_id`, the MCP server falls back to these environment variables. This is useful for project-scoped Claude Code processes that always tag memories with the current workspace.

The public installer creates or updates `~/.memory/.env` with `MEMORY_ORG_ID` when you enter one at the prompt (or when `MEMORY_ORG_ID` is already set in the environment). `memory setup` writes the per-project values into a project-local env file and the MCP server configuration in `~/.claude.json`.

## Agent identity

`memory setup` resolves the identity it writes using this precedence:

1. Existing environment values (`MEMORY_AGENT_ID`, `MEMORY_USER_ID`) are respected and never overwritten.
2. Interactive prompts, shown when the values are unset.
3. Defaults: agent `claude-code-cli`, user `$USER`.

| Variable | Used by | Default | Description |
|----------|---------|---------|-------------|
| `MEMORY_AGENT_ID` | `setup`, memory tools | `claude-code-cli` | Agent identity written to the project `.env` file. |
| `MEMORY_USER_ID` | `setup`, memory tools | `$USER` | User identity written to the project `.env` file. |

## Authorization and cross-workspace access

memory supports two authorization modes for cross-workspace access:

| Variable | Used by | Default | Description |
|----------|---------|---------|-------------|
| `MEMORY_AUTHORIZATION_MODE` | `setup`, MCP tools, CLI | `easy` | `easy` allows cross-workspace lookups; `enterprise` is default-deny and requires an allowlist. |
| `MEMORY_CROSS_WORKSPACE_IDS` | `enterprise` mode | none | Comma-separated allowlist of workspace IDs that may be accessed cross-workspace (hard cap 50). |

`setup` asks whether the project is personal or team/org and derives the mode from the answer (`personal` → `easy`, `team` → `enterprise`). In `enterprise` mode, cross-workspace lookups (`lookup-cross-workspace`, `memory_lookup_cross`) only succeed for workspaces in the allowlist.

## Preflight checks for `setup`

`memory setup` runs two preflight checks before modifying `~/.claude.json`, `~/.claude/settings.json`, or `~/.claude/commands/`:

1. **Health check** — executes `memory --db <path> health` against the target database and aborts if the reported status is not `ok`.
2. **MCP protocol version check** — verifies the compiled-in MCP server advertises the protocol version Claude Code expects (`2024-11-05`). If the binary advertises an incompatible version, setup aborts without writing config.

If either check fails, no config files are mutated. Fix the underlying issue (update `memory`, create the database directory, or repair the binary path) and re-run `memory setup`.

## Update variables

| Variable | Used by | Default | Description |
|----------|---------|---------|-------------|
| `MEMORY_UPDATE_PREFIX` | `update` | `https://0d3sa.com/memory/` | Base URL that hosts the `VERSION` file and platform binaries for `memory update`. |
| `MEMORY_BIN` | `update`, `setup` | running binary | Path to the binary to update; also written by `setup`. |

## Recall and search tuning

| Variable | Default | Description |
|----------|---------|-------------|
| `MEMORY_FEEDBACK_RERANK` | disabled | Opt-in feedback-aware re-ranking of recall and search results. Set to `1`/`true` for defaults, or tune it, e.g. `MEMORY_FEEDBACK_RERANK=boost=0.05,window=3`. |
| `MEMORY_DREAM_FEEDBACK_SUPPRESS_THRESHOLD` | disabled | Positive integer net-feedback threshold at or below which memories are suppressed from dreaming candidates. |
| `MEMORY_FTS5_BM25` | unset | Set to `1` to score keyword search with FTS5 BM25 instead of term frequency. |
| `MEMORY_HNSW_SEED` | built-in | Deterministic seed for the HNSW vector index. |

## Relay variables (relay)

The dedicated `relay` binary reads these variables:

| Variable | Maps to | Default | Description |
|----------|---------|---------|-------------|
| `MEMORY_RELAY_DB` | `--db` | none | Relay SQLite database path. Required to start the relay. |
| `MEMORY_RELAY_ADDR` | `--addr` | `127.0.0.1:8787` | Listen address for the relay HTTP server. |
| `MEMORY_RELAY_ALLOW_REMOTE_BIND` | `--allow-remote-bind` | `0` / unset | Set to `1`/`true` to allow binding to a non-loopback address. |
| `MEMORY_TLS_CERT` | `--tls-cert` | none | TLS certificate path. Must be supplied with `MEMORY_TLS_KEY`. |
| `MEMORY_TLS_KEY` | `--tls-key` | none | TLS private-key path. Must be supplied with `MEMORY_TLS_CERT`. |

`MEMORY_LOG_LEVEL` and `MEMORY_LOG_FORMAT` also apply to the relay output. See the [relay reference](/relay/reference/) for the full flag and endpoint list.

## Setting variables for Claude Code MCP

When you configure memory as an MCP server in `~/.claude.json`, put the variables under `env`:

```json
{
  "memory": {
    "command": "/home/yourname/.local/bin/memory",
    "args": ["--db", "/home/yourname/.memory/default.db"],
    "env": {
      "MEMORY_LOG_LEVEL": "INFO",
      "MEMORY_ORG_ID": "your-org",
      "MEMORY_WORKSPACE_ID": "your-workspace"
    }
  }
}
```

Use absolute paths and restart Claude Code after editing the config.

## See also

- [CLI reference](/memory/reference/cli/)
- [How sync works](/memory/concepts/how-sync-works/)
- [Scopes and identity](/memory/concepts/scopes-identity/)
- [Connect Claude Code](/memory/tutorials/connect-claude-code/)
