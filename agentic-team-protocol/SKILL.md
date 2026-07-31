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
4. **Action** — Builder or Runtime executes the plan and records what was done, rollback options, and state changes. A role may park the goal as `pending_authorisation` if it needs explicit user approval before proceeding.
5. **Verification** — Verifier inspects outcome against success criteria and writes a verdict (`green`, `red`, or `blocked`).
6. **Recording and archival** — Archivist ensures final outcome, decision trail, and skill/runbook updates are stored.
7. **Hand-off or closure** — Archivist confirms records are complete and ownership is transferred if handing off. A new action record after closure supersedes the closure and returns the goal to Action.

### Resumable sub-states

- `blocked` — waiting on an external dependency or authority. The owning role records the unblock condition. The router checks it on every `/agentic-continue`.
- `pending_authorisation` — waiting on explicit user approval for a specific action (e.g., push to origin). The exact question and prepared action are recorded so a new session can resume and apply the answer.

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
- When a session ends or a role is interrupted, the next session uses `/agentic-continue` (or the router subagent) to rehydrate the goal from Eden-memory and dispatch the correct next role.
- A `blocked` or `pending_authorisation` goal remains active until the recorded unblock/approval condition is satisfied; the router re-checks it on continuation.

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
  "stage": "goal_receipt | routing_and_assignment | context_gathering | action | verification | recording_and_archival | hand_off_or_closure | blocked | pending_authorisation",
  "owner_role": "dispatcher | researcher | builder | runtime | verifier | archivist | router",
  "owner_instance": "<optional instance id>",
  "input_record_ids": ["<id>"],
  "output_record_ids": ["<id>"],
  "verdict_id": "<id when applicable>",
  "status": "<in_progress | completed | blocked | pending_authorisation>"
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
- `run_log` — coarse-grained event written by a role at the start/end of each turn; used by the router to detect stale or interrupted work.
- `hand_off_record` — explicit ownership transfer between roles or instances, including input/output IDs, success criteria, and deadline.

## Anti-patterns to avoid

- **Role collapse** — use the correct subagent for each stage.
- **Missing Dispatcher** — every new goal starts with Dispatcher.
- **Skipped Researcher** — non-trivial goals need explicit context gathering.
- **Runtime without rollback** — Runtime must produce a rollback plan.
- **Verifiability gap** — Verifier gate is mandatory before closure.
- **Archivist as secretary** — Archivist owns linking and skill/runbook updates.
- **Memory blindness** — Eden-memory is the single source of truth; do not rely on conversation context.
- **Dropped interrupted work** — always leave a `run_log` or durable record at the end of a turn so `/agentic-continue` can resume.
- **Implicit hand-offs** — transfer ownership through a promoted `hand_off_record`, not chat history.
- **Stale closures** — a new action record after closure supersedes it; do not assume an old `archival_record` is the final word.

## Scope resolution rules

1. Project-local charter (`<project>/.claude/agentic-team-charter.md`) overrides global charter.
2. Project-local agent definitions override global agents.
3. Project-local skill overrides global skill.
4. If a project has no `agentic-team-config.yaml`, the global skill is used and the global charter is ignored unless explicitly referenced.

## Slash commands

- `/ratify-charter` — read the project's `agentic-team-charter.md`, store a ratification record, and report whether the team may proceed.
- `/agentic-status` — list active goals, current stage, owner role, latest record IDs, and continueable/blocked state.
- `/agentic-escalate` — collect goal, options, consulted roles, recommended default, specific question/authority requested, and risk of waiting; write an `escalation_record`.
- `/agentic-continue` — resume an unfinished goal from Eden-memory by rehydrating its state and dispatching the next required role.
- `/agentic-handoff` — transfer ownership of a goal to another role or instance in a durable `hand_off_record`.

## Using the subagents

Spawn the role subagent with its goal context. Each role subagent starts by recalling the latest `goal_record` for its assigned `goal_id`, then acts according to its contract, and finally writes a durable record to Eden-memory before handing off.

For continuation, use the `router` subagent (or `/agentic-continue`) instead of manually picking a role. The router reads the latest Eden records for a `goal_id`, determines the required next stage and role using the lifecycle rules below, and invokes that role with full context.

### Router lifecycle rules

Given the latest non-terminal record for a `goal_id`:

| Latest record | Next stage | Next role |
|---|---|---|
| `goal_record` | routing_and_assignment | Dispatcher |
| `dispatch_instruction` | context_gathering or action | Researcher (if package is research) or assigned role |
| `context_summary` | action | Builder or Runtime per Dispatcher plan |
| `action_record` | verification | Verifier |
| `verdict` status `red` | routing_and_assignment (rework) | Dispatcher |
| `verdict` status `blocked` | blocked | owning role re-checks unblock condition |
| `verdict` status `green` | recording_and_archival | Archivist |
| `hand_off_record` | action / verification per hand-off | receiving role |
| `pending_authorisation` | action | Builder/Runtime after user approval |
| `archival_record` | hand_off_or_closure | none — goal is closed; report only |

If a new `action_record` is stored after an `archival_record` for the same `goal_id`, the archival record is superseded and the goal returns to Action.

## Fallback if MCP is unavailable

If the Eden-memory MCP tools are unavailable, use the `/eden-*` fallback slash commands or invoke `eden-memory` directly from Bash. Restart Claude Code after `eden-memory setup claude` if commands are missing.
