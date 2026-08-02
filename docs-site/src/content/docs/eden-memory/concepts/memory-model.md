---
title: Memory model and embeddings
description: How eden-memory stores memories, vectors, and metadata in SQLite, and how search and recall use embeddings.
content_type: concept
---

# Memory model and embeddings

eden-memory stores durable facts for AI agents in a local SQLite database. Each memory is a short piece of text plus a 256-dimensional embedding vector, metadata, identity scopes, and an expiry. This page explains how the pieces fit together and how recall works.

## What a memory is

A memory is a row in the SQLite database that contains:

| Field | Purpose |
|-------|---------|
| `id` | UUID primary key. |
| `agent_id` | The agent or client that created the memory. |
| `user_id` | The user the memory is about. |
| `content` / `fact` | The text you want to remember. |
| `embedding` | 256-dimensional vector generated from `content`. |
| `metadata` | Free-form JSON for tags, sources, or domains. |
| `org_id` | Fleet or organization scope. |
| `workspace_id` | Project or repository scope. |
| `created_at` / `updated_at` | Timestamps for ordering and sync. |
| `expires_at` | Optional TTL; `NULL` means forever. |

The embedding is what makes semantic recall possible. Two pieces of text with similar meaning get vectors that are close together in 256-dimensional space, even if they use different words.

## SQLite database

The default database lives at:

```text
~/.eden-memory/default.db
```

You can override it with `--db` or the `EDEN_DB_PATH` environment variable. The binary creates the database, tables, and indexes automatically on first use.

eden-memory keeps a write-ahead log (WAL) for concurrency. Call `eden_vacuum` to run a SQLite checkpoint and reclaim space after large deletions or imports.

## Embedding model

eden-memory bundles its own embedding runtime and model weights. On first recall or semantic search the binary extracts the runtime to a platform cache and loads the model. Subsequent calls are local and fast.

- Model output: 256-dimensional vectors.
- Similarity metric: cosine similarity (higher is closer).
- No external API call is made for embedding or recall.

The first semantic call may take a moment while the runtime initializes. After that, `eden_recall` and `eden_search_semantic` return results from the local store.

## How recall works

`eden_recall` converts the query string into an embedding, then searches the database for the nearest neighbours by cosine similarity. Results include:

- the matching memory content,
- the metadata you stored,
- a similarity score.

Recall is scoped by the identity fields you provide. If you pass `agent_id` and `user_id`, eden-memory searches within that slice. Adding `workspace_id` narrows it further. See [Scopes and identity](/eden-memory/concepts/scopes-identity/) for how scoping changes what is returned.

## Keyword vs semantic search

- `eden_search` is a keyword search over stored `content`. Use it when you know exact words.
- `eden_search_semantic` is a semantic search with optional metadata filters. Use it for meaning-based lookup.
- `eden_recall` is the high-level semantic search most agents call at the start of a task.

## Expiry and cleanup

Set `ttl_ms` when storing a memory to make it expire after a number of milliseconds. Expired memories are not returned by recall or search, but they remain in the database until you run `eden_forget_expired` or `eden_prune`.

Housekeeping tools are manual. Do not run them automatically unless you have a specific cleanup policy.

## Privacy and sync

- Vectors and content stay in your SQLite file.
- Multi-device sync exchanges signed, encrypted delta logs. The relay only forwards opaque envelopes. See [How sync works](/eden-memory/concepts/how-sync-works/) and [Security model](/eden-memory/concepts/security-model/).

## See also

- [Scopes and identity](/eden-memory/concepts/scopes-identity/)
- [How sync works](/eden-memory/concepts/how-sync-works/)
- [Tools reference](/eden-memory/reference/tools/)
- [Prune old memories](/eden-memory/how-to/prune-memories/)
