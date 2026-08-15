# Agentic Team Charter — <PROJECT_NAME>

## Identity

Project: `<PROJECT_PATH>`  
Purpose: <Short description of what the project does and why it uses the Agentic Team Protocol.>

## Mission

<One-sentence mission statement, e.g. "Ship observable, reversible changes safely while maintaining a durable decision trail in Eden-memory.">

## Boundaries

- <Boundary 1, e.g. "Do not perform destructive actions on external/live systems without explicit authorisation.">
- <Boundary 2, e.g. "Runtime operations are limited to local development commands unless explicitly authorised.">
- <Boundary 3 (optional), e.g. "Routine commit and push of verified changes to this project's repository is authorised for Runtime after a green Verifier verdict.">
- Secrets, tokens, and credentials must never be stored in Eden-memory or conversation logs.

## Roles/seats

Active roles are defined in `.claude/agentic-team-config.yaml`. The default set in **Lite mode** is:

- Dispatcher (also performs lightweight planning)
- Builder
- Verifier
- Archivist

In **Full mode**, the following additional roles have separate seats:

- Researcher — explicit context gathering and options analysis.
- Runtime — live-system operations (commit/push, deploy, infrastructure changes).

Runtime requires explicit charter authorisation before acting on anything beyond local development tools. If the charter authorises it, Runtime may commit and push verified repository changes without per-action user approval.

## Decision rights

- Dispatcher: routing and assignment decisions.
- Builder: implementation approach within the dispatched scope.
- Verifier: accept/reject/rework verdicts.
- Runtime: go/no-go on live operations.
- User: overrides any role decision.

## Escalation paths

1. Owning role → Dispatcher/Overseer within one status period.
2. Dispatcher → Anchor Operations Chair same day.
3. Chair → Founders' Circle within 48 hours for guardrail/risk issues.
4. Final call by Founders' Circle or project owner.

## Branch discipline

- Non-trivial changes must be developed on a feature branch checked out from
  `<DEFAULT_BRANCH>`. A branch name should include the goal or feature, e.g.,
  `feat/<goal-or-feature>`.
- Direct commits to `<DEFAULT_BRANCH>` are permitted only for trivial one-line
  fixes (e.g., typo correction, single-line flag default change). Anything
  touching more than one file or altering behaviour must use a feature branch.
- Merges into `<DEFAULT_BRANCH>` must use a non-fast-forward merge commit with a
  descriptive conventional-commit message, and both parent SHAs must be recorded
  in the Runtime action record.
- After a successful non-fast-forward merge into `<DEFAULT_BRANCH>` and push to
  `origin/<DEFAULT_BRANCH>`, Runtime must delete the local feature branch (`git
  branch -d <branch>`). If authorized and the branch is not protected, Runtime
  must also delete the remote branch (`git push origin --delete <branch>`).
  Runtime records the deleted branch names, post-merge `<DEFAULT_BRANCH>` SHA,
  and any skip reason in the action record.
- Protected/long-lived branches must never be deleted (`<DEFAULT_BRANCH>`,
  `release/*`, `hotfix/*`, etc.).
- In headless/eden-team workflows, skip local deletion if the working copy is
  not on the feature branch (e.g., detached or shallow checkout) and record
  `headless_skip_local: true`.
- Runtime is the only role that may create merge commits and push to
  `origin/<DEFAULT_BRANCH>`, and only after a green Verifier verdict.
- Never force-push to `origin/<DEFAULT_BRANCH>`.

## Interfaces and dependencies

- Eden-memory (`~/.eden-memory/default.db`) is the durable substrate.
- The global Agentic Team Protocol skill at `~/.claude/skills/team/SKILL.md` provides fallback documentation.
- The project-local skill at `.claude/skills/agentic-team-protocol/SKILL.md` overrides the global skill for `<PROJECT_PATH>`.
- This local charter overrides the global charter for `<PROJECT_PATH>`.

## Runbooks and skills owned

- `.claude/skills/team/SKILL.md`
- `.claude/agents/*.md`
- `.claude/commands/*.md`
- This charter

## Status cadence

Check active goals with `/team-status` at the start of each session working on this project.

## Retirement condition

This charter and the project-local protocol may be retired by removing `.claude/agentic-team-config.yaml` and the `.claude/agentic-team-protocol` files. Until then, this charter is binding.
