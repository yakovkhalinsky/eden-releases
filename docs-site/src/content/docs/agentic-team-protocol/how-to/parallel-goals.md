---
title: Run goals in parallel
description: Use git worktrees to run multiple ATP build or run goals at the same time without switching branches in your main checkout.
content_type: how-to
---

# Run goals in parallel

The Agentic Team Protocol normally puts every non-trivial `build` or `run` goal on its own feature branch. When only one working copy is available, those goals queue up: you stash, switch branches, return, and repeat. Git worktrees remove that serialization by giving each goal its own checkout while keeping a single object store and remote config.

## What a worktree means here

A git worktree is a linked working copy that shares the same `.git` directory as your main checkout. For ATP, each non-trivial `build` or `run` goal gets a worktree under `.claude/worktrees/atp/`, checked out on the goal's feature branch.

A typical layout looks like this:

```text
~/my-project/
  .git/
  .claude/
    agentic-team-config.yaml
    agentic-team-charter.md
    worktrees/
      atp/
        goal-a1b2c3d4-feat-hello-world/   # goal A worktree
        goal-e5f6g7h8-feat-add-docs/        # goal B worktree
  src/
  README.md
```

The default-branch checkout stays clean. Builder and Runtime do all mutating work inside the goal worktree. Runtime still merges, pushes, and cleans up branches from the main checkout.

## Prerequisites

- Git with worktree support (git 2.5+).
- ATP installed and a project-local charter/config in `.claude/`.
- `worktree_policy.enabled: true` in `.claude/agentic-team-config.yaml`.
- Sufficient disk space for the additional working copies (object store is shared, so only working-tree files are duplicated).

## When worktree-per-goal helps

| Situation | Why worktrees help |
|---|---|
| Context switching | Goal A is mid-build and goal B needs a quick fix. Each lives in its own checkout; no stashing or switching. |
| Merge queue | Two goals finish around the same time. Runtime can rebase/retest the second inside its worktree while the first merges from the main checkout. |
| Headless contention | Multiple `eden-team` goals run against the same repo without fighting over one checkout. |

## Configuring `worktree_policy`

Add this block to `.claude/agentic-team-config.yaml` under `branch_policy`:

```yaml
worktree_policy:
  enabled: true
  root: .claude/worktrees/atp
  naming: "goal-{goal_id_short}-{branch}"
  auto_create: true
  auto_remove_after_merge: false
  max_concurrent: 8
```

| Field | What it does |
|---|---|
| `enabled` | Turns worktree-per-goal on or off for this project. |
| `root` | Directory under the repo root where worktrees are created. Defaults to `.claude/worktrees/atp` to avoid colliding with Claude Code's own worktrees. |
| `naming` | Template for the worktree directory. `{goal_id_short}` is the first 8 hex characters of the goal ID; `{branch}` is the sanitized feature-branch name. |
| `auto_create` | When `true`, Builder or Runtime creates the worktree automatically before the action stage. |
| `auto_remove_after_merge` | When `true`, Runtime removes the worktree after a successful merge if it is clean. Defaults to `false` so you can inspect results first. |
| `max_concurrent` | Soft cap on active ATP worktrees. When at the cap, new goals are `blocked` until you finish or remove an active one. |

### Disabling worktrees

To return to the legacy single-checkout flow, set `enabled: false`:

```yaml
worktree_policy:
  enabled: false
```

You can also pass `--no-worktree` or set `ATP_WORKTREE_POLICY_ENABLED=false` for `eden-team` headless runs.

## What you'll see

1. Dispatcher records the goal and decides the package type.
2. If the package is `build` or `run`, Builder/Runtime checks Eden-memory for a recorded `worktree_path`.
3. If none exists, it fetches `origin/<DEFAULT_BRANCH>`, runs `git worktree add -b <branch>`, and records `worktree_path` and `branch_name` in the action record.
4. All commits for that goal happen in the worktree.
5. After a green Verifier verdict, Runtime verifies the main checkout is clean, fetches origin, fast-forwards, creates the non-fast-forward merge commit, and pushes.
6. If push is rejected because another goal landed first, Runtime rebases/retests the feature branch inside the worktree and retries up to three times.
7. Runtime deletes the feature branch. If `auto_remove_after_merge` is true and the worktree is clean, it also removes the worktree.

## Decision rubric

| Approach | Use when |
|---|---|
| **Worktree-per-goal** (default) | Most parallel `build`/`run` goals. Shares object store, stays in sync with origin, keeps main checkout clean. |
| **Clone-per-goal** | Long-running, build-heavy goals where a fully isolated object store is worth the disk cost. Not automated in this first release. |
| **Stacked branches** | Goals depend on each other and you want to build branch B on top of branch A. Out of scope for the first release. |
| **Subagent fan-out** | The task itself is embarrassingly parallel (e.g., review many files). ATP already supports this; worktrees solve repo-level contention, not task decomposition. |

## Headless batch goals

The `eden-team` supervisor honors `worktree_policy` from the project config. You can override the root and naming with flags:

```bash
eden-team start \
  --goal "Add README section about parallel goals" \
  --worktree-root ./.claude/worktrees/atp \
  --worktree-naming "goal-{goal_id_short}-{branch}" \
  --worktree-auto-create \
  --no-worktree-auto-remove \
  --mcp-config ./mcp.json
```

When `max_concurrent` is reached, `eden-team` records a `blocked` state and lists active goals instead of silently creating another worktree.

## Cautions

- **Do not manually delete active worktrees.** If a recorded `worktree_path` disappears, `/team-continue` detects it and asks whether to recreate it or abort.
- **Submodules and sparse checkouts** can break `git worktree add`. If that happens, Builder/Runtime records the failure and either falls back to a clone or escalates.
- **`max_concurrent` is a soft cap.** The supervisor refuses to create new worktrees at the cap, but it never removes an existing worktree automatically to make room.
- **The main checkout must be clean before Runtime merges.** If it is dirty, Runtime records `blocked` and asks you to clean it.

## See also

- [Lifecycle](/agentic-team-protocol/lifecycle/) — where the action stage uses a worktree.
- [Record kinds and schema](/agentic-team-protocol/concepts/record-kinds/) — the `worktree_path` and `branch_name` metadata fields.
- [Slash commands](/agentic-team-protocol/reference/slash-commands/) — `/team-status`, `/team-continue`, and `/team-handoff` carry worktree context.
- [Set up a headless supervisor](/eden-team/tutorials/headless-supervisor/) — `eden-team` flags for worktree control.
