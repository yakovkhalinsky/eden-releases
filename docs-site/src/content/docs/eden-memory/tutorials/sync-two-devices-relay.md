---
title: Sync two devices with a relay
description: Full relay sync from install on both devices to a verified sync loop.
content_type: tutorial
---

# Sync two devices with a relay

This tutorial keeps the same eden-memory database in sync across two devices through a lightweight relay. You will install the binary on both devices, pair them with a relay-mediated PAKE invitation, start a sync loop, and verify that memories propagate.

## Prerequisites

- Two devices running Linux or macOS.
- eden-memory installed on both (or the ability to run the install script).
- A relay URL. You can run your own relay or use one provided by your team.
- A fleet `account-id` shared by both devices.
- A strong root-key passphrase to encrypt the sidecar files.

## 1. Install the binary on both devices

On each device, run:

```bash
curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
```

Confirm the install:

```bash
eden-memory version
eden-memory health
```

Both devices should return a version string and a `status: ok` health report.

## 2. Set up or locate a relay

If you are running your own relay, start it on a reachable host:

```bash
eden-memory relay-server \
  --relay-db /var/lib/eden-relay/relay.db \
  --addr :8787 \
  --confirm
```

The relay needs a persistent SQLite database path and a listen address. Default port is `8787`. For a production relay, see [Run your own relay server](/eden-memory/how-to/run-relay-server/).

If someone else is hosting the relay, write down the base URL (for example, `http://relay.example.com:8787`).

## 3. Create a pairing invitation on the first device

On the device that already has data (or that you want to treat as the source), run:

```bash
eden-memory --db ~/.eden-memory/device.db \
  pair create-invitation \
  --relay-url http://relay.example.com:8787 \
  --account-id your-account \
  --password "correct-horse-battery-staple" \
  --device-name "Studio Desktop" \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

The command prints an invitation code and a short rendezvous code. The pairing password must be at least 10 characters long and have at least 40 bits of estimated entropy. Share the **invitation code** and the **password** with the second device through a trusted channel.

## 4. Accept the invitation on the second device

On the joining device, run:

```bash
eden-memory --db ~/.eden-memory/device.db \
  pair accept-invitation \
  --code INVITATION_CODE \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --start-sync-loop \
  --confirm
```

Replace `INVITATION_CODE` with the code from step 3. The `--start-sync-loop` flag starts a foreground sync loop in the same process. Without it, the device records the initiator as a peer and you can start the loop separately.

Accepting the invitation does three things:

1. Receives the account root key.
2. Records the initiator as a peer.
3. Registers the joining device with the relay.

## 5. Start the sync loop on the first device

If you did not use `--start-sync-loop` on the source device, start the loop there:

```bash
eden-memory --db ~/.eden-memory/device.db \
  sync loop start \
  --relay-url http://relay.example.com:8787 \
  --account-id your-account \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

This runs in the foreground until you press Ctrl+C or send SIGTERM. For a background loop, run the command inside a service manager such as systemd.

Check the loop status at any time:

```bash
eden-memory --db ~/.eden-memory/device.db sync loop status
```

## 6. Verify sync

1. Store a memory on the first device through your MCP client or the CLI fallback.
2. On the second device, force a single sync round:
   ```bash
   eden-memory --db ~/.eden-memory/device.db \
     sync loop once \
     --relay-url http://relay.example.com:8787 \
     --account-id your-account \
     --root-key-passphrase "$(cat passphrase.txt)"
   ```
3. Recall the same memory on the second device.

If both devices run continuous loops, the memory should appear within one loop interval (default 30 seconds). You can also check health on either device:

```bash
eden-memory --db ~/.eden-memory/device.db health
```

A `peer_count` greater than zero means the relay has registered peers.

## Expected output

- Both devices show `status: ok` from `eden_health`.
- `pair create-invitation` returns an `invitation_code`.
- `pair accept-invitation` finishes without errors and, with `--start-sync-loop`, begins syncing.
- A memory stored on one device is recallable on the other.

## Troubleshooting

- **Relay is unreachable** — check the relay URL and firewall rules. The relay listens on the address you passed to `--addr`.
- **Password rejected** — ensure the password is at least 10 characters with enough entropy.
- **Root-key passphrase prompt** — store the passphrase in a file or environment variable. The command falls back to `EDEN_ROOT_KEY_PASSPHRASE` if set.
- **Pending key changes** — if a peer key rotation is staged, approve it with `sync approve-key-change`. See [Approve a peer key rotation](/eden-memory/how-to/approve-peer-key-change/).
- **Loop not registering** — confirm both devices use the same `--account-id` and relay URL, and that each device has a unique device identity sidecar. See [Sidecar files](/eden-memory/concepts/sidecar-files/) and [How sync works](/eden-memory/concepts/how-sync-works/).

## Next steps

- [Sync two databases locally](/eden-memory/tutorials/sync-local-databases/)
- [How sync works](/eden-memory/concepts/how-sync-works/)
- [Security model](/eden-memory/concepts/security-model/)
- [CLI reference](/eden-memory/reference/cli/)
- [Troubleshooting](/eden-memory/reference/troubleshooting/)
