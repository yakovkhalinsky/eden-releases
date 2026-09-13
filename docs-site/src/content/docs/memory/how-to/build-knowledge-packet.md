---
title: Build a knowledge packet
description: Build and export a knowledge packet from memory using the CLI or the memory_packet MCP tool.
content_type: how-to
---

This guide shows how to build a knowledge packet for a workspace using the CLI and the `memory_packet` MCP tool. A packet is a deterministic, scope-bound snapshot of memories, stats, and optional semantic clusters.

## Prerequisites

- `memory` installed and on your PATH.
- A database with at least one remembered memory in the target workspace.
- `MEMORY_ORG_ID` and `MEMORY_WORKSPACE_ID` configured, or identity flags available.

## 1. Verify the workspace scope

```bash
memory tree
```

Confirm the org and workspace you want to export contain the memories you expect. You can also set the environment variables explicitly:

```bash
export MEMORY_ORG_ID="your-org"
export MEMORY_WORKSPACE_ID="eden-releases"
```

## 2. Build a default packet

The default template produces JSON with stats, 120-rune excerpts, and optional clusters:

```bash
memory packet --format json --template default > packet.json
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
memory packet --template compact --format md > brief.md
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
memory packet --template analytical --format html > analysis.html
```

Or keep the default template and enable clusters explicitly:

```bash
memory packet --enrich cluster --format md > clustered.md
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
memory packet --template full --format md > full-brief.md
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
memory packet \
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

## 8. Publish it for later

If the packet is worth keeping, publish it instead of only printing it. Published packets are durable records you can list and re-export later:

```bash
memory packet --template compact --format md --title "Week 34 brief" --publish
memory packet list
memory packet export <packet-id> --format md > brief.md
```

Publishing does not change the packet's contents or scope. See [Publishing packets](/memory/concepts/knowledge-packets/#publishing-packets) for the details.

## Tips

- Use `compact` for chat context windows where size matters.
- Use `analytical` when you want to see how memories group thematically.
- Use `full` only for trusted, private consumers.
- Combine `--limit` with `--since` to keep packets focused.

## See also

- [Knowledge packets concept](/memory/concepts/knowledge-packets/)
- [CLI reference: `memory packet`](/memory/reference/cli/#packet)
- [Tools reference: `memory_packet`](/memory/reference/tools/#memory_packet)
- [Tools reference: packet publishing tools](/memory/reference/tools/#memory_packet_publish)
- [Scopes and identity](/memory/concepts/scopes-identity/)
