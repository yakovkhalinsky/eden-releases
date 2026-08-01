# Agentic Team Protocol for Claude Code

Role-based agent teams with a seven-stage task lifecycle and Eden-memory as the durable substrate.

- **Source paper:** *A Protocol for Role-Based Agent Teams* — https://yakov.khalinsky.com/agentic-team-protocol/
- **Requires:** [eden-memory](https://0d3sa.com/eden-memory/) (`~/.local/bin/eden-memory`) and Claude Code CLI.

## What's included

This package installs Claude Code primitives (skills, subagents, slash commands) at the **global** `~/.claude/` scope and provides **project-local** templates for opting in.

| Artifact | Scope | Path after install |
|----------|-------|--------------------|
| Protocol skill | Global | `~/.claude/skills/agentic-team-protocol/SKILL.md` |
| Dispatcher subagent | Global | `~/.claude/agents/dispatcher.md` |
| Researcher subagent | Global | `~/.claude/agents/researcher.md` |
| Builder subagent | Global | `~/.claude/agents/builder.md` |
| Runtime subagent | Global | `~/.claude/agents/runtime.md` |
| Verifier subagent | Global | `~/.claude/agents/verifier.md` |
| Archivist subagent | Global | `~/.claude/agents/archivist.md` |
| Router subagent | Global | `~/.claude/agents/router.md` |
| `/team-charter` command | Global | `~/.claude/commands/team-charter.md` |
| `/team-status` command | Global | `~/.claude/commands/team-status.md` |
| `/team-escalate` command | Global | `~/.claude/commands/team-escalate.md` |
| Charter template | Project-local | `.claude/agentic-team-charter.md` |
| Config template | Project-local | `.claude/agentic-team-config.yaml` |
| CLAUDE.md template | Project-local | `templates/claude-md.md` (used by `--claude-md`) |

## Quick install

```bash
curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh
```

Restart Claude Code after installing (`/exit`, then reopen).

## Project opt-in with enforced rules

To install the global primitives *and* opt a project in with a `CLAUDE.md` file that instructs Claude Code to follow the protocol on every task:

```bash
cd ~/my-project
curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh -s -- --local --claude-md
```

This creates:

- `.claude/agentic-team-charter.md`
- `.claude/agentic-team-config.yaml`
- `CLAUDE.md` with memory-first and Agentic Team Protocol enforcement rules

If `CLAUDE.md` already exists, the installer appends the rules only if they are not already present.

## Manual install

```bash
# 1. Clone or download this package.
# 2. Copy the global skill/agents/commands into ~/.claude/
cp -r skills/agentic-team-protocol ~/.claude/skills/
cp -r agents/* ~/.claude/agents/
cp -r commands/* ~/.claude/commands/

# 3. In a project that wants to opt in:
cp templates/agentic-team-charter.md .claude/agentic-team-charter.md
cp templates/agentic-team-config.yaml .claude/agentic-team-config.yaml

# 4. Optional: create a CLAUDE.md with protocol enforcement rules
cp templates/claude-md.md CLAUDE.md
```

Edit the charter, config, and `CLAUDE.md` to match the project.

## Project opt-in

A project opts into the Agentic Team Protocol by creating:

- `.claude/agentic-team-charter.md` — identity, mission, boundaries, roles, decision rights, escalation paths.
- `.claude/agentic-team-config.yaml` — active roles, default package type, override flags.

Optionally, add a project-level `CLAUDE.md` (or use `--claude-md`) to instruct Claude Code to follow the protocol on every task.

Once those files exist, project-local definitions override the global ones.

## Scope resolution

1. Project-local charter overrides global charter.
2. Project-local agent definitions override global agents.
3. Project-local skill overrides global skill.
4. If a project has no `agentic-team-config.yaml`, the global skill is used and the global charter is ignored unless explicitly referenced.

## Seven-stage lifecycle

1. **Goal receipt** — Dispatcher records the request.
2. **Routing and assignment** — Dispatcher assigns target role/package, owner, deadline, success criteria.
3. **Context gathering** — Researcher records what is known, options considered, chosen path.
4. **Action** — Builder or Runtime executes and records what was done.
5. **Verification** — Verifier inspects outcome and writes a verdict.
6. **Recording and archival** — Archivist ensures final outcome and skill/runbook updates are stored.
7. **Hand-off or closure** — Archivist confirms records are complete and ownership is transferred if handing off.

## Slash commands

After restart:

- `/team-charter` — read the project charter, store a ratification record in Eden-memory.
- `/team-status` — list active goals, stage, owner role, latest record IDs, and continueable/blocked state.
- `/team-escalate` — write a structured escalation record and route by level.
- `/team-continue` — resume an unfinished goal by rehydrating it from Eden-memory and dispatching the next role.
- `/team-handoff` — transfer ownership of a goal to another role in a durable record.

## License

MIT — see the repository [LICENSE](../LICENSE).
