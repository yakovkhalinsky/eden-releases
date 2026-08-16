# Agentic Team Protocol for Claude Code

Role-based agent teams with a durable Eden-memory trail. **Lite mode** is now the default for everyday tasks; the full seven-stage lifecycle remains available via `/team-full`.

- **Source paper:** *A Protocol for Role-Based Agent Teams* — https://yakov.khalinsky.com/agentic-team-protocol/
- **Requires:** [eden-memory](https://0d3sa.com/eden-memory/) (`~/.local/bin/eden-memory`) and Claude Code CLI.

## What's included

This package installs Claude Code primitives (skills, subagents, slash commands) at the **global** `~/.claude/` scope and provides **project-local** templates for opting in.

| Artifact | Scope | Path after install |
|----------|-------|--------------------|
| Protocol skill | Global | `~/.claude/skills/team/SKILL.md` |
| Dispatcher subagent | Global | `~/.claude/agents/dispatcher.md` |
| Researcher subagent | Global | `~/.claude/agents/researcher.md` |
| Builder subagent | Global | `~/.claude/agents/builder.md` |
| Runtime subagent | Global | `~/.claude/agents/runtime.md` |
| Verifier subagent | Global | `~/.claude/agents/verifier.md` |
| Archivist subagent | Global | `~/.claude/agents/archivist.md` |
| Router subagent | Global | `~/.claude/agents/router.md` |
| `/team` command | Global | `~/.claude/commands/team.md` |
| `/team-full` command | Global | `~/.claude/commands/team-full.md` |
| `/team-charter` command | Global | `~/.claude/commands/team-charter.md` |
| `/team-status` command | Global | `~/.claude/commands/team-status.md` |
| `/team-escalate` command | Global | `~/.claude/commands/team-escalate.md` |
| `/team-continue` command | Global | `~/.claude/commands/team-continue.md` |
| `/team-handoff` command | Global | `~/.claude/commands/team-handoff.md` |
| Charter template | Project-local | `.claude/agentic-team-charter.md` |
| Config template | Project-local | `.claude/agentic-team-config.yaml` |
| Project-local skill template | Project-local | `.claude/skills/agentic-team-protocol/SKILL.md` |
| CLAUDE.md template | Project-local | `templates/claude-md.md` (used by `--claude-md`) |
| Continuation runbook | Package docs | `runbooks/continuation.md` |

## Quick install

Install eden-memory first, then the ATP global primitives:

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh
```

The installers are designed to be piped to `sh`, so you do not need to `chmod +x`
them when using `curl`. If you run `install.sh` from a local clone, the script is
tracked with executable permissions (`./install.sh`).

Check for updates without modifying any files:

```bash
curl -fsSL https://0d3sa.com/agentic-team-protocol/install.sh | sh -s -- --check
```

In each project where you will use ATP, wire the Eden-memory MCP server:

```bash
cd ~/my-project
eden-memory setup claude
```

Restart Claude Code after installing (`/exit`, then reopen).

## Lite mode vs full protocol

- `/team` — **Lite mode** (default). 4 stages: goal → plan → act → check. Reuses the dispatcher as planner and routes directly to builder for everyday tasks. Verifier gate is still mandatory.
- `/team-full` — **Full protocol**. 6 roles, 7 stages. Use for research-heavy, live-system, risky, or heavily-audited goals.
- `/team-escalate` — Promotes a Lite goal to full protocol when the scope grows.

## Project opt-in with enforced rules

To install the global primitives *and* opt a project in with a `CLAUDE.md` file that instructs Claude Code to follow the protocol on every task:

```bash
cd ~/my-project
eden-memory setup claude
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
mkdir -p ~/.claude/skills/team
cp SKILL.md ~/.claude/skills/team/SKILL.md
[ -f CHARTER.md ] && cp CHARTER.md ~/.claude/skills/team/CHARTER.md
cp agents/*.md ~/.claude/agents/
cp commands/*.md ~/.claude/commands/

# 3. In a project that wants to opt in, wire the Eden-memory MCP server:
eden-memory setup claude

# 4. Copy the project-local templates:
mkdir -p .claude/skills/agentic-team-protocol
cp templates/agentic-team-charter.md .claude/agentic-team-charter.md
cp templates/agentic-team-config.yaml .claude/agentic-team-config.yaml
cp templates/skills/agentic-team-protocol/SKILL.md .claude/skills/agentic-team-protocol/SKILL.md

# 5. Optional: create a CLAUDE.md with protocol enforcement rules
cp templates/claude-md.md CLAUDE.md
```

Edit the charter, config, and `CLAUDE.md` to match the project.

## Project opt-in

A project opts into the Agentic Team Protocol by creating:

- `.claude/agentic-team-charter.md` — identity, mission, boundaries, roles, decision rights, escalation paths.
- `.claude/agentic-team-config.yaml` — active roles, default package type, branch policy, override flags.
- `.claude/skills/agentic-team-protocol/SKILL.md` — project-local skill override (e.g., repository-specific branch discipline).

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

## Branch discipline

- Non-trivial changes must be developed on a feature branch checked out from the
  project default branch. Trivial one-line fixes may be committed directly to the
  default branch.
- When `worktree_policy.enabled` is true, non-trivial `build` and `run` goals
  use a dedicated git worktree under `.claude/worktrees/atp/`. Each goal gets
  its own working copy on its feature branch; the default-branch checkout stays
  clean for status checks and Runtime merge operations. Without a worktree
  policy (or with `enabled: false`), goals use the main checkout and still
  require a feature branch for non-trivial work.
- Merges into the default branch must be non-fast-forward merge commits, and both
  parent SHAs must be recorded in the Runtime action record.
- After a successful non-fast-forward merge into the default branch and push to
  origin, Runtime must delete the local feature branch (`git branch -d
  <branch>`). If authorized and the branch is not protected, Runtime must also
  delete the remote branch (`git push origin --delete <branch>`). Runtime records
  the deleted branch names, post-merge default-branch SHA, and any skip reason in
  the action record.
- Protected/long-lived branches must never be deleted (default branch,
  `release/*`, `hotfix/*`, etc.).
- In headless/eden-team workflows, skip local deletion if the working copy is
  not on the feature branch (e.g., detached or shallow checkout) and record
  `headless_skip_local: true`.

## Slash commands

After restart:

- `/team` — invoke the Agentic Team Protocol skill to kick off a goal or ask for help with the lifecycle.
- `/team-charter` — read the project charter, store a ratification record in Eden-memory.
- `/team-status` — list active goals, stage, owner role, latest record IDs, and continueable/blocked state.
- `/team-escalate` — write a structured escalation record and route by level.
- `/team-continue` — resume an unfinished goal by rehydrating it from Eden-memory and dispatching the next role.
- `/team-handoff` — transfer ownership of a goal to another role in a durable record.

## Headless supervisor

For non-interactive goals (CI, scheduled tasks, or controllers), use the `eden-team` binary from the [`eden-memory`](https://github.com/yakovkhalinsky/eden-memory) monorepo. It is the headless ATP supervisor: it records the goal in Eden-memory, spawns the dispatcher, runs the lifecycle, and writes a verdict without requiring an interactive Claude Code session.

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh -s eden-team

eden-team start \
  --goal "Create /tmp/atp-hello.txt containing exactly 'hello from ATP'" \
  --mcp-config ./mcp.json \
  --dangerously-skip-permissions
```

See the [headless supervisor tutorial](https://0d3sa.com/agentic-team-protocol/tutorials/headless-supervisor/) for the full setup.

## License

MIT — see the repository [LICENSE](../LICENSE).
