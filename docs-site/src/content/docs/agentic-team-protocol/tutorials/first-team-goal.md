---
title: Run your first team goal
description: Install the Agentic Team Protocol skill, ratify a project charter, and dispatch a trivial goal to observe the hand-off.
content_type: tutorial
---

# Run your first team goal

This tutorial walks through the shortest complete ATP lifecycle: install the global primitives, opt a project in, ratify its charter, and run a goal that is recorded, built, and handed off in eden-memory.

## Prerequisites

- [eden-memory](/eden-memory/getting-started/) installed and on your `PATH`.
- Claude Code CLI.
- A local git repository you can use as a sandbox (nothing will be pushed).

## Step 1 — Install the global ATP primitives

Run the installer:

```bash
curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh
```

The installer copies the skill, agents, and slash commands into `~/.claude/`:

- `~/.claude/skills/team/SKILL.md`
- `~/.claude/agents/{dispatcher,builder,runtime,verifier,researcher,archivist,router}.md`
- `~/.claude/commands/{team,team-charter,team-status,team-escalate,team-continue,team-handoff}.md`

Restart Claude Code completely (`/exit`, then reopen) so the new commands and agents appear.

**Expected result:** After restart, the command palette accepts `/team-charter` and `/team-status`.

## Step 2 — Opt your sandbox project in

Change into your sandbox repo and install the project-local templates:

```bash
cd ~/your-sandbox-repo
curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh -s -- --local
```

This creates:

- `.claude/agentic-team-charter.md`
- `.claude/agentic-team-config.yaml`
- `.claude/skills/agentic-team-protocol/SKILL.md`

## Step 3 — Edit and ratify the charter

Open `.claude/agentic-team-charter.md` and replace the placeholders:

1. Set the project name and path.
2. Write a one-sentence mission.
3. Confirm the default active roles (Dispatcher, Researcher, Builder, Verifier, Archivist).
4. Keep Runtime gated unless you intend to run live operations.

Then run:

```text
/team-charter
```

The command reads the charter, computes a SHA-256 version hash, and stores a `charter_ratification` record in eden-memory.

**Expected output:**

```text
Charter ratified for project: your-sandbox-repo
Version: a1b2c3d4e5f67890
Record ID: <uuid>
Status: proceed
```

If the command reports placeholders or missing guardrails, edit the charter and run it again.

## Step 4 — Dispatch a trivial goal

Run the top-level protocol command with a tiny request:

```text
/team Add a README file that lists the project purpose and ATP roles
```

The `/team` command spawns the Dispatcher subagent. The Dispatcher records a `goal_record` and a `dispatch_instruction` in eden-memory, then hands off to the Builder.

**Expected output:**

```text
Goal recorded: goal-atp-first-goal-<id>
Dispatch: builder
Deadline: <timestamp>
```

## Step 5 — Observe the hand-off

The Builder reads the dispatch instruction, creates the README, and writes an `action_record` in eden-memory. It then hands off to the Verifier.

You should see:

1. A draft README in your repository.
2. A Builder action summary in the conversation.
3. A Verifier review that results in `green`, `red`, or `blocked`.

If the Verifier returns green, the Archivist links the records and closes the goal.

## Step 6 — Inspect the durable record

Run:

```text
/team-status
```

This lists active and recently closed goals with their current stage, owner role, and latest record ID. The goal you just ran should appear as `closed` or `recording_and_archival`.

## Expected final state

- `.claude/agentic-team-charter.md` contains real project values and has been ratified.
- Eden-memory contains at least a `charter_ratification`, `goal_record`, `dispatch_instruction`, `action_record`, and `verdict` for the same `goal_id`.
- The sandbox repo has a new README summarising the project.

## Next steps

- Learn how to amend and re-ratify the charter in the [Ratify a project charter](/agentic-team-protocol/tutorials/ratify-charter/) tutorial.
- Read the [lifecycle](/agentic-team-protocol/lifecycle/) for the full seven-stage flow.
- Browse the [slash command reference](/agentic-team-protocol/reference/slash-commands/) to know which command to use when.
