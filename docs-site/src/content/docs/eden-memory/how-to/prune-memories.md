---
title: Prune old memories
description: Scoped soft-delete or hard-delete of eden-memory memories with eden_prune.
content_type: how-to
---

# Prune old memories

Over time an eden-memory database accumulates expired, duplicated, or out-of-scope memories. `eden_prune` lets you remove them in bulk, scoped to the identities and workspaces you choose. This guide shows soft deletion and optional permanent deletion.

## Prerequisites

- eden-memory running as an MCP server.
- The scope fields of the memories you want to remove.
- A clear idea of whether you need soft-delete (recoverable until vacuum/purge) or hard-delete (permanent).

## 1. Choose your scope

`eden_prune` filters by any combination of:

- `agent_id`
- `user_id`
- `org_id`
- `workspace_id`
- `keywords`
- `expired_only: true`
- `org_empty`, `workspace_empty`, `agent_empty`, `user_empty` — match rows where that scope is empty

Example: target memories in an old workspace.

```json
{
  "org_id": "your-org",
  "workspace_id": "old-project",
  "keywords": "deprecated"
}
```

## 2. Run a dry-run preview

Without `confirm: true`, `eden_prune` returns the matching count and sample IDs without deleting anything.

```json
{
  "org_id": "your-org",
  "workspace_id": "old-project",
  "keywords": "deprecated",
  "expired_only": false,
  "dry_run": true
}
```

Review the sample carefully. Pruning the wrong scope can remove memories you still need.

## 3. Soft-delete the memories

Soft-delete is the default. Pass `confirm: true` and `dry_run: false`.

```json
{
  "org_id": "your-org",
  "workspace_id": "old-project",
  "keywords": "deprecated",
  "expired_only": false,
  "confirm": true,
  "dry_run": false
}
```

Soft-deleted memories are hidden from recall and search but remain in the database until they are purged by a hard prune or a vacuum.

## 4. Hard-delete for permanent removal

Use hard-delete only when you are sure. You must pass both `hard: true` and `yes_i_really_want_to_delete: true`.

```json
{
  "org_id": "your-org",
  "workspace_id": "old-project",
  "keywords": "deprecated",
  "expired_only": false,
  "hard": true,
  "yes_i_really_want_to_delete": true,
  "confirm": true,
  "dry_run": false
}
```

Hard-deleted rows are removed from SQLite and cannot be recovered from this database.

## 5. Clean up expired memories only

To remove only memories whose TTL has passed:

```json
{
  "expired_only": true,
  "confirm": true,
  "dry_run": false
}
```

This is useful for periodic housekeeping without touching live memories.

## Expected outcome

- Dry-run shows the exact count and sample IDs.
- Soft-delete hides matching memories from recall and search.
- Hard-delete permanently removes matching memories.
- `eden_health` reflects the reduced total count after hard deletion.

## See also

- [Scopes and identity](/eden-memory/concepts/scopes-identity/)
- [Memory model and embeddings](/eden-memory/concepts/memory-model/)
- [Tools reference](/eden-memory/reference/tools/)
