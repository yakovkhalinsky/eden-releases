---
title: How sync works
description: eden-memory sync internals — delta logs, logical clocks, conflict resolution, transports, double envelope, PAKE pairing, and the sync loop.
content_type: concept
---

# How sync works

eden-memory keeps two or more databases consistent by exchanging small, signed delta logs. Sync is peer-to-peer: no central server holds your memories, and the relay only forwards encrypted envelopes it cannot read. This page explains the sync protocol from the database up.

## Delta logs

Instead of sending the whole database, each device records a delta log of changes: inserts, edits, deletes, and key rotations. When devices sync, they exchange only the deltas each peer has not yet seen.

Each delta is cryptographically signed by the device that created it. A peer applies only deltas with valid signatures from a known peer key.

## Logical clocks and last-write-wins

Every change carries a logical timestamp. When two devices edit the same memory and the deltas meet, eden-memory uses a last-write-wins (LWW) rule based on the logical clock:

1. The delta with the higher clock wins.
2. If clocks are equal, a deterministic tie-breaker (for example, the lexicographically smaller device ID) picks the winner.
3. The losing change is still recorded in history; it is not silently dropped.

This keeps conflict resolution predictable across all peers without requiring a central coordinator.

## Transport modes

There are two ways to move deltas between devices:

| Mode | Transport | Pairing | Best for |
|------|-----------|---------|----------|
| Direct sync | Local filesystem access to a peer `.db` file | Optional `pair-device` SPAKE2 | One-shot sync on the same machine or shared filesystem. |
| Relay sync loop | HTTP(S) relay forwards opaque envelopes | Required PAKE invitation | Continuous sync across separate networks. |

### Direct sync

Direct sync opens the peer database file directly and writes deltas into it. Because both databases live in the same process or filesystem, there is no network transport and no relay.

### Relay sync loop

The relay sync loop runs as a background goroutine inside the eden-memory process. At each interval (default 30 seconds) it:

1. Registers with the relay directory if needed.
2. Polls the relay for envelopes addressed to this device.
3. Downloads, decrypts, and applies deltas from peers.
4. Pushes local deltas to the relay for peers to collect.

The loop runs in the foreground until SIGINT/SIGTERM, or can be managed by a service manager for always-on sync.

## The double envelope

Memories never travel as plaintext over the relay. They are wrapped in two layers:

1. **Inner envelope** — the signed delta, encrypted to the recipient's public key.
2. **Outer envelope** — an opaque blob addressed by device ID and account.

The relay sees only the outer envelope: sender and recipient device IDs, account ID, and a timestamp. It cannot decrypt the inner envelope, so it cannot read memory content, metadata, or embeddings.

## PAKE pairing

Before two devices can relay-sync, they must agree on each other's public keys. eden-memory uses a password-authenticated key exchange (PAKE) over the relay:

1. The initiator runs `pair create-invitation` and publishes a PAKE enrolment.
2. The initiator shares the compact invitation code and a strong pairing password out-of-band.
3. The responder runs `pair accept-invitation` with the code and password.
4. Both sides derive the same shared secret, authenticate each other, and exchange long-term public keys.
5. Each device stores the other's public key and registers with the relay.

Direct local pairing uses SPAKE2 in the same process instead of the relay. It stores pinned peer public keys in both databases.

## Key rotation

Device identity keys are stored in sidecar files next to the database. When a device regenerates its keys, the new public key is staged as a pending key change. Peers must approve the new key before they accept deltas signed with it. This prevents a compromised or replaced device from silently injecting changes.

See [Approve a peer key rotation](/eden-memory/how-to/approve-peer-key-change/) for the approval workflow.

## Replay protection

Deltas carry logical clocks and are signed. A peer rejects:

- deltas with clocks lower than the already-applied version for the same memory,
- deltas with invalid signatures,
- deltas from a device whose key change has not been approved.

The relay can replay an outer envelope, but it cannot produce valid signed deltas or read the contents.

## See also

- [Multi-device sync overview](/eden-memory/multi-device-sync/)
- [Sync two devices with a relay](/eden-memory/tutorials/sync-two-devices-relay/)
- [Sidecar files](/eden-memory/concepts/sidecar-files/)
- [Security model](/eden-memory/concepts/security-model/)
- [CLI reference](/eden-memory/reference/cli/)
