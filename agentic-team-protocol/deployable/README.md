# Deployable ATP supervisor

A minimal, headless supervisor for the Agentic Team Protocol. It drives the
seven-stage lifecycle end-to-end without an interactive Claude Code session by
spawning one headless Claude Code CLI process per ATP role.

## What it does

- Reads a goal from `--goal` or `--goal-file`.
- Writes a durable `goal_record` to Eden-memory.
- Routes the goal through Dispatcher → Researcher/Builder/Runtime → Verifier →
  Archivist using the same lifecycle rules as the interactive `/team` skill.
- Each role runs in a separate headless `claude` process with a dedicated prompt
  template and returns structured JSON.
- The supervisor writes every record to Eden-memory via the `eden-memory` CLI,
  so the state is observable across sessions and can be resumed with
  `atp-run continue --goal-id <id>`.

## Requirements

- Go 1.22 or newer
- [eden-memory](https://0d3sa.com/eden-memory/) (`~/.local/bin/eden-memory`)
- Claude Code CLI
- A Claude Code compatible API key or Ollama setup

## Build

```bash
cd agentic-team-protocol/deployable
go build -o atp-run ./cmd/atp-run
```

## Quick start

1. Ensure Eden-memory is configured:

   ```bash
   eden-memory --db ~/.eden-memory/default.db health
   ```

2. Create an MCP config file so role processes can reach Eden-memory (optional
   but recommended):

   ```bash
   cat > ./mcp.json <<'EOF'
   {
     "mcpServers": {
       "eden-memory": {
         "command": "/home/yourname/.local/bin/eden-memory",
         "args": ["--db", "/home/yourname/.eden-memory/default.db"],
         "env": { "EDEN_LOG_LEVEL": "INFO" }
       }
     }
   }
   EOF
   ```

3. Run a goal:

   ```bash
   ./atp-run start \
     --goal "Create /tmp/atp-hello.txt containing exactly 'hello from ATP'" \
     --mcp-config ./mcp.json \
     --dangerously-skip-permissions \
     --verbose
   ```

The supervisor prints the `goal_id` and each record it stores.

## Resume a goal

```bash
./atp-run continue \
  --goal-id <the-goal-id> \
  --mcp-config ./mcp.json \
  --dangerously-skip-permissions
```

## CLI flags

| Flag | Default | Description |
|---|---|---|
| `--goal` | - | Inline goal text |
| `--goal-file` | - | Path to file containing the goal |
| `--goal-id` | generated | Reuse an existing goal ID |
| `--db` | `~/.eden-memory/default.db` | Eden-memory SQLite path |
| `--agent-id` | `atp-run` | Agent identity for records |
| `--user-id` | `$USER` | User identity for records |
| `--org-id` | `$EDEN_ORG_ID` | Organization scope |
| `--workspace-id` | `$EDEN_WORKSPACE_ID` | Workspace scope |
| `--mcp-config` | - | Path to MCP config JSON |
| `--strict-mcp-config` | `true` | Use only the supplied MCP config |
| `--claude-bin` | `claude` | Claude Code CLI binary |
| `--eden-bin` | `~/.local/bin/eden-memory` | Eden-memory binary |
| `--roles-dir` | auto | Directory with role prompt templates |
| `--max-loops` | 20 | Maximum role transitions |
| `--max-turns` | 25 | Max turns per headless role process |
| `--dangerously-skip-permissions` | false | Skip Claude permission prompts |
| `--permission-mode` | - | e.g. `auto` |
| `--verbose` | false | Print commands and Claude output |

## Provider configuration

`atp-run` forwards the current environment to every child `claude` process. Set
provider-specific variables before invoking the supervisor:

- Anthropic: `ANTHROPIC_API_KEY`
- Ollama local: `ANTHROPIC_BASE_URL=http://localhost:11434`,
  `ANTHROPIC_AUTH_TOKEN`, empty `ANTHROPIC_API_KEY`
- Ollama Cloud: `ANTHROPIC_BASE_URL=https://ollama.com`,
  `ANTHROPIC_AUTH_TOKEN=$OLLAMA_API_KEY`, empty `ANTHROPIC_API_KEY`

See `runbooks/headless-deployment.md` for per-provider details.
