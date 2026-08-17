# Cross-Device ATP Metrics Aggregation

Goal: `2a0c59a6-6cf9-4d38-a31a-28e7eecc088f`
Status: Experimental runbook — companion to `atp-metrics-collection.md`.

This runbook explains how to collect and aggregate ATP token-efficiency
metrics across multiple devices using the existing Eden-memory relay sync
transport. It does **not** change the Eden-memory binary schema or the relay
protocol; it only adds a cross-device aggregation lens on top of the metrics
already defined in `atp-metrics-collection.md`.

---

## 1. How metrics flow across devices

ATP role agents emit a `metrics` object inside every end-of-turn `run_log`
metadata (see `runbooks/atp-metrics-collection.md`). One of those fields is
`device_id`, a stable identifier for the originating host. When a role agent
on device A writes a `run_log`, the record is stored in the local Eden-memory
SQLite database. When Eden-memory relay sync runs, the record is replicated to
paired devices.

The transport is the existing Eden-memory relay stack:

- `eden-memory sync` — one-shot sync with a paired device or relay.
- `eden-memory sync loop` — continuous background sync.
- `eden_pair_device` — pair a new device so its memories can be exchanged.

After sync, every device that is paired with device A contains the same
`run_log` records (including the `metrics.device_id` field). The aggregate
helper, `atp-metrics rebuild`, can then scan the local Eden-memory database
and produce per-device, per-role, per-goal, and quality-correlation summaries.

### Why this works without protocol changes

The `metrics` object is opaque to the Eden-memory binary. It lives in the JSON
`metadata` column of the `memories` table, which is already replicated by
`eden-memory sync`. Adding `device_id` is a convention inside the existing
metadata payload, not a schema change.

---

## 2. Enabling `device_id` on each device

Set a stable, privacy-safe device identifier in the environment of every host
that runs ATP roles:

```bash
export EDEN_DEVICE_ID="alice-laptop-7a3f"
```

If `EDEN_DEVICE_ID` is not set, derive it deterministically from the hostname
with the shared helper:

```bash
# Shell usage
export EDEN_DEVICE_ID=$(sh ./agentic_team_protocol/lib/device_id.sh)

# Python script usage
export EDEN_DEVICE_ID=$(python3 ./agentic_team_protocol/lib/device_id.py)

# Python import usage (from the project root)
python3 -c 'from agentic_team_protocol.lib.device_id import derive_device_id; print(derive_device_id())'
```

The helper produces `<project-slug>-<sha256(hostname)[0:16]>` and contains no
personal identifiers. Do **not** use usernames, full MAC addresses, serial
numbers, or any other personal identifier.

The source directory is `agentic_team_protocol/` and contains `lib/__init__.py`,
so Python can import the helper as `agentic_team_protocol.lib.device_id`.

Each ATP role prompt now requires the final `run_log` `metrics` object to
include `device_id` populated from `EDEN_DEVICE_ID` or the shared helper. See
the role prompts under `.claude/agents/` (or `agentic_team_protocol/agents/`).

---

## 3. Running `atp-metrics rebuild`

The `rebuild` subcommand rebuilds the local aggregate database from all
`run_log` records that match an org/workspace/experiment scope.

```bash
./agentic_team_protocol/bin/atp-metrics rebuild \
  --org-id 0d3sa \
  --workspace-id yakovkhalinsky/eden-releases \
  --experiment atp-metrics-20-goal-2026-08
```

If some run_log records do not yet carry `metrics.experiment_id`, use a wildcard
scan to aggregate them all:

```bash
./agentic_team_protocol/bin/atp-metrics rebuild \
  --org-id 0d3sa \
  --workspace-id yakovkhalinsky/eden-releases \
  --experiment '*'
```

### Flags

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--org-id` | yes if not in env | `EDEN_ORG_ID` | Organization scope for the scan. |
| `--workspace-id` | yes if not in env | `EDEN_WORKSPACE_ID` | Workspace scope for the scan. |
| `--experiment` | no | `atp-metrics-20-goal-2026-08` | Experiment identifier; matches `metrics.experiment_id`. Use `'*'` to scan all run_log records regardless of experiment_id. |
| `--db` | no | `~/.eden-memory/default.db` or `EDEN_DB_PATH` | Source Eden-memory database. |
| `--metrics-db` | no | `~/.eden-memory/atp-metrics.db` or `ATP_METRICS_DB_PATH` | Destination aggregate database. |
| `--prices` | no | built-in `DEFAULT_PRICE_TABLE` | Per-model price table (USD per 1M tokens). |
| `--token-ratio` | no | `4.0` | Bytes-per-token ratio for fallback estimation. |
| `--no-summary` | no | false | Skip printing the summary table. |

### What it does

1. Connects to the source Eden-memory SQLite database.
2. Selects `memories` rows where `record_type` is `run_log` (or absent), the
   `org_id`/`workspace_id` match, and `metrics.experiment_id` equals the
   requested experiment.
3. Extracts `device_id`, token estimates, cost, model, verdict, etc.
4. **Clears** the existing aggregate tables and `run_log_metrics` staging table.
5. Re-inserts the selected rows, deduplicated by source record ID.
6. Recomputes per-goal, per-role, per-stage, per-device, and
   quality-correlation aggregates.

### Dedup

Because the same `run_log` may have been synced from multiple devices, the
rebuild uses the Eden-memory record ID as the primary key in
`run_log_metrics`. The `ON CONFLICT(id) DO UPDATE` clause keeps the last
ingested copy; when all source databases are the same synced set, the IDs are
identical and only one row is retained.

### Example output

```text
ATP token-efficiency metrics summary
| goal_id      | mode | roles | turns | total_tokens | cost_usd | duration_s | verdict | transitions | red | reopen |
| ------------ | ---- | ----- | ----- | ------------ | -------- | ---------- | ------- | ----------- | --- | ------ |
| 2a0c59a6-6cf | -    | 2     | 3     | 7200         | 0.0216   | 0          | green   | 3           | 0   | 0      |

Ingested run_log rows: 3

Cross-device aggregate views
  per_goal rows: 1
  per_role rows: 2
  per_device rows: 2
  quality_correlation rows: 1
```

---

## 4. Querying the aggregate views

`atp-metrics rebuild` creates the following SQLite views in the aggregate
database:

### `per_goal`

Totals and averages per goal.

```sql
SELECT goal_id, total_tokens_est, cost_estimate_usd, transition_count,
       avg_total_tokens_per_transition, final_verdict
FROM per_goal;
```

Key columns: `goal_id`, `mode`, `experiment_id`, `total_*_tokens_est`,
`avg_*_tokens_per_transition`, `transition_count`, role/verdict/rework/reopen
counts, `cost_estimate_usd`, `final_verdict`.

### `per_role`

Totals and averages per role across all goals.

```sql
SELECT role, goals, turns, total_tokens_est,
       avg_total_tokens_per_turn, cost_estimate_usd
FROM per_role;
```

### `per_device`

Totals and averages per originating device.

```sql
SELECT device_id, turns, goals, total_tokens_est,
       avg_total_tokens_per_turn, cost_estimate_usd
FROM per_device;
```

This is the cross-device view: it groups by `metrics.device_id` and shows how
much each host contributed to the experiment.

### `quality_correlation`

Joins per-goal metrics with the final verdict quality/status.

```sql
SELECT goal_id, final_verdict, verdict_quality, total_tokens_est,
       cost_estimate_usd, transition_count, rework_count
FROM quality_correlation;
```

`verdict_quality` is a numeric mapping:

- `green` → `1`
- `blocked` → `0`
- `red` → `-1`
- missing verdict → `NULL`

Use this view to correlate token spend, churn, and rework with outcome
quality.

---

## 5. Privacy considerations

`device_id` is designed to be a stable but non-identifying label.

- **Do** use a project-specific slug plus a short hash of the hostname, or a
  per-install identifier written to `~/.eden-memory/device_id`.
- **Do not** include usernames, full MAC addresses, serial numbers, IP
  addresses, or anything that can be tied back to a person without consent.
- The aggregate database is local by default (`~/.eden-memory/atp-metrics.db`).
  If you export it, scrub or hash `device_id` first if the export leaves the
  originating trust boundary.
- If a deterministic identifier cannot be derived, use `unknown`. Missing
  `device_id` rows will appear under `device_id = 'unknown'` in `per_device`.

---

## 6. `metric_record` fallback

If a role cannot include the full `metrics` object in a `run_log` (for example,
because the record type is not a `run_log`), it may write a separate
`metric_record` with the same schema. `atp-metrics rebuild` currently consumes
`run_log` records only; a future extension can add `metric_record` support
without changing the Eden-memory binary schema.

Until that extension is needed, do **not** implement the fallback. Keep the
convention simple: one `metrics` object per end-of-turn `run_log`.

---

## 7. Rollback

To undo the cross-device metrics additions and return to the baseline
ATP lifecycle:

1. **Disable metrics collection**:
   ```bash
   # In your project .env or shell environment
   ATP_METRICS_ENABLED=0
   ```
2. **Stop the aggregate helper**:
   - Remove any scripts, aliases, or cron jobs that run
     `./agentic_team_protocol/bin/atp-metrics rebuild` automatically.
   - You may keep `bin/atp-metrics` for manual analysis, but it must not be
     required by role prompts.
3. **Revert the role-prompt edits**:
   - In every file under `agentic_team_protocol/agents/`, remove the requirement
     that end-of-turn `run_log` records include a `metrics` object with
     `device_id`, `experiment_id`, and the other metrics fields.
4. **Delete the shared device-id helpers**:
   ```bash
   rm -f agentic_team_protocol/lib/device_id.sh
   rm -f agentic_team_protocol/lib/device_id.py
   rm -f agentic_team_protocol/lib/__init__.py
   ```
5. **Revert environment wiring**:
   - Remove or comment the `EDEN_DEVICE_ID` line in
     `agentic_team_protocol/.env.example`.
6. **Remove this runbook** (optional):
   ```bash
   rm -f agentic_team_protocol/runbooks/cross-device-atp-metrics.md
   ```

After rollback, the only durable trace of the experiment should be archived
Eden-memory records; the working tree should be back to the pre-experiment ATP
state.

---

## 8. Files

- Runbook: `/home/yakov/git/eden-releases/agentic_team_protocol/runbooks/cross-device-atp-metrics.md`
- Metrics schema runbook: `/home/yakov/git/eden-releases/agentic_team_protocol/runbooks/atp-metrics-collection.md`
- Helper script: `/home/yakov/git/eden-releases/agentic_team_protocol/bin/atp-metrics`
- Role prompts: `/home/yakov/git/eden-releases/agentic_team_protocol/agents/*.md`
