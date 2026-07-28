---
name: eden-memory-mcp-usage
description: |
  Wire the eden-memory Go binary's MCP server into Claude Desktop, Cursor,
  pi.dev, Hermes, or any stdio MCP client, and configure the agent to prefer
  memory by default while keeping the store local-first, minimal, and private.
version: 2.0.0
author: Eden Fleet
license: MIT
metadata:
  hermes:
    tags: [mcp, eden-memory, memory-first, stdio, claude, cursor, hermes, integration]
    related_skills: [hermes-agent, native-mcp]
    registry:
      discoverable: true
      category: software-development
      install_hint: download the eden-memory release binary for your platform
---

# Using the eden-memory MCP server

## Overview

The `eden-memory` release is a single Go binary that embeds its own Python
runtime and embedding model. It exposes the Model Context Protocol (MCP) over
stdio. Any MCP client that can spawn a subprocess can use it: **Claude Desktop**,
**Cursor**, **pi.dev**, **Hermes Agent**, or a custom client.

This skill covers how to configure each harness, the stdio tool surface, a
memory-first usage loop, and the few environment variables that matter.

## When to Use

- You are wiring `eden-memory` into a new harness.
- You need the exact JSON shape for `eden_remember`, `eden_recall`, etc.
- You want the agent to recall before deciding and remember durable facts at the
  end of a task.
- The MCP server is not responding or a tool call returns an error.
- You want to set the DB path, log level, or swap the embedding model.

## Install the server

Download a release binary from `yakovkhalinsky/eden-releases` and place it on
`$PATH`:

```bash
cd /usr/local/bin   # or ~/.local/bin, $HOME/bin, etc.
gh release download latest --repo yakovkhalinsky/eden-releases \
  --pattern 'eden-memory-linux-arm64' --clobber
chmod +x eden-memory-linux-arm64
ln -sf eden-memory-linux-arm64 eden-memory
eden-memory version
```

Supported platform suffixes: `linux-amd64`, `linux-arm64`, `darwin-amd64`,
`darwin-arm64`.

The binary is self-contained. On first run it extracts the bundled Python
runtime and model weights to the platform cache directory:

- Linux: `~/.cache/eden-memory`
- macOS: `~/Library/Caches/eden-memory`

## CLI basics

```bash
# Default: start the MCP stdio server (requires --db)
eden-memory --db ~/.eden-memory/default.db

# Subcommands
eden-memory version
eden-memory health --db ~/.eden-memory/default.db
eden-memory forget-expired --db ~/.eden-memory/default.db

# Flags
eden-memory --db PATH --log-format json --log-level DEBUG
```

The Go binary does **not** have an `--mcp` flag. The default command is the MCP
server. To use another subcommand, pass it as the first positional argument.

## Identity and workspace defaults

Identity dimensions are resolved at the tool boundary:

| Dimension | Precedence (highest first) | Default |
|-----------|----------------------------|---------|
| `user_id` | tool arg | required (no default) |
| `agent_id` | tool arg | required (no default) |
| `workspace_id` | tool arg | none |
| `org_id` | tool arg | none |

Always pass `agent_id` and `user_id`. Omit them only when a skill explicitly
asks for a fleet-wide constant. Use `workspace_id` to scope memories to a
project or repo; leave `org_id` unset unless you are in a fleet/SaaS context.

The Go binary does **not** auto-resolve the OS username as a default `user_id`
nor does it derive a workspace from git. If you want those behaviors, set them
explicitly in the harness configuration or system prompt.

## Per-harness configuration

The server command is always the same: spawn `eden-memory --db <PATH>` as a
stdio subprocess. The only required argument is `--db` (or the `EDEN_DB_PATH`
environment variable). All harnesses use the same tool names: `eden_remember`,
`eden_recall`, `eden_forget`, `eden_search`, `eden_search_semantic`,
`eden_edit`, `eden_forget_expired`, `eden_health`, and `eden_vacuum`.

### Claude Desktop

File:

- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- Linux: `~/.config/Claude/claude_desktop_config.json`

Example:

```json
{
  "mcpServers": {
    "eden-memory": {
      "command": "/usr/local/bin/eden-memory",
      "args": ["--db", "~/.eden-memory/default.db"],
      "env": {
        "EDEN_LOG_LEVEL": "INFO"
      }
    }
  }
}
```

Restart Claude Desktop. The hammer menu → "MCP tools" should list the
eden-memory tools.

**Memory-first note:** Connection is only the first step. Add the system-prompt
nudge below to Claude's project instructions so it treats `eden-memory` as the
default lookup before asking the user something they may have already said.

### Cursor

File:

- macOS: `~/.cursor/mcp.json`
- Windows: `%USERPROFILE%\.cursor\mcp.json`
- Linux: `~/.cursor/mcp.json`

Example:

```json
{
  "mcpServers": {
    "eden-memory": {
      "command": "/usr/local/bin/eden-memory",
      "args": ["--db", "~/.eden-memory/default.db"]
    }
  }
}
```

Open Cursor Settings → MCP → refresh. The eden-memory tools should appear under
MCP servers.

**Memory-first note:** Add the system-prompt nudge below to Cursor's rules or
project instructions.

### pi.dev

Add `.mcp.json` at the project root:

```json
{
  "mcpServers": {
    "eden-memory": {
      "command": "/usr/local/bin/eden-memory",
      "args": ["--db", "${PROJECT_ROOT}/.eden-memory/project.db"]
    }
  }
}
```

If pi.dev does not substitute `${PROJECT_ROOT}`, use an absolute path. Reload the
agent workspace.

**Memory-first note:** Add the system-prompt nudge below to the project prompt.

### Hermes Agent

Hermes exposes eden-memory through native `mcp__eden__eden_*` tools when the
server is configured in `config.yaml`. If your Hermes instance has those tools,
follow the same memory-first loop below. Otherwise, register `eden-memory` as a
stdio MCP server under the `mcp` section of `config.yaml`.

A minimal stdio server entry:

```yaml
mcp:
  servers:
    eden-memory:
      command: /usr/local/bin/eden-memory
      args:
        - --db
        - ~/.eden-memory/default.db
      env:
        EDEN_LOG_LEVEL: INFO
```

**Memory-first note:** Native tools are convenient, but behavior still depends on
the prompt. Include the system-prompt nudge in skills that use `eden-memory`
so the agent checks memory before asking and stores only durable takeaways at
task end.

### Any other stdio MCP client

The generic shape is:

```json
{
  "mcpServers": {
    "eden-memory": {
      "command": "/usr/local/bin/eden-memory",
      "args": ["--db", "~/.eden-memory/default.db"],
      "env": {}
    }
  }
}
```

No HTTP URL is used. The client spawns `eden-memory` as a subprocess and speaks
JSON-RPC over stdin/stdout.

## Available Tools

| Tool | Purpose |
|------|---------|
| `eden_remember` | Store a durable fact. Keep `content` to one concise fact; prefer `ttl_ms: null` for permanent preferences. |
| `eden_recall` | Semantic recall for this user. Call once at task start and before finalizing user-facing decisions that could contradict past preferences or conventions. |
| `eden_search` | Keyword search over stored memory content. Use for exact terms. |
| `eden_search_semantic` | Semantic search with optional metadata filters. Use when the query is open-ended and prior memories might be relevant. |
| `eden_edit` | Update an existing memory when a fact has changed or been corrected. Prefer editing over duplicating. |
| `eden_forget` | Delete a memory by ID. Use when a memory is obsolete or actively misleading. |
| `eden_forget_expired` | Delete memories whose TTL has passed. Manual/admin only; do not call automatically. |
| `eden_health` | Return a combined health, sync, usage, and telemetry snapshot. No arguments. |
| `eden_vacuum` | Run a safe WAL checkpoint to compact the store. Manual/admin only. |

`eden_status`, `eden_metrics`, and `eden_usage` from the Python era no longer
exist. `eden_health` replaces them.

## First-use setup (run once per account / harness)

Before the first `eden_remember` in a new account, agent, or project, settle the
identity and storage settings. Without stable values, later sessions cannot recall
what was stored and search becomes noisy.

1. **Choose `user_id`.**
   - Derive from the harness account or the user's stated name. Ask the user to
     confirm rather than silently adopting a value.

2. **Choose `agent_id`.**
   - Use the harness short name (`claude`, `cursor`, `pi-dev`, `hermes`, `adam`,
     `eve`, etc.) unless the user wants a different label.

3. **Choose `workspace_id`.**
   - Use a stable project name or leave it unset for a personal default.
   - The Go binary does not auto-derive a git workspace. If you want a
     project-scoped workspace, set it explicitly.

4. **Choose `org_id` (fleet/SaaS only).**
   - For standalone users, leave `org_id` unset.
   - In a fleet context, use the shared org identifier.

5. **Confirm the database path.**
   - Use an absolute path. Do not rely on `~` expansion in JSON config unless
     the harness expands it; many clients pass the literal string to the
     binary, and `eden-memory` does expand `$HOME`, so `~/.eden-memory/default.db`
     usually works, but an absolute path is safer.

6. **Persist these choices as durable memories.**
   - Store at least:
     - *"My preferred eden-memory user_id is `<user_id>`."*
     - *"My eden-memory agent_id for this harness is `<agent_id>`."*
     - *"My eden-memory workspace_id is `<workspace_id>`."*
     - *"My eden-memory database path is `<db_path>`."*
   - Use `ttl_ms: null` so they survive across sessions.
   - Tag them with `metadata: {"source": "first-use-setup", "domain": "eden-memory-config"}`
     so they are easy to find and update.

7. **Use the settled values consistently.**
   - Every `eden_remember` / `eden_recall` / `eden_search` call in this account
     should use the same `user_id`, `agent_id`, and `workspace_id`.

### When to repeat first-use setup

- New machine or new harness where the database path differs.
- User explicitly asks to switch accounts or reset memory identity.
- Recalls repeatedly return empty despite the user expecting prior memories.

## Memory-first loop

Eden-memory should be the first place the agent looks before asking the user
something they may have already said. The loop is:

1. **At task start.** After the user states the current task, call
   `eden_recall` once for the user and topic. Do not recall before the first
   user message.
2. **Before finalizing a user-facing decision.** If the decision touches
   preferences, conventions, security, or tooling, recall once per sub-task.
3. **After a correction.** Recall related memories, then `eden_edit` the matching
   entry or `eden_remember` if none exists. Rate-limit to one memory update per
   correction event.
4. **At task end.** Store at most 3–5 concise, durable takeaways. If nothing
   should persist, store nothing.

Avoid recalling or remembering on every intermediate reasoning step.

## What to remember

Remembering too much is worse than remembering too little. Prefer concise,
forward-looking facts. Store only when the user says something they would expect
to be remembered next week.

| Category | Good example |
|----------|--------------|
| Preferences | *"Exposes services via Tailscale only; refuses LAN or 0.0.0.0 binding."* |
| Project conventions | *"Uses `uv` for Python tooling; `pipx` is a fallback only."* |
| Corrections | *"User corrected: do not introduce new agents before formal introduction."* |
| Working solutions | *"Restarting the Hermes gateway from inside itself requires a one-shot cron job."* |
| Identity | *"User's name is Yakov. In this account they call me Adam."* |

### Scope rules

- Use `agent_id` / `user_id` / `workspace_id` for facts that belong to one user
  + agent + workspace triple.
- Never omit `agent_id` and `user_id` unless the skill explicitly instructs you
  to store a fleet-wide constant.
- For Claude/Cursor/pi.dev, derive `user_id` from the authenticated account,
  not a hard-coded value.
- For project-scoped memories, prefer a stable `workspace_id` over
  `metadata.project`; the latter is legacy and does not enforce isolation at the
  store level.
- Keep each memory **one fact or one small rule**. Compound entries poison
  semantic search and make `eden_edit` awkward.

## What not to remember

| Category | Example | Where it belongs |
|----------|---------|------------------|
| Full tool outputs | JSON from `eden_health`, stack traces | Logs or the current conversation. |
| Ephemeral reasoning | "I should check file X first." | Inline chain-of-thought, not memory. |
| Drafts / scratch code | Partial snippets before final version | The repo or the chat history. |
| Already-versioned artifacts | Commit SHAs, PR numbers, branch names after merge | Git history, not memory. |
| Generic knowledge | How `pytest` works, MCP spec details | External docs, skills, or web search. |
| Speculative guesses | "Maybe the issue is…" | Do not store until validated. |
| Local topology | Hostnames, Tailscale IPs, device lists, internal network paths. | Record only the abstract policy (e.g., Tailscale-only). |
| Secrets | Passwords, API keys, tokens, private credentials. | Keyring or vault; never the memory store. |

## TTL guidance and local-first notes

### TTL guidance

- `ttl_ms: null` — explicitly immortal.
- Omitting `ttl_ms` — the Go binary does not apply a default store TTL;
  memories without a TTL are kept indefinitely. Set `ttl_ms` explicitly when
  you want a time-boxed memory.
- **Immortal (`ttl_ms: null`)** for things that should persist until the user
  changes them: preferences, project conventions, corrections, identity.
- **TTL 30–90 days** for seasonal context: current sprint goal, active hardware,
  short-term workarounds.
- **TTL 1–7 days** for ephemeral but useful context: trip dates, temporary file
  paths, one-time debugging flags.

A blanket short TTL silently deletes important facts. Set per-memory TTL
explicitly rather than forcing one on every entry.

### Local-first / air-gapped notes

- Do not call `eden_search_semantic` automatically on every session start. The
  first semantic call may load or download the embedding model. Prefer
  `eden_recall` unless semantic similarity is required.
- Do not call `eden_health` automatically. It is safe but unnecessary noise.
- Always set `--db` or `EDEN_DB_PATH` explicitly if continuity across agent
  sessions is required. The default path is per-user, but explicit is safer.
- Treat these as manual/admin tools; do not run them as part of the default loop:
  - `eden_forget_expired`
  - `eden_vacuum`
- Do not record secrets, API keys, tokens, or private credentials. Record only
  policy metadata (e.g., "uses Tailscale, not LAN").
- The Go binary embeds its own Python runtime, so `EDEN_EMBEDDER_MODEL` only
  matters if you want to override the bundled model with a local directory.
- If several harnesses share the same `--db`, writes serialize through SQLite
  WAL; heavy recall loops can starve each other.

## System-prompt nudge

If the harness supports a system or hidden-instructions prompt, include a block
like this:

> You have access to `eden-memory` tools. Your default loop is:
> 1. If `user_id`, `agent_id`, and the database path are not yet settled, run
>    the first-use setup: ask the user for their preferred `user_id`, choose an
>    `agent_id` for this harness, confirm `--db`, and store those choices with
>    `eden_remember` (`ttl_ms: null`).
> 2. After the user states a task, call `eden_recall` once for relevant history.
> 3. Before finalizing a user-facing decision, recall to check for preferences
>    and corrections.
> 4. After the user corrects you, recall related memories, then `eden_edit` or
>    `eden_remember`.
> 5. At task end, store at most 3–5 durable takeaways — one concise fact per
>    memory.
> 6. Do not store raw command output, generic knowledge, local topology, secrets,
>    or unverified guesses.

For Hermes, adapt the tool names to `mcp__eden__eden_remember`,
`mcp__eden__eden_recall`, etc.

## Call examples

### `eden_remember`

```json
{
  "name": "eden_remember",
  "arguments": {
    "agent_id": "eve",
    "user_id": "yakov",
    "workspace_id": "eden-releases",
    "content": "User prefers services exposed only via Tailscale, never LAN or 0.0.0.0.",
    "metadata": {"source": "direct-statement", "domain": "security"},
    "ttl_ms": null
  }
}
```

Response:

```json
{"id": "a1b2c3d4-...", "status": "remembered"}
```

Notes:

- `agent_id` and `user_id` are required.
- `workspace_id` and `org_id` are optional. Pass `workspace_id` to scope the
  memory to a project.
- `ttl_ms: null` means explicitly immortal. Omit it for an indefinite memory, or
  set an integer for a time-boxed one.
- `metadata` is optional; any JSON object is allowed.

### `eden_recall`

```json
{
  "name": "eden_recall",
  "arguments": {
    "agent_id": "eve",
    "user_id": "yakov",
    "workspace_id": "eden-releases",
    "query": "Tailscale exposure preference",
    "limit": 5
  }
}
```

Response:

```json
{
  "results": [
    {
      "id": "a1b2c3d4-...",
      "content": "User prefers services exposed only via Tailscale, never LAN or 0.0.0.0.",
      "metadata": {"source": "direct-statement", "domain": "security"},
      "score": 0.92
    }
  ]
}
```

### `eden_search`

```json
{
  "name": "eden_search",
  "arguments": {
    "agent_id": "eve",
    "user_id": "yakov",
    "query": "Tailscale",
    "limit": 5
  }
}
```

### `eden_search_semantic`

```json
{
  "name": "eden_search_semantic",
  "arguments": {
    "agent_id": "eve",
    "user_id": "yakov",
    "query": "How should services be exposed?",
    "filters": {"domain": "security"},
    "limit": 5
  }
}
```

The first semantic call may trigger a model download if no local model is
cached. In air-gapped or local-first environments, stage the model directory and
set `EDEN_EMBEDDER_MODEL` to that path.

### `eden_edit`

```json
{
  "name": "eden_edit",
  "arguments": {
    "id": "a1b2c3d4-...",
    "content": "Primary install method is download from eden-releases; platform suffix matters.",
    "metadata": {"source": "user-correction", "domain": "packaging"}
  }
}
```

Response:

```json
{"id": "a1b2c3d4-...", "status": "updated"}
```

### `eden_forget`

```json
{
  "name": "eden_forget",
  "arguments": {"id": "a1b2c3d4-..."}
}
```

Response:

```json
{"id": "a1b2c3d4-...", "status": "forgotten"}
```

### `eden_health`

```json
{
  "name": "eden_health",
  "arguments": {}
}
```

Response keys: `status`, `version`, `total`, `latency_ms`, `checked_at`,
`counters`, `sync`, `usage`.

### `eden_vacuum`

```json
{
  "name": "eden_vacuum",
  "arguments": {}
}
```

Run manually to compact the WAL. Do not call automatically.

## Environment Variables

| Variable | Effect |
|----------|--------|
| `EDEN_DB_PATH` | SQLite database file. Can be set instead of passing `--db`. |
| `EDEN_LOG_FORMAT` | `text` or `json`. Default `text`. |
| `EDEN_LOG_LEVEL` | `DEBUG`, `INFO`, `WARN`, `ERROR`. Default `INFO`. |
| `EDEN_METRICS_ADDR` | Optional HTTP address (e.g. `:8080`) for metrics on `/metrics`. |
| `EDEN_USE_HNSW` | Set to `1` or `true` to enable the approximate NSW vector index for large recall. |
| `EDEN_EMBEDDER_MODEL` | Path to an alternative model directory; overrides the bundled model. |
| `EDEN_EMBEDDER_WORKER` | Command to use as the embedder worker instead of the bundled Python runtime. |
| `EDEN_MAX_WORKERS` | Number of embedder workers (default: `1`). |
| `EDEN_BATCH_SIZE` | Max texts per worker batch (default: `16`). |
| `EDEN_BATCH_TIMEOUT_MS` | Batcher wait timeout in milliseconds (default: `50`). |

The Python-era variables `EDEN_EMBEDDER_REPO`, `EDEN_EMBEDDER_DIM`,
`EDEN_EMBEDDER_DOWNLOAD_TIMEOUT`, `EDEN_EMBEDDER_DOWNLOAD_RETRIES`,
`EDEN_MODEL2VEC_CACHE`, `EDEN_BETA_LOG_DIR`, `EDEN_BETA_LOG_REDACT`,
`EDEN_BETA_LOG_RETENTION_DAYS`, and `EDEN_BETA_LOG_LEVEL` no longer apply.

## Common Pitfalls

1. **The default command is the stdio MCP server.** Do not pass `--mcp`; the Go
   binary starts the MCP server by default. Use `eden-memory version`,
   `eden-memory health`, or `eden-memory forget-expired` for subcommands.

2. **No HTTP endpoint.** The client spawns `eden-memory` as a subprocess and
   speaks JSON-RPC over stdin/stdout. There is no `http://` URL to connect to.

3. **`--db` is effectively required.** Without it, the server exits at startup.
   Set it explicitly in every harness configuration.

4. **`agent_id` and `user_id` are required.** The Go binary does not supply
   defaults. Always pass them in tool arguments or settle them during first-use
   setup.

5. **First semantic call may download a model.** In air-gapped environments,
   stage the model directory and set `EDEN_EMBEDDER_MODEL`. The binary bundles a
   model, so the download is only needed on first run.

6. **DB path is per-harness if unset.** If two clients run separate
   `eden-memory` instances with different `--db` values, they see different
   stores. Use the same absolute path for shared state.

7. **SIGTERM handling requires client cooperation.** The MCP server flushes
   queued writes and checkpoints the WAL on SIGTERM/SIGINT. For a clean exit,
   the client should close the server's stdin before (or at the same time as)
   sending SIGTERM.

## Verification Checklist

- [ ] `eden-memory version` runs and prints a version.
- [ ] `eden-memory --db /path/to/db.db` starts the MCP server and waits on stdin.
- [ ] The target harness lists the eden-memory tools after refreshing MCP servers.
- [ ] `eden_remember` returns a UUID `id`.
- [ ] `eden_recall` returns the stored memory.
- [ ] After sending SIGTERM, the DB can be reopened and the WAL is clean
      (check with `eden-memory health --db /path/to/db.db`).

## References

- `references/go-tool-surface.md` — exact tool schemas and response shapes from
  the Go binary.
