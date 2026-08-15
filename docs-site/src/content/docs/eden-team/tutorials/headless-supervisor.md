---
title: Set up a headless supervisor
description: Run an Ollama-backed headless ATP supervisor with eden-team, a strict MCP config, JSON output, and durable memory records.
content_type: tutorial
---

# Set up a headless supervisor

A headless supervisor lets an automated controller run ATP goals through Claude Code CLI without an interactive chat session. This is useful for CI jobs, scheduled tasks, or any controller that can parse JSON output. This tutorial uses `eden-team`, the headless ATP supervisor.

## Prerequisites

- [eden-memory](/eden-memory/getting-started/) installed and on your `PATH`.
- `eden-team` binary built from the monorepo (or downloaded from a release).
- Claude Code CLI installed.
- Ollama 0.14 or newer with a tool-calling model of at least 32K context window.
- A dedicated database or project directory for the supervisor (do not reuse a personal workspace database unless you intend to share history).

## Step 1 — Build or install `eden-team`

The `eden-team` source lives in the `eden-memory` monorepo at `/home/yakov/git/eden-memory`:

```bash
cd /home/yakov/git/eden-memory
go build -o eden-team ./cmd/eden-team
```

This produces `./eden-team` in the repository root. The binary uses role templates from `cmd/eden-team/roles/` and the runbook at `cmd/eden-team/runbooks/headless-deployment.md`.

To install a released binary instead, use the monorepo installer:

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh -s eden-team
```

## Step 2 — Create a strict MCP config file

Create a file named `mcp.json` in the supervisor working directory. It should load **only** the eden-memory MCP server:

```json
{
  "mcpServers": {
    "eden-memory": {
      "command": "/home/yourname/.local/bin/eden-memory",
      "args": ["--db", "/home/yourname/.eden-memory/supervisor.db"],
      "env": { "EDEN_LOG_LEVEL": "INFO" }
    }
  }
}
```

Replace `yourname` with the actual user that will run the supervisor, and update `command` to the absolute path of the `eden-memory` binary you want role processes to use. For a local build from the `eden-memory` monorepo, use the path to the compiled binary (e.g., `/home/yourname/git/eden-memory/eden-memory`). Use absolute paths for both `command` and `--db`; child role processes may not inherit your shell environment.

## Step 3 — Launch the headless supervisor locally

Run `eden-team start` with the strict MCP config. `eden-team` defaults to **Lite mode** (`--mode lite`), which is the fastest path for everyday headless goals:

```bash
./eden-team start \
  --goal "Create /tmp/atp-hello.txt containing exactly 'hello from ATP'" \
  --mcp-config ./mcp.json \
  --dangerously-skip-permissions \
  --verbose
```

Flags explained:

| Flag | Why it matters |
|------|----------------|
| `--goal` | The natural-language goal to dispatch through the ATP lifecycle. |
| `--mcp-config ./mcp.json` | Points to the strict config from Step 2. Role processes inherit it. |
| `--mode lite` / `--mode full` | Selects the ATP lifecycle. Defaults to `lite`. |
| `--dangerously-skip-permissions` | Disables interactive tool-permission prompts (safe only in automated environments). |
| `--verbose` | Prints lifecycle progress so you can follow dispatcher/builder/verifier transitions. |

The supervisor writes a `goal_record` with `mode: lite`, spawns the dispatcher subagent, and continues the lifecycle until a verdict is recorded. Child Claude Code CLI processes use `--strict-mcp-config` with the supplied `mcp.json`.

## Step 4 — Target Ollama Cloud (optional)

To run against Ollama Cloud, set the Anthropic-compatible endpoint and authenticate with your Ollama API key before invoking `eden-team`:

```bash
export ANTHROPIC_BASE_URL=https://ollama.com
export ANTHROPIC_AUTH_TOKEN=$OLLAMA_API_KEY
export ANTHROPIC_API_KEY=""
export ANTHROPIC_DEFAULT_HAIKU_MODEL=kimi-k2.5:cloud

cd /home/yakov/git/eden-memory
./eden-team start \
  --goal "Create /tmp/atp-hello-cloud.txt containing exactly 'hello from ATP cloud'" \
  --mode lite \
  --mcp-config ./mcp.json \
  --dangerously-skip-permissions \
  --verbose
```

If you are logged into Claude Max/Pro, an empty `ANTHROPIC_API_KEY` may still fall back to Anthropic. Use a separate Claude Code config directory, or run `/status` inside a role process to confirm the active provider.

## Step 5 — Resume an interrupted goal

If a run is interrupted or you want to continue a previously recorded goal, use `eden-team continue`:

```bash
./eden-team continue \
  --goal-id <the-goal-id-from-output> \
  --mcp-config ./mcp.json \
  --dangerously-skip-permissions \
  --verbose
```

The supervisor reads the latest durable record for that `goal_id` from Eden-memory, detects the goal's `mode` from the records, dispatches the next required role, and continues the lifecycle.

## Step 6 — Verify durable records

After the run, search the supervisor database for the goal:

```bash
eden-memory --db /home/yourname/.eden-memory/supervisor.db search \
  --agent-id eden-team \
  --user-id "$(id -un)" \
  --keywords "goal_record verdict" \
  --limit 20
```

You should see a `goal_record`, `dispatch_instruction`, `action_record`, and `verdict` linked by the same `goal_id`.

## Expected final state

- `mcp.json` exists and declares only the eden-memory server, using the absolute path to the desired `eden-memory` binary.
- `eden-team` launches without MCP auto-discovery and writes lifecycle records.
- A test goal produces a traceable `goal_id` and a final verdict.
- For a **Lite mode** goal, eden-memory contains a `goal_record` with `mode: lite`, a `plan_record`, an `action_record`, and a `verdict` linked by the same `goal_id`.

## Caveats

- Use a tool-calling model with a context window of at least 32K tokens.
- Prefer `--dangerously-skip-permissions` only in fully automated, isolated accounts; for semi-automated setups use `--permission-mode auto` or `--allowedTools mcp__eden-memory__eden_*`.
- Headless supervisors share memory scope with the configured database; isolate production and sandbox databases.
- The supervisor forwards the current process environment to every child `claude` process; set provider variables before invoking `eden-team`.

## Next steps

- Read the [agent prompts reference](/agentic-team-protocol/reference/agent-prompts/) to decide which subagent the supervisor should spawn.
- Learn the [slash command reference](/agentic-team-protocol/reference/slash-commands/) for `/team`, `/team-status`, and `/team-continue`.
- See the [continuation runbook](https://github.com/yakovkhalinsky/eden-releases/blob/main/agentic-team-protocol/runbooks/continuation.md) for handling interrupted headless goals.
- Inspect the `eden-team` source and runbook in `/home/yakov/git/eden-memory/cmd/eden-team/`.
