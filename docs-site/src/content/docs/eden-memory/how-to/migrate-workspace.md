---
title: Migrate a workspace
description: Remap org_id and workspace_id for a set of eden-memory memories with eden_migrate.
content_type: how-to
---

# Migrate a workspace

When a project is renamed or moved to a new organization, you can update the `org_id` and `workspace_id` on every matching memory with `eden_migrate`. This guide shows how to preview and execute a scope remap.

## Prerequisites

- eden-memory running as an MCP server.
- The current `org_id` and `workspace_id` values.
- The new `org_id` and `workspace_id` values.
- Optional: enough disk space for a backup copy if you set `backup: true`.

## 1. Plan the remap

Decide which scope fields change. Common cases:

| From | To | Reason |
|------|----|--------|
| `old-org` | `new-org` | Company rebrand or acquisition. |
| `old-project` | `new-project` | Repository rename. |
| empty (`org_empty`) | `your-org` | Backfilling fleet scope on legacy memories. |

## 2. Run a dry-run preview

`eden_migrate` defaults to dry-run. Call it first to see how many rows match without changing anything.

```json
{
  "from_org_id": "old-org",
  "from_workspace_id": "old-project",
  "to_org_id": "new-org",
  "to_workspace_id": "new-project"
}
```

Review the returned count and sample memory IDs. Make sure only the intended memories are affected.

## 3. Back up the database

Before mutating, export an encrypted snapshot:

```json
{
  "path": "/home/yourname/backups/eden-memory-pre-migrate.bin",
  "passphrase": "a strong unique passphrase"
}
```

Or set `backup: true` in the migrate call to make a local copy first.

## 4. Execute the remap

Add `confirm: true` and `dry_run: false` to apply the change.

```json
{
  "from_org_id": "old-org",
  "from_workspace_id": "old-project",
  "to_org_id": "new-org",
  "to_workspace_id": "new-project",
  "backup": true,
  "confirm": true,
  "dry_run": false
}
```

`backup: true` copies the database before writing. The copy is placed next to the original with a timestamp suffix.

## 5. Verify the result

Run a scoped recall with the new workspace:

```json
{
  "agent_id": "claude-code-cli",
  "user_id": "yourname",
  "org_id": "new-org",
  "workspace_id": "new-project",
  "query": "any known fact",
  "limit": 5
}
```

The memories should now appear under the new scope. A recall against the old scope should return nothing.

## Expected outcome

- Dry-run reports the matching rows without changing them.
- The live remap updates `org_id` and/or `workspace_id` on every matching memory.
- A backup exists if `backup: true` was used.
- Recall under the new scope returns the migrated memories.

## See also

- [Scopes and identity](/eden-memory/concepts/scopes-identity/)
- [Back up and restore a database](/eden-memory/how-to/backup-restore/)
- [Tools reference](/eden-memory/reference/tools/)
