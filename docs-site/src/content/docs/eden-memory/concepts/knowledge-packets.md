---
title: Knowledge packets
description: What a knowledge packet is, when to use it, available templates and formats, and how scope and privacy work.
content_type: concept
---

A knowledge packet is a deterministic, scope-bound snapshot of the memories in one workspace. It bundles stats, excerpts, optional semantic clusters, and warnings into a single rendered artifact that can be passed to another agent, saved to a file, or read offline.

## What a packet contains

The canonical JSON packet (schema version `1.1.0`) contains:

| Section | Purpose |
|---------|---------|
| `schema_version` | `1.1.0` for packets with optional cluster enrichment. |
| `generated_at` | UTC timestamp when the packet was built. |
| `scope` | The `org_id` and `workspace_id` the packet covers. |
| `stats` | Total memory count, breakdown by agent/user, and a daily creation timeline. |
| `excerpts` | The matching memories, ordered by most recently updated first. |
| `clusters` | Optional semantic groupings derived from vector similarity (no raw vectors). |
| `warnings` | Privacy warnings, for example when full contents are emitted. |

A packet never contains raw embedding vectors. It only exposes derived counts, labels, and memory IDs.

## When to use a packet

- **Hand off context.** Start a new agent session with a compact packet summarizing the current workspace.
- **Export for review.** Render an HTML packet and open it in a browser for a human-readable project brief.
- **Capture a milestone.** Build a packet before a big refactor or release so you can compare what changed later.
- **Feed external tools.** Use the JSON packet as structured input for another script or pipeline.

## Formats

Packets can be rendered in three formats:

| Format | Best for |
|--------|----------|
| `json` | Programmatic consumers, archival, or diffing. This is the canonical schema. |
| `md` | Reading in a text editor, pasting into chat, or storing in a repository. |
| `html` | Opening in a browser. Self-contained, escaped, and dark-mode aware. |

## Templates

Templates are consumer presets. They set defaults; explicit flags override them.

| Template | Use case | Default limit | Default excerpt length |
|----------|----------|---------------|------------------------|
| `default` | Balanced summary for general use. | 50 | 120 runes |
| `compact` | Short agent brief; trimmed stats and short excerpts. | 10 | 80 runes |
| `analytical` | Stats plus semantic clusters for exploration. | 50 | 120 runes |
| `full` | Complete memory contents when the consumer is trusted. | 50 | full content |

The `compact` template omits per-memory metadata. The `analytical` template enables `enrich=cluster` automatically. The `full` template sets `include_content=true` automatically.

## Scope and identity

A packet is always scoped to exactly one `org_id`/`workspace_id` pair. The server environment variables `EDEN_ORG_ID` and `EDEN_WORKSPACE_ID` are used by default; you can override them per call with `org_id` and `workspace_id` (CLI: `--org-id`/`--org`, `--workspace-id`/`--workspace`).

You can narrow the time window with `since` and cap the size with `limit`.

## Privacy model

By default, each excerpt is truncated to 120 runes (or 80 runes for `compact`). This lets a packet summarize a workspace without exposing full memory text.

Full contents are emitted only when:

- `include_content` is `true`, or
- the `full` template is selected.

In both cases the packet includes a warning: "Full memory contents are included in this packet. Share it only with trusted consumers."

No packet ever emits raw vector embeddings. Clusters only expose IDs, labels, sizes, and a single exemplar ID per cluster.

## Determinism

Packet rendering is deterministic for a given store state:

- Excerpts are sorted by `updated_at` descending, then by memory ID.
- Stats maps and timelines are sorted lexicographically or chronologically.
- Clustering uses deterministic seeded ordering and tie-breaking by memory ID.

This makes packets safe to diff or checksum when you want to confirm that two workspaces contain the same contextual picture.

## See also

- [Build a knowledge packet](/eden-memory/how-to/build-knowledge-packet/)
- [CLI reference](/eden-memory/reference/cli/#packet)
- [Tools reference: `eden_packet`](/eden-memory/reference/tools/#eden_packet)
- [Scopes and identity](/eden-memory/concepts/scopes-identity/)
- [Memory model and embeddings](/eden-memory/concepts/memory-model/)
