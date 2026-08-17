# ATP-orchestrated Event Insights Workflow

This runbook describes how the headless ATP supervisor `eden-team` drives the
end-to-end Eden Business Simulator workflow: generate a persisted business event
stream, analyze it, and store a durable `insights_report` Eden-memory record
linked to the ATP goal.

## Goal

Use `eden-team` to execute the event-insights workflow so that every produced
stream has a reproducible, verifiable analytics pass that is discoverable in
Eden-memory through the current `EDEN_GOAL_ID`.

## Components

| Component | Location |
|---|---|
| ATP supervisor | `/home/yakov/git/eden-memory/eden-team` |
| Orchestration script | `/home/yakov/git/eden-releases/scripts/atp_insights_run.py` |
| Simulator CLI | `eden-business-simulator` in `/home/yakov/git/eden-business-simulator` |
| Insights docs | `/home/yakov/git/eden-business-simulator/docs/insights.md` |


## Migration note

The `atp-run` supervisor was removed from `eden-releases` on 2026-08-05.
The same headless ATP functionality now lives in the `eden-team` binary in
`/home/yakov/git/eden-memory`. Build it with `make build-team` from the
`eden-memory` repository; the binary is produced as `eden-team` in the repository
root. Update any local runbook paths and MCP configs from
`agentic_team_protocol/` to `cmd/eden-team/` inside `eden-memory`.

## Orchestration script

`/home/yakov/git/eden-releases/scripts/atp_insights_run.py` is a thin Python
glue script that knows how to invoke the simulator CLI through `uv run`. It:

1. Creates a working directory for the stream.
2. Runs `eden-business-simulator daemon --business <type> --stream-id <id>
   --storage sqlite --max-events <N> --no-realtime --output none`.
3. Runs `eden-business-simulator insights <stream_id> --storage sqlite
   --output-dir <dir>`.
4. Exports `EDEN_GOAL_ID` and `EDEN_WORKSPACE_ID` into the subprocess
   environment so the `insights` command stores the report memory under the
   correct ATP goal and workspace.
5. Writes a JSON run report with exit codes, artifact paths, and the linked
   Eden-memory record ID.

### Arguments

```text
atp_insights_run.py <business_type> <stream_id>
  [--events N]
  [--rate R]
  [--seed S]
  [--realtime]
  [--work-dir DIR]
  [--output-dir DIR]
  [--simulator-dir DIR]
  [--goal-id GOAL_ID]
  [--eden-memory-db PATH]
```

- `business_type` — domain to simulate, e.g. `ecommerce`, `gym`, `cafe`, `saas`.
- `stream_id` — durable identifier used for the SQLite DB and insights output.
- `--events` — stop the daemon after this many events (default 50). Keep small
  for deterministic ATP validation.
- `--realtime` — when omitted, generation runs as fast as possible.
- `--goal-id` — defaults to `EDEN_GOAL_ID` from the environment, falling back
  to the fixed ATP goal `76fbaeac-698b-444f-82f9-4f77aa431e54` for standalone
  testing.

### Environment variables

| Variable | Purpose |
|---|---|
| `EDEN_GOAL_ID` | ATP goal ID attached to the `insights_report` memory. |
| `EDEN_BUSINESS_SIMULATOR_DIR` | Override the simulator checkout path. |
| `EDEN_MEMORY_DB` | Override the Eden-memory SQLite path. |
| `EDEN_WORKSPACE_ID` | The script overrides this with the simulator directory so memories are stored in the simulator workspace. |

## Manual / standalone run

```bash
export EDEN_GOAL_ID=76fbaeac-698b-444f-82f9-4f77aa431e54
cd /home/yakov/git/eden-releases
python3 scripts/atp_insights_run.py ecommerce atp_ecom_demo_001
```

This leaves artifacts in `/tmp/atp-insights-atp_ecom_demo_001/` and a run report
at `/tmp/atp-insights-atp_ecom_demo_001/atp_insights_run.json`.

## ATP integration

Use `eden-team start` with an inline goal that instructs the Runtime role to
execute the script. `eden-team` forwards the generated `EDEN_GOAL_ID` to the role
process, and the script propagates it to the simulator CLI:

```bash
/home/yakov/git/eden-memory/eden-team start \
  --goal "Run the event-insights workflow for the ecommerce business. Execute /home/yakov/git/eden-releases/scripts/atp_insights_run.py ecommerce atp_ecom_$(date +%Y%m%d%H%M%S) --events 50. Verify that the run report JSON shows daemon_exit_code=0, insights_exit_code=0, and a non-null memory_record id. Return the SQLite stream path and the insights_report.json path." \
  --mcp-config /home/yakov/git/eden-memory/cmd/eden-team/mcp.json \
  --dangerously-skip-permissions \
  --verbose
```

Because the script reads `EDEN_GOAL_ID` from the environment, the resulting
`insights_report` memory is automatically linked to the goal that `eden-team`
created.

## Verification

After a run, confirm the memory link:

```bash
cd /home/yakov/git/eden-business-simulator
eden-memory --db ~/.eden-memory/default.db recall \
  -agent-id eden-business-simulator \
  -user-id "$USER" \
  -workspace-id /home/yakov/git/eden-business-simulator \
  -query "insights_report <stream_id>" \
  -limit 1 \
  -format json
```

The returned record should contain:

- `metadata.record_type`: `insights_report`
- `metadata.goal_id`: the current ATP goal ID
- `content`: a JSON summary with `stream_id`, `business_type`, `event_count`,
  `duration_seconds`, `anomaly_flag_count`, and `artifact_dir`.

## Success criteria

1. `eden-team` can dispatch the script without modifying the simulator CLI or
   the `eden-team` binary.
2. A short stream (default 50 events) is generated and persisted to SQLite.
3. Insights artifacts are written to the requested output directory.
4. An `insights_report` Eden-memory record exists and references the ATP goal
   via `metadata.goal_id`.
5. The run report JSON captures exit codes, paths, and the linked memory ID.

## Constraints

- Do not change live production systems; this script targets local/CI streams.
- Do not commit to the default branch; keep ATP glue work on a feature branch.
- The simulator CLI is treated as a stable dependency; if the CLI surface
  changes, escalate instead of silently patching the script.
