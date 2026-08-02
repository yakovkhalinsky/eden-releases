---
title: Set up a headless supervisor
description: Run an Ollama-backed headless ATP supervisor with a strict MCP config, JSON output, and durable memory records.
content_type: tutorial
---

# Set up a headless supervisor

A headless supervisor lets an automated controller run ATP goals through Claude Code CLI without an interactive chat session. This is useful for CI jobs, scheduled tasks, or any controller that can parse JSON output. This tutorial wires an Ollama-backed Claude Code CLI instance to eden-memory via a strict MCP config and JSON output mode.

## Prerequisites

- [eden-memory](/eden-memory/getting-started/) installed and on your `PATH`.
- Claude Code CLI installed.
- Ollama 0.14 or newer with a tool-calling model of at least 32K context window.
- A dedicated database or project directory for the supervisor (do not reuse a personal workspace database unless you intend to share history).

## Step 1 — Create a strict MCP config file

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

Replace `yourname` with the actual user that will run the supervisor. Use absolute paths; the supervisor process may not inherit your shell environment.

## Step 2 — Choose the supervisor prompt

Write a short prompt file or inline string that instructs the supervisor to use the Agentic Team Protocol. A minimal prompt:

```text
You are an ATP headless supervisor. When given a goal, spawn the dispatcher subagent, record the goal in eden-memory, and return the final result as JSON. Do not perform role work yourself. Always use --output-format json for downstream parsing.
```

Save it as `supervisor-prompt.txt` next to `mcp.json`.

## Step 3 — Launch the headless supervisor locally

Run Claude Code CLI through `ollama launch` with the strict MCP config:

```bash
ANTHROPIC_DEFAULT_HAIKU_MODEL=qwen3.5 \
ollama launch claude --model qwen3.5 --yes -- \
  -p "$(cat supervisor-prompt.txt)" \
  --strict-mcp-config \
  --mcp-config ./mcp.json \
  --dangerously-skip-permissions \
  --output-format json \
  --max-turns 10
```

Flags explained:

| Flag | Why it matters |
|------|----------------|
| `--strict-mcp-config` | Loads only the servers declared in `mcp.json`. |
| `--mcp-config ./mcp.json` | Points to the strict config from Step 1. |
| `--dangerously-skip-permissions` | Disables interactive tool-permission prompts (safe only in automated environments). |
| `--output-format json` | Makes the final result parseable by downstream scripts. |
| `--max-turns 10` | Caps the conversation length so jobs do not run indefinitely. |

**Important:** do not use `--bare`. It disables all MCP servers, including eden-memory, which breaks the ATP lifecycle.

## Step 4 — Target Ollama Cloud (optional)

To run against Ollama Cloud, set the Anthropic-compatible endpoint and authenticate with your Ollama API key:

```bash
ANTHROPIC_BASE_URL=https://ollama.com \
ANTHROPIC_AUTH_TOKEN=$OLLAMA_API_KEY \
ANTHROPIC_API_KEY="" \
ANTHROPIC_DEFAULT_HAIKU_MODEL=kimi-k2.5:cloud \
ollama launch claude --model kimi-k2.5:cloud --yes -- \
  -p "$(cat supervisor-prompt.txt)" \
  --strict-mcp-config \
  --mcp-config ./mcp.json \
  --dangerously-skip-permissions \
  --output-format json \
  --max-turns 10
```

If you are logged into Claude Max/Pro, an empty `ANTHROPIC_API_KEY` may still fall back to Anthropic. Use a separate Claude Code config directory, or run `/status` inside the launched session to confirm the active provider.

## Step 5 — Send a supervised goal

From another terminal or controller, invoke the supervisor with a goal. The exact mechanism depends on your controller. A simple test is to pipe a goal into the launched Claude Code CLI or use its remote API if exposed.

The supervisor should:

1. Parse the goal.
2. Spawn the dispatcher subagent.
3. Wait for the lifecycle to complete (or time out after `max-turns`).
4. Return a JSON object containing at least the `goal_id`, final `stage`, and `verdict`.

## Step 6 — Verify durable records

After the run, search the supervisor database for the goal:

```bash
eden-memory --db /home/yourname/.eden-memory/supervisor.db search \
  --agent-id claude-code-cli \
  --user-id "$(id -un)" \
  --keywords "goal_record verdict" \
  --limit 20
```

You should see a `goal_record`, `dispatch_instruction`, `action_record`, and `verdict` linked by the same `goal_id`.

## Expected final state

- `mcp.json` exists and declares only the eden-memory server.
- The supervisor launches without MCP auto-discovery.
- A test goal produces JSON output with a traceable `goal_id`.
- eden-memory contains the full lifecycle record chain for that goal.

## Caveats

- Use a tool-calling model with a context window of at least 32K tokens.
- Do not run the supervisor with `--bare`.
- Prefer `--dangerously-skip-permissions` only in fully automated, isolated accounts; for semi-automated setups use `--permission-mode auto` or `--allowedTools mcp__eden-memory__eden_*`.
- Headless supervisors share memory scope with the configured database; isolate production and sandbox databases.

## Next steps

- Read the [agent prompts reference](/agentic-team-protocol/reference/agent-prompts/) to decide which subagent the supervisor should spawn.
- Learn the [slash command reference](/agentic-team-protocol/reference/slash-commands/) for `/team`, `/team-status`, and `/team-continue`.
- See the [continuation runbook](https://github.com/yakovkhalinsky/eden-releases/blob/main/agentic-team-protocol/runbooks/continuation.md) for handling interrupted headless goals.
