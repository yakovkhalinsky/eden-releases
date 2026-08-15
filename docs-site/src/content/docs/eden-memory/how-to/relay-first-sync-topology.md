---
title: Relay-first sync topology
description: Stand up the relay first, then bring each device online in the right order for reliable multi-device sync.
content_type: how-to
---

# Relay-first sync topology

A relay-first topology makes the relay the fixed point of your sync network. You start the relay, confirm it is reachable, register every device explicitly, pair devices over a relay-mediated PAKE invitation, start the sync loop, and verify end-to-end propagation. This order eliminates the most common source of confusion: trying to pair or sync against a relay that is not running yet.

## Prerequisites

- A host that can run the relay continuously (your own machine, an always-on server, or a VPS).
- `eden-memory` or the dedicated `eden-relay` binary installed on the relay host.
- `eden-memory` installed on every client device.
- A fleet `account-id` shared by all devices.
- A strong root-key passphrase to encrypt the sidecar files.
- A firewall rule allowing inbound TCP traffic on the relay port (default `8787`).

## 1. Start the relay

Create a persistent directory for the relay database, then start the relay.

```bash
sudo mkdir -p /var/lib/eden-relay
sudo chown $(whoami):$(whoami) /var/lib/eden-relay

eden-memory relay-server \
  --relay-db /var/lib/eden-relay/relay.db \
  --addr :8787 \
  --confirm
```

Or use the dedicated `eden-relay` binary:

```bash
eden-relay \
  --db /var/lib/eden-relay/relay.db \
  --addr :8787
```

You can also set `EDEN_RELAY_DB` and `EDEN_RELAY_ADDR` instead of passing flags. To bind to a specific interface, use `--addr 192.168.1.10:8787`. For TLS, supply `--tls-cert` and `--tls-key` (or `EDEN_TLS_CERT` and `EDEN_TLS_KEY`).

## 2. Verify relay reachability

From a client device, check the relay health endpoint:

```bash
curl http://relay.example.com:8787/health
```

A healthy relay returns a JSON status report. If you are testing locally, use `http://localhost:8787/health`. Do not proceed until this check succeeds.

## 3. Register the first device

On the device that already has data (or that you want to treat as the source), register it with the relay:

```bash
eden-memory --db ~/.eden-memory/device.db \
  relay-register \
  --relay-url http://relay.example.com:8787 \
  --account-id your-account \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

If you set `EDEN_RELAY_URL`, `EDEN_ACCOUNT_ID`, and `EDEN_ROOT_KEY_PASSPHRASE` in the environment, you can omit those flags.

## 4. Register additional devices

Repeat `relay-register` on every other device that will sync:

```bash
eden-memory --db ~/.eden-memory/device.db \
  relay-register \
  --relay-url http://relay.example.com:8787 \
  --account-id your-account \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

Each device must use the same `--account-id` and relay URL. Pairing in the next step also registers devices automatically, but explicit registration confirms that each device can talk to the relay before pairing begins.

## 5. Pair devices with a relay-mediated invitation

On the source device, create an invitation:

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

Share the printed invitation code and password with the joining device through a trusted channel.

On the joining device, accept the invitation and start the loop:

```bash
eden-memory --db ~/.eden-memory/device.db \
  pair accept-invitation \
  --code INVITATION_CODE \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --start-sync-loop \
  --confirm
```

Accepting receives the account root key, records the initiator as a peer, and registers the joining device with the relay.

## 6. Start the sync loop on the source device

If you did not already start a loop, start it on the source device:

```bash
eden-memory --db ~/.eden-memory/device.db \
  sync loop start \
  --relay-url http://relay.example.com:8787 \
  --account-id your-account \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

This runs in the foreground. For an always-on background loop, run it under a service manager such as systemd. Check status at any time:

```bash
eden-memory --db ~/.eden-memory/device.db sync loop status
```

You can override the default 30-second interval with `--sync-interval` or `EDEN_SYNC_INTERVAL`.

## 7. Verify end-to-end sync

1. Store a memory on the source device through your MCP client or the CLI.
2. On the joining device, force a single sync round:
   ```bash
   eden-memory --db ~/.eden-memory/device.db \
     sync loop once \
     --relay-url http://relay.example.com:8787 \
     --account-id your-account \
     --root-key-passphrase "$(cat passphrase.txt)"
   ```
3. Recall the same memory on the joining device.

If both devices run continuous loops, the memory should appear within one loop interval.

## Expected outcomes

- `curl http://relay.example.com:8787/health` returns a JSON OK response before any client step.
- `relay-register` succeeds from every client device.
- `pair create-invitation` returns an `invitation_code`.
- `pair accept-invitation` finishes without errors and, with `--start-sync-loop`, begins syncing.
- `eden-memory --db ~/.eden-memory/device.db health` on either device shows `peer_count` greater than zero.
- A memory stored on one device is recallable on the other.

## When you see "connection refused"

A `connection refused` error during `relay-register`, pairing, or sync is almost always a topology misconfiguration, not an authentication failure. Diagnose it in this order:

1. **Relay is not running** — confirm the relay process is up and logged no startup errors. The relay must start before any client command.
2. **Wrong relay host or port** — check that `EDEN_RELAY_URL` or `--relay-url` points to the interface and port the relay is actually listening on. The default is `:8787` on all interfaces, but a custom `--addr` binds only that address.
3. **Firewall or network path** — confirm the client can reach the relay host and port. `telnet relay.example.com 8787` or `nc -vz relay.example.com 8787` is a faster check than the eden-memory command.
4. **Reverse proxy or TLS mismatch** — if the relay is behind a reverse proxy, use the external URL and scheme (`https://` when TLS terminates at the proxy). If the relay serves TLS directly, use `https://` and the correct port.

If the health endpoint responds but eden-memory still refuses the connection, check whether `EDEN_RELAY_REQUIRE_PER_DEVICE_AUTH` is enabled and that each device registered with a per-device secret.

## See also

- [Run your own relay server](/eden-relay/how-to/run-relay-server/)
- [Sync two devices with a relay](/eden-memory/tutorials/sync-two-devices-relay/)
- [How sync works](/eden-memory/concepts/how-sync-works/)
- [Security model](/eden-memory/concepts/security-model/)
- [Environment variables](/eden-memory/reference/environment-variables/)
- [Troubleshooting](/eden-memory/reference/troubleshooting/)
