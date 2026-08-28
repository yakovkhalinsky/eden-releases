---
title: Run your own relay server
description: Stand up a self-hosted eden-relay with the dedicated binary, configure flags and environment variables, and connect devices.
content_type: how-to
---

# Run your own relay server

A self-hosted relay lets you sync eden-memory devices across separate networks without relying on a third-party service. This guide sets up the dedicated `eden-relay` binary as a long-running process, verifies it, and connects a device.

For a full public-internet VPS deployment with Let's Encrypt, systemd, firewall rules, and hardening, see [Deploy on a public VPS](/eden-relay/how-to/deploy-public-vps/). For a private mesh deployment (for example, Tailscale) without exposing ports to the internet, bind the relay to the mesh interface and use plain HTTP inside the mesh.

## Prerequisites

- The `eden-relay` binary installed on the relay host:

  ```bash
  curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh -s eden-relay
  ```

- A reachable host and port (default `8787`).
- A persistent directory for the relay SQLite database.
- A firewall rule allowing inbound TCP traffic on the relay port.

## 1. Create the relay database directory

```bash
sudo mkdir -p /var/lib/eden-relay
sudo chown $(whoami):$(whoami) /var/lib/eden-relay
```

## 2. Start the relay

The `--db` flag (or `EDEN_RELAY_DB`) is required:

```bash
eden-relay \
  --db /var/lib/eden-relay/relay.db \
  --addr 127.0.0.1:8787
```

The relay binds to **loopback** by default (`127.0.0.1:8787`). To accept connections from other devices, opt in with `--allow-remote-bind` and pass a non-loopback address:

```bash
eden-relay \
  --db /var/lib/eden-relay/relay.db \
  --addr 192.168.1.10:8787 \
  --allow-remote-bind
```

Without `--allow-remote-bind`, a non-loopback `--addr` is rejected at startup. See [CLI, env vars, and endpoints](/eden-relay/reference/) for all flags, including `--tls-cert`/`--tls-key` for HTTPS.

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
  eden-memory --db ~/.eden-memory/default.db pair create-invitation \
    --relay-url http://relay.example.com:8787 \
    --account-id your-account \
    --password "correct-horse-battery-staple"

  # On the new device
  eden-memory --db ~/.eden-memory/default.db pair accept-invitation \
    --code <invitation-code> \
    --relay-url http://relay.example.com:8787 \
    --account-id your-account \
    --start-sync-loop
  ```

- **The `eden_relay_register` MCP tool.** From an agent session, call `eden_relay_register` with the relay URL and account ID. The `eden_relay_server` MCP tool can also embed a relay inside an eden-memory process.

Once registered, start the foreground sync loop with `eden-memory sync loop start --relay-url ... --account-id ... --confirm`. See [Sync two devices with a relay](/eden-memory/tutorials/sync-two-devices-relay/).

## 5. Run the relay as a service

For production, run the relay under a service manager. Example systemd unit:

```ini
[Unit]
Description=eden-relay
After=network.target

[Service]
ExecStart=/home/yourname/.local/bin/eden-relay --db /var/lib/eden-relay/relay.db --addr 127.0.0.1:8787
Restart=always
User=eden-relay
Group=eden-relay

[Install]
WantedBy=multi-user.target
```

If the relay must accept off-host connections directly (no reverse proxy), add `--allow-remote-bind --addr 0.0.0.0:8787` to `ExecStart`. Create a dedicated user, set the file permissions on `/var/lib/eden-relay`, and reload systemd.

## 6. Secure the relay

- Put the relay behind a reverse proxy with TLS, or give the binary its own certificate with `--tls-cert`/`--tls-key`, when devices sync over the internet.
- Restrict firewall rules to known device IP ranges if possible.
- Run the relay as an unprivileged user.
- Back up the relay database regularly; it stores account and device directory data but not memory contents.

## Expected outcome

- `curl http://127.0.0.1:8787/health` returns `{"status":"ok"}`.
- Devices register through pairing or `eden_relay_register` and appear in `GET /v1/peers`.
- Devices with the same `account-id` can discover each other and exchange envelopes.

## See also

- [CLI, env vars, and endpoints](/eden-relay/reference/)
- [Deploy on a public VPS](/eden-relay/how-to/deploy-public-vps/)
- [How sync works](/eden-memory/concepts/how-sync-works/)
- [Security model](/eden-memory/concepts/security-model/)
- [Sync two devices with a relay](/eden-memory/tutorials/sync-two-devices-relay/)