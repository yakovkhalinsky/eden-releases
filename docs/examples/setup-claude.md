# setup-claude examples

`eden-memory setup claude` wires a project directory to Claude Code CLI as an MCP
server and writes a project-level `.env` file.

## Agent identity precedence

The agent identity (`EDEN_AGENT_ID`) is chosen in this order:

1. Explicit `--agent-id` / `--agent` flag.
2. `EDEN_ATP_ROLE` environment variable, when it is one of:
   `dispatcher`, `researcher`, `builder`, `runtime`, `verifier`, `archivist`.
3. `claude-code-cli` fallback.

## Examples

### Default setup

```bash
cd ~/project-a
eden-memory setup claude
# EDEN_AGENT_ID defaults to claude-code-cli
```

### Set the agent id from an ATP role

```bash
cd ~/project-a
EDEN_ATP_ROLE=builder eden-memory setup claude
# EDEN_AGENT_ID is set to builder
```

### Override the role with an explicit flag

```bash
cd ~/project-a
EDEN_ATP_ROLE=builder eden-memory setup claude --agent-id ci-builder
# EDEN_AGENT_ID is ci-builder
```

### Public installer

The public `scripts/setup-claude.sh` installer chooses the agent identity using a
slightly different order because it has no `--agent-id` flag:

1. `EDEN_ATP_ROLE` environment variable, when it names a supported role.
2. Positional argument passed after `sh -s --`.
3. `claude-code-cli` fallback.

```bash
# EDEN_ATP_ROLE wins over the positional argument
EDEN_ATP_ROLE=researcher curl -fsSL https://0d3sa.com/eden-memory/setup-claude.sh | sh -s -- my-agent
# Agent ID becomes researcher
```

```bash
# Positional argument is used when EDEN_ATP_ROLE is absent
curl -fsSL https://0d3sa.com/eden-memory/setup-claude.sh | sh -s -- my-agent
# Agent ID becomes my-agent
```

```bash
# Fallback when neither env var nor argument is supplied
curl -fsSL https://0d3sa.com/eden-memory/setup-claude.sh | sh
# Agent ID becomes claude-code-cli
```
