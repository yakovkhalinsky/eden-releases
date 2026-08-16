---
name: agentic-team-protocol
title: Agentic Team Protocol — <PROJECT_NAME>
description: Project-local override for the Agentic Team Protocol with branch discipline.
version: 1.1.4
tags: [agents, roles, protocol, team]
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
    - TaskCreate
    - TaskUpdate
    - TaskGet
    - TaskList
harness: claude-code
---

# Agentic Team Protocol — <PROJECT_NAME>

This is the project-local override for the Agentic Team Protocol in
`<PROJECT_PATH>`. It supplements the global skill at
`~/.claude/skills/team/SKILL.md` with repository-specific branch discipline and
the project charter in `.claude/agentic-team-charter.md`.

## Branch policy

- **Default branch:** `<DEFAULT_BRANCH>`
- **Feature branches required for:** non-trivial `build` and `run` work
- **Allowed direct-on-`<DEFAULT_BRANCH>`:** only trivial one-line fixes (e.g.,
  typo correction, single-line default change)
- **Merge strategy:** non-fast-forward merge commit with a descriptive
  conventional-commit message
- **Record parent SHAs:** yes, in every Runtime action record that creates a
  merge commit
- **Force-push to `origin/<DEFAULT_BRANCH>`:** never

## Workflow

1. Dispatcher records the goal and assigns a role.
2. Builder (or Runtime) checks the current git branch. If on
   `<DEFAULT_BRANCH>` and the work is non-trivial, create a feature branch from
   the current state with a descriptive name (e.g., `feat/<goal-or-feature>`)
   and do all implementation work on that branch.
3. All implementation commits go to the feature branch.
4. After a green Verifier verdict, Runtime merges the feature branch into
   `<DEFAULT_BRANCH>` with a non-fast-forward merge commit and pushes to
   `origin/<DEFAULT_BRANCH>`.
5. Runtime cleans up the feature branch: delete the local branch (`git branch -d
   <branch>`); if authorized and unprotected, delete the remote branch (`git push
   origin --delete <branch>`). Record deleted branch names, the post-merge
   `<DEFAULT_BRANCH>` SHA, and any skip reason (e.g., protected branch, headless
   skip) in the action record. Never delete protected or long-lived branches
   (`<DEFAULT_BRANCH>`, `release/*`, `hotfix/*`, etc.). In headless/eden-team
   workflows, skip local deletion if the working copy is not on the feature branch
   and record `headless_skip_local: true`.
6. Archivist records the closure, linking the action record, verdict, merge
   parent SHAs, and branch cleanup details.

### Worktree-first workflow

When `worktree_policy.enabled` is true in `.claude/agentic-team-config.yaml`:

1. Dispatcher decides the `package_type`. Only `build` and `run` packages may use
   a worktree.
2. Before the action role starts, Builder or Runtime checks whether a worktree
   exists for the current `goal_id` in Eden-memory (look for `worktree_path` and
   `branch_name` in the latest action record).
3. If no worktree is recorded, fetch `origin/<DEFAULT_BRANCH>` and create a
   worktree under `worktree_policy.root` from the fetched tip, checking out the
   feature branch there with `git worktree add -b <branch>`. Record
   `worktree_path` and `branch_name` in the action record.
4. All mutating work happens in the recorded worktree. Do not switch branches in
   the default-branch working copy for this goal.
5. After a green Verifier verdict, Runtime verifies the default-branch working
   copy is clean. If it is dirty, record a `blocked` state and ask the user to
   clean it before merging.
6. Runtime fetches `origin/<DEFAULT_BRANCH>`, fast-forwards the main checkout,
   and creates the non-fast-forward merge commit there. If another goal landed
   first and push is rejected, rebase/retest the feature branch inside the goal
   worktree and retry up to three times.
7. Runtime deletes the feature branch. If `auto_remove_after_merge` is true and
   the worktree is clean, Runtime also removes the worktree. If the worktree is
   dirty, record a `blocked` state and ask the user.

## Task list synchronization

Keep the Claude Code in-app task list in sync with the Eden-memory trail. One
task represents the whole goal; store its `claude_task_id` in every durable
record's metadata. When a role starts, update the task to `in_progress` with an
`activeForm` matching the current stage (e.g. "Planning goal", "Building goal").
When the role finishes, update it to `completed`. When Verifier returns
`blocked` or the goal is `pending_authorisation`, update the task with a blocker
note and stop until resolved. Headless environments may skip updates if task
tools are unavailable; record the skip in a `run_log`.

## Escalation

If the current branch is `<DEFAULT_BRANCH>`, the work is non-trivial, and the
user or charter has not explicitly authorised direct-on-`<DEFAULT_BRANCH>`
work, the owning role must either create a feature branch or escalate to the
user.

## Workspace identity and isolation rules

Every ATP Eden-memory tool call (`eden_recall`, `eden_remember`, `eden_search`,
`eden_search_semantic`, `eden_edit`, `eden_forget`, and the `eden_health`/`eden_vacuum`
helpers) must be scoped with explicit `org_id` and `workspace_id` values. ATP roles
and slash commands must read these from:

1. The current process environment (`EDEN_ORG_ID`, `EDEN_WORKSPACE_ID`).
2. The project `.env` file generated by `eden-memory setup claude`.
3. The project-local `agentic-team-config.yaml` under `org_id` and `workspace_id`.
4. As a last resort, `~/.eden-memory/.env`.

The project-local `agentic-team-config.yaml` must declare non-empty `org_id` and
`workspace_id`. If either is empty, tools that default to an empty workspace must not
be called; resolve the identity first or warn the user.

**Empty-scope prohibition:** If `org_id` or `workspace_id` would be empty, the
command must abort with an error rather than call eden-memory with an empty scope.
The eden-memory CLI currently accepts empty strings for `--org-id`/`--workspace-id`
and stores or fetches unscoped records; the long-term fix requires an eden-memory
binary change. Until that fix ships, ATP commands and agents must validate scope before
invoking the CLI and ask the user to escalate or file an issue if validation fails.

`eden_recall` example:

```json
{
  "agent_id": "dispatcher",
  "user_id": "yakov",
  "query": "routing rules for team goals",
  "org_id": "0d3sa",
  "workspace_id": "yakovkhalinsky/eden-releases"
}
```

`eden_remember` example (metadata carries the identity):

```json
{
  "agent_id": "builder",
  "user_id": "yakov",
  "content": "Goal: <goal_id> | Record ID: <this_record_id> | Stage: action | Owner: builder",
  "metadata": {
    "goal_id": "<goal_id>",
    "stage": "action",
    "owner_role": "builder",
    "org_id": "0d3sa",
    "workspace_id": "yakovkhalinsky/eden-releases"
  }
}
```

This prevents team-mode Eden-memory calls from recalling memories that belong to
other workspaces.
