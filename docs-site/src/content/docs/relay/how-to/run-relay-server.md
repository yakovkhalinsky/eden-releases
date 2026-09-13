---
title: Run your own relay server
description: Stand up a self-hosted relay with the dedicated binary, configure flags and environment variables, and connect devices.
content_type: how-to
---

# Run your own relay server

A self-hosted relay lets you sync memory devices across separate networks without relying on a third-party service. This guide sets up the dedicated `relay` binary as a long-running process, verifies it, and connects a device.

For a full public-internet VPS deployment with Let's Encrypt, systemd, firewall rules, and hardening, see [Deploy on a public VPS](/relay/how-to/deploy-public-vps/). For a private mesh deployment (for example, Tailscale) without exposing ports to the internet, bind the relay to the mesh interface and use plain HTTP inside the mesh.

## Prerequisites

- The `relay` binary installed on the relay host:

  ```bash
  curl -fsSL https://0d3sa.com/memory/install.sh | sh -s relay
  ```

- A reachable host and port (default `8787`).
- A persistent directory for the relay SQLite database.
- A firewall rule allowing inbound TCP traffic on the relay port.

## 1. Create the relay database directory

```bash
sudo mkdir -p /var/lib/relay
sudo chown $(whoami):$(whoami) /var/lib/relay
```

## 2. Start the relay

The `--db` flag (or `MEMORY_RELAY_DB`) is required:

```bash
relay \
  --db /var/lib/relay/relay.db \
  --addr 127.0.0.1:8787
```

The relay binds to **loopback** by default (`127.0.0.1:8787`). To accept connections from other devices, opt in with `--allow-remote-bind` and pass a non-loopback address:

```bash
relay \
  --db /var/lib/relay/relay.db \
  --addr 192.168.1.10:8787 \
  --allow-remote-bind
```

Without `--allow-remote-bind`, a non-loopback `--addr` is rejected at startup. See [CLI, env vars, and endpoints](/relay/reference/) for all flags, including `--tls-cert`/`--tls-key` for HTTPS.

:::caution
Without `--tls-cert` and `--tls-key` the relay serves plain HTTP and logs a warning. Use TLS whenever devices sync over an untrusted network.
:::

## 3. Verify the relay is running

Check the health endpoint:

```bash
curl http://127.0.0.1:8787/health
```

A healthy relay returns `{"status":"ok"}`. If the relay is behind a reverse proxy, check the external URL instead.

## 4. Connect a device

There is no `relay-register` CLI subcommand. Devices register with the relay in one of two ways:

- **Pairing (recommended).** `pair create-invitation` / `pair accept-invitation` register both devices with the relay as part of the PAKE exchange:

  ```bash
  # On a device already in the fleet
  memory --db ~/.memory/default.db pair create-invitation \
    --relay-url http://relay.example.com:8787 \
    --account-id your-account \
    --password "correct-horse-battery-staple"

  # On the new device
  memory --db ~/.memory/default.db pair accept-invitation \
    --code <invitation-code> \
    --relay-url http://relay.example.com:8787 \
    --account-id your-account \
    --start-sync-loop
  ```

- **The `memory_relay_register` MCP tool.** From an agent session, call `memory_relay_register` with the relay URL and account ID. The `memory_relay_server` MCP tool can also embed a relay inside an memory process.

Once registered, start the foreground sync loop with `memory sync loop start --relay-url ... --account-id ... --confirm`. See [Sync two devices with a relay](/memory/tutorials/sync-two-devices-relay/).

## 5. Run the relay as a service

For production, run the relay under a service manager. Example systemd unit:

```ini
[Unit]
Description=relay
After=network.target

[Service]
ExecStart=/home/yourname/.local/bin/relay --db /var/lib/relay/relay.db --addr 127.0.0.1:8787
Restart=always
User=relay
Group=relay

[Install]
WantedBy=multi-user.target
```

If the relay must accept off-host connections directly (no reverse proxy), add `--allow-remote-bind --addr 0.0.0.0:8787` to `ExecStart`. Create a dedicated user, set the file permissions on `/var/lib/relay`, and reload systemd.

## 6. Secure the relay

- Put the relay behind a reverse proxy with TLS, or give the binary its own certificate with `--tls-cert`/`--tls-key`, when devices sync over the internet.
- Restrict firewall rules to known device IP ranges if possible.
- Run the relay as an unprivileged user.
- Back up the relay database regularly; it stores account and device directory data but not memory contents.

## Expected outcome

- `curl http://127.0.0.1:8787/health` returns `{"status":"ok"}`.
- Devices register through pairing or `memory_relay_register` and appear in `GET /v1/peers`.
- Devices with the same `account-id` can discover each other and exchange envelopes.

## See also

- [CLI, env vars, and endpoints](/relay/reference/)
- [Deploy on a public VPS](/relay/how-to/deploy-public-vps/)
- [How sync works](/memory/concepts/how-sync-works/)
- [Security model](/memory/concepts/security-model/)
- [Sync two devices with a relay](/memory/tutorials/sync-two-devices-relay/)