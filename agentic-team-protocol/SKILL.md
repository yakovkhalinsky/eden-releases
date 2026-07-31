---
name: agentic-team-protocol
title: Agentic Team Protocol
description: Use role-based agent teams with a seven-stage task lifecycle and Eden-memory as the durable substrate.
version: 1.0.0
tags: [agents, subagents, roles, eden-memory, protocol, team]
tools:
  discoverable: true
  list:
    - mcp__eden-memory__eden_remember
    - mcp__eden-memory__eden_recall
    - mcp__eden-memory__eden_search
    - mcp__eden-memory__eden_search_semantic
    - mcp__eden-memory__eden_edit
    - mcp__eden-memory__eden_forget
    - mcp__eden-memory__eden_forget_expired
    - mcp__eden-memory__eden_health
    - mcp__eden-memory__eden_vacuum
harness: claude-code
related_skills:
  - eden-memory-claude
---

# Agentic Team Protocol

A role-based agent team protocol implemented as Claude Code primitives (skills, agents, slash commands) with Eden-memory as the single source of truth for state, ownership, and auditability.

## Core idea

Every goal passes through a seven-stage lifecycle. Each stage has an owner role, exit criteria, and a durable record in Eden-memory. Roles are specialised subagents; the Dispatcher decides who does what; the Verifier gate is mandatory before closure.

## When to use

Use this protocol when a task is non-trivial, risky, multi-step, or needs to be observable across sessions. For trivial one-line fixes, direct action is fine.

## Roles

| Role | Obligation | Subagent |
|------|------------|----------|
| Dispatcher | Decides who does what | `dispatcher` |
| Researcher | Gathers context before decisions | `researcher` |
| Builder | Produces durable, reviewable artefacts | `builder` |
| Runtime | Operates live systems safely | `runtime` |
| Verifier | Validates work before acceptance | `verifier` |
| Archivist | Maintains durable, searchable fleet memory | `archivist` |

## Seven-stage task lifecycle

1. **Goal receipt** — Dispatcher records the request, requester, constraints, and package type.
2. **Routing and assignment** — Dispatcher assigns target role/package, owner, deadline, success criteria, confidence/escalation trigger.
3. **Context gathering** — Researcher (or assigned role) records what is known, options considered, chosen path.
4. **Action** — Builder or Runtime executes the plan and records what was done, rollback options, and state changes.
5. **Verification** — Verifier inspects outcome against success criteria and writes a verdict.
6. **Recording and archival** — Archivist ensures final outcome, decision trail, and skill/runbook updates are stored.
7. **Hand-off or closure** — Archivist confirms records are complete and ownership is transferred if handing off.

## Routing rules and dispatcher defaults

- Every new goal starts with Dispatcher.
- Package types:
  - `research` → Researcher
  - `build` → Builder
  - `run` → Runtime
  - `verify` → Verifier
  - `archive` → Archivist
- Low confidence, missing authority, or tight deadline → escalate via `/agentic-escalate`.
- Builder and Runtime must not start without sufficient context; request Researcher support if needed.

## Hand-off format

Every hand-off must include:

- `goal_id`
- Current stage
- Owner role and instance
- Input record IDs
- Output record IDs
- Success criteria and deadline
- Escalation trigger (if any)

## Eden-memory record schema

Store records with metadata so they can be recalled, linked, and audited:

```json
{
  "goal_id": "<uuid>",
  "stage": "goal_receipt | routing_and_assignment | context_gathering | action | verification | recording_and_archival | hand_off_or_closure",
  "owner_role": "dispatcher | researcher | builder | runtime | verifier | archivist",
  "owner_instance": "<optional instance id>",
  "input_record_ids": ["<id>"],
  "output_record_ids": ["<id>"],
  "verdict_id": "<id when applicable>"
}
```

Required record types:

- `goal_record` — initial request and constraints.
- `dispatch_instruction` — routing decision from Dispatcher.
- `context_summary` — findings from Researcher.
- `action_record` — what Builder or Runtime did.
- `verdict` — green/red/blocked from Verifier with evidence.
- `escalation_record` — escalation request and routing.
- `archival_record` — final outcome and links.

## Anti-patterns to avoid

- **Role collapse** — use the correct subagent for each stage.
- **Missing Dispatcher** — every new goal starts with Dispatcher.
- **Skipped Researcher** — non-trivial goals need explicit context gathering.
- **Runtime without rollback** — Runtime must produce a rollback plan.
- **Verifiability gap** — Verifier gate is mandatory before closure.
- **Archivist as secretary** — Archivist owns linking and skill/runbook updates.
- **Memory blindness** — Eden-memory is the single source of truth; do not rely on conversation context.

## Scope resolution rules

1. Project-local charter (`<project>/.claude/agentic-team-charter.md`) overrides global charter.
2. Project-local agent definitions override global agents.
3. Project-local skill overrides global skill.
4. If a project has no `agentic-team-config.yaml`, the global skill is used and the global charter is ignored unless explicitly referenced.

## Slash commands

- `/ratify-charter` — read the project's `agentic-team-charter.md`, store a ratification record, and report whether the team may proceed.
- `/agentic-status` — list active goals, current stage, owner role, and latest record IDs.
- `/agentic-escalate` — collect goal, options, consulted roles, recommended default, specific question/authority requested, and risk of waiting; write an `escalation_record`.

## Using the subagents

Spawn the role subagent with its goal context. Each role subagent starts by recalling the latest `goal_record` for its assigned `goal_id`, then acts according to its contract, and finally writes a durable record to Eden-memory before handing off.

## Fallback if MCP is unavailable

If the Eden-memory MCP tools are unavailable, use the `/eden-*` fallback slash commands or invoke `eden-memory` directly from Bash. Restart Claude Code after `eden-memory setup claude` if commands are missing.
