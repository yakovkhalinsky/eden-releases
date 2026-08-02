# Headless deployment runbook

This runbook explains how to run the Agentic Team Protocol supervisor
(`atp-run`) in a fully non-interactive environment, either locally or inside a
container.

## What is headless ATP?

The deployable supervisor is a small Go program that:

1. Receives a goal.
2. Writes every lifecycle stage to Eden-memory.
3. Spawns a headless Claude Code CLI process for each ATP role.
4. Continues until the goal is archived or reaches `max-loops`.

It does not require an interactive Claude Code session, so it can run in CI,
cron, or a container.

## Local setup

### 1. Install prerequisites

- Go 1.22+
- [eden-memory](https://0d3sa.com/eden-memory/)
- Claude Code CLI

### 2. Build `atp-run`

```bash
cd agentic-team-protocol/deployable
go build -o atp-run ./cmd/atp-run
```

### 3. Configure Eden-memory

Make sure the database directory exists:

```bash
mkdir -p ~/.eden-memory
eden-memory --db ~/.eden-memory/default.db health
```

### 4. Create an MCP config

Create `mcp.json` next to the binary or in your project directory:

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

Role processes use this config so they can read files and call Eden-memory MCP
tools directly. The supervisor itself talks to Eden-memory via the `eden-memory`
CLI, so it does not need MCP.

## Running a goal

### Inline goal

```bash
./atp-run start \
  --goal "Create /tmp/atp-hello.txt containing exactly 'hello from ATP'" \
  --mcp-config ./mcp.json \
  --dangerously-skip-permissions \
  --verbose
```

### Goal from a file

```bash
./atp-run start \
  --goal-file ./goal.txt \
  --mcp-config ./mcp.json \
  --dangerously-skip-permissions
```

### Resume a goal

```bash
./atp-run continue \
  --goal-id <the-goal-id-from-output> \
  --mcp-config ./mcp.json \
  --dangerously-skip-permissions
```

## Provider configuration

`atp-run` does not configure the LLM provider itself; it forwards the current
process environment to every child `claude` process. Set the relevant variables
before you invoke `atp-run`.

| Provider | Required environment variables |
|---|---|
| Anthropic (direct) | `ANTHROPIC_API_KEY` |
| Ollama local | `ANTHROPIC_BASE_URL=http://localhost:11434`, `ANTHROPIC_AUTH_TOKEN` (or `ANTHROPIC_API_KEY` if Ollama accepts it), empty `ANTHROPIC_API_KEY` to avoid falling back to Anthropic |
| Ollama Cloud | `ANTHROPIC_BASE_URL=https://ollama.com`, `ANTHROPIC_AUTH_TOKEN=$OLLAMA_API_KEY`, empty `ANTHROPIC_API_KEY` |
| AWS Bedrock | `ANTHROPIC_BASE_URL` pointing to a Bedrock/Anthropic gateway, plus `ANTHROPIC_AUTH_TOKEN` or `AWS_*` credentials as required by your gateway |
| OpenAI API | `ANTHROPIC_BASE_URL` pointing to an Anthropic-compatible OpenAI gateway (e.g. LiteLLM), plus `ANTHROPIC_AUTH_TOKEN` |
| Google Vertex | `ANTHROPIC_BASE_URL` pointing to a Vertex/Anthropic gateway, plus `ANTHROPIC_AUTH_TOKEN` |
| Microsoft Foundry | `ANTHROPIC_BASE_URL` pointing to a Foundry/Anthropic gateway, plus `ANTHROPIC_AUTH_TOKEN` |

For providers that are not natively Anthropic-compatible, run a small gateway
(e.g. [LiteLLM Proxy](https://docs.litellm.ai/docs/simple_proxy)) and point
`ANTHROPIC_BASE_URL` at it.

### Ollama `launch` shortcut

If you use the Ollama CLI:

```bash
ANTHROPIC_DEFAULT_HAIKU_MODEL=qwen3.5 \
ollama launch claude --model qwen3.5 --yes -- \
  ./atp-run start \
    --goal "..." \
    --mcp-config ./mcp.json \
    --dangerously-skip-permissions
```

`ollama launch` configures the parent `claude` process; child processes inherit
environment variables. To be explicit, also set `ANTHROPIC_BASE_URL` and
`ANTHROPIC_AUTH_TOKEN`.

## Permission modes

For fully automated runs, use one of:

- `--dangerously-skip-permissions` — skips all Claude permission prompts.
- `--permission-mode auto` — auto-accepts most prompts.

Only use these in a sandboxed, charter-authorized environment. In production or
when touching real systems, keep an interactive approval step.

## Container notes

Even though this prototype ships without a Dockerfile, you can containerise it
quickly:

1. Copy the built `atp-run` binary, the `roles/` directory, and your `mcp.json`
   into the image.
2. Install `eden-memory` and `claude` CLI in the image.
3. Set the provider environment variables at runtime.
4. Run the container with a mounted goal file and the Eden-memory database.

Keep the Eden-memory database and any API keys outside the image (mounts or
secrets).

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `eden-memory search` returns no records | Wrong `--db`, `--org-id`, or `--workspace-id` | Check `eden-memory health` output and pass the same scope used by your interactive Claude sessions |
| Role output is not parseable JSON | The model returned prose or markdown | Increase `--max-turns` or use a stronger tool-calling model |
| Child Claude ignores MCP | `--bare` was used | The supervisor does not pass `--bare`; role processes use `--strict-mcp-config` |
| Provider falls back to Anthropic | `ANTHROPIC_API_KEY` is still set | Export `ANTHROPIC_API_KEY=""` before running |
| Goal loops forever | Dispatch or verdict status is missing/invalid | Inspect records with `eden-memory search` and fix the role prompt |

## Next steps

- Read the full Agentic Team Protocol skill: `~/.claude/skills/team/SKILL.md`
- Inspect the role prompts in `roles/`
- Add provider-specific env-file loading to `atp-run` when you outgrow manual
  exports.
