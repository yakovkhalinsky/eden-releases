---
title: Security model
description: eden-memory threat model, what a relay can and cannot see, password requirements, key rotation, and replay protection.
content_type: concept
---

# Security model

eden-memory is local-first: your memories and embeddings live in a SQLite file on your machine. Multi-device sync adds a relay, but the relay is a blind forwarder. This page describes the threat model and the guarantees the protocol provides.

## What is trusted

- **Your device** — the machine running eden-memory and your MCP client.
- **Your password manager** — where you keep the root-key passphrase and pairing passwords.
- **Your peers** — the other devices you explicitly paired with.

## What is not trusted

- **The relay operator** — should not be able to read memory content, metadata, or embeddings.
- **The network between you and the relay** — may be monitored; traffic is encrypted in transit.
- **A stolen database file** — is opaque without the root-key or snapshot passphrase.

## What the relay sees

The relay handles account registration and envelope forwarding. For every envelope it can see:

- the account ID,
- the sender and recipient device IDs,
- the envelope size and timestamp,
- the outer envelope ciphertext.

It cannot see:

- memory content,
- metadata,
- embeddings,
- the inner delta plaintext,
- pairing passwords,
- root-key passphrases.

## What the relay cannot do

Because every delta is signed and encrypted peer-to-peer, the relay cannot:

- forge a valid delta for any device,
- decrypt an envelope,
- modify a delta without breaking the signature,
- force a pairing without the pairing password,
- bypass a pending key-change approval.

## Password and entropy requirements

Pairing passwords must be strong because they bootstrap the PAKE exchange:

- Minimum length: 10 characters.
- Minimum estimated entropy: 40 bits.
- Must be shared out-of-band, not over the relay.

Root-key passphrases encrypt the account root-key sidecar. Use a unique, high-entropy passphrase stored in a password manager.

## Key rotation

Each device has Ed25519 signing keys and X25519 encryption keys in its sidecar. When a device regenerates its keys, peers receive a **pending key change**. Deltas signed with the new key are rejected until a peer explicitly approves the rotation.

This protects against:

- a lost or regenerated sidecar being used to impersonate a device,
- a restored backup overwriting a device's keys without notice,
- an attacker who gains write access to the sidecar directory.

See [Approve a peer key rotation](/eden-memory/how-to/approve-peer-key-change/) for the workflow.

## Replay protection

Deltas include logical clocks. Peers reject old deltas and duplicates. The relay can resend an outer envelope, but the recipient will drop it if the clock has already advanced.

## Sidecar security

Sidecar files hold private keys. Keep them:

- on the local filesystem,
- readable only by the user running eden-memory (`chmod 600`),
- excluded from public backups or repositories,
- backed up separately from the database.

See [Sidecar files](/eden-memory/concepts/sidecar-files/) for details.

## Encrypted snapshots

Database snapshots exported with `eden_export_snapshot` use AES-256-GCM with a key derived from your passphrase via scrypt. The snapshot file is safe to store in ordinary backup storage as long as the passphrase is not stored with it.

## When to escalate

Contact your relay operator or security team if:

- you suspect a device sidecar has been exposed,
- you see unexpected pending key changes,
- a peer reports receiving deltas you did not create,
- the relay asks for your passphrase or pairing password.

eden-memory will never ask the relay operator for secrets.

## See also

- [How sync works](/eden-memory/concepts/how-sync-works/)
- [Sidecar files](/eden-memory/concepts/sidecar-files/)
- [Approve a peer key rotation](/eden-memory/how-to/approve-peer-key-change/)
- [Run your own relay server](/eden-memory/how-to/run-relay-server/)
- [Troubleshooting](/eden-memory/reference/troubleshooting/)
