# ATP Token-Efficiency Metrics Collection

Goal: `50598512-4eb0-4e0b-b0a1-f2ccbe1f0f7d`
Context summary: `38aa53f5-50da-4566-a833-8de79f4d67fa`
Status: Experimental runbook — implement, measure, and ratify before promoting to `SKILL.md`.

This runbook defines a minimal, schema-compatible token-efficiency metrics
collection setup for the Agentic Team Protocol (ATP). It embeds a `metrics`
object in `run_log` metadata (no Eden-memory binary schema change) and provides a
local SQLite aggregation helper, `atp-metrics`, to compute per-goal, per-stage,
and per-role aggregates.

Target outcome: **>= 15% median token reduction on full-protocol goals** in a
20-goal experiment window, while keeping `red` verdict and post-closure re-open
rates within +5 percentage points of baseline.

---

## 1. Opt-in experiment flag

Set in the project `.env` or `agentic-team-config.yaml`:

```bash
# Enable the 20-goal token-efficiency metrics experiment.
ATP_METRICS_ENABLED=1

# Optional: override the aggregate database path.
ATP_METRICS_DB_PATH=${HOME}/.eden-memory/atp-metrics.db
```

When `ATP_METRICS_ENABLED=1`, every ATP role must append a `metrics` object to
the metadata of every `run_log` it writes. Roles must still write `run_log`
records when the flag is disabled, but may omit the `metrics` object.

---

## 2. `metrics` JSON schema for `run_log` metadata

The `metrics` object is a sibling of other `run_log` metadata fields. It is
optional and ignored by the Eden-memory binary; only `atp-metrics` and downstream
analysts consume it.

### 2.1 Field definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `enabled` | boolean | yes | Must be `true` when `ATP_METRICS_ENABLED=1`. Lets the helper distinguish experimental records from baseline records. |
| `experiment_id` | string | yes | Stable experiment identifier. Default: `atp-metrics-20-goal-2026-08`. |
| `device_id` | string | yes | Stable identifier for the originating device/host where this `run_log` was produced. Prefer the value of the `EDEN_DEVICE_ID` environment variable; otherwise derive a deterministic ID from the hostname (e.g., a hash or sanitized hostname) or use a persistent per-install identifier. Must not include PII such as a username or full MAC address. |
| `role` | string | yes | Role that produced the `run_log`: `dispatcher`, `researcher`, `builder`, `runtime`, `verifier`, `archivist`, `router`. |
| `stage` | string | yes | Lifecycle stage at turn end, e.g. `goal_receipt`, `routing_and_assignment`, `context_gathering`, `action`, `verification`, `recording_and_archival`, `hand_off_or_closure`. |
| `turn_start` | RFC3339 | yes | ISO timestamp when the role turn started. |
| `turn_end` | RFC3339 | yes | ISO timestamp when the role turn ended (just before writing the `run_log`). |
| `input_tokens_est` | integer | yes | Estimated input tokens consumed by this turn. See §4 for estimation rules. |
| `output_tokens_est` | integer | yes | Estimated output tokens consumed by this turn. See §4 for estimation rules. |
| `total_tokens_est` | integer | yes | `input_tokens_est + output_tokens_est`. |
| `cost_estimate_usd` | float | recommended | Estimated cost in USD for this turn: `(input_tokens_est × input_price + output_tokens_est × output_price) / 1_000_000`. Prices are taken from the configured price table (see §2.5). |
| `context_size` | integer | recommended | Approximate size in bytes of the context window handed to the model (content + metadata + recalled memories). Used as a fallback token proxy. |
| `model` | string | yes | Model identifier used for the turn, e.g. `ollama:kimi-k2.7-code:cloud` or `anthropic:sonnet`. |
| `backend` | string | yes | Backend used: `anthropic`, `ollama`, etc. |
| `effort` | string | yes | Claude Code `--effort` value: `low`, `medium`, `high`. |
| `lifecycle_transition` | boolean | yes | `true` if this `run_log` marks the end of a lifecycle stage and a hand-off to another role. Used to count transitions. |
| `verdict` | string | optional | `green`, `red`, `blocked`, or `null`. Required for the verifier's final `run_log`; omit for other roles. |
| `rework` | boolean | optional | `true` if the turn was triggered by a `red` or `blocked` verdict from an earlier attempt. Used to compute rework rate. |
| `reopen` | boolean | optional | `true` if this action occurs after a prior `archival_record` for the same `goal_id`. Used to compute post-closure re-open rate. |
| `human_intervention` | boolean | optional | `true` if the role paused for explicit human approval or clarification during the turn. |
| `notes` | string | optional | Free-text clarification, e.g. "verifier bypassed by human". |

### 2.2 Total size budget

The `metrics` object is machine-generated JSON and must stay under **2 KB**
when serialized. Keep `notes` under 200 bytes.

### 2.3 Where it lives

Embed `metrics` inside the `run_log` metadata JSON blob (the trailing JSON block
in the record content, which `atp-metrics` also parses as a fallback):

```json
{
  "record_type": "run_log",
  "goal_id": "50598512-4eb0-4e0b-b0a1-f2ccbe1f0f7d",
  "stage": "action",
  "owner_role": "builder",
  "agent_id": "builder",
  "status": "in_progress",
  "input_record_ids": ["<parent_record_id>"],
  "output_record_ids": ["<this_record_id>"],
  "recalled_memory_ids": ["<memory_id>"],
  "org_id": "0d3sa",
  "workspace_id": "yakovkhalinsky/eden-releases",
  "metrics": {
    "enabled": true,
    "experiment_id": "atp-metrics-20-goal-2026-08",
    "device_id": "device-abc123",
    "role": "builder",
    "stage": "action",
    "turn_start": "2026-08-17T10:00:00Z",
    "turn_end": "2026-08-17T10:05:00Z",
    "input_tokens_est": 15000,
    "output_tokens_est": 3000,
    "total_tokens_est": 18000,
    "cost_estimate_usd": 0.054,
    "context_size": 54000,
    "model": "ollama:kimi-k2.7-code:cloud",
    "backend": "ollama",
    "effort": "medium",
    "lifecycle_transition": false,
    "verdict": null,
    "rework": false,
    "reopen": false,
    "human_intervention": false,
    "notes": null
  }
}
```

The `run_log` content begins with the searchable identity line, may include
free text, and ends with the JSON metadata block. The `atp-metrics` helper
merges the `metadata` column with the trailing JSON block so the `metrics`
object is found regardless of which store wrote the record.

### 2.4 Example `run_log` content block

```text
Goal: 50598512-4eb0-4e0b-b0a1-f2ccbe1f0f7d | Record ID: <this_record_id> | Stage: action | Owner: builder

RUN LOG — builder turn complete; handing off to verifier.

{"record_type":"run_log","goal_id":"50598512-4eb0-4e0b-b0a1-f2ccbe1f0f7d","stage":"action","owner_role":"builder","agent_id":"builder","status":"completed","input_record_ids":["<parent>"],"output_record_ids":["<this>"],"recalled_memory_ids":["<memory>"],"org_id":"0d3sa","workspace_id":"yakovkhalinsky/eden-releases","metrics":{"enabled":true,"experiment_id":"atp-metrics-20-goal-2026-08","device_id":"device-abc123","role":"builder","stage":"action","turn_start":"2026-08-17T10:00:00Z","turn_end":"2026-08-17T10:05:00Z","input_tokens_est":15000,"output_tokens_est":3000,"total_tokens_est":18000,"cost_estimate_usd":0.054,"context_size":54000,"model":"ollama:kimi-k2.7-code:cloud","backend":"ollama","effort":"medium","lifecycle_transition":true,"verdict":null,"rework":false,"reopen":false,"human_intervention":false,"notes":null}}
```

### 2.5 Default model price table

`cost_estimate_usd` is derived from per-model input and output prices:

```
cost_estimate_usd = (input_tokens_est × input_price + output_tokens_est × output_price) / 1_000_000
```

Prices are in **USD per 1,000,000 tokens**. The `atp-metrics` helper ships with an
illustrative `default_price_table` for the models referenced by the ATP prompts.
Because provider pricing changes, treat these defaults as placeholders and refresh
them from the provider before reporting real costs.

```json
{
  "default_price_table": {
    "claude-sonnet": {"input": 3.00, "output": 15.00},
    "claude-haiku": {"input": 0.25, "output": 1.25},
    "claude-opus": {"input": 15.00, "output": 75.00},
    "kimi-k2.7-code": {"input": 2.00, "output": 8.00},
    "deepseek-v4-pro": {"input": 1.50, "output": 6.00},
    "deepseek-v4-flash": {"input": 0.50, "output": 2.00},
    "minimax-m3": {"input": 2.50, "output": 10.00}
  }
}
```

The helper matches `metrics.model` against this table. Backend prefixes such as
`ollama:` or `anthropic:` are stripped, and a substring match is used as a
fallback. Override the table with `--prices` or the `ATP_METRICS_PRICE_TABLE`
environment variable.

---

## 3. How each role populates the metrics object

Roles write a `run_log` at the **start** and **end** of each turn. Only the
**end-of-turn** `run_log` must include the `metrics` object.

### `device_id`

Every role must set `metrics.device_id` to a stable identifier for the device or
host that produced the `run_log`. Use this precedence:

1. `EDEN_DEVICE_ID` environment variable, if set. The project `.env.example`
   derives this automatically with `./agentic_team_protocol/lib/device_id.sh`.
2. A deterministic, privacy-safe derived ID from the hostname using the shared
   helper: `./agentic_team_protocol/lib/device_id.sh` (shell) or
   `agentic_team_protocol/lib/device_id.py` (Python, importable as
   `from agentic_team_protocol.lib.device_id import derive_device_id`). The
   helper produces `<project-slug>-<sha256(hostname)[0:16]>` and contains no PII.
3. A persistent per-install identifier written to `~/.eden-memory/device_id`.

Do not include usernames, full MAC addresses, serial numbers, or other personal
identifiers in `device_id`. If a deterministic identifier cannot be derived, use
the literal `unknown`.

### Dispatcher

- `role`: `dispatcher`
- `stage`: `goal_receipt` or `routing_and_assignment` (or `plan` in Lite mode)
- `lifecycle_transition`: `true` when writing the final `run_log` before handing
  off to the next role.
- `model` / `backend` / `effort`: from the effective role configuration.
- `input_tokens_est` / `output_tokens_est`: estimate from the prompt/context
  size and response length.

### Researcher

- `role`: `researcher`
- `stage`: `context_gathering`
- `lifecycle_transition`: `true` at hand-off to builder/runtime.
- Include `context_size` of the recalled memory corpus used for the summary.

### Builder / Runtime

- `role`: `builder` or `runtime`
- `stage`: `action` (or `cleanup` for cleanup records)
- `lifecycle_transition`: `true` at hand-off to verifier.
- `rework`: `true` if this turn was triggered by a `red` verdict on a previous
  action attempt.
- `reopen`: `true` if an `action_record` is written after a prior
  `archival_record` for the same goal.
- `human_intervention`: `true` if a `pending_authorisation` step was required.

### Verifier

- `role`: `verifier`
- `stage`: `verification`
- `verdict`: `green`, `red`, or `blocked` — required.
- `lifecycle_transition`: `true` at hand-off to archivist (green), dispatcher
  (red), or owning role (blocked).

### Archivist

- `role`: `archivist`
- `stage`: `recording_and_archival` or `hand_off_or_closure`
- `lifecycle_transition`: `true` at final closure.

### Router

- `role`: `router`
- `stage`: `routing_and_assignment`
- `lifecycle_transition`: `true` when the router writes the hand-off record
  and dispatches the next role.

---

## 4. Token estimation rules

The current Eden-memory / Claude Code CLI integration does not expose exact
token counts per role turn. Until it does, estimate tokens as follows:

1. **Input tokens** ≈ `context_size / 4` bytes-per-token ratio, rounded up, plus
   any image or tool-result overhead. Use the actual `context_size` the role
   measured from the context window handed to the model.
2. **Output tokens** ≈ response text bytes / 4, rounded up.
3. **Fallback**: if `context_size` is unavailable, use the byte size of the
   role's end-of-turn `run_log` content multiplied by 1.5 as a rough proxy for
   context window size, then divide by 4.
4. Record the estimation method in `metrics.notes` when a fallback is used, e.g.
   `notes: "token estimate from context_size/4"`.

The helper script (`atp-metrics`) recomputes `total_tokens_est` from
`input_tokens_est + output_tokens_est` and warns when the stored total differs.
It also accepts a `--token-ratio` flag to change the bytes-per-token ratio.

---

## 5. Helper script: `atp-metrics`

Location: `agentic_team_protocol/bin/atp-metrics`

A Python 3 script that reads `run_log` records from the Eden-memory SQLite
database, extracts embedded `metrics` metadata, and writes aggregated results to a
local SQLite database (default `~/.eden-memory/atp-metrics.db`) or a JSONL file.

### 5.1 Usage

```bash
# Aggregate a single goal.
./agentic_team_protocol/bin/atp-metrics --goal-id 50598512-4eb0-4e0b-b0a1-f2ccbe1f0f7d

# Aggregate all full-protocol goals in a date window.
./agentic_team_protocol/bin/atp-metrics --since 2026-08-01 --until 2026-08-31 --mode full

# Write aggregates to a JSONL file instead of the default SQLite DB.
./agentic_team_protocol/bin/atp-metrics --goal-id <goal-id> --output jsonl --output-file ./atp-metrics.jsonl

# Override paths.
ATP_METRICS_DB_PATH=/tmp/metrics.db ./agentic_team_protocol/bin/atp-metrics --db /home/yakov/.eden-memory/default.db --goal-id <goal-id>

# Override the model price table (JSON file or inline JSON).
./agentic_team_protocol/bin/atp-metrics --goal-id <goal-id> \
  --prices '{"claude-sonnet":{"input":3,"output":15},"claude-haiku":{"input":0.25,"output":1.25}}'

# Print a per-goal and per-role cost breakdown from existing aggregates.
./agentic_team_protocol/bin/atp-metrics cost --goal-id <goal-id>

# Rebuild cross-device aggregates for an experiment (see runbooks/cross-device-atp-metrics.md).
./agentic_team_protocol/bin/atp-metrics rebuild \
  --org-id 0d3sa --workspace-id yakovkhalinsky/eden-releases \
  --experiment atp-metrics-20-goal-2026-08
```

### 5.2 Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ATP_METRICS_ENABLED` | `0` | Set to `1` to tell roles to emit the `metrics` object. The helper script runs regardless of this flag. |
| `ATP_METRICS_DB_PATH` | `${HOME}/.eden-memory/atp-metrics.db` | Aggregate database path. |
| `ATP_METRICS_PRICE_TABLE` | built-in `DEFAULT_PRICE_TABLE` | JSON file path or inline JSON with per-model input/output prices (USD per 1M tokens). |
| `EDEN_DB_PATH` | `${HOME}/.eden-memory/default.db` | Source Eden-memory database path. |
| `EDEN_ORG_ID` | resolved from `.env` / config | Organization scope for queries. |
| `EDEN_WORKSPACE_ID` | resolved from `.env` / config | Workspace scope for queries. |
| `EDEN_DEVICE_ID` | `unknown` | Stable identifier for the host producing `run_log` metrics. Must be privacy-safe. |

### 5.3 Aggregate database schema

The helper creates the following tables in `ATP_METRICS_DB_PATH`:

- `goal_summary` — one row per goal:
  - `goal_id`, `mode`, `experiment_id`, `first_record_at`, `last_record_at`,
    `duration_seconds`, `total_input_tokens_est`, `total_output_tokens_est`,
    `total_tokens_est`, `transition_count`, `role_count`, `green_count`,
    `red_count`, `blocked_count`, `rework_count`, `reopen_count`,
    `human_intervention_count`, `cost_estimate_usd`, `final_verdict`, `recorded_at`.
- `role_summary` — one row per `(goal_id, role)`:
  - `goal_id`, `role`, `turns`, `total_input_tokens_est`,
    `total_output_tokens_est`, `total_tokens_est`, `lifecycle_transitions`,
    `cost_estimate_usd`, `first_turn_at`, `last_turn_at`.
- `stage_summary` — one row per `(goal_id, stage)`:
  - `goal_id`, `stage`, `turns`, `total_input_tokens_est`,
    `total_output_tokens_est`, `total_tokens_est`, `cost_estimate_usd`,
    `first_turn_at`, `last_turn_at`.
- `run_log_metrics` — one row per source `run_log`:
  - `id`, `goal_id`, `role`, `stage`, `device_id`, `stored_at`, `metrics_json`,
    `input_tokens_est`, `output_tokens_est`, `total_tokens_est`,
    `cost_estimate_usd`, `lifecycle_transition`, `verdict`, `rework`, `reopen`,
    `human_intervention`, `source_db`, `ingested_at`.
- Cross-device aggregate views (created by `atp-metrics rebuild`):
  - `per_goal` — totals and averages per goal.
  - `per_role` — totals and averages per role.
  - `per_device` — totals and averages per originating device.
  - `quality_correlation` — per-goal metrics joined with final verdict status.
  See `runbooks/cross-device-atp-metrics.md` for query examples.

### 5.4 Summary table output

When run interactively, the script prints a Markdown table to stdout:

```text
| goal_id | mode | roles | turns | total_tokens | cost_usd | duration | final_verdict |
|---------|------|-------|-------|--------------|----------|----------|---------------|
| 50598512-... | full | 4 | 7 | 84200 | 0.1234 | 245s | green |
```

---

## 6. 20-goal experiment plan

### 6.1 Window definition

- Experiment ID: `atp-metrics-20-goal-2026-08`.
- Cohort: the next **20 full-protocol (`/team-full`) goals** started after the
  runbook is ratified, with `ATP_METRICS_ENABLED=1`.
- Baseline: the 20 full-protocol goals immediately preceding the experiment
  window, with `metrics.enabled == false` or `metrics` absent.

### 6.2 Data collected

For each goal:

- Per-role token estimates (`dispatcher`, `researcher`, `builder`, `runtime`,
  `verifier`, `archivist`, `router`).
- Per-stage token estimates.
- Total goal tokens, duration, lifecycle transition count.
- Verdict counts (`green`, `red`, `blocked`).
- Rework count (goals with at least one `red` or `blocked` verdict followed by
  a subsequent action).
- Re-open count (goals with a new `action_record` after an `archival_record`).
- Human intervention count (goals with at least one `pending_authorisation`
  or explicit human-approval pause).

### 6.3 Analysis

- **Tokens**: compare median and p95 total tokens per goal between cohorts.
  Use Mann-Whitney U test or bootstrap percentile CI.
- **Verdict rates**: compare `red` and `re-open` proportions with a two-
  proportion z-test.
- **Transition churn**: compare median lifecycle transitions per goal.
- **Alarm thresholds**:
  - `red` rate more than +5 percentage points above baseline.
  - `re-open` rate more than +5 percentage points above baseline.
  - Any verifier-bypass event (verdict manually overridden without a new
    verifier turn).

### 6.4 Success thresholds

- Primary: **>= 15% median token reduction** in the experiment cohort vs.
  baseline.
- Guardrail: `red` verdict rate and post-closure re-open rate must stay within
  **+5 percentage points** of baseline.
- Secondary (informational): non-inferior median time-to-verdict and lifecycle
  transition count.

### 6.5 Rollback

If the experiment fails the primary threshold or breaches a guardrail, roll back
the metrics experiment cleanly:

1. **Disable the experiment flag**:
   ```bash
   # In your project .env or shell environment
   ATP_METRICS_ENABLED=0
   ```
2. **Stop requiring the `metrics` object in role prompts**:
   - Revert the edits in `agentic_team_protocol/agents/builder.md`,
     `agentic_team_protocol/agents/dispatcher.md`,
     `agentic_team_protocol/agents/researcher.md`,
     `agentic_team_protocol/agents/router.md`,
     `agentic_team_protocol/agents/runtime.md`,
     `agentic_team_protocol/agents/verifier.md`, and
     `agentic_team_protocol/agents/archivist.md`.
   - Remove any lines that require `metrics.device_id`, `metrics.experiment_id`,
     or the full `metrics` object.
3. **Stop using `atp-metrics` for automatic aggregation**:
   - Remove any cron jobs, CI steps, or wrapper scripts that run
     `atp-metrics rebuild` automatically.
   - The helper can remain in `bin/` for ad-hoc analysis, but it should not be
     part of the default ATP lifecycle.
4. **Delete the shared device-id helpers** (if they are no longer needed):
   ```bash
   rm -f agentic_team_protocol/lib/device_id.sh
   rm -f agentic_team_protocol/lib/device_id.py
   rm -f agentic_team_protocol/lib/__init__.py
   rm -f agentic_team_protocol  # top-level symlink alias, if it exists
   ```
5. **Revert environment wiring**:
   - Remove or comment the `EDEN_DEVICE_ID` line in
     `agentic_team_protocol/.env.example`.
6. **File a follow-up research goal** to understand the failure mode and decide
   whether to redesign the experiment.

---

## 7. SKILL.md and role prompt updates

Add the following minimal obligations to `SKILL.md` and each role prompt file:

- When `ATP_METRICS_ENABLED=1`, every end-of-turn `run_log` must include a
  `metrics` object that conforms to the schema in §2.
- The `metrics` object must include `enabled: true` and the current
  `experiment_id`.
- Roles must still write `run_log` records when metrics are disabled; the
  `metrics` object is optional in that case.

The helper script itself documents the full schema and aggregation rules. Role
prompts should reference this runbook rather than duplicating the schema.

---

## 8. Risks and mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Token estimates are noisy. | Threatens the 15% threshold. | Use consistent estimation rules (§4); report confidence intervals, not point differences. |
| Roles forget to populate `metrics`. | Missing data in the cohort. | Add the obligation to role prompts and `SKILL.md`; `atp-metrics` warns on records with `ATP_METRICS_ENABLED=1` but missing `metrics`. |
| Metrics object bloats metadata. | Larger Eden-memory rows. | Cap at 2 KB; store only scalar estimates and booleans. |
| Verdict outcomes come from `verdict` records, not only `run_log`. | Summary final_verdict may be wrong. | The helper reads both `run_log` and `verdict` records and prefers the latest `verdict` record for `final_verdict`. |
| Date-range queries rely on `stored_at` metadata. | Records without `stored_at` are skipped. | Require `stored_at` on all ATP records per `SKILL.md`; the helper falls back to `created_at` only as a last resort. |

---

## 9. Promotion criteria

Promote this runbook into `SKILL.md` and retire the experimental flag only when:

- [ ] The 20-goal experiment window is complete and the primary >= 15% token
      reduction threshold is met.
- [ ] `red` and re-open rates are within +5 percentage points of baseline.
- [ ] `atp-metrics` has been used successfully to aggregate at least one real
      goal end-to-end.
- [ ] A maintainer has reviewed the schema and the helper script.

---

## 10. Files

- Runbook: `/home/yakov/git/eden-releases/agentic_team_protocol/runbooks/atp-metrics-collection.md`
- Helper script: `/home/yakov/git/eden-releases/agentic_team_protocol/bin/atp-metrics`
- Env template: `/home/yakov/git/eden-releases/agentic_team_protocol/.env.example`
