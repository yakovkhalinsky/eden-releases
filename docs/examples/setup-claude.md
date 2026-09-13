# setup-claude examples

`memory setup claude` wires a project directory to Claude Code CLI as an MCP
server and writes a project-level `.env` file.

## Identity precedence

The agent identity (`MEMORY_AGENT_ID`) is chosen in this order:

1. Explicit `--agent-id` / `--agent` flag.
2. `claude-code-cli` default.

The user identity (`MEMORY_USER_ID`) is chosen in this order:

1. Explicit `--user-id` flag.
2. `MEMORY_USER_ID` environment variable.
3. `$USER`.
4. An interactive prompt.

## Examples

### Default setup

```bash
cd ~/project-a
memory setup claude
# MEMORY_AGENT_ID defaults to claude-code-cli
```

### Set the agent id explicitly

```bash
cd ~/project-a
memory setup claude --agent-id ci-builder
# MEMORY_AGENT_ID is ci-builder
```

### Set the user id

```bash
cd ~/project-a
memory setup claude --user-id yakov
# MEMORY_USER_ID is yakov
```

### Public installer

The public `scripts/setup-claude.sh` installer chooses the agent identity using a
slightly different order because it has no `--agent-id` flag:

1. Positional argument passed after `sh -s --`.
2. `claude-code-cli` fallback.

```bash
# Positional argument sets the agent ID
curl -fsSL https://0d3sa.com/memory/setup-claude.sh | sh -s -- my-agent
# Agent ID becomes my-agent
```

```bash
# Fallback when no argument is supplied
curl -fsSL https://0d3sa.com/memory/setup-claude.sh | sh
# Agent ID becomes claude-code-cli
```