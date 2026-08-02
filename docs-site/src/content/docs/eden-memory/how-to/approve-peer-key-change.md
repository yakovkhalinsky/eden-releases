---
title: Approve a peer key rotation
description: Inspect and approve or reject pending Ed25519/X25519 key changes from a peer device.
content_type: how-to
---

# Approve a peer key rotation

When a peer device replaces its identity sidecar, eden-memory stages the new public key as a **pending key change**. You must inspect and approve it before the device can sync again. This guide shows how to list, approve, or reject pending changes.

## Prerequisites

- eden-memory running as an MCP server or available via CLI.
- The peer device has regenerated its keys (for example, after a reinstall or sidecar restore).
- You have a trusted channel to verify the new public-key fingerprint.

## 1. List pending key changes

Use the CLI or the equivalent MCP tool:

```bash
eden-memory --db ~/.eden-memory/default.db \
  sync list-pending-key-changes
```

The output shows each peer device ID, the old and new key fingerprints, and the time the change was staged.

## 2. Verify the fingerprint out-of-band

Contact the peer owner through a trusted channel (in person, video call, or team chat) and confirm the new Ed25519 and X25519 fingerprints match what they see on their device.

You can view their current public key with:

```bash
eden-memory --db ~/.eden-memory/default.db health
```

If the relay shows a different fingerprint than the one you received directly, do not approve the change.

## 3. Approve the change

If the fingerprints match, approve the pending change:

```bash
eden-memory --db ~/.eden-memory/default.db \
  sync approve-key-change \
  --peer-id <device-id> \
  --confirm
```

After approval, deltas signed with the new key are accepted. Sync resumes on the next loop interval or `sync loop once`.

## 4. Reject a suspicious change

If the fingerprint does not match or you do not recognize the device, reject it:

```bash
eden-memory --db ~/.eden-memory/default.db \
  sync reject-key-change \
  --peer-id <device-id> \
  --confirm
```

Rejected changes are discarded. The peer must fix its identity or re-pair before sync can work.

## 5. Force a sync round

After approval, verify sync works:

```bash
eden-memory --db ~/.eden-memory/default.db \
  sync loop once \
  --relay-url http://relay.example.com:8787 \
  --account-id your-account \
  --root-key-passphrase "$(cat passphrase.txt)"
```

If the loop succeeds and no new pending changes appear, the rotation is complete.

## Expected outcome

- `sync list-pending-key-changes` shows the staged change before approval.
- Out-of-band verification matches the new fingerprints.
- `sync approve-key-change` enables deltas from the new peer key.
- `sync loop once` completes without creating a new pending change.

## See also

- [How sync works](/eden-memory/concepts/how-sync-works/)
- [Sidecar files](/eden-memory/concepts/sidecar-files/)
- [Security model](/eden-memory/concepts/security-model/)
- [CLI reference](/eden-memory/reference/cli/)
