---
title: Record kinds and schema
description: The durable records that link an ATP goal lifecycle together, what each kind means, and the common metadata they share.
content_type: concept
---

# Record kinds and schema

ATP does not keep state in the conversation. Every milestone is written to eden-memory as a durable record. Each record has a `kind` and a common metadata schema so later sessions, subagents, and headless supervisors can recall the full lifecycle.

## Common metadata

Every record should include these fields so it can be traced:

```json
{
  "goal_id": "<uuid-or-slug>",
  "stage": "goal_receipt | routing_and_assignment | context_gathering | action | verification | recording_and_archival | hand_off_or_closure | escalation | charter_ratification",
  "owner_role": "dispatcher | researcher | builder | runtime | verifier | archivist | router",
  "owner_instance": "<optional-instance-id>",
  "input_record_ids": ["<id>"],
  "output_record_ids": ["<id>"],
  "verdict_id": "<id-when-applicable>"
}
```

`input_record_ids` and `output_record_ids` are the links that turn a pile of notes into a replayable chain. Store them on every record, even on small context summaries.

## Record kinds

### `goal_record`

The first record of every goal. It captures the request, requester, constraints, and package type.

| Field | Purpose |
|-------|---------|
| `goal_id` | Stable identifier for the whole lifecycle. |
| `requester` | Who asked for the goal (user, scheduler, another role). |
| `constraints` | Guardrails that apply to this goal. |
| `package_type` | `research`, `build`, `run`, `verify`, or `archive`. |
| `stage` | `goal_receipt`. |
| `owner_role` | `dispatcher`. |

### `dispatch_instruction`

The Dispatcher assigns the goal to a role, sets a deadline, defines success criteria, and records an escalation trigger.

| Field | Purpose |
|-------|---------|
| `target_role` | Role that will own the next stage. |
| `owner` | Optional named owner or instance. |
| `deadline` | ISO-8601 deadline. |
| `success_criteria` | What "done" looks like for the next stage. |
| `escalation_trigger` | When to escalate (e.g., build failure, external dependency blocked). |
| `stage` | `routing_and_assignment`. |
| `owner_role` | `dispatcher`. |

### `context_summary`

The Researcher writes this before a decision is made. It contains the question, sources consulted, options considered, trade-offs, confidence, and a recommended next step.

| Field | Purpose |
|-------|---------|
| `question` | The decision the summary is meant to inform. |
| `sources` | Files read, searches run, external references. |
| `options` | Approaches considered and rejected or selected. |
| `trade_offs` | Why the chosen path was selected. |
| `recommended_next_step` | Usually "dispatch to Builder with scope X". |
| `stage` | `context_gathering`. |
| `owner_role` | `researcher`. |

### `action_record`

Builder or Runtime writes this after doing the work. It documents what changed, how to roll back, and what still needs verification.

| Field | Purpose |
|-------|---------|
| `summary` | Human-readable description of the change. |
| `files_changed` | Paths affected, for code or docs changes. |
| `rollback_steps` | How to undo the change if needed. |
| `build_result` | Test/build outcome when applicable. |
| `phase` | Optional phase marker for multi-phase goals. |
| `stage` | `action`. |
| `owner_role` | `builder` or `runtime`. |

### `verdict`

The Verifier compares the outcome against the dispatch success criteria and writes a green, red, or blocked verdict.

| Field | Purpose |
|-------|---------|
| `status` | `green`, `red`, or `blocked`. |
| `evidence` | What was checked and what was found. |
| `scope_verified` | What the verdict covers. |
| `scope_not_verified` | What was not checked. |
| `residual_risks` | Risks that remain after the verdict. |
| `stage` | `verification`. |
| `owner_role` | `verifier`. |

### `escalation_record`

Written when a goal is blocked, risky, or needs authority beyond the current owner. It records the reason, consulted roles, recommended default, and the question or authority requested.

| Field | Purpose |
|-------|---------|
| `reason` | Why the goal cannot proceed. |
| `consulted_roles` | Roles already asked for input. |
| `recommended_default` | Suggested resolution. |
| `question` | Specific authority or decision requested. |
| `risk_of_waiting` | Impact of delay. |
| `stage` | `escalation`. |
| `owner_role` | `dispatcher`. |

### `charter_ratification`

Produced by `/team-charter` when a project charter is approved. It contains a SHA-256 version hash of the charter content so future goals can confirm which guardrails were in force.

| Field | Purpose |
|-------|---------|
| `charter_path` | File that was ratified. |
| `version` | Short SHA-256 hash of the charter content. |
| `rater` | Who or what approved it. |
| `status` | `proceed` or `no-proceed`. |
| `stage` | `charter_ratification`. |
| `owner_role` | `archivist`. |

### `archival_record`

The Archivist writes this when a goal closes. It links the full chain and captures the final outcome and any reusable conventions.

| Field | Purpose |
|-------|---------|
| `outcome` | Summary of what happened and why. |
| `conventions` | Updated skills or runbooks if reusable patterns emerged. |
| `stage` | `recording_and_archival`. |
| `owner_role` | `archivist`. |

### `hand_off_record`

Used whenever ownership of a goal moves from one role to another, including at the end of `/team-handoff` and when `/team-continue` dispatches the next role. It preserves the latest stage, success criteria, deadline, and escalation trigger so the receiving role can resume without chat history.

| Field | Purpose |
|-------|---------|
| `from_role` | Role transferring ownership. |
| `to_role` | Role receiving ownership. |
| `reason` | Why the hand-off is happening. |
| `current_stage` | Stage at hand-off time. |
| `success_criteria` | Copied from the latest dispatch instruction. |
| `deadline` | Copied from the latest dispatch instruction. |
| `escalation_trigger` | Copied from the latest dispatch instruction. |
| `stage` | `hand_off_or_closure`. |
| `owner_role` | The transferring role. |

## How the kinds connect

A typical build goal leaves this chain:

```text
goal_record
    ↓
dispatch_instruction
    ↓
context_summary  (optional, for non-trivial goals)
    ↓
action_record
    ↓
verdict
    ↓
archival_record  or  hand_off_record
```

Escalations and charter ratifications sit outside this main chain but are linked by `goal_id` or project path so status checks can find them.

## What not to store

- Secrets, tokens, or credentials.
- Raw command output that could contain secrets.
- Ephemeral reasoning that is not load-bearing.
- Unvalidated guesses.

Store these in the record content itself or in file attachments, never in eden-memory.

## See also

- [Lifecycle](/agentic-team-protocol/lifecycle/) — the seven stages these records map to.
- [Agent prompts](/agentic-team-protocol/reference/agent-prompts/) — which role produces each record.
- [Slash commands](/agentic-team-protocol/reference/slash-commands/) — how to start, continue, and escalate goals.
