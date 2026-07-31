# Project instructions

<!-- AGENTIC TEAM PROTOCOL RULES -->

## Memory-first rules

1. Immediately after the user gives a task, call `mcp__eden-memory__eden_recall` with the task summary.
2. Before any decision that touches user preferences, coding style, security, or tooling, call `mcp__eden-memory__eden_recall` first.
3. After corrections, working solutions, or settled conventions, call `mcp__eden-memory__eden_remember`.
4. At the end of every task, batch 3–5 durable takeaways into `mcp__eden-memory__eden_remember` calls.
5. Do not remember secrets, tokens, raw command output, ephemeral reasoning, or unvalidated guesses.
6. If eden-memory tools are unavailable, use the `/eden-*` fallback slash commands.

## Agentic Team Protocol rules

1. For every non-trivial task, start with the Dispatcher subagent, record a goal receipt in Eden-memory, and obtain a dispatch instruction before any implementation work.
2. Do not begin implementation until the Researcher has gathered context and the plan is approved.
3. Builder (or Runtime) executes the action and records an action record; Verifier inspects the outcome and writes a verdict; Archivist closes and links all records.
4. Start each session by checking `/agentic-status`.
5. Escalate via `/agentic-escalate` when confidence is low, authority is missing, or scope expands.
6. The user can override any role decision.
