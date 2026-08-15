---
name: team
title: Agentic Team Protocol
description: Use role-based agent teams with a seven-stage task lifecycle and Eden-memory as the durable substrate.
version: 1.0.1
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

## Setup

Quick install for the global primitives:

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh
```

Detailed steps:

1. Install `eden-memory` and make sure it is on your `PATH`:
   ```bash
   curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
   ```
2. Install the global ATP primitives:
   ```bash
   curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh
   ```
3. In every project where you will use ATP, wire the Eden-memory MCP server:
   ```bash
   cd ~/your-project
   eden-memory setup claude
   ```
4. Install the project-local ATP templates:
   ```bash
   curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh -s -- --local
   ```
5. Restart Claude Code completely so the MCP server, agents, and slash commands load.

## Per-role model configuration

Each agent prompt file starts with a YAML frontmatter block that declares a default `model` and `effort`:

```yaml
---
name: builder
model: sonnet
# model: ollama:kimi-k2.7-code:cloud
effort: medium
---
```

- `model` is the default Claude Code CLI model alias for the role.
- `effort` is passed to Claude Code CLI as `--effort` (`low`, `medium`, or `high`).
- Commented lines show the recommended Ollama Cloud alternative.

### Interactive Claude Code agents

For the default interactive agents, the recommended defaults are:

| Role | Default model | Default effort |
|------|---------------|----------------|
| Dispatcher | `sonnet` | `medium` |
| Router | `sonnet` | `medium` |
| Researcher | `opus` | `high` |
| Builder | `sonnet` | `medium` |
| Runtime | `sonnet` | `medium` |
| Verifier | `opus` | `high` |
| Archivist | `sonnet` | `medium` |

### Headless `eden-team` supervisor

The `eden-team` binary resolves the effective model per role in this order:

1. `ATP_<ROLE>_MODEL`, `ATP_<ROLE>_BACKEND`, `ATP_<ROLE>_EFFORT` environment variables.
2. `--role-model role=backend:model` CLI flag.
3. `ATP_DEFAULT_MODEL` / `ATP_DEFAULT_BACKEND`.
4. Role prompt frontmatter.

Use `backend:model` form for cross-backend values, e.g. `anthropic:sonnet`, `ollama:kimi-k2.7-code:cloud`.

### Env-file precedence

`eden-team` loads environment files without polluting the parent process:

1. Explicit `--env-file` or `ATP_ENV_FILE`.
2. Project-level `$PWD/.env`.
3. Global `~/.eden-memory/.env`.
4. Process environment variables.
5. CLI flags.
6. Role prompt frontmatter.

Run `eden-memory setup claude` in a project to generate or update the project `.env` with seed keys and per-role model comments.

### Ollama Cloud wiring

To target Ollama Cloud, set the Anthropic-compatible endpoint and authenticate with your Ollama API key:

```bash
export ANTHROPIC_BASE_URL=https://ollama.com
export ANTHROPIC_AUTH_TOKEN=$OLLAMA_API_KEY
export ANTHROPIC_API_KEY=
```

`eden-team` ensures these variables are forwarded to every child `claude` process and validates that `ANTHROPIC_AUTH_TOKEN` is set for any role using the `ollama` backend.

## Core idea

The Agentic Team Protocol (ATP) defines role contracts and a durable memory trail for agent teams. The **Verifier gate is mandatory before any goal is closed**. By default, `/team` now uses **Lite mode**: a lightweight 4-stage path that reuses the same six agents but suppresses the ones not needed for everyday tasks. For complex, risky, or heavily-audited work, escalate to the **Full protocol** via `/team-full`.

## Lite mode (default for `/team`)

Lite mode is designed for the common case: a well-scoped request that fits in a single session and does not need heavy research, live-system runtime work, or formal charter ratification. It keeps the contracts and the durable trail, but folds context gathering into planning and archives straight after verification.

### Lite roles

| Lite role | Full agent(s) used | Obligation |
|-----------|-------------------|------------|
| `planner` | `dispatcher` | Records the goal, evaluates context, chooses an approach, and writes the plan. In Lite, the dispatcher absorbs the `researcher` context-gathering step for everyday tasks. |
| `maker` | `builder` (or `runtime` for live-system work) | Executes the plan and records what changed, including rollback options. |
| `checker` | `verifier`, then `archivist` | Verifies the outcome, then closes the durable record trail. |

### Lite lifecycle

1. **Goal receipt** — planner records the request.
2. **Plan** — planner writes a `plan_record` (routing + context + success criteria).
3. **Act** — maker executes and writes an `action_record`.
4. **Check** — verifier writes a `verdict`; archivist writes the terminal `archival_record`.

### When Lite is enough

- Small to medium implementation tasks.
- Low-risk local development or documentation changes.
- Tasks that need a clear trail but not a research phase or formal runtime gate.

### When to use the full protocol (`/team-full`)

- The goal requires explicit research before action.
- It touches production, live systems, or security-sensitive surfaces.
- Multiple owners, sessions, or audit checkpoints are expected.
- Charter ratification, non-fast-forward branch discipline, or formal escalation is required.

## Full protocol

Use `/team-full` to run the original 6-role, 7-stage lifecycle. The full protocol is unchanged: every goal passes through goal receipt, routing and assignment, context gathering, action, verification, recording and archival, and hand-off or closure. The dispatcher, researcher, builder, runtime, verifier, and archivist each have their own turn.

## Roles

| Role | Obligation | Subagent |
|------|------------|----------|
| Dispatcher | Decides who does what | `dispatcher` |
| Researcher | Gathers context before decisions | `researcher` |
| Builder | Produces durable, reviewable artefacts | `builder` |
| Runtime | Operates live systems safely | `runtime` |
| Verifier | Validates work before acceptance | `verifier` |
| Archivist | Maintains durable, searchable fleet memory | `archivist` |

## Full protocol: seven-stage lifecycle

The full `/team-full` lifecycle is unchanged:

1. **Goal receipt** — Dispatcher records the request, requester, constraints, and package type.
2. **Routing and assignment** — Dispatcher assigns target role/package, owner, deadline, success criteria, confidence/escalation trigger.
3. **Context gathering** — Researcher (or assigned role) records what is known, evaluates options, chooses a path, and captures any written plan. Planning is not a private activity; it belongs in this durable record.
4. **Action** — Builder or Runtime executes the plan and records what was done, rollback options, and state changes. A role may park the goal as `pending_authorisation` if it needs explicit user approval before proceeding. If a role created temporary files, subprocesses, ports, or leases during a non-trivial turn, it may emit a `cleanup_record` with `stage: cleanup` documenting what was released before handing off to Verifier.
5. **Verification** — Verifier inspects outcome against success criteria and writes a verdict (`green`, `red`, or `blocked`).
6. **Recording and archival** — Archivist ensures final outcome, decision trail, and skill/runbook updates are stored.
7. **Hand-off or closure** — Archivist confirms records are complete and ownership is transferred if handing off. A new action record after closure supersedes the closure and returns the goal to Action.

### Resumable sub-states

- `blocked` — waiting on an external dependency or authority. The owning role records the unblock condition. The router checks it on every `/team-continue`.
- `pending_authorisation` — waiting on explicit user approval for a specific high-risk action outside routine charter authority (e.g., deleting a public release or modifying fleet-wide CI secrets). The exact question and prepared action are recorded so a new session can resume and apply the answer. Routine repository commit/push after a green Verifier verdict is not a pending_authorisation step.
- `cleanup_record` — an optional cleanup stage after a non-trivial action. The role that performed the action documents what temporary resources were released; the router routes the goal to Verifier so the claimed releases can be confirmed.

## Routing rules and dispatcher defaults

- Every new goal starts with Dispatcher.
- In **Lite mode**, the dispatcher also performs everyday context gathering and writes a `plan_record`. It routes directly to `builder` unless the task is obviously live-system or security-sensitive, in which case it routes to `runtime` or escalates to `/team-full`.
- In **Full mode**, package types are:
  - `research` → Researcher
  - `build` → Builder
  - `run` → Runtime
  - `verify` → Verifier
  - `archive` → Archivist
- Low confidence, missing authority, or tight deadline → escalate via `/team-escalate` (Lite goals that need research or formal runtime gating are promoted to full protocol).
- Builder and Runtime must not start without sufficient context and a visible plan (either in `plan_record`, `context_summary`, or `action_record`); request Researcher support if needed.
- When a session ends or a role is interrupted, the next session uses `/team-continue` (or the router subagent) to rehydrate the goal from Eden-memory and dispatch the correct next role using the stored `mode`.
- A `blocked` or `pending_authorisation` goal remains active until the recorded unblock/approval condition is satisfied; the router re-checks it on continuation.

## Automatic continuation within a session

After any role subagent writes its durable stage record and `hand_off_record` and returns to the parent assistant, the parent assistant must immediately continue the goal without asking the user. The parent must spawn the `router` subagent (or invoke `/team-continue ${GOAL_ID}`) so the router can read the latest Eden-memory records, determine the next required stage and role, and dispatch it.

The parent assistant must not ask "Shall I proceed?" or otherwise wait for user confirmation between normal lifecycle transitions.

Exceptions — pause and surface the situation to the user instead of auto-continuing only when the latest durable record indicates:

- `blocked` — waiting on an external dependency or authority.
- `pending_authorisation` — waiting on explicit user approval for a specific action.
- An explicit escalation is required (e.g., low confidence, missed deadline, or charter conflict).

### Parent assistant continuation checklist

1. Read the latest Eden-memory record for the `goal_id`.
2. If it is `blocked`, `pending_authorisation`, or an `escalation_record`, stop and surface the situation to the user.
3. Otherwise, immediately spawn the `router` subagent or invoke `/team-continue ${GOAL_ID}`.
4. Do not ask "Shall I proceed?" between normal lifecycle transitions.

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

Store records with metadata so they can be recalled, linked, and audited. Every durable record must also begin its `content` with a searchable identity line because `eden_recall` and `eden_search` inspect `content`, not metadata:

```text
Goal: <goal_id> | Record ID: <this_record_id> | Stage: <stage> | Owner: <owner_role>
```

The identity line embeds both `goal_id` and the record's own UUID in searchable text. If the storage tool returns the record ID after creation, update the content to insert the actual UUID.

```json
{
  "goal_id": "<uuid>",
  "stage": "goal_receipt | routing_and_assignment | context_gathering | action | verification | recording_and_archival | hand_off_or_closure | blocked | pending_authorisation | cleanup",
  "owner_role": "dispatcher | researcher | builder | runtime | verifier | archivist | router",
  "owner_instance": "<optional instance id>",
  "input_record_ids": ["<id>"],
  "output_record_ids": ["<id>"],
  "recalled_memory_ids": ["<id>"],
  "verdict_id": "<id when applicable>",
  "status": "<in_progress | completed | blocked | pending_authorisation>",
  "plan_file_path": "<absolute path when a plan file exists; optional but strongly recommended>"
}
```

Every durable record that relies on recalled Eden-memory context must include `recalled_memory_ids`: the IDs of the memories that shaped the record. This applies to `context_summary`, `action_record`, `verdict`, and any other record written after an `eden_recall` or `eden_search` call.

Use the clean role name as `agent_id` for all ATP role records (e.g., `dispatcher`, `researcher`, `builder`, `runtime`, `verifier`, `archivist`, `router`).

Required record types:

- `goal_record` — initial request and constraints.
- `dispatch_instruction` — routing decision from Dispatcher (full protocol).
- `context_summary` — findings from Researcher (full protocol).
- `plan_record` — Lite-only combined routing + context + success-criteria record written by the dispatcher.
- `action_record` — what Builder or Runtime did.
- `verdict` — green/red/blocked from Verifier with evidence.
- `escalation_record` — escalation request and routing.
- `archival_record` — final outcome and links.
- `run_log` — coarse-grained event written by a role at the start/end of each turn; used by the router to detect stale or interrupted work.
- `cleanup_record` — release and evidence for temporary resources (files, subprocesses, ports, leases) created during a role's turn. Not a terminal record; the goal still requires a `green` verdict before closure.
- `hand_off_record` — explicit ownership transfer between roles or instances, including input/output IDs, success criteria, and deadline.

Every goal record should include `mode: lite | full` in its metadata. The router and `/team-continue` use this to choose the correct lifecycle table. If `mode` is absent on an older goal, default to `full` to avoid breaking in-flight full-protocol goals.

## Memory-first rules

- Immediately after receiving a task, call `eden_recall` with the task summary.
- Before any decision that touches user preferences, coding style, security, tooling, or project conventions, call `eden_recall` first.
- When reviewing `eden_recall` results, only treat a memory as relevant if its score is ≥ 0.45. For low scores, call `eden_search` or ask the user.
- After corrections, working solutions, or settled conventions, call `eden_remember`.
- At the end of every task, batch 3–5 durable takeaways into `eden_remember` calls.
- Do not remember secrets, tokens, raw command output, ephemeral reasoning, or unvalidated guesses.
- If Eden-memory MCP tools are unavailable, use the `/eden-*` fallback slash commands.

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
- After a successful non-fast-forward merge into the default branch and push to
  origin, Runtime must delete the local feature branch (`git branch -d
  <branch>`). If authorized and the branch is not protected, Runtime must also
  delete the remote branch (`git push origin --delete <branch>`). Runtime records
  the deleted branch names, post-merge default-branch SHA, and any skip reason in
  the action record.
- Protected/long-lived branches must never be deleted (default branch,
  `release/*`, `hotfix/*`, etc.).
- In headless/eden-team workflows, skip local deletion if the working copy is
  not on the feature branch (e.g., detached or shallow checkout) and record
  `headless_skip_local: true`.
- Never force-push the default branch.

## Slash commands

- `/team [goal]` — start or continue a goal in **Lite mode** (default). The dispatcher acts as planner and routes directly to builder for everyday tasks.
- `/team-full [goal]` — start or continue a goal in the **Full protocol** with the complete 6-role, 7-stage lifecycle.
- `/team-charter` — read the project's `agentic-team-charter.md`, store a ratification record, and report whether the team may proceed (full protocol / charter-heavy projects).
- `/team-status` — list active goals, current stage, owner role, latest record IDs, mode (`lite`/`full`), and continueable/blocked state.
- `/team-escalate` — collect goal, options, consulted roles, recommended default, specific question/authority requested, and risk of waiting; write an `escalation_record`. In Lite mode, escalation also promotes the goal to the full protocol.
- `/team-continue [goal_id]` — resume an unfinished goal from Eden-memory by rehydrating its state and dispatching the next required role. Uses the goal's stored `mode` to pick the correct lifecycle table.
- `/team-handoff` — transfer ownership of a goal to another role or instance in a durable `hand_off_record`.

## Using the subagents

Spawn the role subagent with its goal context. Each role subagent starts by recalling the latest `goal_record` for its assigned `goal_id`, then acts according to its contract, and finally writes a durable record to Eden-memory before handing off.

When a role subagent returns after writing its durable record and `hand_off_record`, the parent assistant must immediately continue the goal by spawning the `router` subagent (or invoking `/team-continue ${GOAL_ID}`). The parent must not ask the user "Shall I proceed?" between normal lifecycle transitions. For the full checklist, see [Automatic continuation within a session](#automatic-continuation-within-a-session).

For cross-session or cross-role transfers, the transferring role (or the Router when continuing) must also write a `hand_off_record`.

For continuation, use the `router` subagent (or `/team-continue`) instead of manually picking a role. The router reads the latest Eden records for a `goal_id`, determines the required next stage and role using the lifecycle rules below, and invokes that role with full context.

### Router lifecycle rules

The router first reads the goal's `mode` metadata. If `mode` is `lite` (or the goal uses Lite-specific records such as `plan_record`), it applies the Lite table. Otherwise it applies the Full table.

#### Lite mode decision table

| Latest record | Next stage | Next role |
|---|---|---|
| `goal_record` | plan | Dispatcher (as planner) |
| `plan_record` | action | Builder |
| `action_record` | verification | Verifier |
| `cleanup_record` | verification | Verifier |
| `verdict` status `red` | plan (rework) | Dispatcher |
| `verdict` status `blocked` | blocked | owning role re-checks unblock condition |
| `verdict` status `green` | recording_and_archival | Archivist |
| `hand_off_record` | action / verification per hand-off | receiving role |
| `pending_authorisation` | action | Builder after user approval |
| `archival_record` | hand_off_or_closure | none — goal is closed; report only |

#### Full protocol decision table

| Latest record | Next stage | Next role |
|---|---|---|
| `goal_record` | routing_and_assignment | Dispatcher |
| `dispatch_instruction` | context_gathering or action | Researcher (if package is research) or assigned role |
| `context_summary` | action | Builder or Runtime per Dispatcher plan |
| `action_record` | verification | Verifier |
| `cleanup_record` | verification | Verifier |
| `verdict` status `red` | routing_and_assignment (rework) | Dispatcher |
| `verdict` status `blocked` | blocked | owning role re-checks unblock condition |
| `verdict` status `green` | recording_and_archival | Archivist |
| `hand_off_record` | action / verification per hand-off | receiving role |
| `pending_authorisation` | action | Builder/Runtime after user approval |
| `archival_record` | hand_off_or_closure | none — goal is closed; report only |

If a new `action_record` is stored after an `archival_record` for the same `goal_id`, the archival record is superseded and the goal returns to Action.

## Headless supervisor

For automated or scheduled goals, use the `eden-team` binary from the `eden-memory` monorepo instead of an interactive Claude Code session. `eden-team` defaults to Lite mode (`--mode lite`) for everyday goals; use `--mode full` for the complete 6-role lifecycle. It writes the ATP lifecycle records to Eden-memory and spawns Claude Code CLI subagent processes for each role.

Example (Lite mode):

```bash
cd /home/yakov/git/eden-memory
make build-team
./eden-team start \
  --goal "Refactor the login handler to use table-driven tests" \
  --mode lite \
  --mcp-config ./mcp.json \
  --dangerously-skip-permissions \
  --verbose
```

Example (Full protocol):

```bash
./eden-team start \
  --goal "Audit production certificate rotation process" \
  --mode full \
  --mcp-config ./mcp.json \
  --dangerously-skip-permissions \
  --verbose
```

Resume an interrupted goal with `eden-team continue --goal-id <goal-id> --mcp-config ./mcp.json` (the mode is read from the goal record).

## Fallback if MCP is unavailable

If the Eden-memory MCP tools are unavailable, use the `/eden-*` fallback slash commands or invoke `eden-memory` directly from Bash. Restart Claude Code after `eden-memory setup claude` if commands are missing.
