---
name: memory-mcp-usage
title: memory MCP usage
description: |
  Use memory as a persistent memory skill inside any stdio MCP client.
version: 3.0.1
tags: [mcp, memory, memory-first, stdio, skill]
tools:
  discoverable: true
  list:
    - memory_remember
    - memory_recall
    - memory_search
    - memory_search_semantic
    - memory_lookup
    - memory_lookup_cross
    - memory_edit
    - memory_forget
    - memory_forget_expired
    - memory_health
    - memory_vacuum
    - memory_prune
    - memory_migrate
    - memory_packet
    - memory_packet_publish
    - memory_packet_list
    - memory_packet_export
    - memory_report
    - memory_document
    - memory_document_publish
    - memory_document_list
    - memory_document_export
    - memory_dream
    - memory_dream_apply
    - memory_export_snapshot
    - memory_import_snapshot
    - memory_sync
    - memory_pair_device
    - memory_sync_loop
    - memory_relay_server
    - memory_relay_register
    - memory_pair_create_invitation
    - memory_pair_accept_invitation
install_hint: curl -fsSL https://0d3sa.com/memory/install.sh | sh
related_skills:
  - memory-claude
  - memory-cursor
  - memory-hermes
---

# memory MCP usage

## Overview

`memory` is a self-contained Go binary that exposes the Model Context Protocol (MCP) over stdio. It stores memories in a local SQLite database with 256-dimensional embeddings.

This skill describes the memory-first loop. Load a child skill for your specific harness to get wiring instructions.

## When to use memory

- **At task start.** Call `memory_recall` once after the user states their goal.
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

1. `memory_recall` — pull relevant context.
2. Do the work.
3. `memory_remember` — store durable takeaways.

Efficiency notes:
- Prefer `memory_search` for exact keyword lookups.
- Keep recalled context concise; do not dump large raw outputs into memories.

## Tool summary

| Tool | Purpose |
|------|---------|
| `memory_remember` | Store a durable fact |
| `memory_recall` | Semantic recall for this user |
| `memory_search` | Keyword search |
| `memory_search_semantic` | Semantic search with filters |
| `memory_edit` | Update a memory by ID |
| `memory_forget` | Delete a memory by ID |
| `memory_forget_expired` | Delete expired memories (manual/admin) |
| `memory_health` | Combined health snapshot |
| `memory_vacuum` | Compact the SQLite store (manual/admin) |
| `memory_prune` | Bulk soft-delete or hard-delete memories |
| `memory_migrate` | Remap `org_id`/`workspace_id` for a scope |
| `memory_packet` | Build a deterministic knowledge packet |
| `memory_export_snapshot` | Export an encrypted database snapshot |
| `memory_import_snapshot` | Import an encrypted snapshot (replaces DB) |
| `memory_sync` | One-shot sync with a peer database |
| `memory_pair_device` | Pair with a local peer database |
| `memory_sync_loop` | Background relay sync loop |
| `memory_relay_server` | Start/stop a local relay server |
| `memory_relay_register` | Register with a relay directory |
| `memory_pair_create_invitation` | Create a relay-mediated pairing invitation |
| `memory_pair_accept_invitation` | Accept a relay-mediated pairing invitation |

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
Context: Alice prefers Python examples and short sentences. Call memory_recall if you need more conventions.
```

The subagent can then call `memory_recall` to load additional context before acting.

## Memory checkpoint

Before finishing any task:
1. Confirm at least one `memory_recall` happened at task start.
2. For each takeaway, call `memory_search` or `memory_search_semantic` to avoid storing near-duplicates.
3. Write missing memories with `ttl_ms: null` for durable facts.
4. Confirm at least one `memory_remember` happened at task end.
