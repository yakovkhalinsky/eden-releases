---
name: agentic-team-protocol
title: Agentic Team Protocol — <PROJECT_NAME>
description: Project-local override for the Agentic Team Protocol with branch discipline.
version: 1.0.3
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
