---
title: Tools Reference
description: Tool schemas and usage guidance for the eden-memory MCP server.
---

eden-memory advertises the following stdio tools. All schemas use JSON input objects.

## `eden_remember`

Store a durable memory.

```json
{
  "content": "User prefers Python examples and concise sentences.",
  "agent_id": "assistant",
  "user_id": "yakov",
  "ttl_seconds": 86400,
  "tags": ["preference", "style"],
  "priority": "normal"
}
```

Use for durable facts, preferences, and corrections that should survive across sessions. Avoid remembering transient command output or secrets.

## `eden_recall`

Retrieve the most relevant memories for a context.

```json
{
  "query": "What style does the user prefer?",
  "agent_id": "assistant",
  "user_id": "yakov",
  "limit": 5,
  "min_relevance": 0.6
}
```

Call this before making decisions or assuming user preferences.

## `eden_search`

Full-text search over stored memories.

```json
{
  "query": "Python examples",
  "agent_id": "assistant",
  "user_id": "yakov",
  "limit": 10
}
```

## `eden_search_semantic`

Vector/semantic search over embeddings.

```json
{
  "query": "style and tone preferences",
  "agent_id": "assistant",
  "user_id": "yakov",
  "limit": 5
}
```

## `eden_edit`

Update an existing memory by ID.

```json
{
  "memory_id": "018f...",
  "content": "User prefers Python examples, concise sentences, and explicit types.",
  "ttl_seconds": 86400
}
```

Prefer editing over appending when a fact changes.

## `eden_forget`

Delete a specific memory by ID.

```json
{
  "memory_id": "018f..."
}
```

## `eden_forget_expired`

Remove all memories past their TTL. This is an admin/housekeeping tool; do not call it automatically.

```json
{}
```

## `eden_health`

Check store health and embedder status.

```json
{
  "check_embedder": false
}
```

Use sparingly for diagnostics. Set `check_embedder: true` only when diagnosing embedding issues, as it may be slow.

## `eden_vacuum`

Compact the SQLite store. Call only when explicitly asked to perform maintenance.

```json
{}
```

## Agent patterns

- **Recall before deciding.** Before answering a question about user preferences, recall first.
- **Edit, don't duplicate.** When a fact changes, find the existing memory and edit it.
- **What not to store.** Avoid secrets, command output, session IDs, and temporary state.
- **Housekeeping is manual.** `eden_forget_expired`, `eden_vacuum`, and embedder health checks are admin tools, not automatic routines.

For complete schemas and response shapes, see the source MCP tool definitions or the `eden-memory-mcp-usage` Hermes skill.
