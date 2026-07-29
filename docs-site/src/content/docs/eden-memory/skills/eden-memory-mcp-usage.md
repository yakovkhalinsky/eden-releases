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
