---
title: Run your own relay server
description: Stand up a self-hosted relay with the dedicated binary, configure flags and environment variables, and connect devices.
content_type: how-to
---

# Run your own relay server

A self-hosted relay lets you sync memory devices across separate networks without relying on a third-party service. This guide sets up the dedicated `od3sa-relay` binary as a long-running process, verifies it, and connects a device.

For a full public-internet VPS deployment with Let's Encrypt, systemd, firewall rules, and hardening, see [Deploy on a public VPS](/relay/how-to/deploy-public-vps/). For a private mesh deployment (for example, Tailscale) without exposing ports to the internet, bind the relay to the mesh interface and use plain HTTP inside the mesh.

## Prerequisites

- The `od3sa-relay` binary installed on the relay host:

  ```bash
  curl -fsSL https://0d3sa.com/memory/install.sh | sh -s od3sa-relay
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
od3sa-relay \
  --db /var/lib/relay/relay.db \
  --addr 127.0.0.1:8787
```

The relay binds to **loopback** by default (`127.0.0.1:8787`). To accept connections from other devices on a **trusted LAN or private mesh**, opt in with `--allow-remote-bind` and `--insecure-bind`:

```bash
od3sa-relay \
  --db /var/lib/relay/relay.db \
  --addr 192.168.1.10:8787 \
  --allow-remote-bind \
  --insecure-bind
```

For **public internet** or untrusted networks, use TLS instead of `--insecure-bind`:

```bash
od3sa-relay \
  --db /var/lib/relay/relay.db \
  --addr 0.0.0.0:443 \
  --allow-remote-bind \
  --tls-cert /path/to/cert.pem \
  --tls-key /path/to/key.pem
```

Without `--allow-remote-bind`, a non-loopback `--addr` is rejected at startup. Without `--insecure-bind` or TLS, the relay refuses to serve plain HTTP to off-host clients. See [CLI, env vars, and endpoints](/relay/reference/) for all flags.

:::danger[Never use `--insecure-bind` on the public internet]
`--insecure-bind` is for trusted LANs and private meshes only. On public networks, always use `--tls-cert`/`--tls-key` or put the relay behind a reverse proxy that terminates TLS.
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
  # Prepare password and passphrase files with restricted permissions
  install -m 0600 /dev/null ~/.memory/pairing-password.txt
  echo "correct-horse-battery-staple" > ~/.memory/pairing-password.txt
  
  install -m 0600 /dev/null ~/.memory/root-key-passphrase.txt
  # ... write your passphrase ...

  # On a device already in the fleet
  od3sa-memory --db ~/.memory/default.db pair create-invitation \
    --relay-url https://relay.example.com \
    --account-id your-account \
    --password-file ~/.memory/pairing-password.txt \
    --root-key-passphrase-file ~/.memory/root-key-passphrase.txt \
    --confirm

  # On the new device (after receiving code and password on SEPARATE channels)
  install -m 0600 /dev/null ~/.memory/invitation-code.txt
  echo "<invitation-code>" > ~/.memory/invitation-code.txt
  
  od3sa-memory --db ~/.memory/default.db pair accept-invitation \
    --code-file ~/.memory/invitation-code.txt \
    --password-file ~/.memory/pairing-password.txt \
    --root-key-passphrase-file ~/.memory/root-key-passphrase.txt \
    --start-sync-loop \
    --confirm
  ```

  :::warning[Share on separate channels]
  Share the invitation code and pairing password through **different trusted channels**. Never send both on the same channel.
  :::

- **The `memory_relay_register` MCP tool.** From an agent session, call `memory_relay_register` with the relay URL and account ID.

Serving a relay is always the standalone `od3sa-relay` binary installed above — `od3sa-memory` is only ever a relay *client*. The `memory_relay_server` MCP tool, which used to embed a relay inside the memory process, was removed in 0.6.0, so there is no longer a way to serve a relay from `od3sa-memory`.

Once registered, start the foreground sync loop with `od3sa-memory sync loop start --relay-url ... --account-id ... --confirm`. See [Sync two devices with a relay](/memory/tutorials/sync-two-devices-relay/).

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

If the relay must accept off-host connections directly (no reverse proxy), add `--allow-remote-bind --addr 0.0.0.0:443 --tls-cert /path/to/cert.pem --tls-key /path/to/key.pem` to `ExecStart`. For trusted LAN only, you can use `--insecure-bind` instead of TLS, but **never on the public internet**. Create a dedicated user, set the file permissions on `/var/lib/relay`, and reload systemd.

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