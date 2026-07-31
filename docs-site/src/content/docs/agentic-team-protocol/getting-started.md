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
| `/ratify-charter` | Ratify the project charter. |
| `/agentic-status` | Show active goals and current stages. |
| `/agentic-escalate` | Escalate a blocked or risky goal. |

## Next steps

- Read the [overview](/agentic-team-protocol/) for the lifecycle and roles.
- Read the [charter anatomy](/agentic-team-protocol/charter-anatomy/) to write a project-local charter.
- Read the [lifecycle](/agentic-team-protocol/lifecycle/) for the seven-stage flow.
- Read the [agent prompts](/agentic-team-protocol/agents/) to learn when to spawn each role.
- Inspect the raw prompt files in `~/.claude/agents/`.
