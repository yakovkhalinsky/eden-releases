---
title: Build a knowledge packet
description: Build and export a knowledge packet from eden-memory using the CLI or the eden_packet MCP tool.
content_type: how-to
---

This guide shows how to build a knowledge packet for a workspace using the CLI and the `eden_packet` MCP tool. A packet is a deterministic, scope-bound snapshot of memories, stats, and optional semantic clusters.

## Prerequisites

- `eden-memory` installed and on your PATH.
- A database with at least one remembered memory in the target workspace.
- `EDEN_ORG_ID` and `EDEN_WORKSPACE_ID` configured, or identity flags available.

## 1. Verify the workspace scope

```bash
eden-memory tree
```

Confirm the org and workspace you want to export contain the memories you expect. You can also set the environment variables explicitly:

```bash
export EDEN_ORG_ID="your-org"
export EDEN_WORKSPACE_ID="eden-releases"
```

## 2. Build a default packet

The default template produces JSON with stats, 120-rune excerpts, and optional clusters:

```bash
eden-memory packet --format json --template default > packet.json
```

Equivalent MCP tool call:

```json
{
  "format": "json",
  "template": "default",
  "org_id": "your-org",
  "workspace_id": "eden-releases"
}
```

## 3. Build a compact brief for hand-offs

Use `compact` for a short Markdown brief with short excerpts and trimmed stats:

```bash
eden-memory packet --template compact --format md > brief.md
```

Equivalent MCP:

```json
{
  "format": "md",
  "template": "compact"
}
```

## 4. Add semantic clusters

The `analytical` template enables cluster enrichment automatically:

```bash
eden-memory packet --template analytical --format html > analysis.html
```

Or keep the default template and enable clusters explicitly:

```bash
eden-memory packet --enrich cluster --format md > clustered.md
```

Equivalent MCP:

```json
{
  "format": "html",
  "template": "analytical",
  "enrich": "cluster"
}
```

Clusters group related memories by vector similarity and include only memory IDs and labels — never raw vectors.

## 5. Export full contents

Use the `full` template, or pass `--include-content`, when the consumer is trusted and needs complete memory text:

```bash
eden-memory packet --template full --format md > full-brief.md
```

Equivalent MCP:

```json
{
  "format": "md",
  "template": "full"
}
```

The rendered output will include a privacy warning.

:::caution
Only export full contents when you trust the consumer. The warning reminds you that the packet now contains the complete text of every matching memory.
:::

## 6. Limit to recent memories

Use `--since` to include only memories created or updated after a specific time:

```bash
eden-memory packet \
  --since "$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --format md \
  > recent.md
```

Equivalent MCP:

```json
{
  "format": "md",
  "since": "2026-07-25T00:00:00Z"
}
```

## 7. Verify the rendered packet

Open or preview the output:

- JSON: pipe through `jq` or your JSON viewer.
- Markdown: open in any text editor or paste into a chat context.
- HTML: open in a browser. The file is self-contained and escaped.

## Tips

- Use `compact` for chat context windows where size matters.
- Use `analytical` when you want to see how memories group thematically.
- Use `full` only for trusted, private consumers.
- Combine `--limit` with `--since` to keep packets focused.

## See also

- [Knowledge packets concept](/eden-memory/concepts/knowledge-packets/)
- [CLI reference: `eden-memory packet`](/eden-memory/reference/cli/#packet)
- [Tools reference: `eden_packet`](/eden-memory/reference/tools/#eden_packet)
- [Scopes and identity](/eden-memory/concepts/scopes-identity/)
