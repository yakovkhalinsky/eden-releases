---
title: Quick start
description: Install the Agentic Team Protocol, ratify a project charter, and run your first team goal in Claude Code.
content_type: tutorial
---

# Quick start

This tutorial gets the Agentic Team Protocol installed, a project charter ratified, and a trivial first goal dispatched in under ten minutes.

> [!TIP]
> ATP installs per-project inside your Claude Code workspace. Each repository you use it in gets its own `.claude/agentic-team-charter.md`, `.claude/agentic-team-config.yaml`, and `.claude/skills/agentic-team-protocol/SKILL.md`. Read the [charter anatomy](/agentic-team-protocol/charter-anatomy/) and the [first team goal tutorial](/agentic-team-protocol/tutorials/first-team-goal/) for the full workflow.

## Prerequisites

- [eden-memory](/eden-memory/getting-started/) installed and available on your `PATH`.
- Claude Code CLI.
- A git repository to use as a sandbox.

## Step 1 — Install the global primitives

Run the installer:

```bash
curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh
```

This copies the skill, agents, and slash commands into `~/.claude/`:

- `~/.claude/skills/team/SKILL.md`
- `~/.claude/agents/{dispatcher,builder,runtime,verifier,researcher,archivist,router}.md`
- `~/.claude/commands/{team,team-charter,team-status,team-escalate,team-continue,team-handoff}.md`

Restart Claude Code completely (`/exit`, then reopen).

## Step 2 — Opt your project in

In your sandbox repo, install the project-local templates:

```bash
cd ~/your-sandbox-repo
curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh -s -- --local
```

This creates `.claude/agentic-team-charter.md`, `.claude/agentic-team-config.yaml`, and `.claude/skills/agentic-team-protocol/SKILL.md`.

## Step 3 — Ratify the charter

Edit `.claude/agentic-team-charter.md` and replace the placeholders with your project identity, mission, boundaries, and active roles. Then run:

```text
/team-charter
```

The command reads the charter, computes a SHA-256 version hash, and stores a `charter_ratification` record in eden-memory. It reports whether the team may proceed.

**Expected output:**

```text
Charter ratified for project: your-sandbox-repo
Version: a1b2c3d4e5f67890
Record ID: <uuid>
Status: proceed
```

## Step 4 — Run your first goal

Run the top-level command with a small request:

```text
/team Add a README file that lists the project purpose and ATP roles
```

The Dispatcher records a `goal_record` and `dispatch_instruction`, then hands off to the Builder. The Builder creates the README and writes an `action_record`. The Verifier reviews it and writes a `verdict`. If the verdict is green, the Archivist closes the goal.

## Step 5 — Check status

Run:

```text
/team-status
```

You should see your first goal listed as `closed` or `recording_and_archival`, with links to the latest record IDs.

## What next?

- Follow the full [Run your first team goal](/agentic-team-protocol/tutorials/first-team-goal/) tutorial for a more detailed walkthrough and expected output.
- Learn to amend and re-ratify the charter in [Ratify a project charter](/agentic-team-protocol/tutorials/ratify-charter/).
- Set up an [Ollama-backed headless supervisor](/agentic-team-protocol/tutorials/headless-supervisor/) for automated goals.
- Read the [slash command reference](/agentic-team-protocol/reference/slash-commands/) for `/team`, `/team-status`, `/team-continue`, and the rest.
