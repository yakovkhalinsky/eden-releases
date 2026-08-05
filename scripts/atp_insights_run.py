#!/usr/bin/env python3
"""ATP-orchestrated event-insights workflow for the Eden Business Simulator.

This script is the glue that lets ``eden-team`` drive an end-to-end workflow:

1. Generate a short, persisted SQLite event stream with
   ``eden-business-simulator daemon``.
2. Analyze the stream with ``eden-business-simulator insights``.
3. Ensure the resulting ``insights_report`` Eden-memory record is linked to the
   current ATP goal via ``EDEN_GOAL_ID``.

It is intentionally small and shell-free so it can be invoked from a headless
ATP role process.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


DEFAULT_SIMULATOR_DIR = "/home/yakov/git/eden-business-simulator"
DEFAULT_GOAL_ID = "76fbaeac-698b-444f-82f9-4f77aa431e54"


def _simulator_cli(simulator_dir: str) -> list[str]:
    """Return the invocation prefix for the simulator CLI."""
    return ["uv", "run", "--project", simulator_dir, "eden-business-simulator"]


def _run_daemon(
    business_type: str,
    stream_id: str,
    simulator_dir: str,
    work_dir: Path,
    events: int,
    rate: float,
    seed: int,
    realtime: bool,
    env: dict[str, str],
) -> int:
    db_path = work_dir / f"{stream_id}.db"
    cmd = _simulator_cli(simulator_dir) + [
        "daemon",
        business_type,
        "--stream-id", stream_id,
        "--storage", "sqlite",
        "--storage-uri", str(db_path),
        "--output", "none",
        "--max-events", str(events),
        "--rate", str(rate),
        "--seed", str(seed),
    ]
    if not realtime:
        cmd.append("--no-realtime")

    result = subprocess.run(cmd, cwd=work_dir, env=env, text=True, capture_output=True)
    if result.returncode != 0:
        print("[daemon] failed", file=sys.stderr)
        print(result.stderr or result.stdout, file=sys.stderr)
    else:
        print("[daemon]", result.stderr.strip())
    return result.returncode


def _run_insights(
    stream_id: str,
    simulator_dir: str,
    work_dir: Path,
    output_dir: Path,
    env: dict[str, str],
) -> int:
    db_path = work_dir / f"{stream_id}.db"
    cmd = _simulator_cli(simulator_dir) + [
        "insights",
        stream_id,
        "--storage", "sqlite",
        "--storage-uri", str(db_path),
        "--output-dir", str(output_dir),
    ]

    result = subprocess.run(cmd, cwd=work_dir, env=env, text=True, capture_output=True)
    if result.returncode != 0:
        print("[insights] failed", file=sys.stderr)
        print(result.stderr or result.stdout, file=sys.stderr)
    else:
        print("[insights]", result.stderr.strip())
    return result.returncode


def _build_memory_env(base_env: dict[str, str], goal_id: str, workspace_id: str) -> dict[str, str]:
    env = dict(base_env)
    env["EDEN_GOAL_ID"] = goal_id
    env["EDEN_WORKSPACE_ID"] = workspace_id
    # Keep the simulator's own agent identity for the report memory.
    env.setdefault("EDEN_MEMORY_AGENT_ID", "eden-business-simulator")
    env.setdefault("EDEN_MEMORY_USER_ID", env.get("USER", "unknown"))
    return env


def _find_memory_record(
    stream_id: str,
    agent_id: str,
    user_id: str,
    workspace_id: str,
    db_path: str,
) -> dict[str, Any] | None:
    """Recall the latest insights_report memory for this stream."""
    cmd = [
        "eden-memory",
        "--db", db_path,
        "recall",
        "-agent-id", agent_id,
        "-user-id", user_id,
        "-workspace-id", workspace_id,
        "-query", f"insights_report {stream_id}",
        "-limit", "5",
        "-format", "json",
    ]
    result = subprocess.run(cmd, text=True, capture_output=True)
    if result.returncode != 0:
        return None
    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError:
        return None
    for row in data.get("results", []):
        meta = row.get("metadata", {})
        if meta.get("record_type") == "insights_report" and stream_id in row.get("content", ""):
            return row
    return None


def _write_run_report(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, indent=2, default=str), encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="ATP glue: generate a business event stream and run insights on it."
    )
    parser.add_argument("business_type", help="Business domain to simulate (e.g. ecommerce).")
    parser.add_argument("stream_id", help="Stream identifier for persistence and analysis.")
    parser.add_argument(
        "--events", type=int, default=50,
        help="Number of events to generate (default: 50).",
    )
    parser.add_argument(
        "--rate", type=float, default=2.0,
        help="Events per simulated second (default: 2.0).",
    )
    parser.add_argument(
        "--seed", type=int, default=42,
        help="Random seed (default: 42).",
    )
    parser.add_argument(
        "--realtime", action="store_true",
        help="Pace generation against wall-clock time (default: off).",
    )
    parser.add_argument(
        "--work-dir",
        help="Directory for the SQLite stream and run report (default: /tmp/atp-insights-<stream_id>).",
    )
    parser.add_argument(
        "--output-dir",
        help="Directory for insights artifacts (default: <work_dir>/insights_<stream_id>).",
    )
    parser.add_argument(
        "--simulator-dir", default=os.environ.get("EDEN_BUSINESS_SIMULATOR_DIR", DEFAULT_SIMULATOR_DIR),
        help="Path to the eden-business-simulator checkout.",
    )
    parser.add_argument(
        "--goal-id", default=os.environ.get("EDEN_GOAL_ID", DEFAULT_GOAL_ID),
        help="ATP goal ID to attach to the insights_report memory.",
    )
    parser.add_argument(
        "--eden-memory-db", default=os.environ.get("EDEN_MEMORY_DB", str(Path.home() / ".eden-memory" / "default.db")),
        help="Path to the Eden-memory SQLite database.",
    )
    args = parser.parse_args(argv)

    if not Path(args.simulator_dir).exists():
        print(f"Simulator directory not found: {args.simulator_dir}", file=sys.stderr)
        return 2

    work_dir = Path(args.work_dir) if args.work_dir else Path(f"/tmp/atp-insights-{args.stream_id}")
    output_dir = Path(args.output_dir) if args.output_dir else work_dir / f"insights_{args.stream_id}"
    work_dir.mkdir(parents=True, exist_ok=True)
    output_dir.mkdir(parents=True, exist_ok=True)

    base_env = os.environ.copy()
    env = _build_memory_env(base_env, args.goal_id, args.simulator_dir)

    started_at = datetime.now(timezone.utc).isoformat()
    daemon_exit = _run_daemon(
        business_type=args.business_type,
        stream_id=args.stream_id,
        simulator_dir=args.simulator_dir,
        work_dir=work_dir,
        events=args.events,
        rate=args.rate,
        seed=args.seed,
        realtime=args.realtime,
        env=env,
    )

    insights_exit = 1
    if daemon_exit == 0:
        insights_exit = _run_insights(
            stream_id=args.stream_id,
            simulator_dir=args.simulator_dir,
            work_dir=work_dir,
            output_dir=output_dir,
            env=env,
        )

    memory_record: dict[str, Any] | None = None
    if daemon_exit == 0 and insights_exit == 0:
        memory_record = _find_memory_record(
            stream_id=args.stream_id,
            agent_id=env.get("EDEN_MEMORY_AGENT_ID", "eden-business-simulator"),
            user_id=env.get("EDEN_MEMORY_USER_ID", "unknown"),
            workspace_id=args.simulator_dir,
            db_path=args.eden_memory_db,
        )

    report_path = work_dir / "atp_insights_run.json"
    report: dict[str, Any] = {
        "started_at": started_at,
        "finished_at": datetime.now(timezone.utc).isoformat(),
        "goal_id": args.goal_id,
        "business_type": args.business_type,
        "stream_id": args.stream_id,
        "events_requested": args.events,
        "daemon_exit_code": daemon_exit,
        "insights_exit_code": insights_exit,
        "work_dir": str(work_dir),
        "storage_uri": str(work_dir / f"{args.stream_id}.db"),
        "insights_output_dir": str(output_dir),
        "insights_report_json": str(output_dir / "insights_report.json"),
        "eden_memory_db": args.eden_memory_db,
        "memory_record": memory_record,
    }
    _write_run_report(report_path, report)

    print(f"Run report written to {report_path}")
    if memory_record:
        print(f"Linked insights_report memory: {memory_record['id']}")

    if daemon_exit != 0 or insights_exit != 0:
        return 1
    if memory_record is None:
        print("Warning: insights completed but no Eden-memory record was found.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
