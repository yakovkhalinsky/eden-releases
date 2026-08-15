---
title: Quick start
description: Install the Agentic Team Protocol and run your first Lite-mode team goal in Claude Code. Use the full protocol for complex or risky work.
content_type: tutorial
---

This tutorial gets the Agentic Team Protocol installed and a trivial first **Lite-mode** goal dispatched in under ten minutes. Lite mode is the default for `/team`; the full 6-role protocol is available via `/team-full`.

> [!TIP]
> ATP installs per-project inside your Claude Code workspace. Each repository you use it in gets its own `.claude/agentic-team-charter.md`, `.claude/agentic-team-config.yaml`, and `.claude/skills/agentic-team-protocol/SKILL.md`. Read the [Lite mode](/agentic-team-protocol/lite-mode/) concept page and the [first team goal tutorial](/agentic-team-protocol/tutorials/first-team-goal/) for the full workflow.

## Prerequisites

- [eden-memory](/eden-memory/getting-started/) installed and available on your `PATH`.
- Claude Code CLI.
- A git repository to use as a sandbox.

## Step 1 — Install the global primitives

Install eden-memory first, then the ATP global primitives:

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh
```

These installers are designed to be piped to `sh`, so you do not need to `chmod +x`
them when using `curl`. If you run a script directly from a local clone, the file is
tracked with executable permissions; otherwise use `sh ./agentic-team-protocol/install.sh`.

Check for ATP updates without changing any files:

```bash
curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh -s -- --check
```

The ATP installer copies the skill, agents, and slash commands into `~/.claude/`:

- `~/.claude/skills/team/SKILL.md`
- `~/.claude/agents/{dispatcher,builder,runtime,verifier,researcher,archivist,router}.md`
- `~/.claude/commands/{team,team-full,team-charter,team-status,team-escalate,team-continue,team-handoff}.md`

Restart Claude Code completely (`/exit`, then reopen).

## Step 2 — Wire eden-memory for the project

The ATP agents need the eden-memory MCP server to write and read lifecycle records. In your sandbox repo, run:

```bash
cd ~/your-sandbox-repo
eden-memory setup claude
```

This configures the current directory in `~/.claude.json` as an MCP project and installs the `/eden-*` fallback slash commands.

## Step 3 — Opt your project in

Install the project-local ATP templates:

```bash
cd ~/your-sandbox-repo
curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh -s -- --local
```

This creates `.claude/agentic-team-charter.md`, `.claude/agentic-team-config.yaml`, and `.claude/skills/agentic-team-protocol/SKILL.md`.

## Step 4 — (Optional) Ratify the charter

For **Lite mode** goals, charter ratification is optional. For **Full protocol** goals, or if you want enforced branch/runtime discipline, edit `.claude/agentic-team-charter.md` and replace the placeholders with your project identity, mission, boundaries, and active roles. Then run:

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

## Step 5 — Run your first goal

Run the top-level command with a small request:

```text
/team Add a README file that lists the project purpose and ATP roles
```

The Dispatcher records a `goal_record` and a Lite `plan_record`, then hands off to the Builder. The Builder creates the README and writes an `action_record`. The Verifier reviews it and writes a `verdict`. If the verdict is green, the Archivist closes the goal.

For goals that need research, runtime, or formal escalation, use `/team-full` instead.

## Step 6 — Check status

Run:

```text
/team-status
```

You should see your first goal listed as `closed` or `recording_and_archival`, with links to the latest record IDs.

## What next?

- Read the [Lite mode](/agentic-team-protocol/lite-mode/) concept page.
- Follow the full [Run your first team goal](/agentic-team-protocol/tutorials/first-team-goal/) tutorial for a more detailed walkthrough and expected output.
- Learn to amend and re-ratify the charter in [Ratify a project charter](/agentic-team-protocol/tutorials/ratify-charter/).
- Set up an [Ollama-backed headless supervisor](/eden-team/tutorials/headless-supervisor/) for automated goals.
- Read the [slash command reference](/agentic-team-protocol/reference/slash-commands/) for `/team`, `/team-full`, `/team-status`, `/team-continue`, and the rest.
