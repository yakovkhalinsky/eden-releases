---
title: Scopes and identity
description: How agent_id, user_id, org_id, and workspace_id scope eden-memory records and affect recall, search, and pruning.
content_type: concept
---

# Scopes and identity

Every memory in eden-memory is tagged with identity scopes. These scopes decide who can see the memory, which project it belongs to, and how bulk operations like prune or migrate apply. This page explains the four scope fields, their defaults, and how they affect queries.

## The four scope fields

| Field | Typical value | Purpose |
|-------|---------------|---------|
| `agent_id` | `claude-code-cli`, `cursor`, `my-agent` | The client or agent that wrote or is reading the memory. |
| `user_id` | Your username or email | The human the memory is about. |
| `org_id` | `0d3sa`, `your-org` | Fleet or organization scope. |
| `workspace_id` | `my-project`, repository slug | Project or workspace scope. |

`agent_id` and `user_id` are required for tools that read or write memories. `org_id` and `workspace_id` are optional, but strongly recommended for team or multi-project use.

## Defaults from the environment

If a tool call omits `org_id` or `workspace_id`, the MCP server falls back to environment variables:

- `EDEN_ORG_ID` → `org_id`
- `EDEN_WORKSPACE_ID` → `workspace_id`

This lets a project-scoped Claude Code process automatically tag every memory with the right workspace without you passing it on every call.

## How scoping affects recall and search

When you call `eden_recall` or `eden_search_semantic`, eden-memory filters to memories that match the scopes you provide. The more scopes you pass, the narrower the result set.

For example, a recall with only `agent_id` and `user_id` returns memories across every workspace you have ever used. Adding `workspace_id` restricts the results to one project.

The `total` count returned by `eden_health` is global and not affected by scoping. It counts every memory in the database, including expired and soft-deleted rows that have not yet been purged.

## Empty scopes

Some memories may have empty `org_id`, `workspace_id`, `agent_id`, or `user_id`. You can target these with the `_empty` filters in `eden_prune`:

- `org_empty: true`
- `workspace_empty: true`
- `agent_empty: true`
- `user_empty: true`

These are useful when cleaning up records created before you started using fleet-wide scopes.

## Scoping in prune and migrate

`eden_prune` and `eden_migrate` are scope-driven bulk tools.

- `eden_prune` deletes memories that match the scope filters you pass. Without a scope it can affect every row in the database, so it defaults to dry-run and requires `confirm: true`.
- `eden_migrate` remaps `org_id` and/or `workspace_id` for all matching memories. It is dry-run by default and can optionally back up the database first. See [Migrate a workspace](/eden-memory/how-to/migrate-workspace/).

## Cross-scope recall

eden-memory does not silently search across scopes. If you want a memory to be visible to multiple agents or workspaces, store it with broad scopes, or store a separate copy per scope. There is no built-in sharing rule layer beyond the identity fields.

## Sync and scopes

Multi-device sync replicates the raw memory rows, including all four scope fields. After sync, both devices have identical scope values, so recall behaves the same way on each device. See [How sync works](/eden-memory/concepts/how-sync-works/).

## See also

- [Memory model and embeddings](/eden-memory/concepts/memory-model/)
- [Prune old memories](/eden-memory/how-to/prune-memories/)
- [Migrate a workspace](/eden-memory/how-to/migrate-workspace/)
- [Tools reference](/eden-memory/reference/tools/)
