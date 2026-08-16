---
title: Slash commands
description: Reference for the seven global ATP slash commands — when to use them, what arguments they accept, and what they return.
content_type: reference
---

# Slash commands

The Agentic Team Protocol installs seven global slash commands into Claude Code. They are the user-facing control surface for starting, continuing, and governing goals.

| Command | Purpose | Mode |
|---------|---------|------|
| `/team` | Start or continue a goal in **Lite** mode. | lite |
| `/team-full` | Start or continue a goal in the **Full** protocol. | full |
| `/team-charter` | Ratify the project charter. | full / optional |
| `/team-status` | Show active goals and stages. | both |
| `/team-escalate` | Write an escalation record; can promote Lite to Full. | both |
| `/team-continue` | Resume an unfinished goal from eden-memory. | both |
| `/team-handoff` | Transfer goal ownership to another role. | both |

## `/team`

Top-level entry point for **Lite mode**. It is intentionally thin: it parses the argument and delegates to the Dispatcher or `/team-continue`.

**Usage**

```text
/team
/team <request>
/team <goal_id>
```

**Behaviour**

| Input | Action |
|-------|--------|
| No argument | Show status and ask for a goal. |
| UUID-like or contains `-` | Resume via `/team-continue`. |
| Any other text | Spawn the `dispatcher` subagent with the request in **Lite** mode. |

**Output**

- A `goal_record` with `mode: lite` stored in eden-memory.
- A `plan_record` combining routing, context, and success criteria.
- A hand-off to the `builder` subagent (or `runtime` for authorised live-system tasks).
- For non-trivial `build` or `run` goals, a dedicated git worktree under `.claude/worktrees/atp/` if `worktree_policy.enabled` is true.

## `/team-full`

Top-level entry point for the **full 6-role, 7-stage protocol**. Use for complex, risky, or heavily-audited goals.

**Usage**

```text
/team-full
/team-full <request>
/team-full <goal_id>
```

**Behaviour**

Same as `/team`, but starts the goal with `mode: full` and produces a `dispatch_instruction` followed by the full lifecycle (researcher, builder/runtime, verifier, archivist).

**Output**

- A `goal_record` with `mode: full`.
- A `dispatch_instruction`.
- A hand-off to the assigned role subagent.
- For non-trivial `build` or `run` goals, a dedicated git worktree under `.claude/worktrees/atp/` if `worktree_policy.enabled` is true.

## `/team-charter`

Reads the project charter and stores a ratification record.

**Usage**

```text
/team-charter
```

**What it does**

1. Finds `.claude/agentic-team-charter.md` (project-local) or falls back to `~/.claude/skills/team/CHARTER.md`.
2. Computes a SHA-256 version hash.
3. Checks for unresolved placeholders and role mismatches with `.claude/agentic-team-config.yaml`.
4. Stores a `charter_ratification` record in eden-memory.

**Output**

```text
Charter path: .claude/agentic-team-charter.md
Version: <16-char-sha>
Record ID: <uuid>
Status: proceed | no-proceed
```

## `/team-status`

Lists active goals, current stage, owner role, mode, latest record ID, and whether each goal is continueable, blocked, or closed.

**Usage**

```text
/team-status
/team-status <goal_id>
/team-status <role>
```

**Output columns**

| Column | Meaning |
|--------|---------|
| `goal_id` | Stable goal identifier. |
| `stage` | Current lifecycle stage. |
| `owner_role` | Role currently responsible. |
| `mode` | `lite` or `full`. |
| `latest_record_id` | Most recent durable record. |
| `deadline` | Dispatch deadline if recorded. |
| `state` | `active`, `blocked`, `pending_authorisation`, `continueable`, `closed`. |
| `Location` | Worktree path for the goal, or "main checkout". |

## `/team-escalate`

Writes a structured `escalation_record` and reports the escalation chain. In Lite mode, escalation often means promoting the goal to the full protocol.

**Usage**

```text
/team-escalate <goal_id: reason and options>
```

**What it captures**

- Goal ID and escalation reason.
- Current `mode` (`lite` or `full`).
- Whether to promote a Lite goal to full protocol.
- Consulted roles.
- Recommended default resolution.
- Specific question or authority requested.
- Risk of waiting.

**Output**

- An `escalation_record` in eden-memory.
- The assigned escalation level (1–4).
- The next authority in the chain.
- If `promote_to_full` is true, instructions to resume with `/team-full` or `/team-continue`.

## `/team-continue`

Resumes an unfinished goal by reading the latest records from eden-memory and dispatching the correct next role.

**Usage**

```text
/team-continue
/team-continue <goal_id>
```

**Behaviour by latest record**

| Latest record | Next action |
|---------------|-------------|
| `goal_record` | Route to Dispatcher for dispatch instruction. |
| `dispatch_instruction` | Route to assigned role. |
| `context_summary` | Route to Builder or Runtime per plan. |
| `action_record` | Route to Verifier. |
| `verdict` green | Route to Archivist for closure. |
| `verdict` red/blocked | Route to Dispatcher for rework or report blocker. |
| `hand_off_record` | Route to receiving role. |
| `archival_record` (no newer action) | Report goal is closed. |

**Output**

- A `run_log` continuation record.
- A check that the recorded `worktree_path` still exists, if one is present. If it does not exist, `/team-continue` asks whether to recreate the worktree or abort.
- A hand-off to the next role with the latest context and worktree location.

## `/team-handoff`

Transfers ownership of a goal to another role in a durable `hand_off_record`.

**Usage**

```text
/team-handoff <goal_id: to_role [reason]>
```

**Required fields**

- `goal_id`
- `to_role`: `dispatcher`, `researcher`, `builder`, `runtime`, `verifier`, `archivist`, or `router`
- `reason` (optional but recommended)

**What it copies**

The hand-off record copies `success_criteria`, `deadline`, and `escalation_trigger` from the latest dispatch instruction so the receiving role can continue without re-reading the full history. When the latest action record includes `worktree_path` and `branch_name`, those are also copied so the receiver starts in the correct checkout.

**Output**

- A `hand_off_record` in eden-memory.
- The receiving role subagent is spawned with the hand-off payload.

## See also

- [Run your first team goal](/agentic-team-protocol/tutorials/first-team-goal/) — `/team` and `/team-charter` in action.
- [Lifecycle](/agentic-team-protocol/lifecycle/) — the stages these commands move goals through.
- [Record kinds](/agentic-team-protocol/concepts/record-kinds/) — the records these commands read and write.
