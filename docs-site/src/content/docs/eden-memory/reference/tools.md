---
title: Tools reference
description: What each eden-memory tool does and when to use it.
---

All inputs are JSON objects. `agent_id` and `user_id` are required for tools that read or write memories.

## `eden_remember`

Store a durable memory.

```json
{
  "agent_id": "my-client",
  "user_id": "yakov",
  "content": "User prefers Python examples and concise sentences.",
  "metadata": {"source": "direct-statement", "domain": "style"},
  "ttl_ms": null,
  "workspace_id": "eden-releases",
  "org_id": null
}
```

- `agent_id` and `user_id` are required.
- `ttl_ms: null` means the memory never expires. A positive integer sets an expiry in milliseconds.
- `workspace_id` scopes the memory to a project; `org_id` is for fleet contexts.

Response:

```json
{"id": "a1b2c3d4-...", "status": "remembered"}
```

## `eden_recall`

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

## `eden_search`

Keyword search over stored memory content.

```json
{
  "agent_id": "my-client",
  "user_id": "yakov",
  "query": "Python examples",
  "limit": 10
}
```

## `eden_search_semantic`

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

## `eden_edit`

Update an existing memory by ID. Use this when a fact changes instead of storing a duplicate.

```json
{
  "id": "a1b2c3d4-...",
  "content": "User prefers Python examples, concise sentences, and explicit types.",
  "metadata": {"source": "user-correction", "domain": "style"},
  "ttl_ms": null
}
```

## `eden_forget`

Delete a specific memory by ID.

```json
{"id": "a1b2c3d4-..."}
```

## `eden_forget_expired`

Remove all memories past their TTL. This is a housekeeping tool; do not call it automatically.

```json
{}
```

## `eden_health`

Return a combined health, usage, and telemetry snapshot.

```json
{}
```

## `eden_vacuum`

Compact the SQLite store. Call only when explicitly asked to perform maintenance.

```json
{}
```

## Usage tips

- **Recall before deciding.** Before answering a question about user preferences, recall first.
- **Edit, don't duplicate.** When a fact changes, find the existing memory and edit it.
- **What not to store.** Avoid secrets, command output, session IDs, and temporary state.
- **Housekeeping is manual.** `eden_forget_expired`, `eden_vacuum`, and embedder health checks are admin tools, not automatic routines.

## Legacy aliases

The Go binary also accepts the older Python-era aliases for compatibility:

- `observer_id` → `agent_id`
- `observed_id` → `user_id`
- `fact` → `content`
- `topic` / `top_k` → `query` / `limit`

New integrations should use the canonical field names above.
