---
name: agentic-team-protocol
title: Agentic Team Protocol — <PROJECT_NAME>
description: Project-local override for the Agentic Team Protocol with branch discipline.
version: 1.0.1
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
5. Archivist records the closure, linking the action record, verdict, and merge
   parent SHAs.

## Escalation

If the current branch is `<DEFAULT_BRANCH>`, the work is non-trivial, and the
user or charter has not explicitly authorised direct-on-`<DEFAULT_BRANCH>`
work, the owning role must either create a feature branch or escalate to the
user.
