---
name: team
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
3. **Context gathering** — Researcher (or assigned role) records what is known, evaluates options, chooses a path, and captures any written plan. Planning is not a private activity; it belongs in this durable record.
4. **Action** — Builder or Runtime executes the plan and records what was done, rollback options, and state changes. A role may park the goal as `pending_authorisation` if it needs explicit user approval before proceeding.
5. **Verification** — Verifier inspects outcome against success criteria and writes a verdict (`green`, `red`, or `blocked`).
6. **Recording and archival** — Archivist ensures final outcome, decision trail, and skill/runbook updates are stored.
7. **Hand-off or closure** — Archivist confirms records are complete and ownership is transferred if handing off. A new action record after closure supersedes the closure and returns the goal to Action.

### Resumable sub-states

- `blocked` — waiting on an external dependency or authority. The owning role records the unblock condition. The router checks it on every `/team-continue`.
- `pending_authorisation` — waiting on explicit user approval for a specific high-risk action outside routine charter authority (e.g., deleting a public release or modifying fleet-wide CI secrets). The exact question and prepared action are recorded so a new session can resume and apply the answer. Routine repository commit/push after a green Verifier verdict is not a pending_authorisation step.

## Routing rules and dispatcher defaults

- Every new goal starts with Dispatcher.
- Package types:
  - `research` → Researcher
  - `build` → Builder
  - `run` → Runtime
  - `verify` → Verifier
  - `archive` → Archivist
- Low confidence, missing authority, or tight deadline → escalate via `/team-escalate`.
- Builder and Runtime must not start without sufficient context and a visible plan (either in `context_summary` or `action_record`); request Researcher support if needed.
- When a session ends or a role is interrupted, the next session uses `/team-continue` (or the router subagent) to rehydrate the goal from Eden-memory and dispatch the correct next role.
- A `blocked` or `pending_authorisation` goal remains active until the recorded unblock/approval condition is satisfied; the router re-checks it on continuation.

## Automatic continuation within a session

After any role subagent writes its durable stage record and `hand_off_record` and returns to the parent assistant, the parent assistant must immediately continue the goal without asking the user. The parent must spawn the `router` subagent (or invoke `/team-continue ${GOAL_ID}`) so the router can read the latest Eden-memory records, determine the next required stage and role, and dispatch it.

The parent assistant must not ask "Shall I proceed?" or otherwise wait for user confirmation between normal lifecycle transitions.

Exceptions — pause and surface the situation to the user instead of auto-continuing only when the latest durable record indicates:

- `blocked` — waiting on an external dependency or authority.
- `pending_authorisation` — waiting on explicit user approval for a specific action.
- An explicit escalation is required (e.g., low confidence, missed deadline, or charter conflict).

For cross-session or cross-role transfers, the transferring role (or the Router when continuing) must also write a `hand_off_record`.

## Hand-off format

Every lifecycle transition must leave a durable `hand_off_record` (or an equivalent action/verdict/archival record that embeds the hand-off format) in Eden-memory before ownership changes. Chat history is not a hand-off.

Every hand-off must include:

- `goal_id`
- Current stage
- Owner role and instance
- Input record IDs (the latest durable stage records, not the `goal_id` itself)
- Output record IDs (the new hand-off/run_log/action record, or the receiving role's expected record)
- Next role
- Reason for the transfer
- Success criteria and deadline
- Escalation trigger (if any)

### Router obligation

When the Router spawns a role, it must first write a durable hand-off record (a `hand_off_record` or a continuation `run_log` with the full hand-off payload). This record is the activation signal that lets the receiving role recall the goal without depending on conversation context. If the spawned role fails to produce its expected downstream record, the Router writes a recovery record and reports the missing hand-off to the user.

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
  "status": "<in_progress | completed | blocked | pending_authorisation>",
  "plan_file_path": "<absolute path when a plan file exists; optional but strongly recommended>"
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
- **Dropped interrupted work** — always leave a `run_log` or durable record at the end of a turn so `/team-continue` can resume.
- **Implicit hand-offs** — transfer ownership through a promoted `hand_off_record` (or role record that includes the hand-off format), not chat history. The Router must write this record before spawning the next role.
- **Stale closures** — a new action record after closure supersedes it; do not assume an old `archival_record` is the final word.
- **Ghost planning** — capturing a plan only in a local file or chat history without referencing it from an Eden-memory record. Any plan file or detailed implementation plan must be referenced from `context_summary` or `action_record`.
- **Default-branch drift** — committing non-trivial work directly to `master`/`main` instead of using a feature branch.
- **Fast-forward erasure** — merging feature branches with fast-forward so the branch topology and parent SHAs are lost.
- **Force-push to default branch** — rewriting public default-branch history, which breaks the durable record chain.

## Scope resolution rules

1. Project-local charter (`<project>/.claude/agentic-team-charter.md`) overrides global charter.
2. Project-local agent definitions override global agents.
3. Project-local skill overrides global skill.
4. If a project has no `agentic-team-config.yaml`, the global skill is used and the global charter is ignored unless explicitly referenced.

## Branch discipline

- Non-trivial work must happen on a feature branch checked out from the project
  default branch. Trivial one-line fixes may be committed directly to the default
  branch.
- Merges into the default branch must be non-fast-forward merge commits that
  preserve both parent SHAs.
- Runtime is the only role that may create merge commits and push to the default
  branch, and only after a green Verifier verdict.
- Never force-push the default branch.

## Slash commands

- `/team-charter` — read the project's `agentic-team-charter.md`, store a ratification record, and report whether the team may proceed.
- `/team-status` — list active goals, current stage, owner role, latest record IDs, and continueable/blocked state.
- `/team-escalate` — collect goal, options, consulted roles, recommended default, specific question/authority requested, and risk of waiting; write an `escalation_record`.
- `/team-continue` — resume an unfinished goal from Eden-memory by rehydrating its state and dispatching the next required role.
- `/team-handoff` — transfer ownership of a goal to another role or instance in a durable `hand_off_record`.

## Using the subagents

Spawn the role subagent with its goal context. Each role subagent starts by recalling the latest `goal_record` for its assigned `goal_id`, then acts according to its contract, and finally writes a durable record to Eden-memory before handing off.

When a role subagent returns after writing its durable record and `hand_off_record`, the parent assistant must immediately continue the goal by spawning the `router` subagent (or invoking `/team-continue ${GOAL_ID}`). The parent must not ask the user "Shall I proceed?" between normal lifecycle transitions.

For cross-session or cross-role transfers, the transferring role (or the Router when continuing) must also write a `hand_off_record`.

For continuation, use the `router` subagent (or `/team-continue`) instead of manually picking a role. The router reads the latest Eden records for a `goal_id`, determines the required next stage and role using the lifecycle rules below, and invokes that role with full context.

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
