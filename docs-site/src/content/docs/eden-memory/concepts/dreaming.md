---
title: Dreaming
description: LLM-first memory curation with the eden_dream and eden_dream_apply MCP tools, the eden-memory dream preview and apply CLI, and local ~/.eden-memory/.env LLM provider configuration. Supports dry-run previews and json, md, and html output formats.
content_type: concept
keywords:
  - dreaming
  - eden_dream
  - eden_dream_apply
  - dream_record
  - LLM curation
  - memory curation
  - MCP tools
  - eden-memory dream CLI
  - preview
  - apply
  - dry-run
  - output formats
---

Dreaming is an LLM-first curation pass over a scoped memory corpus. It lets you ask a question such as "what do we know about deployment conventions?" and get a focused, synthesized report without manually reading every matching memory.

By default, dreaming is read-only. A separate apply step is required before any curated result is persisted back into the database.

## Shipped surfaces

There are two ways to run a dream:

| Surface | Primary use |
|---|---|
| MCP tools `eden_dream` and `eden_dream_apply` | Called by an agent or IDE integration such as Claude Code. |
| CLI `eden-memory dream preview` and `eden-memory dream apply` | Run directly in a terminal for ad-hoc curation. |

This page documents only the shipped MCP and CLI surfaces. The internal `/team-dream` slash command and `eden-team` REST dream endpoints are not covered here.

## MCP tools

### `eden_dream`

Run a read-only curation preview over a scoped set of memories.

```json
{
  "agent_id": "builder",
  "user_id": "yakov",
  "topic": "refactor safety",
  "limit": 50,
  "output_format": "md",
  "dry_run": true
}
```

Parameters:

- `agent_id` and `user_id` — required scope identities.
- `topic` — the curation question or theme.
- `limit` — maximum memories to consider (default is small; raise it for broad topics).
- `output_format` — `json`, `md`, or `html`. Defaults to `md`.
- `dry_run` — defaults to `true`. A preview does not write anything.
- `org_id` and `workspace_id` — optional scope filters.

The tool returns a `report` string containing the curated synthesis. When `dry_run` is `true`, nothing is persisted.

### `eden_dream_apply`

Persist a dream result as a `dream_record` memory.

```json
{
  "agent_id": "builder",
  "user_id": "yakov",
  "topic": "refactor safety",
  "limit": 50,
  "output_format": "md",
  "dry_run": false
}
```

Pass `dry_run: false` to store the result. The persisted record has `record_type: dream_record` in its metadata and can be recalled later like any other memory.

## CLI

The same surfaces are available on the command line.

Preview without writing anything:

```bash
eden-memory --db ~/.eden-memory/default.db dream preview \
  --topic "refactor safety" \
  --output-format md
```

Preview and persist:

```bash
eden-memory --db ~/.eden-memory/default.db dream preview \
  --topic "Tailscale" \
  --limit 30 \
  --output-format json \
  --persist
```

The `--persist` flag is the CLI equivalent of `dry_run: false`. Without it, the command is read-only.

## LLM provider configuration

Dreaming needs an OpenAI-compatible chat-completions endpoint. Configure it in `~/.eden-memory/.env`:

```bash
EDEN_LLM_BASE_URL=http://localhost:11434/v1
EDEN_LLM_API_KEY=ollama
EDEN_LLM_MODEL=llama3.1
```

Local endpoints such as Ollama are priced at zero by default. Remote endpoints use the built-in price table unless overridden with:

```bash
EDEN_LLM_DEFAULT_PRICE_INPUT=0.0000025
EDEN_LLM_DEFAULT_PRICE_OUTPUT=0.0000100
```

The endpoint must expose `/v1/chat/completions` and accept the standard OpenAI request shape.

## Output formats

| Format | Best for |
|---|---|
| `md` | Reading in a chat panel or rendering in documentation. |
| `json` | Programmatic parsing, downstream agents, or archival. |
| `html` | Embedding in a web page or rendered report. |

The format can be set per request in both the MCP tool and the CLI.

## Default behaviour

Dreaming defaults to **dry-run / preview mode**. Whether you call `eden_dream` with no `dry_run` field or run `eden-memory dream preview` without `--persist`, the result is returned but not written to the database. This keeps curation safe to experiment with.

Persisting a result explicitly creates a `dream_record`, which is useful for turning a curated synthesis into durable team knowledge.

## Privacy and cost notes

- The LLM sees only the scoped corpus you provide through `topic`, `limit`, and scope filters.
- Local endpoints incur no cost tracking.
- Remote endpoints report estimated cost in the response metadata.
- Do not pass secrets, tokens, or raw private output into a dream topic or corpus.

## See also

- [Tools reference](/eden-memory/reference/tools/)
- [CLI reference](/eden-memory/reference/cli/)
- [Environment variables](/eden-memory/reference/environment-variables/)
- [Memory model and embeddings](/eden-memory/concepts/memory-model/)
