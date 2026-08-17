# Token-Efficient ATP Hand-offs

Goal: `ca45b09d-5773-487e-afd8-c94240006da0`
Context summary: `8954e25a-a10d-4094-9c87-f941dd027988`
Status: Experimental runbook — implement, measure, and ratify before promoting to `SKILL.md`.

This runbook proposes a concrete token-efficiency experiment for the Agentic Team Protocol (ATP):

1. A structured `context_envelope` field in hand-off records, capped at **4 KB**.
2. A **router confidence pre-gate** that routes low-confidence builder outputs back to the dispatcher before invoking the verifier.
3. Per-role model/effort tuning recommendations for this project.

Target outcome: **≥ 20% reduction in average tokens per full-protocol goal** while keeping verifier green-rate and issue-catch rate neutral or improved.

---

## 1. `context_envelope` schema

The `context_envelope` is a **lossy, structured summary** that travels inside every `hand_off_record`. It is not a replacement for the full durable record; it is a compact activation signal for the next role. If the receiving role needs evidence, it recalls the upstream records by ID.

### 1.1 Field definitions

| Field | Required | Max size | Description |
|-------|----------|----------|-------------|
| `goal_id` | yes | 36 chars | UUID of the owning goal. |
| `stage` | yes | 40 chars | Current lifecycle stage, e.g. `context_gathering`, `action`, `routing_and_assignment`. |
| `next_role` | yes | 20 chars | Role that should act next: `dispatcher`, `researcher`, `builder`, `runtime`, `verifier`, `archivist`, `router`. |
| `mode` | yes | 10 chars | `lite` or `full`. |
| `decision_summary` | yes | ≤ 500 tokens / ~2 KB | What was decided, what changed, and why. Use bullet fragments, not prose. |
| `evidence_ids` | yes | list of ≤ 10 IDs | Eden-memory record IDs the next role must be able to recall. Always include the latest action/context/verdict records, not the goal ID. |
| `success_criteria` | yes | ≤ 200 tokens / ~800 B | Copy or paraphrase the success criteria from the dispatch instruction. |
| `residual_risks` | yes | ≤ 150 tokens / ~600 B | Unclosed risks that the next role must evaluate. |
| `confidence` | yes | enum | `high`, `medium`, `low`. Set by the producing role based on the checklist in §3. |
| `escalation_trigger` | if any | ≤ 100 tokens / ~400 B | Condition that should force human escalation. Omit if none. |
| `worktree_path` | if any | path string | Absolute path to the current worktree, if the goal uses one. |
| `branch_name` | if any | 100 chars | Current Git branch name, if the goal uses one. |

### 1.2 Total size budget

The serialized envelope must fit in **4 KB (4096 bytes)**. The recommended budgets above sum to roughly 3.9 KB of English text; keep fields shorter when possible. If a field cannot be compressed further, split the hand-off into two records: one envelope plus one linked detail record.

### 1.3 Where it lives

Embed the envelope inside the `hand_off_record` content as a YAML or JSON block **after** the searchable identity line and before the JSON metadata blob. Example placement:

```text
Goal: <goal_id> | Record ID: <this_record_id> | Stage: <stage> | Owner: <owner_role>

HAND-OFF SUMMARY
<free-text one-liner for humans>

```yaml
context_envelope:
  goal_id: <goal_id>
  stage: action
  next_role: verifier
  mode: full
  decision_summary: ...
  evidence_ids:
    - <record_id>
  success_criteria: ...
  residual_risks: ...
  confidence: high
  worktree_path: /home/yakov/git/eden-releases/.claude/worktrees/...
  branch_name: feat/...
```

{"record_type":"hand_off_record",...}
```

The JSON metadata blob remains unchanged so existing `eden-team` tooling can parse it.

---

## 2. Concrete example: compressed hand-off record content

The following example is a complete hand-off from a builder to the verifier. It is intentionally compact and fits under 4 KB.

```text
Goal: ca45b09d-5773-487e-afd8-c94240006da0 | Record ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890 | Stage: action | Owner: builder

HAND-OFF: Builder → Verifier. Token-efficiency runbook artefact written. No code changes.

```yaml
context_envelope:
  goal_id: ca45b09d-5773-487e-afd8-c94240006da0
  stage: action
  next_role: verifier
  mode: full
  decision_summary:
    - Wrote /home/yakov/git/eden-releases/agentic-team-protocol/runbooks/token-efficient-handoffs.md.
    - Defined 4 KB context_envelope schema and router confidence pre-gate.
    - Provided example template, decision table, and .env recommendations.
    - No binary or skill-schema changes; no worktree used (docs-only runbook).
  evidence_ids:
    - 8954e25a-a10d-4094-9c87-f941dd027988   # context_summary
    - 6528f2b0-94f5-4666-92d3-f7c816120d95     # researcher → dispatcher hand-off
    - a1b2c3d4-e5f6-7890-abcd-ef1234567890     # this action_record
  success_criteria:
    - Runbook file exists with envelope schema, example, decision table, and env recommendations.
    - File references goal_id and context_summary record ID.
    - action_record stored with correct metadata.
  residual_risks:
    - Model recommendations are based on vendor/third-party listings from 2026-08; verify MiniMax M3 independently before promoting it to primary verifier.
    - 4 KB cap may omit nuance; receiving roles must recall evidence_ids when uncertain.
  confidence: high
  escalation_trigger: none
  worktree_path: null
  branch_name: null
```

{"record_type":"hand_off_record","goal_id":"ca45b09d-5773-487e-afd8-c94240006da0","stage":"action","owner_role":"builder","agent_id":"builder","next_role":"verifier","mode":"full","input_record_ids":["8954e25a-a10d-4094-9c87-f941dd027988","6528f2b0-94f5-4666-92d3-f7c816120d95"],"output_record_ids":["a1b2c3d4-e5f6-7890-abcd-ef1234567890"],"confidence":"high","org_id":"0d3sa","workspace_id":"yakovkhalinsky/eden-releases","claude_task_id":1}
```

---

## 3. Router confidence pre-gate

Before the router spawns the verifier, it inspects the incoming `context_envelope.confidence` and any self-reported failures. The verifier gate remains **mandatory for every claimed-success outcome**; the pre-gate only decides whether the builder needs another pass first.

### 3.1 Decision table

| `confidence` | `self_test` / `self_check` field | Router action | Next role | Rationale |
|--------------|----------------------------------|---------------|-----------|-----------|
| `high` | passed or omitted | Spawn verifier with envelope only. Verifier may recall evidence IDs as needed. | `verifier` | Fast path. |
| `medium` | passed | Spawn verifier, but include a note that builder confidence is medium. Verifier should read evidence IDs. | `verifier` | Slightly wider audit. |
| `low` | passed or failed | Route back to `dispatcher` with reason: builder confidence low; request rework or researcher support. Do **not** spawn verifier yet. | `dispatcher` | Avoid wasting verifier tokens on known-weak work. |
| any | failed / self-test-red | Route back to `dispatcher` with the failure summary. Verifier is **not** invoked. | `dispatcher` | Builder already found a defect; fix it first. |
| missing envelope | n/a | Route back to `dispatcher` with reason: hand-off lacks required `context_envelope`; request a compliant hand-off. | `dispatcher` | Schema compliance gate. |
| envelope > 4 KB | n/a | Route back to `builder` with reason: envelope exceeds 4 KB; compress or split. | `builder` | Enforce size budget. |

### 3.2 Required checklist for the router

Before spawning the verifier, the router must confirm:

- [ ] The latest durable record for the goal is an `action_record` or a compliant `hand_off_record`.
- [ ] The hand-off contains a `context_envelope` block.
- [ ] The envelope is ≤ 4 KB when serialized.
- [ ] `goal_id`, `stage`, `next_role`, `mode`, `decision_summary`, `evidence_ids`, `success_criteria`, `residual_risks`, and `confidence` are all present.
- [ ] `evidence_ids` includes the latest action/context/verdict records, not just the goal ID.
- [ ] `confidence` is `high` or `medium`; if `low`, route to dispatcher.
- [ ] No self-reported failure (`self_test: failed`, `self_check: red`, etc.) is present; if found, route to dispatcher.
- [ ] The verifier model assignment matches the current `.env` policy (see §4).

If any box is unchecked, write a `run_log` explaining the deviation and route to the appropriate recovery role.

### 3.3 Verifier behaviour when receiving an envelope

1. Treat the envelope as a **reading guide**, not the only evidence.
2. Recall the records listed in `evidence_ids` before reaching a verdict.
3. If evidence is insufficient, return a `blocked` verdict with the missing record IDs rather than a `red` verdict.
4. If the envelope omits a required field, return `blocked` and ask the builder to resubmit.

---

## 4. Config / env variable recommendations

These recommendations are for the current project configuration in `/home/yakov/git/eden-releases/.env`. They are based on the context summary `8954e25a-a10d-4094-9c87-f941dd027988`.

### 4.1 Recommended changes

```bash
# Researcher: keep — strongest long-context reasoning, cheapest long-context input among proven models.
ATP_RESEARCHER_MODEL=ollama:deepseek-v4-pro:cloud
ATP_RESEARCHER_BACKEND=ollama
ATP_RESEARCHER_EFFORT=high

# Builder: keep for MCP-heavy work; add fallback rule for non-MCP-heavy goals.
ATP_BUILDER_MODEL=ollama:kimi-k2.7-code:cloud
ATP_BUILDER_BACKEND=ollama
ATP_BUILDER_EFFORT=medium

# Verifier: change primary from MiniMax M3 to DeepSeek V4 Pro until independent benchmarks confirm M3 quality.
# Use MiniMax M3 only as a secondary/diversity verifier for high-stakes goals after DeepSeek returns green.
ATP_VERIFIER_MODEL=ollama:deepseek-v4-pro:cloud
ATP_VERIFIER_BACKEND=ollama
ATP_VERIFIER_EFFORT=high

# Router/Dispatcher: keep on a competent coding model for reliable routing.
ATP_ROUTER_MODEL=ollama:kimi-k2.7-code:cloud
ATP_ROUTER_BACKEND=ollama
ATP_ROUTER_EFFORT=medium

# Archivist: can be lighter; it only summarises and links records.
ATP_ARCHIVIST_MODEL=ollama:deepseek-v4-flash:cloud
ATP_ARCHIVIST_BACKEND=ollama
ATP_ARCHIVIST_EFFORT=medium
```

### 4.2 Suggested new env flags for the experiment

```bash
# Enable the 4 KB context_envelope in hand-off records.
ATP_CONTEXT_ENVELOPE_ENABLED=1

# Maximum bytes for a context_envelope. Default 4096.
ATP_CONTEXT_ENVELOPE_MAX_BYTES=4096

# Enforce router confidence pre-gate before verifier.
ATP_ROUTER_CONFIDENCE_GATE_ENABLED=1

# Allow the dispatcher to downgrade a low-risk build goal to a cheaper builder model.
ATP_BUILDER_FALLBACK_MODEL=ollama:deepseek-v4-pro:cloud
ATP_BUILDER_FALLBACK_EFFORT=medium
```

### 4.3 How to apply

1. Edit `/home/yakov/git/eden-releases/.env` with the verifier change and the new feature flags.
2. Update `/home/yakov/git/eden-releases/agentic-team-protocol/agents/router.md` to add the pre-gate checklist (§3.2).
3. Update each role prompt (`builder.md`, `researcher.md`, `verifier.md`, etc.) to emit a `context_envelope` block at the end of every hand-off.
4. Run the measurement plan in §5 before promoting the runbook to `SKILL.md`.

---

## 5. Measurement plan

1. Select 5–10 representative full-protocol goals of varying complexity.
2. Capture per-goal token counts (or transcript-size proxy) before the envelope change.
3. Re-run equivalent goals with the envelope enabled and the confidence gate enabled.
4. Record:
   - Total tokens per goal.
   - Tokens consumed by the verifier stage.
   - Verifier green-rate.
   - Verifier issue-catch rate (number of defects found per goal).
   - Number of false-positive low-confidence reroutes.
5. Success: **≥ 20% token reduction** with **neutral or improved verifier catch rate**.

---

## 6. Rollback and risks

### 6.1 Rollback

- Delete this runbook file: `rm /home/yakov/git/eden-releases/agentic-team-protocol/runbooks/token-efficient-handoffs.md`.
- Revert any `.env` changes with `git checkout -- .env`.
- Revert any role-prompt edits with `git checkout -- agentic-team-protocol/agents/*.md`.
- Disable the experiment: set `ATP_CONTEXT_ENVELOPE_ENABLED=0` and `ATP_ROUTER_CONFIDENCE_GATE_ENABLED=0`.

### 6.2 Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| 4 KB envelope drops evidence the verifier needs. | Verifier returns `blocked` or false `green`. | Require `evidence_ids`; verifier must recall them. |
| Router incorrectly routes a `medium` confidence goal back to dispatcher, wasting a turn. | Extra latency, not extra verifier cost. | Log every pre-gate routing decision; tune thresholds after measurement. |
| Verifier model change from MiniMax M3 to DeepSeek V4 Pro affects verdict quality. | Possible regression in issue detection. | Run side-by-side comparison on sample goals before switching. |
| Schema change breaks `/team-continue` or `eden-team` parsing. | Continuation failures. | Add envelope as optional field; keep JSON metadata blob unchanged. |

---

## 7. Promotion criteria

Promote this runbook into `SKILL.md` and retire the experimental flags only when:

- [ ] Measurement plan in §5 is complete and meets the ≥ 20% token-reduction target.
- [ ] Verifier catch rate is neutral or improved.
- [ ] At least one `/team-continue` cycle has exercised the envelope end-to-end.
- [ ] The dispatcher and archivist prompts have been updated to consume the envelope.
- [ ] A maintainer has reviewed and approved the model-config changes.
