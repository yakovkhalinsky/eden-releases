---
title: Ratify a project charter
description: Edit the default charter template, run /team-charter, and inspect the ratification record stored in eden-memory.
content_type: tutorial
---

# Ratify a project charter

A charter is the contract between you and the agentic team. Before any ATP goal is dispatched, a charter must be ratified and stored as a durable `charter_ratification` record in eden-memory. This tutorial covers editing the template, running the ratification command, and inspecting the stored record.

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
| **Interfaces** | eden-memory path, global skill path, project-local skill override. |
| **Runbooks owned** | Files the Archivist should keep up to date. |
| **Status cadence** | How often to run `/team-status`. |
| **Retirement condition** | How to stop using ATP for this project. |

Common guardrails to keep:

- Do not perform destructive actions on external or live systems without explicit authorisation.
- Secrets, tokens, and credentials must never be stored in eden-memory or conversation logs.
- Runtime is gated unless explicitly authorised by this charter.

## Step 3 — Verify the active roles match

Open `.claude/agentic-team-config.yaml` and confirm the roles listed there are the same roles marked active in the charter. Mismatches cause `/team-charter` to report `no-proceed`.

Example active set:

```yaml
active_roles:
  - dispatcher
  - researcher
  - builder
  - verifier
  - archivist
```

## Step 4 — Run /team-charter

In Claude Code, run:

```text
/team-charter
```

The command:

1. Resolves the charter path (project-local first, then global fallback).
2. Computes a SHA-256 hash of the file content.
3. Checks for placeholders and role mismatches.
4. Stores a `charter_ratification` record in eden-memory.
5. Reports whether the team may proceed.

**Expected output:**

```text
Charter path: .claude/agentic-team-charter.md
Version: 9f86d081884c7d65
Record ID: <uuid>
Status: proceed
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
  "owner_role": "archivist"
}
```

The record content also stores the charter version, the rater, and the ratification timestamp.

## Step 6 — Amend and re-ratify

When you change the charter, re-run `/team-charter`. The new version hash is stored as a separate ratification record. The Archivist should keep an amendment log linking the old and new versions.

**Expected output after re-ratification:**

```text
Charter path: .claude/agentic-team-charter.md
Version: 7d865e959b246691 (was 9f86d081884c7d65)
Record ID: <new-uuid>
Status: proceed
```

## Expected final state

- `.claude/agentic-team-charter.md` contains no placeholders.
- `.claude/agentic-team-config.yaml` lists the same active roles as the charter.
- eden-memory contains at least one `charter_ratification` record with a non-zero version hash.

## Next steps

- Read the [charter anatomy](/agentic-team-protocol/charter-anatomy/) concept page for a deeper explanation of each section.
- Learn the default global charter in the [default charter reference](/agentic-team-protocol/reference/default-charter/).
- Run your first goal with `/team` after ratification succeeds.
