---
title: Sync two devices with a relay
description: Full relay sync from install on both devices to a verified sync loop.
content_type: tutorial
---

# Sync two devices with a relay

This tutorial keeps the same memory database in sync across two devices through a lightweight relay. You will install the binary on both devices, pair them with a relay-mediated PAKE invitation, start a sync loop, and verify that memories propagate.

## Prerequisites

- Two devices running Linux or macOS.
- `od3sa-memory` installed on both (or the ability to run the install script).
- A relay URL from a self-hosted or team-run relay.
- A fleet `account-id` shared by both devices.
- A strong root-key passphrase to encrypt the sidecar files (stored in a file with `0600` permissions).
- A strong pairing password (stored in a file with `0600` permissions).

## 1. Install the binary on both devices

On each device, run:

```bash
curl -fsSL https://0d3sa.com/memory/install.sh | sh
```

Confirm the install:

```bash
od3sa-memory version
od3sa-memory health
```

Both devices should return a version string and a `status: ok` health report.

## 2. Set up or locate a relay

If you are running your own relay, install and start the dedicated `od3sa-relay` binary on an always-on host:

```bash
curl -fsSL https://0d3sa.com/memory/install.sh | sh -s od3sa-relay

od3sa-relay \
  --db /var/lib/relay/relay.db \
  --addr 127.0.0.1:8787
```

The relay needs a persistent SQLite database path and a listen address. It binds to **loopback by default**. The table below summarizes when to use each binding mode:

| Scenario | `--addr` | `--allow-remote-bind` | `--insecure-bind` | TLS flags | Example URL |
|----------|----------|----------------------|-------------------|-----------|-------------|
| Local testing (same machine) | `127.0.0.1:8787` | No | No | — | `http://127.0.0.1:8787` |
| LAN / private mesh (Tailscale) | `100.64.x.x:8787` | Yes | Yes | — | `http://100.64.0.1:8787` |
| Public internet (direct TLS) | `0.0.0.0:443` | Yes | No | `--tls-cert` `--tls-key` | `https://relay.example.com` |
| Public internet (reverse proxy) | `127.0.0.1:8787` | No | No | — (proxy terminates TLS) | `https://relay.example.com` |

- **`--allow-remote-bind`** — required for any non-loopback `--addr`. Without it, the relay exits.
- **`--insecure-bind`** — required for non-loopback without TLS. The relay refuses to serve plain HTTP to off-host clients unless you explicitly opt in.

:::danger[Never use `--insecure-bind` on the public internet]
`--insecure-bind` is for trusted LANs and private meshes only. On public networks, always use `--tls-cert`/`--tls-key` for direct TLS or put the relay behind a reverse proxy that terminates TLS.
:::

For a production relay with TLS, see [Run your own relay server](/relay/how-to/run-relay-server/).

If your team runs a relay, get the base URL from the relay operator (for example, `https://relay.example.com`).

## 3. Prepare secret files

Before pairing, create files for the pairing password and root-key passphrase with restricted permissions:

```bash
# Create password file (at least 10 characters, 40+ bits entropy)
install -m 0600 /dev/null ~/.memory/pairing-password.txt
echo "correct-horse-battery-staple" > ~/.memory/pairing-password.txt
chmod 0600 ~/.memory/pairing-password.txt

# Create passphrase file if not already present
install -m 0600 /dev/null ~/.memory/root-key-passphrase.txt
# ... write your passphrase ...
chmod 0600 ~/.memory/root-key-passphrase.txt
```

:::caution[Never put secrets on the command line]
Secrets passed via `--password` or `--code` are visible to `ps` and process-list tools. Always use `--password-file` and `--code-file` instead, with files that have `0600` (owner read/write only) permissions.
:::

## 4. Create a pairing invitation on the first device

On the device that already has data (or that you want to treat as the source), run:

```bash
od3sa-memory --db ~/.memory/device.db \
  pair create-invitation \
  --relay-url https://relay.example.com \
  --account-id your-account \
  --password-file ~/.memory/pairing-password.txt \
  --device-name "Studio Desktop" \
  --root-key-passphrase-file ~/.memory/root-key-passphrase.txt \
  --confirm
```

The command prints an invitation code and a short rendezvous code.

:::warning[Share on separate channels]
Share the **invitation code** and the **pairing password** through **different trusted channels**. For example, send the invitation code via a secure messaging app and share the password in person or via a password manager. Never send both on the same channel — if that channel is compromised, an attacker can complete the pairing.
:::

## 5. Accept the invitation on the second device

On the joining device, create files for the invitation code and password (received through separate channels):

```bash
# Save the invitation code to a file
install -m 0600 /dev/null ~/.memory/invitation-code.txt
echo "INVITATION_CODE" > ~/.memory/invitation-code.txt
chmod 0600 ~/.memory/invitation-code.txt

# Save the pairing password to a file
install -m 0600 /dev/null ~/.memory/pairing-password.txt
echo "correct-horse-battery-staple" > ~/.memory/pairing-password.txt
chmod 0600 ~/.memory/pairing-password.txt
```

Then accept the invitation:

```bash
od3sa-memory --db ~/.memory/device.db \
  pair accept-invitation \
  --code-file ~/.memory/invitation-code.txt \
  --password-file ~/.memory/pairing-password.txt \
  --root-key-passphrase-file ~/.memory/root-key-passphrase.txt \
  --start-sync-loop \
  --confirm
```

The `--start-sync-loop` flag starts a foreground sync loop in the same process. Without it, the device records the initiator as a peer and you can start the loop separately.

Accepting the invitation does three things:

1. Receives the account root key.
2. Records the initiator as a peer.
3. Registers the joining device with the relay.

## 6. Start the sync loop on the first device

If you did not use `--start-sync-loop` on the source device, start the loop there:

```bash
od3sa-memory --db ~/.memory/device.db \
  sync loop start \
  --relay-url https://relay.example.com \
  --account-id your-account \
  --root-key-passphrase-file ~/.memory/root-key-passphrase.txt \
  --confirm
```

This runs in the foreground until you press Ctrl+C or send SIGTERM. For a background loop, run the command inside a service manager such as systemd.

Check the loop status at any time:

```bash
od3sa-memory --db ~/.memory/device.db sync loop status
```

## 7. Verify sync

1. Store a memory on the first device through your MCP client or the CLI fallback.
2. On the second device, force a single sync round:
   ```bash
   od3sa-memory --db ~/.memory/device.db \
     sync loop once \
     --relay-url https://relay.example.com \
     --account-id your-account \
     --root-key-passphrase-file ~/.memory/root-key-passphrase.txt
   ```
3. Recall the same memory on the second device.

If both devices run continuous loops, the memory should appear within one loop interval (default 30 seconds). You can also check health on either device:

```bash
od3sa-memory --db ~/.memory/device.db health
```

A `peer_count` greater than zero means the relay has registered peers.

## Expected output

- Both devices show `status: ok` from `memory_health`.
- `pair create-invitation` returns an `invitation_code`.
- `pair accept-invitation` finishes without errors and, with `--start-sync-loop`, begins syncing.
- A memory stored on one device is recallable on the other.

## Troubleshooting

- **Relay is unreachable** — check the relay URL and firewall rules. The relay listens on the address you passed to `--addr`. If connecting over the internet, use `https://` and ensure the relay has TLS configured.
- **Password rejected** — ensure the password is at least 10 characters with enough entropy.
- **Secret file permissions** — `--password-file` and `--code-file` require files with `0600` or `0400` permissions. Check with `ls -l` and fix with `chmod 0600`.
- **Root-key passphrase prompt** — use `--root-key-passphrase-file` with a `0600` file, or set `MEMORY_ROOT_KEY_PASSPHRASE` in the environment.
- **Pending key changes** — if a peer key rotation is staged, approve it with `sync approve-key-change`. See [Approve a peer key rotation](/memory/how-to/approve-peer-key-change/).
- **Loop not registering** — confirm both devices use the same `--account-id` and relay URL, and that each device has a unique device identity sidecar. See [Sidecar files](/memory/concepts/sidecar-files/) and [How sync works](/memory/concepts/how-sync-works/).

## Next steps

- [Relay-first sync topology](/memory/how-to/relay-first-sync-topology/)
- [Sync two databases locally](/memory/tutorials/sync-local-databases/)
- [How sync works](/memory/concepts/how-sync-works/)
- [Security model](/memory/concepts/security-model/)
- [CLI reference](/memory/reference/cli/)
- [Troubleshooting](/memory/reference/troubleshooting/)
