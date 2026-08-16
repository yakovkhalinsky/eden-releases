---
title: Default charter
description: Annotated default global ATP charter and a ratification checklist for project-local overrides.
content_type: reference
---

# Default charter

ATP ships with a **global default charter** at `~/.claude/skills/team/CHARTER.md`. Projects can ratify it as-is or override it with `.claude/agentic-team-charter.md`. This page annotates the default charter and provides a checklist for ratifying a project-local version.

## Global default charter summary

The global charter is safe to ratify when a project has not yet written its own charter. It defines the baseline guardrails and decision rights.

### Scope

The charter governs agentic teams using ATP with eden-memory as the durable memory substrate.

### Default active roles

| Role | Purpose |
|------|---------|
| Dispatcher | Decides what to build and delegates goals. |
| Researcher | Investigates, evaluates, and reports options. |
| Builder | Implements and tests the chosen approach. |
| Verifier | Reviews outputs for correctness, safety, and charter compliance. |
| Archivist | Records goal lifecycle data and manages memory hygiene. |

**Runtime is not active by default.** It requires explicit project-local charter authorisation before it may operate on anything beyond local development tools. When authorised, routine commit/push of verified changes is within normal scope and does not require per-action user approval.

### Decision rights

- **Task ownership**: Dispatcher assigns; owning role decides implementation details within scope.
- **Tooling / dependencies**: Researcher recommends; Builder decides; Verifier vetoes risky choices.
- **Deploy timing**: Verifier must approve; Runtime executes only if authorised.
- **Verification verdict**: Verifier owns final green/red judgement.
- **Charter changes**: Require re-ratification by the project owner or Founders' Circle.

### Escalation path

1. Owning role → Dispatcher/Overseer within one status period.
2. Dispatcher → Anchor Operations Chair same day.
3. Chair → Founders' Circle within 48 hours for guardrail or risk issues.
4. Final call by Founders' Circle or project owner.

### Guardrails

- Secrets must never be stored in eden-memory.
- Runtime may not touch production systems without explicit charter authorisation.
- Every goal must end in either a hand-off/closure record or an escalation record.
- Charter changes require re-ratification.
- Non-trivial changes require a feature branch.
- Merges into the default branch must be non-fast-forward merge commits that preserve both parent SHAs.
- Force-pushing the default branch is prohibited.

### Branch discipline

Projects ratifying this charter keep the default branch protected unless a project-local charter overrides these rules:

1. **Feature branches for non-trivial work.** Any change touching more than one file, altering behaviour, or dispatched as `build` or `run` must be developed on a feature branch. The feature branch is the durable audit and merge artifact regardless of whether the goal uses a dedicated worktree.
2. **Trivial fixes only on the default branch.** Single-line corrections may be committed directly.
3. **Non-fast-forward merge commits.** Merges into the default branch must create a merge commit with a descriptive conventional-commit message.
4. **Record both parent SHAs.** Runtime records the feature-branch SHA and the previous default-branch SHA in the merge action record.
5. **No force-push.** Force-pushing the default branch is never permitted.
6. **Runtime authority.** Runtime is the only role that may create merge commits and push to the default branch, and only after a green Verifier verdict.

### Worktree discipline

When `worktree_policy.enabled` is true in `.claude/agentic-team-config.yaml`:

1. Non-trivial `build` and `run` goals use a dedicated git worktree under `.claude/worktrees/atp/`, checked out on the goal's feature branch.
2. Builder may create goal worktrees; Runtime may remove them when `auto_remove_after_merge` is true, but only after verifying the worktree is clean.
3. Runtime must verify the default-branch working copy is clean before fetching `origin/<DEFAULT_BRANCH>` and merging.
4. Runtime records the actual `origin/<DEFAULT_BRANCH>` SHA as a merge parent.
5. The default-branch working copy stays reserved for trivial fixes, status checks, and merge operations.

### Ratification and version control

- Ratified when `/team-charter` stores a `charter_ratification` record in eden-memory.
- Version is the short SHA-256 hash of the charter content.
- Amendments follow: propose → review → re-ratify → archive previous version.
- The Archivist owns the amendment log.

### Retirement

A team retires by:

1. Archiving the ratification record.
2. Marking eden-memory team records as `team_retired`.
3. Removing local agent/command files only after archival is verified.

## Project-local charter template

The installer copies the project-local template to `.claude/agentic-team-charter.md`. The template is based on the global charter but adds placeholders for project identity and branch-specific values.

Key sections in the template:

| Section | Purpose |
|---------|---------|
| Identity | Project name, path, and purpose statement. |
| Mission | One-sentence mission. |
| Boundaries | Hard guardrails, including the no-secrets rule and Runtime gating. |
| Roles/seats | Active roles and whether Runtime is gated. |
| Decision rights | Who decides routing, implementation, verdicts, live ops, and user overrides. |
| Escalation paths | Chain from owning role up to founders. |
| Branch discipline | Feature-branch rules, merge-commit style, Runtime authority. |
| Worktree discipline | Worktree-per-goal rules when `worktree_policy.enabled` is true. |
| Interfaces and dependencies | eden-memory path, global skill path, project-local skill override. |
| Runbooks and skills owned | Files the Archivist should maintain. |
| Status cadence | How often to run `/team-status`. |
| Retirement condition | How to stop using ATP for this project. |

## Ratification checklist

Before running `/team-charter`, confirm each item below.

- [ ] The charter file exists at `.claude/agentic-team-charter.md` (or global fallback is intentional).
- [ ] `<PROJECT_NAME>` and `<PROJECT_PATH>` placeholders are replaced.
- [ ] The mission statement is project-specific and not the template example.
- [ ] Boundaries explicitly forbid destructive live operations without authorisation.
- [ ] Boundaries forbid storing secrets in eden-memory or conversation logs.
- [ ] Roles in `.claude/agentic-team-config.yaml` match the active roles in the charter.
- [ ] Runtime is either omitted, explicitly gated, or explicitly authorised with scope limits.
- [ ] Branch discipline states the default branch name.
- [ ] If worktrees are enabled, `worktree_policy` is present and `Worktree discipline` is described.
- [ ] Escalation paths name real people, roles, or channels for the project.
- [ ] Retirement condition is described.

If any item is unchecked, `/team-charter` will likely report `no-proceed`. Edit the charter and run it again.

## Scope resolution

When both global and project-local files exist, the project-local versions win:

1. Project-local charter overrides global charter.
2. Project-local agent definitions override global agents.
3. Project-local skill overrides global skill.
4. If a project has no `agentic-team-config.yaml`, the global skill is used and the global charter is ignored unless explicitly referenced.

## See also

- [Ratify a project charter](/agentic-team-protocol/tutorials/ratify-charter/) — step-by-step ratification.
- [Charter anatomy](/agentic-team-protocol/charter-anatomy/) — explains each section in depth.
- [Record kinds](/agentic-team-protocol/concepts/record-kinds/) — the `charter_ratification` record produced by `/team-charter`.
