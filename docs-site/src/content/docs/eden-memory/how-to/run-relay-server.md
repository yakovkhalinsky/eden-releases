---
title: Run your own relay server
description: Stand up a self-hosted eden-memory relay, configure flags and environment variables, and register devices with it.
content_type: how-to
---

# Run your own relay server

A self-hosted relay lets you sync eden-memory devices across separate networks without relying on a third-party service. This guide sets up the relay as a long-running process, verifies it, and registers a device.

## Prerequisites

- eden-memory installed on the relay host.
- A reachable host and port (default `8787`).
- A persistent directory for the relay SQLite database.
- A firewall rule allowing inbound TCP traffic on the relay port.

## 1. Create the relay database directory

```bash
sudo mkdir -p /var/lib/eden-relay
sudo chown $(whoami):$(whoami) /var/lib/eden-relay
```

## 2. Start the relay

Run the `relay-server` subcommand. The `--relay-db` flag is required.

```bash
eden-memory relay-server \
  --relay-db /var/lib/eden-relay/relay.db \
  --addr :8787 \
  --confirm
```

The relay listens on `0.0.0.0:8787` by default. To bind to a specific interface, pass `--addr 192.168.1.10:8787`.

## 3. Verify the relay is running

Check the health endpoint:

```bash
curl http://localhost:8787/health
```

A healthy relay returns a JSON status report. If the relay is behind a reverse proxy, check the external URL instead.

## 4. Register a device with the relay

From a client device, run `relay-register` so peers can discover it:

```bash
eden-memory --db ~/.eden-memory/default.db \
  relay-register \
  --relay-url http://relay.example.com:8787 \
  --account-id your-account \
  --root-key-passphrase "$(cat passphrase.txt)" \
  --confirm
```

Pairing with `pair create-invitation` / `pair accept-invitation` also registers devices automatically. Explicit registration is useful if you paired locally and later want to use a relay.

## 5. Run the relay as a service

For production, run the relay under a service manager. Example systemd unit:

```ini
[Unit]
Description=eden-memory relay
After=network.target

[Service]
ExecStart=/home/yourname/.local/bin/eden-memory relay-server --relay-db /var/lib/eden-relay/relay.db --addr :8787 --confirm
Restart=always
User=eden-relay
Group=eden-relay

[Install]
WantedBy=multi-user.target
```

Create a dedicated user, set the file permissions on `/var/lib/eden-relay`, and reload systemd.

## 6. Secure the relay

- Put the relay behind a reverse proxy with TLS when devices sync over the internet.
- Restrict firewall rules to known device IP ranges if possible.
- Run the relay as an unprivileged user.
- Back up the relay database regularly; it stores account and device directory data but not memory contents.

## Expected outcome

- `curl http://localhost:8787/health` returns a JSON OK response.
- `relay-register` succeeds from a client device.
- Devices with the same `account-id` can discover each other and exchange envelopes.

## See also

- [How sync works](/eden-memory/concepts/how-sync-works/)
- [Security model](/eden-memory/concepts/security-model/)
- [Sync two devices with a relay](/eden-memory/tutorials/sync-two-devices-relay/)
- [CLI reference](/eden-memory/reference/cli/)
