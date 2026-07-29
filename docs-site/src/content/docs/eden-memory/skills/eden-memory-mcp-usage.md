---
title: eden-memory MCP usage
description: Agent skill for working with eden-memory.
---

# eden-memory MCP usage

## Overview

`eden-memory` is a self-contained Go binary that exposes the Model Context Protocol (MCP) over stdio. It stores memories in a local SQLite database with 256-dimensional embeddings.

This skill describes the memory-first loop. Load a child skill for your specific harness to get wiring instructions.

## When to use memory

- **At task start.** Call `eden_recall` once after the user states their goal.
- **Before decisions that touch preferences, conventions, security, or tooling.** Recall first.
- **After corrections or working solutions.** Update or store durable takeaways.
- **At task end.** Store 3–5 concise, durable facts.

## What to remember

- Preferences and conventions
- Corrections from the user
- Working solutions to recurring problems
- Identity facts (role, stack, constraints)

Use `ttl_ms: null` for facts that should persist until the user changes them.

## What not to remember

- Secrets, tokens, passwords
- Raw command output
- Ephemeral reasoning
- Generic knowledge already in docs
- Unvalidated guesses

## Basic loop

1. `eden_recall` — pull relevant context.
2. Do the work.
3. `eden_remember` — store durable takeaways.

Efficiency notes:
- Prefer `eden_search` for exact keyword lookups.
- Keep recalled context concise; do not dump large raw outputs into memories.

## Tool summary

| Tool | Purpose |
|------|---------|
| `eden_remember` | Store a durable fact |
| `eden_recall` | Semantic recall for this user |
| `eden_search` | Keyword search |
| `eden_search_semantic` | Semantic search with filters |
| `eden_edit` | Update a memory by ID |
| `eden_forget` | Delete a memory by ID |
| `eden_forget_expired` | Delete expired memories (manual/admin) |
| `eden_health` | Combined health snapshot |
| `eden_vacuum` | Compact the SQLite store (manual/admin) |

## Remember example

```json
{
  "agent_id": "my-agent",
  "user_id": "alice",
  "kind": "preference",
  "content": "Use Python for examples and keep sentences short.",
  "ttl_ms": null
}
```

Use a stable `agent_id` that matches the harness (e.g. `claude-code-cli`, `cursor-agent`, `hermes`, `my-agent`). Do not change it per conversation; consistency improves recall relevance.

## Recall example

```json
{
  "agent_id": "my-agent",
  "user_id": "alice",
  "kind": "preference",
  "query": "How should I write examples?"
}
```

## Subagent delegation

When delegating to a subagent, include the memory context in the prompt:

```text
Context: Alice prefers Python examples and short sentences. Call eden_recall if you need more conventions.
```

The subagent can then call `eden_recall` to load additional context before acting.

## Memory checkpoint

Before finishing any task:
1. Confirm at least one `eden_recall` happened at task start.
2. For each takeaway, call `eden_search` or `eden_search_semantic` to avoid storing near-duplicates.
3. Write missing memories with `ttl_ms: null` for durable facts.
4. Confirm at least one `eden_remember` happened at task end.
