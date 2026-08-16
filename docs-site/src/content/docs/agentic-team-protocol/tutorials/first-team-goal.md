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

## Step 2 — Wire eden-memory for the project

The ATP agents need the eden-memory MCP server to write and read lifecycle records. In your sandbox repo, run:

```bash
cd ~/your-sandbox-repo
eden-memory setup claude
```

This configures the current directory in `~/.claude.json` as an MCP project and installs the `/eden-*` fallback slash commands. If `eden-memory` is not on your `PATH`, use the full path to the binary.

## Step 3 — Opt your sandbox project in

Install the project-local ATP templates:

```bash
cd ~/your-sandbox-repo
curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh -s -- --local
```

This creates:

- `.claude/agentic-team-charter.md`
- `.claude/agentic-team-config.yaml`
- `.claude/skills/agentic-team-protocol/SKILL.md`

## Step 4 — (Optional) Edit and ratify the charter

For **Lite mode** goals, charter ratification is optional. For **Full protocol** goals, or if you want enforced branch/runtime discipline, open `.claude/agentic-team-charter.md` and replace the placeholders:

1. Set the project name and path.
2. Write a one-sentence mission.
3. Confirm the default active roles for Lite mode (Dispatcher, Builder, Verifier, Archivist).
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

## Step 5 — Dispatch a trivial goal

Run the top-level protocol command with a tiny request:

```text
/team Add a README file that lists the project purpose and ATP roles
```

The `/team` command spawns the Dispatcher subagent in **Lite mode**. The Dispatcher records a `goal_record` with `metadata.mode: lite` and a `plan_record` in eden-memory, then hands off to the Builder.

> [!NOTE]
> The project template enables `worktree_policy` by default. When it is enabled,
> non-trivial `build` goals create a dedicated git worktree under
> `.claude/worktrees/atp/` and a feature branch. The README will be committed
> there, not on your default branch. You can inspect it with
> `git -C <worktree_path> log --oneline`, or merge it yourself, or promote the
> goal to full protocol so Runtime merges it. If `worktree_policy.enabled` is
> false or the block is absent, the README is committed to a feature branch in
> your main checkout instead.

**Expected output:**

```text
Goal recorded: goal-atp-first-goal-<id>
Mode: lite
Plan: builder
Worktree (if enabled): .claude/worktrees/atp/goal-<short>-feat-<branch>
Deadline: <timestamp>
```

## Step 6 — Observe the hand-off

The Builder reads the `plan_record`, checks or creates the goal worktree, and writes an `action_record` in eden-memory with `worktree_path` and `branch_name`. It then hands off to the Verifier.

You should see:

1. A new worktree directory under `.claude/worktrees/atp/` (only if `worktree_policy.enabled` is true).
2. A draft README in the worktree (or in the main checkout if `worktree_policy.enabled` is false), committed to a feature branch.
3. A Builder action summary in the conversation, including the worktree path (or "main checkout" if worktrees are disabled).
4. A Verifier review that results in `green`, `red`, or `blocked`.

If the Verifier returns green, the Archivist links the records and closes the goal. In Lite mode the merge into the default branch is manual unless you escalate to `/team-full`.

## Step 7 — Inspect the durable record

Run:

```text
/team-status
```

This lists active and recently closed goals with their current stage, owner role, latest record ID, and **Location** (worktree path or "main checkout").

## Expected final state

- `.claude/agentic-team-charter.md` contains real project values if you chose to ratify it (optional for Lite mode).
- Eden-memory contains at least a `goal_record` with `mode: lite`, a `plan_record`, an `action_record` (with `worktree_path` and `branch_name`), and a `verdict` for the same `goal_id`.
- The sandbox repo has a new feature branch containing the README (and a new worktree under `.claude/worktrees/atp/` if `worktree_policy.enabled` is true).
- To land the README on the default branch, either merge the feature branch manually or run `/team-full` for the same goal so Runtime performs the merge.

## Next steps

- Learn how to amend and re-ratify the charter in the [Ratify a project charter](/agentic-team-protocol/tutorials/ratify-charter/) tutorial.
- Read the [lifecycle](/agentic-team-protocol/lifecycle/) for the Lite and Full flows.
- Browse the [slash command reference](/agentic-team-protocol/reference/slash-commands/) to know which command to use when.
