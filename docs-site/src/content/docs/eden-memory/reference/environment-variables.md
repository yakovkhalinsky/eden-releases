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

The public installer creates or updates `~/.eden-memory/.env` with `EDEN_ORG_ID` when you enter one at the prompt (or when `EDEN_ORG_ID` is already set in the environment). `eden-memory setup claude` writes `EDEN_WORKSPACE_ID` into the per-project MCP server configuration in `~/.claude.json`.

## Relay variables (eden-relay and `eden-memory relay-server`)

The dedicated `eden-relay` binary and the `eden-memory relay-server` subcommand read these variables:

| Variable | Maps to | Default | Description |
|----------|---------|---------|-------------|
| `EDEN_RELAY_DB` | `--db` (`eden-relay`) / `--relay-db` (`eden-memory relay-server`) | none | Relay SQLite database path. Required to start the relay. |
| `EDEN_RELAY_ADDR` | `--addr` | `:8787` | Listen address for the relay HTTP server. |
| `EDEN_RELAY_REQUIRE_PER_DEVICE_AUTH` | `--require-per-device-auth` | `0` / unset | When set to `1`, reject legacy account-derived auth tokens and require per-device auth secrets. |
| `EDEN_TLS_CERT` | `--tls-cert` | none | TLS certificate path. Must be supplied with `EDEN_TLS_KEY`. |
| `EDEN_TLS_KEY` | `--tls-key` | none | TLS private-key path. Must be supplied with `EDEN_TLS_CERT`. |

`EDEN_LOG_LEVEL` and `EDEN_LOG_FORMAT` also apply to the relay output.

## Variables used by the eden-team ATP supervisor

The headless ATP supervisor reads these additional variables when running eden-memory under the hood:

| Variable | Purpose | Default |
|----------|---------|---------|
| `EDEN_MEMORY_DB` | Path to the eden-memory SQLite database. | `~/.eden-memory/default.db` |
| `EDEN_AGENT_ID` | Agent identity for records. | `eden-team` |
| `EDEN_USER_ID` | User identity for records. | `$USER` |
| `EDEN_ORG_ID` | Organization scope for records. | none |
| `EDEN_WORKSPACE_ID` | Workspace scope for records. | none |
| `EDEN_MEMORY_BIN` | Path to the `eden-memory` binary. | `~/.local/bin/eden-memory` |
| `CLAUDE_CODE_BIN` | Path to the Claude Code CLI. | `claude` |
| `ATP_MCP_CONFIG` | Path to MCP config JSON for role processes. | none |
| `ATP_ROLES_DIR` | Directory containing role prompt templates. | next to the ATP binary |
| `ATP_PERMISSION_MODE` | Permission mode passed to role processes. | none |

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
