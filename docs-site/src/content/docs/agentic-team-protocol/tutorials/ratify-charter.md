---
title: Ratify a project charter
description: Run the interactive /team-charter checklist, resolve placeholders and role mismatches, and store a durable ratification record in eden-memory.
content_type: tutorial
---

# Ratify a project charter

A charter is the contract between you and the agentic team. Before any ATP goal is dispatched, a charter must be ratified and stored as a durable `charter_ratification` record in eden-memory. `/team-charter` now walks you through an interactive checklist so you can resolve placeholders, confirm guardrails, and ratify with confidence.

## Prerequisites

- ATP global primitives installed (see the [first team goal](/agentic-team-protocol/tutorials/first-team-goal/) tutorial).
- A project with `.claude/agentic-team-charter.md` (created by `./install.sh --local` or copied manually).
- eden-memory installed and configured.

## Step 1 — Open the charter template

The project-local charter lives at:

```text
.claude/agentic-team-charter.md
```

If it does not exist, copy it from the package templates:

```bash
mkdir -p .claude
cp /path/to/eden-releases/agentic-team-protocol/templates/agentic-team-charter.md .claude/agentic-team-charter.md
```

## Step 2 — Replace every placeholder

Edit the file and fill in each section:

| Section | What to write |
|---------|---------------|
| **Identity** | Project name, path, and one-line purpose. |
| **Mission** | A single sentence describing what success looks like. |
| **Boundaries** | Hard guardrails: no destructive live operations, no secrets in memory, Runtime gated unless authorised. |
| **Roles/seats** | Active roles and whether Runtime is gated. |
| **Decision rights** | Who decides routing, implementation, verdicts, live ops, and user overrides. |
| **Escalation paths** | Chain from owning role to Dispatcher, chair, and founders. |
| **Branch discipline** | Feature-branch rules, merge-commit style, and Runtime authority. |
| **Worktree discipline** | Worktree-per-goal rules when `worktree_policy.enabled` is true. |
| **Interfaces** | eden-memory path, global skill path, project-local skill override. |
| **Runbooks owned** | Files the Archivist should keep up to date. |
| **Status cadence** | How often to run `/team-status`. |
| **Retirement condition** | How to stop using ATP for this project. |

Common guardrails to keep:

- Do not perform destructive actions on external or live systems without explicit authorisation.
- Secrets, tokens, and credentials must never be stored in eden-memory or conversation logs.
- Runtime is gated unless explicitly authorised by this charter.

## Step 3 — Verify the active roles match

Open `.claude/agentic-team-config.yaml` and confirm the roles listed there are the same roles marked active in the charter. Mismatches cause `/team-charter` to flag the delta in the interactive checklist.

Example active set:

```yaml
active_roles:
  - dispatcher
  - researcher
  - builder
  - verifier
  - archivist
```

## Step 4 — Run the interactive checklist

In Claude Code, run:

```text
/team-charter
```

The command enters a three-phase flow:

1. **Discovery** — it locates the charter, computes a full SHA-256 hash, scans for placeholders, reads active roles from the config, resolves the Eden-memory workspace identity, and fetches any prior ratification record.
2. **Checklist** — it presents each validation as an item you can confirm, defer, or fix:
   - Charter file located
   - Version hash
   - Placeholders resolved
   - Template example text removed
   - Active roles match between config and charter
   - Runtime gating is explicit
   - Default branch is stated
   - `org_id`, `workspace_id`, and `agent_id` resolved
   - Re-ratification diff (if a prior record exists)
3. **Ratification** — after your final confirmation, it stores a `charter_ratification` record and reports `proceed` or `no-proceed`.

You can edit the charter from inside the checklist. After any edit the command recomputes the hash and returns to the checklist.

**Example output:**

```text
Charter path: /home/yakov/my-project/.claude/agentic-team-charter.md
Version: 9f86d081884c7d65 (full SHA-256 in record metadata)
Record ID: <uuid>
Status: proceed
Deferrals: none
```

If blockers remain, the status is `no-proceed` and the reason is shown:

```text
Charter path: .claude/agentic-team-charter.md
Version: 7d865e959b246691
Record ID: <uuid>
Status: no-proceed
Reason: unresolved placeholder <PROJECT_NAME> at line 1
```

## Step 5 — Inspect the ratification record

Retrieve the record with the eden-memory CLI:

```bash
eden-memory search \
  --agent-id claude-code-cli \
  --user-id "$(id -un)" \
  --keywords "charter_ratification" \
  --limit 10
```

Each ratification record contains metadata like:

```json
{
  "kind": "charter_ratification",
  "stage": "charter_ratification",
  "goal_id": "charter-ratification",
  "owner_role": "archivist",
  "charter_path": "/home/yakov/my-project/.claude/agentic-team-charter.md",
  "charter_version": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
  "proceed": true,
  "deferrals": []
}
```

The record content also stores the charter version, the rater, the ratification timestamp, and any deferrals.

## Step 6 — Amend and re-ratify

When you change the charter, re-run `/team-charter`. The command detects the prior ratification, shows the old version hash, and asks you to confirm the new ratification.

**Expected output after re-ratification:**

```text
Charter path: .claude/agentic-team-charter.md
Version: 7d865e959b246691 (was 9f86d081884c7d65)
Record ID: <new-uuid>
Status: proceed
Previous record: <old-uuid>
```

The Archivist should keep an amendment log linking the old and new versions.

## Non-interactive mode

For CI or expert users, bypass the checklist with:

```text
/team-charter --non-interactive
```

Or set the environment variable:

```bash
export ATP_NON_INTERACTIVE=1
```

In non-interactive mode the command runs the original deterministic flow: locate, hash, validate, store, report.

## Expected final state

- `.claude/agentic-team-charter.md` contains no unresolved placeholders.
- `.claude/agentic-team-config.yaml` lists the same active roles as the charter.
- eden-memory contains at least one `charter_ratification` record with the full SHA-256 hash in metadata.
- The record's `proceed` field is `true` before the team dispatches production goals.

## Next steps

- Read the [charter anatomy](/agentic-team-protocol/charter-anatomy/) concept page for a deeper explanation of each section.
- Learn the default global charter in the [default charter reference](/agentic-team-protocol/reference/default-charter/).
- Run your first goal with `/team` after ratification succeeds.
