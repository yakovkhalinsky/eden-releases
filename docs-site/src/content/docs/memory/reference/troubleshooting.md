---
title: Troubleshooting
description: Symptom, cause, and fix matrix for common memory problems.
content_type: reference
---

# Troubleshooting

This page lists common memory problems, the most likely cause, and the fix. If a symptom is not here, run `memory_health` and check the logs for the first error.

## Server exits or will not start

| Symptom | Cause | Fix |
|---------|-------|-----|
| `memory` exits immediately with a database error | The database directory does not exist, or `--db` is a relative path. | Create `~/.memory/` or use an absolute `--db` path. |
| MCP server exits in Claude Code | The MCP config uses a relative path or a missing binary. | Use absolute paths for `command` and `--db`. Re-run `memory setup claude`. |
| `memory setup claude` aborts with a health error | The database cannot be opened or `--db` points to a missing directory. | Run `memory --db <path> health` manually, fix the path, then re-run setup. |
| `memory setup claude` aborts with a protocol-version error | The `memory` binary advertises an MCP protocol version incompatible with Claude Code. | Update to a release that supports `2024-11-05` and re-run setup. |
| `ModuleNotFoundError: No module named 'memory_memory'` | A stale Python wrapper is installed at `~/.local/bin/memory`. | Remove the wrapper and reinstall: `rm -f ~/.local/bin/memory; curl -fsSL https://0d3sa.com/memory/install.sh \| sh`. |

## Slow first recall

| Symptom | Cause | Fix |
|---------|-------|-----|
| First `memory_recall` takes several seconds | The bundled embedding runtime and model weights are being extracted to the platform cache. | Wait for it to finish. Subsequent calls are fast. |
| Recall stays slow after the first call | The database is very large, or the query matches many rows. | Run `memory_vacuum` and consider pruning old memories. |

## Relay pairing failures

| Symptom | Cause | Fix |
|---------|-------|-----|
| `pair create-invitation` rejects the password | Password is too short or low entropy. | Use at least 10 characters with at least 40 bits estimated entropy. |
| `pair accept-invitation` cannot find the enrolment | Wrong invitation code, relay URL, or the enrolment expired. | Re-run `pair create-invitation` and share the new code. Verify the relay URL and that both devices can reach the relay. |
| Pairing succeeds but sync does not start | `--start-sync-loop` was not passed and the loop was not started manually. | Run `sync loop start` on both devices. |

## Pending key changes

| Symptom | Cause | Fix |
|---------|-------|-----|
| `sync list-pending-key-changes` shows a peer | A peer device has new identity keys. | Verify the new fingerprints out-of-band, then run `sync approve-key-change`. If suspicious, run `sync reject-key-change`. |
| Pending change reappears after approval | The peer device keeps regenerating keys. | Check whether the peer is restoring an old sidecar or reinstalling repeatedly. |

## Relay connection refused

| Symptom | Cause | Fix |
|---------|-------|-----|
| `connection refused` during registration, pairing, or sync | The relay is not running, or the client is pointing at the wrong relay host/port. | Confirm the relay process is up, that `--relay-url` matches the address in `--addr`, and that the client can reach the relay host and port. See the [relay-first sync topology runbook](/memory/how-to/relay-first-sync-topology/) for the full topology checklist. |

## Sync loop issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| `sync loop status` shows no peers | The device is not registered with the relay, or the account ID differs. | Run `sync loop once` (registers the device) and verify `--account-id` matches on all devices. |
| Sync loop runs but memories do not propagate | A pending key change is blocking deltas. | List pending changes and approve them. |
| Loop stops after network blip | The foreground loop exits on unrecoverable errors. | Restart the loop, or run it under a service manager for always-on sync. |
| High relay CPU or bandwidth | Devices are syncing very large embeddings or a huge backlog. | Increase `--batch-size` or prune old memories before syncing. |

## General checks

Run these first when something is wrong:

1. `memory --db ~/.memory/default.db health` — confirms the database and sidecars are healthy.
2. `memory --db ~/.memory/default.db sync loop status` — confirms the relay loop state and peer count.
3. `memory --db ~/.memory/default.db sync list-pending-key-changes` — rules out blocked key rotations.
4. `curl http://relay.example.com:8787/health` — confirms the relay is reachable.

## Getting more help

If the issue persists, capture:

- the exact command or tool call,
- the error message,
- the output of `memory_health`,
- whether the problem is local-only or affects sync.

See the [CLI reference](/memory/reference/cli/) and [How sync works](/memory/concepts/how-sync-works/) for background on each subsystem.
