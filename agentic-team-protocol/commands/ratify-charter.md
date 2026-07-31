---
description: Ratify the project's Agentic Team Protocol charter
allowed-tools:
  - Bash
  - Read
---

# /ratify-charter

Read the project's `agentic-team-charter.md` (project-local first, then global fallback), store a ratification record in Eden-memory, and report whether the team may proceed to production implementation.

## Steps

1. Determine the charter path:
   - If `/home/yakov/git/test/.claude/agentic-team-charter.md` exists, use it.
   - Otherwise fall back to `~/.claude/skills/agentic-team-protocol/CHARTER.md` if it exists.
2. Read the charter with `Read` or `cat`.
3. Compute a simple version hash from the file content:
   ```bash
   CHARTER_PATH="/home/yakov/git/test/.claude/agentic-team-charter.md"
   VERSION=$(sha256sum "$CHARTER_PATH" | cut -d' ' -f1 | head -c 16)
   ```
4. Store a ratification record in Eden-memory:
   ```bash
   /home/yakov/.local/bin/eden-memory remember \
     --agent-id claude-code-cli \
     --user-id yakov \
     --content "Charter ratified for project. Version: $VERSION. Rater: yakov. Date: $(date -u +%Y-%m-%dT%H:%M:%SZ). Mechanism: /ratify-charter. Deferrals: none." \
     --metadata '{"kind":"charter_ratification","stage":"charter_ratification","goal_id":"charter-ratification","owner_role":"archivist"}'
   ```
5. Summarise for the user: charter path, version, ratification record ID, and proceed/no-proceed status. If critical guardrails are deferred or the charter is missing, report no-proceed.
