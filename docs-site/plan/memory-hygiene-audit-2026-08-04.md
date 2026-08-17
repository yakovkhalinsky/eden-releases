# Memory Hygiene Audit — `eden-releases` workspace

**Date:** 2026-08-04  
**Workspace scope:** `0d3sa` / `yakovkhalinsky/eden-releases`  
**Goal ID:** `memory-hygiene-packet-20260804`  
**Parent goal:** `measure-improve-recall-efficiency-20260804`  
**Owner role:** researcher  
**Status:** completed  
**Input record:** `a9218c62-ed26-42da-b98c-f242272b585f`

---

## Executive summary

The `eden-releases` workspace contains **502 non-deleted eden-memory records** written by a single user (`yakov`) across nine distinct agent IDs. The corpus is dominated by ATP (Agentic Team Protocol) execution artifacts: dispatch instructions, hand-off records, verdicts, and action/run logs. Durable takeaways, conventions, and context summaries are a small minority. A semantic-recall spot-check shows that topically focused queries return highly relevant results with scores above 0.60, but broad or process-oriented queries surface a long tail of low-relevance execution records with scores below 0.30. To improve signal-to-noise ratio, agents should record high-signal summaries instead of raw execution logs, always tag `record_type`, and adopt a relevance-score threshold of **≥ 0.45** when deciding which recalled memories to keep in context.

---

## Memory type distribution

### Scope totals

| Metric | Count |
| --- | --- |
| Total non-deleted records in database | 1 388 |
| Records scoped to this workspace (`yakovkhalinsky/eden-releases`) | 502 |
| Distinct `agent_id` values | 9 |
| Distinct `user_id` values | 1 |
| Records lacking `record_type` metadata | 94 |

### By `agent_id`

| Agent | Records | Share |
| --- | --- | --- |
| `claude-code-cli` | 412 | 82.1 % |
| `claude-code-cli-main` | 40 | 8.0 % |
| `atp-run` (legacy, see note) | 15 | 3.0 % |
| `claude-code-cli-researcher` | 8 | 1.6 % |
| `claude-code-cli-dispatcher` | 6 | 1.2 % |
| `dispatcher` | 6 | 1.2 % |
| `claude-code-cli-builder` | 7 | 1.4 % |
| `claude-code-cli-verifier` | 5 | 1.0 % |
| `claude-code-cli-archivist` | 3 | 0.6 % |


> **Note:** The `atp-run` agent ID is legacy. The headless ATP supervisor
> previously lived in `eden-releases/agentic_team_protocol/` and was
> removed on 2026-08-05. The same functionality is now provided by `eden-team`
> in `/home/yakov/git/eden-memory`. New records should use agent ID `eden-team`.

### By `record_type`

| Record type | Count | Notes |
| --- | --- | --- |
| `hand_off_record` | 111 | ATP role transitions |
| `dispatch_instruction` | 76 | Router assignments |
| `verdict` | 45 | Verification outcomes |
| `action_record` | 44 | Implementation work |
| `run_log` | 26 | Builder/runtime execution logs |
| `archival_record` | 22 | Closure/archival markers |
| `goal_record` | 21 | New goal receipts |
| `output_record_ids_correction` | 20 | Correction entries |
| `context_summary` | 12 | Researcher/dispatcher context summaries |
| `durable_takeaway` | 7 | Long-lived project facts |
| `convention` | 4 | Process conventions |
| `change_summary` | 2 | Concise change descriptions |
| `execution_plan` | 2 | Runtime plans |
| `hand_off_or_closure` | 2 | Combined hand-off/closure |
| `escalation_record` | 2 | Escalations |
| `pending_authorisation` | 3 | Awaiting authorisation |
| `charter_ratification` | 2 | Charter approvals |
| `builder_takeaway` | 1 | Builder takeaway |
| `authorisation_resolution` | 1 | Authorisation resolution |
| `research_findings` | 1 | Research findings |
| `plan` | 1 | Plan artifact |
| `branch` | 1 | Git branch note |
| `commit` | 1 | Git commit note |
| `linkage_correction` | 1 | Record linkage fix |
| *(no `record_type`)* | 94 | 18.7 % of corpus |

### Daily write volume

| Day | Records |
| --- | --- |
| 2026-08-01 | 188 |
| 2026-08-02 | 309 |
| 2026-08-04 | 5 |

The August 1–2 spike reflects the multi-goal ATP execution burst; August 4 is the start of the recall-efficiency work.

---

## Example recall behavior

Two spot-check queries illustrate the current signal-to-noise trade-off.

### Focused technical query: `"relay sync design"`

| Rank | `record_type` | Score | Relevance |
| --- | --- | --- | --- |
| 1 | durable takeaway / design note | 0.682 | High |
| 2 | context summary | 0.620 | High |
| 3 | action record | 0.603 | High |
| 4 | convention | 0.592 | High |
| 5 | action record | 0.592 | High |

All top-five results are on-topic and derive from the relay-sync work. A threshold of 0.45 would retain all five.

### Process-oriented query: `"memory hygiene recall score threshold"`

| Rank | `record_type` | Score | Relevance |
| --- | --- | --- | --- |
| 1 | goal_record | 0.562 | Directly relevant |
| 2 | goal_record | 0.294 | Off-topic older goal |
| 3 | action_record | 0.294 | Off-topic implementation |
| 4 | hand_off_record | 0.286 | Off-topic |
| 5 | convention | 0.282 | Off-topic |
| 6–10 | hand_off_record, durable_takeaway, verdict, etc. | 0.265–0.275 | Mostly noise |

Only the first result is directly useful; the rest are unrelated execution records that happen to share a few words. Without a cutoff, an agent would pull in a large amount of irrelevant context.

---

## Score-threshold recommendation

**Recommended minimum recall relevance score: 0.45**

Rationale:

- Focused, high-value memories in this workspace score 0.55–0.68.
- The first directly relevant result in the process query scored 0.56.
- The noise floor for tangentially related execution records begins around 0.26–0.30.
- A 0.45 cutoff keeps clearly relevant results while dropping the bulk of the long-tail noise.

This threshold aligns with the parent goal’s success criteria and can be adjusted after the first week of `recalled_memory_ids` tracking.

---

## Hygiene recommendations

1. **Always set `record_type`.** 94 records (18.7 %) lack this field. Add it retroactively where possible and make it mandatory in ATP record templates.
2. **Prefer durable takeaways over raw run logs.** Convert builder/run_log entries into `durable_takeaway` or `convention` records once a goal closes, and archive the execution noise.
3. **Tag `recalled_memory_ids` on action, context_summary, and verdict records.** This closes the recall-efficiency feedback loop and lets future audits measure which recalled memories actually influenced outcomes.
4. **Apply the 0.45 relevance cutoff in agent prompts.** Agents should only cite or act on recalled memories whose `score` is ≥ 0.45 unless explicitly overridden.
5. **Prune or archive low-signal execution records.** `output_record_ids_correction`, duplicated hand-offs, and one-off `branch`/`commit` notes can be consolidated into context summaries or archival records.
6. **Set `ttl_ms` for transient records.** Execution logs and pending-authorisation entries should expire automatically when no longer actionable.
7. **Standardise agent IDs.** Consolidate the overlapping `dispatcher` / `claude-code-cli-dispatcher` and `claude-code-cli-*` role labels so distribution analytics are cleaner.
8. **Schedule a weekly hygiene review.** Use `eden_packet` (analytical template) to re-check type distribution and recall-score distributions until the noise ratio stabilises.

---

## Files

- This audit report: `/home/yakov/git/eden-releases/docs-site/plan/memory-hygiene-audit-2026-08-04.md`
