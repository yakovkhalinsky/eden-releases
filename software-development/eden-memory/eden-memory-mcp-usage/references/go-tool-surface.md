# eden-memory Go binary tool surface

This reference documents the exact tool schemas and response shapes of the
eden-memory Go MCP server as of `internal/version/version.go`. It is derived
from `/home/yakov/eden-memory/internal/mcp/tools.go` and
`/home/yakov/eden-memory/internal/memory/service.go`.

## Commands

```bash
# Default MCP stdio server
eden-memory --db PATH [--log-format text|json] [--log-level DEBUG|INFO|WARN|ERROR]

# Subcommands
eden-memory version
eden-memory health --db PATH
eden-memory forget-expired --db PATH
```

## Tool schemas

### `eden_remember`

Store a durable memory.

**Input schema**

```json
{
  "type": "object",
  "properties": {
    "agent_id": {"type": "string"},
    "user_id": {"type": "string"},
    "content": {"type": "string"},
    "metadata": {"type": "object"},
    "ttl_ms": {"type": "integer"},
    "workspace_id": {"type": "string"},
    "org_id": {"type": "string"},
    "observer_id": {"type": "string"},
    "observed_id": {"type": "string"},
    "fact": {"type": "string"}
  },
  "required": ["agent_id", "user_id", "content"]
}
```

Legacy aliases: `observer_id` → `agent_id`, `observed_id` → `user_id`,
`fact` → `content`.

**Response**

```json
{"id": "<UUID>", "status": "remembered"}
```

### `eden_recall`

Semantic recall by cosine similarity.

**Input schema**

```json
{
  "type": "object",
  "properties": {
    "agent_id": {"type": "string"},
    "user_id": {"type": "string"},
    "query": {"type": "string"},
    "limit": {"type": "integer"},
    "top_k": {"type": "integer"},
    "workspace_id": {"type": "string"},
    "org_id": {"type": "string"},
    "observer_id": {"type": "string"},
    "observed_id": {"type": "string"},
    "topic": {"type": "string"}
  },
  "required": ["agent_id", "user_id", "query"]
}
```

Legacy aliases: `observer_id` → `agent_id`, `observed_id` → `user_id`,
`topic` → `query`, `top_k` → `limit`.

**Response**

```json
{
  "results": [
    {
      "id": "<UUID>",
      "content": "...",
      "metadata": {},
      "score": 0.92,
      "created_at": "...",
      "updated_at": "..."
    }
  ]
}
```

### `eden_search`

Keyword search over stored content.

**Input schema**

```json
{
  "type": "object",
  "properties": {
    "agent_id": {"type": "string"},
    "user_id": {"type": "string"},
    "query": {"type": "string"},
    "limit": {"type": "integer"},
    "workspace_id": {"type": "string"},
    "org_id": {"type": "string"}
  },
  "required": ["agent_id", "user_id", "query"]
}
```

**Response**: same `{"results": [...]}` shape as `eden_recall`.

### `eden_search_semantic`

Pure semantic search with optional metadata filters.

**Input schema**

```json
{
  "type": "object",
  "properties": {
    "agent_id": {"type": "string"},
    "user_id": {"type": "string"},
    "query": {"type": "string"},
    "filters": {"type": "object"},
    "limit": {"type": "integer"},
    "workspace_id": {"type": "string"},
    "org_id": {"type": "string"}
  },
  "required": ["agent_id", "user_id", "query"]
}
```

**Response**: same `{"results": [...]}` shape as `eden_recall`.

### `eden_edit`

Update content and/or metadata.

**Input schema**

```json
{
  "type": "object",
  "properties": {
    "id": {"type": "string"},
    "content": {"type": "string"},
    "metadata": {"type": "object"},
    "ttl_ms": {"type": "integer"}
  },
  "required": ["id"]
}
```

**Response**

```json
{"id": "<UUID>", "status": "updated"}
```

### `eden_forget`

Delete a memory by ID.

**Input schema**

```json
{
  "type": "object",
  "properties": {
    "id": {"type": "string"}
  },
  "required": ["id"]
}
```

**Response**

```json
{"id": "<UUID>", "status": "forgotten"}
```

### `eden_forget_expired`

Delete expired memories, optionally scoped.

**Input schema**

```json
{
  "type": "object",
  "properties": {
    "agent_id": {"type": "string"},
    "user_id": {"type": "string"},
    "workspace_id": {"type": "string"},
    "org_id": {"type": "string"}
  }
}
```

**Response**

```json
{"deleted": 42}
```

### `eden_health`

Return combined health, sync, usage, telemetry, and version.

**Input schema**

```json
{
  "type": "object",
  "properties": {}
}
```

**Response**

```json
{
  "status": "ok",
  "version": "0.3.15",
  "total": 123,
  "latency_ms": 1,
  "checked_at": "2026-07-28T16:00:00Z",
  "counters": {...},
  "sync": {...},
  "usage": {...}
}
```

### `eden_vacuum`

Run a safe WAL checkpoint.

**Input schema**

```json
{
  "type": "object",
  "properties": {}
}
```

**Response**: result of `store.Checkpoint(ctx)` (a map with checkpoint metadata).

## Removed tools

The Python-era tools `eden_status`, `eden_metrics`, `eden_usage`,
`eden_cleanup_wal`, and `eden_checkpoint` are gone. Their roles are folded into
`eden_health` (`status`, `metrics`, `usage`) and `eden_vacuum` (WAL checkpoint).

## Legacy aliases

The Go binary still accepts the Eden 2.0 aliases `observer_id`, `observed_id`,
`fact`, and `topic`/`top_k` for compatibility with old clients. New harnesses
should use the canonical field names.

## Notes

- `agent_id` and `user_id` are required for all identity-scoped tools.
- `workspace_id` and `org_id` are optional.
- `ttl_ms` is milliseconds. `ttl_ms: 0` or `null` means no expiry. Positive
  values set `ExpiresAt = now + ttl_ms`.
- `eden_recall` and `eden_search_semantic` both embed the query before searching.
- `eden_search` is keyword-only and does not run the embedder.
- All JSON-RPC communication happens over the spawned process's stdin/stdout.
