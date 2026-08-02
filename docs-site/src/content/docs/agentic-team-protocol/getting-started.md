---
title: Install and get started
description: Install the agentic-team-protocol primitives in Claude Code and ratify your first project charter.
---

# Install and get started

## Requirements

- [eden-memory](/eden-memory/getting-started/) installed and available on your PATH.
- Claude Code CLI.

## Install the global primitives

```bash
curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh
```

This copies the skill, agents, and slash commands into `~/.claude/`:

- `~/.claude/skills/team/SKILL.md`
- `~/.claude/agents/{dispatcher,builder,runtime,verifier,researcher,archivist,router}.md`
- `~/.claude/commands/{team-charter,team-status,team-escalate,team-continue,team-handoff}.md`

Restart Claude Code to load them.

## Manual install from the repository

If you prefer to inspect the files first:

```bash
git clone https://github.com/yakovkhalinsky/eden-releases.git
cd eden-releases/agentic-team-protocol
./install.sh
```

To also install project-local templates in the current directory:

```bash
./install.sh --local
```

## Running with Ollama

`ollama launch` is the official Ollama CLI command for wiring external
applications to Ollama models. You can use it to run Claude Code CLI against a
local Ollama server or Ollama Cloud.

### Local Ollama

```bash
ollama launch claude --model qwen3.5
```

### Headless supervisor

For a headless ATP supervisor, pass a dedicated MCP config so Eden-memory is
available, and use `--output-format json` so downstream scripts can parse the
result. `--bare` disables MCP auto-discovery, so it is intentionally omitted for
supervisors that rely on Eden-memory.

```bash
ANTHROPIC_DEFAULT_HAIKU_MODEL=qwen3.5 \
ollama launch claude --model qwen3.5 --yes -- \
  -p "<supervisor prompt>" \
  --strict-mcp-config \
  --mcp-config ./mcp.json \
  --dangerously-skip-permissions \
  --output-format json \
  --max-turns 10
```

`./mcp.json` should contain the Eden-memory server:

```json
{
  "mcpServers": {
    "eden-memory": {
      "command": "/home/yourname/.local/bin/eden-memory",
      "args": ["--db", "/home/yourname/.eden-memory/default.db"],
      "env": { "EDEN_LOG_LEVEL": "INFO" }
    }
  }
}
```

If you prefer a permissions prompt instead of `--dangerously-skip-permissions`,
use `--permission-mode auto` or `--allowedTools mcp__eden-memory__eden_*`.

### Ollama Cloud

To target Ollama Cloud, point Claude Code CLI at the Ollama endpoint and
authenticate with your Ollama API key:

```bash
ANTHROPIC_BASE_URL=https://ollama.com \
ANTHROPIC_AUTH_TOKEN=$OLLAMA_API_KEY \
ANTHROPIC_API_KEY="" \
ANTHROPIC_DEFAULT_HAIKU_MODEL=kimi-k2.5:cloud \
ollama launch claude --model kimi-k2.5:cloud --yes -- \
  -p "<supervisor prompt>" \
  --strict-mcp-config \
  --mcp-config ./mcp.json \
  --dangerously-skip-permissions \
  --output-format json \
  --max-turns 10
```

### Requirements and caveats

- Ollama 0.14 or newer.
- Use a tool-calling model with a context window of at least 32K tokens.
- Do not use `--bare` for Eden-memory-backed supervisors; it disables MCP
  servers. Use `--strict-mcp-config` to load only the servers you need.
- If you are logged into Claude Max/Pro, an empty `ANTHROPIC_API_KEY` may still
  fall back to Anthropic. Use a separate Claude Code config directory or run
  `/status` to confirm the active provider.

## Project-local setup

In each project that uses the protocol, create a `.claude/` directory with a
charter, config, and project-local skill:

```bash
cd your-project
mkdir -p .claude/skills/agentic-team-protocol
cp /path/to/eden-releases/agentic-team-protocol/templates/agentic-team-charter.md .claude/agentic-team-charter.md
cp /path/to/eden-releases/agentic-team-protocol/templates/agentic-team-config.yaml .claude/agentic-team-config.yaml
cp /path/to/eden-releases/agentic-team-protocol/templates/skills/agentic-team-protocol/SKILL.md .claude/skills/agentic-team-protocol/SKILL.md
```

Or run `./install.sh --local` from the package directory.

## Ratify the charter

Edit `.claude/agentic-team-charter.md` to match your project, then run:

```text
/team-charter
```

This reads the charter, computes a SHA-256 version hash, and stores a
`charter_ratification` record in eden-memory with metadata like:

```json
{
  "kind": "charter_ratification",
  "stage": "charter_ratification",
  "goal_id": "charter-ratification",
  "owner_role": "archivist"
}
```

The command reports whether the team may proceed.

## How agents use eden-memory

Every role uses the eden-memory MCP server:

- **Dispatcher** writes `goal_record` and `dispatch_instruction` records.
- **Researcher** recalls prior context, then writes a `context_summary`.
- **Builder / Runtime** recall the latest goal and dispatch records, do the work,
  and write an `action_record` with `input_record_ids` and `output_record_ids`.
- **Verifier** reads the action record and writes a `verdict`.
- **Archivist** links everything into a final `archival_record` or hand-off.

Each record should carry at least `goal_id`, `stage`, `owner_role`,
`input_record_ids`, and `output_record_ids` so the lifecycle can be traced and
recalled in later sessions.

## Common commands

| Command | Purpose |
|---------|---------|
| `/team` | Invoke the Agentic Team Protocol skill to kick off a goal. |
| `/team-charter` | Ratify the project charter. |
| `/team-status` | Show active goals and current stages. |
| `/team-escalate` | Escalate a blocked or risky goal. |
| `/team-continue` | Continue a previously handed-off goal. |
| `/team-handoff` | Hand off a goal to another session or agent. |

## Next steps

- Read the [overview](/agentic-team-protocol/) for the lifecycle and roles.
- Read the [charter anatomy](/agentic-team-protocol/charter-anatomy/) to write a project-local charter.
- Read the [lifecycle](/agentic-team-protocol/lifecycle/) for the seven-stage flow.
- Read the [agent prompts](/agentic-team-protocol/agents/) to learn when to spawn each role.
- Inspect the raw prompt files in `~/.claude/agents/`.
