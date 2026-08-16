# Plan: Interactive `/team-charter` ratification UX

**Goal ID:** `interactive-charter-ratification-2026-08-16`  
**Owner role:** Builder (planning)  
**Stage:** action (planning)  
**Status:** pending approval  
**Date:** 2026-08-16  
**Deadline:** 2026-08-17T00:00:00Z  

---

## 1. Goal summary and success criteria

### Goal
Redesign the `/team-charter` slash command so charter ratification is an interactive, staged checklist + confirmation flow instead of a single-shot validation + store. The command should guide the user through missing placeholders, config/charter mismatches, and guardrails before writing a durable `charter_ratification` record to eden-memory.

### Why now
The current `/team-charter` command reads the charter, computes a hash, checks placeholders, and stores a record in one pass. Users report it is opaque: they only discover placeholder or role-mismatch failures after the fact, and they never get a chance to review what will be ratified. This undermines trust in the charter as a binding contract.

### Success criteria
1. `/team-charter` presents a staged checklist before ratifying.
2. Placeholders and template example text are detected and surfaced with file/line hints.
3. Active-role mismatches between `.claude/agentic-team-config.yaml` and the charter are shown as a delta.
4. The user can ratify, defer specific items, edit the charter, or abort without side effects.
5. A durable eden-memory record is written only after explicit final confirmation.
6. The ratification record stores the full SHA-256 hash, charter path, rater, timestamp, deferrals, and proceed/no-proceed reason.
7. Re-ratification shows the previous version hash and any changes since the last ratification.
8. Expert/non-interactive usage is preserved via a flag or environment variable.
9. Docs and templates are updated to match the new flow.
10. No final code or docs changes are made until this plan is approved by yakov or a Dispatcher-assigned Verifier.

---

## 2. Team recommendations

Synthesised from Researcher, Builder, and Verifier subagents.

### Recommended interaction pattern: staged checklist + confirmation
The command runs in three phases:

1. **Discovery** — locate the charter (project-local first, deliberate global fallback), compute the version hash, scan for placeholders/template text, and compare active roles to the charter.
2. **Checklist** — present each section/validation as an item the user can confirm, defer, or edit. Highlight blockers vs warnings.
3. **Ratification** — after final confirmation, store the `charter_ratification` record and report `proceed` or `no-proceed` with a specific reason.

This pattern was chosen because it keeps the user in control, avoids the complexity of a full file-editing wizard, and maps cleanly to the existing guardrails.

### Non-negotiable invariants (Verifier)
- The ratified version hash must be computed from the exact file bytes the user approved, after any edits and before storage. Store the full SHA-256 in metadata, not a 16-character truncation.
- Explicit, informed consent is required: final confirmation must show charter path, version hash, active roles, Runtime gating status, default branch, and guardrail summary.
- No durable record is written until confirmation succeeds.
- The command must not silently rewrite the charter file during ratification; any edits are explicit user actions.
- Re-ratification creates a new record; previous records are never mutated.
- Cancellation at any step leaves zero side effects.

### Implementation approach (Builder)
- Update `commands/team-charter.md` to define the three-phase flow. Add `AskUserQuestion` to `allowed-tools`.
- Keep the command file self-contained: reuse the existing `_resolve_identity_from_config_or_env` helper and add small POSIX helpers for `_charter_path`, `_version_hash`, `_scan_placeholders`, and `_active_roles_delta`.
- Preserve a non-interactive path: `/team-charter --non-interactive` or `ATP_NON_INTERACTIVE=1` runs the current deterministic flow verbatim.
- Update `templates/agentic-team-charter.md` to keep placeholder tokens machine-detectable (`<PROJECT_NAME>`, `<PROJECT_PATH>`, `<DEFAULT_BRANCH>`, etc.) and add a short comment block listing common deferrals.
- Update `SKILL.md` and public docs (`tutorials/ratify-charter.md`, `reference/slash-commands.md`) to describe the interactive flow and the non-interactive bypass.
- No install-script changes are required; the existing `install.sh` copies updated command/template files.

### UX gaps addressed (Researcher)
- No up-front guidance or staged review.
- Weak error explanation for placeholders and role mismatches.
- No re-ratification diff.
- Silent global fallback when project-local charter is missing.
- Fatal identity failures without offering remediation.

---

## 3. Detailed flow

### Phase A — Discovery
1. Locate charter:
   - `.claude/agentic-team-charter.md` if it exists.
   - Otherwise explicitly ask: "No project-local charter found. Ratify the global fallback at `~/.claude/skills/team/CHARTER.md`, or create a local charter first?"
2. Compute `CHARTER_VERSION` = full SHA-256 of the file.
3. Scan for placeholders and template example text.
4. Read `.claude/agentic-team-config.yaml` and compute role delta vs charter.
5. Resolve `org_id`, `workspace_id`, `agent_id`; if missing, explain and offer to run `eden-memory setup claude`.
6. Fetch the latest `charter_ratification` record for `goal_id: charter-ratification` to detect re-ratification.

### Phase B — Checklist
Present a checklist with machine-readable items:

| # | Item | Status | User action |
|---|------|--------|-------------|
| 1 | Charter file exists at known path | OK / missing | Create or abort |
| 2 | No unresolved placeholders | OK / blocked | Edit or defer with reason |
| 3 | No template example text remains | OK / warning | Edit or accept |
| 4 | Active roles match config | OK / blocked | Edit charter or config |
| 5 | Runtime gating is explicit | OK / warning | Confirm or defer |
| 6 | Default branch is stated | OK / blocked | Edit or defer |
| 7 | `org_id`/`workspace_id` resolved | OK / blocked | Run setup or abort |
| 8 | Re-ratification diff (if prior record exists) | OK / changed | Review or abort |

The user can choose:
- **Ratify now** if no blockers remain.
- **Edit charter** — opens the file (assistant offers to edit specific placeholders) and returns to Phase A.
- **Defer item** — records a deferral reason; if any blocker is deferred, final status becomes `no-proceed`.
- **Abort** — no durable writes, report "not ratified."

### Phase C — Ratification
1. Show final summary: path, full hash, active roles, Runtime status, default branch, deferrals, previous version (if re-ratifying).
2. Ask final confirmation: "Store charter ratification record and set status to proceed/no-proceed?"
3. If confirmed, call `eden-memory remember` (or `eden_remember` when MCP is available) with:
   - `agent_id`: `archivist`
   - `user_id`: `$USER`
   - `content`: searchable identity line + summary
   - `metadata`: `kind: charter_ratification`, `stage: charter_ratification`, `goal_id: charter-ratification`, `owner_role: archivist`, `charter_path`, `charter_version` (full hash), `proceed` (bool), `deferrals` (array), `previous_record_id` (if re-ratifying), `org_id`, `workspace_id`
4. If `claude_task_id` is present, update the task with ratification status.
5. Report: path, version (short + full available in metadata), record ID, status.

---

## 4. Files to change

| File | Change |
|------|--------|
| `agentic-team-protocol/commands/team-charter.md` | Rewrite steps to three-phase interactive flow; add `AskUserQuestion` to frontmatter; add helper functions; add non-interactive bypass. |
| `agentic-team-protocol/templates/agentic-team-charter.md` | Keep placeholders machine-detectable; add deferral comment block. |
| `agentic-team-protocol/SKILL.md` | Update `/team-charter` description and setup instructions to mention interactive review and `--non-interactive`. |
| `agentic-team-protocol/README.md` | Update branch/charter section if needed to match interactive flow. |
| `docs-site/src/content/docs/agentic-team-protocol/tutorials/ratify-charter.md` | Rewrite tutorial to show the checklist flow. |
| `docs-site/src/content/docs/agentic-team-protocol/reference/slash-commands.md` | Update `/team-charter` reference with new output and flags. |
| `docs-site/src/content/docs/agentic-team-protocol/charter-anatomy.mdx` | Optional: mention interactive ratification in the ratification section. |

---

## 5. Acceptance criteria (Verifier)

- [ ] Ratification record contains the full SHA-256 hash in metadata.
- [ ] `proceed` is reported only after a successful durable record write.
- [ ] Placeholders or role mismatches produce `no-proceed` with a specific reason and file/line hint.
- [ ] The wizard can be cancelled at any step with zero side effects (no memory write, no file change).
- [ ] Re-running on an unchanged charter is idempotent or records a clear duplicate.
- [ ] Re-ratification surfaces the previous version hash.
- [ ] `--non-interactive` or `ATP_NON_INTERACTIVE=1` runs the old deterministic flow unchanged.
- [ ] Docs accurately describe the new flow and the bypass.

---

## 6. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Too much interactivity causes confirmation fatigue | Only blockers require explicit action; warnings can be acknowledged in bulk. |
| Hidden edits during wizard | Edits are explicit user choices; hash is recomputed from disk after any edit. |
| Mid-wizard abandonment leaves state unclear | No durable writes until final confirmation; abort reports incomplete items. |
| Non-interactive users are broken | Preserve `--non-interactive` flag and `ATP_NON_INTERACTIVE` env var. |
| Global fallback confusion | Explicitly ask before ratifying global charter; do not silently fall back. |

---

## 7. Dependencies and blockers

- No new binary dependencies; relies on existing `eden-memory` CLI and `sha256sum`.
- Requires `AskUserQuestion` availability in Claude Code slash-command execution.
- Docs sync script (`scripts/sync-atp-to-docs.js`) must be run after ATP source files change.

---

## 8. Approval

This plan is ready for review by yakov or a Dispatcher-assigned Verifier. Once approved, the Builder will implement the changes, the Verifier will review against the acceptance criteria, and the Archivist will update durable records and docs.
