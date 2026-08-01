# Agentic Team Charter — <PROJECT_NAME>

## Identity

Project: `<PROJECT_PATH>`  
Purpose: <Short description of what the project does and why it uses the Agentic Team Protocol.>

## Mission

<One-sentence mission statement, e.g. "Ship observable, reversible changes safely while maintaining a durable decision trail in Eden-memory.">

## Boundaries

- <Boundary 1, e.g. "Do not perform destructive actions on external/live systems without explicit authorisation.">
- <Boundary 2, e.g. "Runtime operations are limited to local development commands unless explicitly authorised.">
- Secrets, tokens, and credentials must never be stored in Eden-memory or conversation logs.

## Roles/seats

Active roles are defined in `.claude/agentic-team-config.yaml`. The default set is:

- Dispatcher
- Researcher
- Builder
- Verifier
- Archivist

Runtime is available but requires explicit charter authorisation before acting on anything beyond local development tools.

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

## Interfaces and dependencies

- Eden-memory (`~/.eden-memory/default.db`) is the durable substrate.
- The global Agentic Team Protocol skill at `~/.claude/skills/agentic-team-protocol/SKILL.md` provides fallback documentation.
- This local charter overrides the global charter for `<PROJECT_PATH>`.

## Runbooks and skills owned

- `.claude/skills/agentic-team-protocol/SKILL.md`
- `.claude/agents/*.md`
- `.claude/commands/*.md`
- This charter

## Status cadence

Check active goals with `/team-status` at the start of each session working on this project.

## Retirement condition

This charter and the project-local protocol may be retired by removing `.claude/agentic-team-config.yaml` and the `.claude/agentic-team-protocol` files. Until then, this charter is binding.
