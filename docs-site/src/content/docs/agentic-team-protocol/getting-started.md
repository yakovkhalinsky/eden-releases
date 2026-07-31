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

- `~/.claude/skills/agentic-team-protocol/SKILL.md`
- `~/.claude/agents/{dispatcher,builder,runtime,verifier,researcher,archivist}.md`
- `~/.claude/commands/{ratify-charter,agentic-status,agentic-escalate}.md`

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

## Project-local setup

In each project that uses the protocol, create a `.claude/` directory with a
charter and config:

```bash
cd your-project
mkdir -p .claude
cp /path/to/eden-releases/agentic-team-protocol/templates/agentic-team-charter.md .claude/agentic-team-charter.md
cp /path/to/eden-releases/agentic-team-protocol/templates/agentic-team-config.yaml .claude/agentic-team-config.yaml
```

Or run `./install.sh --local` from the package directory.

## Ratify the charter

Edit `.claude/agentic-team-charter.md` to match your project, then run:

```text
/ratify-charter
```

This stores a `charter_ratification` record in eden-memory. The command reports
whether the team may proceed.

## Common commands

| Command | Purpose |
|---------|---------|
| `/ratify-charter` | Ratify the project charter. |
| `/agentic-status` | Show active goals and current stages. |
| `/agentic-escalate` | Escalate a blocked or risky goal. |

## Next steps

- Read the [overview](/agentic-team-protocol/) for the lifecycle and roles.
- Learn the agent prompts by inspecting `~/.claude/agents/`.
