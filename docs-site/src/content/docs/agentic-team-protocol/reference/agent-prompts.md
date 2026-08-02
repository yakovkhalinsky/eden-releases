---
title: Agent prompts
description: What each default ATP subagent prompt does and when to spawn it.
content_type: reference
---

# Agent prompts

The protocol is implemented as Claude Code subagents. Each role has a prompt file under `~/.claude/agents/` and a matching responsibility. Spawn the right subagent for the current lifecycle stage.

## Quick reference

| Role | File | Spawns when… |
|------|------|--------------|
| Dispatcher | `~/.claude/agents/dispatcher.md` | A new goal arrives or routing is needed. |
| Researcher | `~/.claude/agents/researcher.md` | Context must be gathered before a decision. |
| Builder | `~/.claude/agents/builder.md` | A concrete artefact needs to be produced. |
| Runtime | `~/.claude/agents/runtime.md` | Live systems need safe operational changes. |
| Verifier | `~/.claude/agents/verifier.md` | Work is ready to be validated. |
| Archivist | `~/.claude/agents/archivist.md` | A goal is closing and records need linking. |
| Router | `~/.claude/agents/router.md` | A previously interrupted goal needs resuming. |

## Dispatcher

**What it does:** Decides who does what. Every new goal starts here.

**Required outputs:**

- A `goal_record` with `goal_id`, requester, constraints, and package type.
- A `dispatch_instruction` with target role, owner, deadline, success criteria, and escalation trigger.

**When to spawn:**

- A user types `/team` with a new request.
- A headless supervisor receives a new goal.
- A goal needs re-routing after a blocked or red verdict.

## Researcher

**What it does:** Gathers context before decisions are made.

**Required outputs:**

- A `context_summary` containing the question, sources consulted, options considered, trade-offs, confidence, and recommended next step.

**When to spawn:**

- The Dispatcher needs options before assigning a build or run task.
- A non-trivial goal has unknown constraints or dependencies.
- The Builder needs background research before implementation.

## Builder

**What it does:** Produces durable, reviewable artefacts.

**Required outputs:**

1. The artefact itself (code, config, doc, test, etc.).
2. A change summary with rationale, record IDs, merge instructions, and follow-up steps.
3. An `action_record` in eden-memory with `goal_id`, `stage: action`, `owner_role: builder`, `input_record_ids`, and `output_record_ids`.

**When to spawn:**

- A `dispatch_instruction` assigns a build package.
- A `context_summary` recommends a concrete implementation.

## Runtime

**What it does:** Executes operational actions safely on live systems.

**Required outputs:**

1. An ordered execution plan.
2. A rollback/recovery plan for each step.
3. Observed state before and after execution.
4. Health evidence.
5. An `action_record` in eden-memory.

**When to spawn:**

- A `dispatch_instruction` assigns a run package.
- A goal requires deploys, infrastructure changes, or data migrations.
- The charter explicitly authorises Runtime for live operations.

**Important:** Runtime is gated by default. Do not spawn it for live operations unless the project charter authorises it.

## Verifier

**What it does:** Validates work before it is accepted.

**Required outputs:**

- A `verdict` record with status `green`, `red`, or `blocked`.
- Evidence supporting the verdict.
- Scope of what was verified and what was not.
- Residual risks and recommended mitigations.

**When to spawn:**

- A Builder or Runtime action record is ready for review.
- The success criteria are objective enough to inspect.

**Rule:** A role must not verify its own work.

## Archivist

**What it does:** Maintains durable, searchable fleet memory.

**Required outputs:**

1. Canonical records for the final outcome and decision trail.
2. Searchable links between related records.
3. Updated skills/runbooks if a reusable convention emerged.
4. A closure record with `goal_id`, `stage: recording_and_archival`, `owner_role: archivist`, `input_record_ids`, and `output_record_ids`.
5. For hand-offs, an ownership transfer record.

**When to spawn:**

- A green `verdict` is ready for closure.
- A goal needs to be handed off to another session or role.
- Reusable conventions need to be captured in project skills.

## Router

**What it does:** Resumes interrupted or unfinished goals by reading eden-memory and dispatching the correct next role.

**Required outputs:**

1. A `run_log` record marking the continuation attempt.
2. A clear decision: which role should act next and why.
3. A hand-off payload containing `goal_id`, inferred stage, next role, latest record IDs, success criteria, and any escalation trigger.

**When to spawn:**

- `/team-continue` is invoked with a `goal_id`.
- A headless supervisor needs to resume a partially completed goal.
- The conversation was interrupted before a role finished.

## Spawning a subagent

Spawn the role with its `goal_id` and the latest record IDs. Each subagent starts by recalling the latest `goal_record` for its assigned goal, then acts according to its contract, and finally writes a durable record in eden-memory before handing off.

## Fallback

If the eden-memory MCP tools are unavailable, use the `/eden-*` fallback slash commands or invoke `eden-memory` directly from Bash. Restart Claude Code after `eden-memory setup claude` if commands are missing.

## See also

- [Lifecycle](/agentic-team-protocol/lifecycle/) — the seven-stage flow these roles implement.
- [Record kinds](/agentic-team-protocol/concepts/record-kinds/) — the records each role is responsible for producing.
- [Set up a headless supervisor](/agentic-team-protocol/tutorials/headless-supervisor/) — running these subagents from a script or scheduler.
