# Global Agentic Team Protocol Charter

This is the **default global charter** used when a project does not define its
own `agentic-team-charter.md`. It is safe to ratify as a starting point and
can be overridden by a project-local charter in `.claude/agentic-team-charter.md`.

## Scope

This charter governs agentic teams using the Agentic Team Protocol with
eden-memory as the durable memory substrate.

## Roles

The default active roles are:

| Role | Purpose |
|------|---------|
| Dispatcher | Decides what to build and delegates goals to the right role. |
| Researcher | Investigates, evaluates, and reports options. |
| Builder | Implements and tests the chosen approach. |
| Verifier | Reviews outputs for correctness, safety, and charter compliance. |
| Archivist | Records goal lifecycle data and manages memory hygiene. |

Runtime is **not active by default** and requires explicit project-local charter
authorisation before it may operate on anything beyond local development tools.

## Decision rights

- **Task ownership**: Dispatcher assigns; owning role decides implementation
details within its scope.
- **Tooling / dependencies**: Researcher recommends; Builder decides; Verifier
vetos risky choices.
- **Deploy timing**: Verifier must approve; Runtime executes only if authorised.
- **Verification verdict**: Verifier owns final green/red judgement.
- **Charter changes**: require re-ratification by the project owner or Founders'
Circle.

## Escalation path

1. Owning role → Dispatcher/Overseer within one status period.
2. Dispatcher → Anchor Operations Chair same day.
3. Chair → Founders' Circle within 48 hours for guardrail / risk issues.
4. Final call by Founders' Circle or project owner.

## Guardrails

- Secrets must never be stored in eden-memory.
- Runtime may not touch production systems without explicit charter authorisation.
- Every goal must end in either a hand-off/closure record or an escalation record.
- Charter changes require re-ratification.

## Ratification

This charter is ratified when `/team-charter` records a
`charter_ratification` entry in eden-memory. The first ratification may be done
by the project owner. Fleet-wide charters require Founders' Circle sign-off.

## Version and amendments

- Version is the short SHA-256 hash of the charter content.
- Amendments: propose → review → re-ratify → archive previous version.
- Archivist owns the amendment log.

## Retirement

A team retires by:
1. Archiving the ratification record.
2. Marking eden-memory team records as `team_retired`.
3. Removing local agent/command files only after archival is verified.
