---
title: Deploy on a public VPS
description: Run a self-hosted eden-relay on a public VPS with Let's Encrypt TLS, systemd, ufw, fail2ban, and certbot renewal hooks.
content_type: how-to
---

# Deploy on a public VPS

This guide walks through running a self-hosted eden-relay on a public
VPS with valid TLS, systemd, firewall rules, and basic hardening. All
commands are copy-pasteable once you replace `relay.example.com` with your own
domain.

For a private mesh deployment (for example, behind Tailscale), see the
[Tailscale-only relay](#tailscale-only-relay-optional) section at the end of
this guide instead of exposing port 443 to the public internet. For a simpler
self-hosted relay without TLS hardening details, see [Run your own relay
server](/eden-relay/how-to/run-relay-server/).

## 1. VPS minimum specs and OS

- Ubuntu 22.04 LTS or 24.04 LTS (other recent Debian-derived distributions work
  with minor package-name changes).
- 1 vCPU, 1 GB RAM, 10 GB disk (enough for the binary, SQLite database, logs,
  and a small certbot footprint).
- A public IPv4 address. IPv6 is optional but recommended; add an `AAAA` record
  if you use it.
- A DNS `A` (and `AAAA`) record pointing `relay.example.com` to the VPS IP.

## 2. Install eden-memory

Download the latest release binary for the VPS architecture. Replace
`linux-amd64` with `linux-arm64` if you are on an ARM VPS.

```bash
sudo mkdir -p /opt/eden-memory /usr/local/bin
cd /opt/eden-memory
curl -fsSL -o eden-memory \
  "https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-linux-amd64"
chmod +x eden-memory
sudo ln -sf /opt/eden-memory/eden-memory /usr/local/bin/eden-memory
eden-memory version
```

The binary is a single file; no runtime or package manager is required.

## 3. Create the `eden-relay` user and directories

Run the relay as an unprivileged system user with no login shell.

```bash
sudo useradd -r -s /usr/sbin/nologin -M eden-relay
sudo mkdir -p /var/lib/eden-relay /etc/eden-relay /var/log/eden-relay
sudo chown -R eden-relay:eden-relay /var/lib/eden-relay /etc/eden-relay /var/log/eden-relay
sudo chmod 750 /var/lib/eden-relay /etc/eden-relay
sudo chmod 755 /var/log/eden-relay
```

Paths used throughout this guide:

| Path | Purpose |
|------|---------|
| `/var/lib/eden-relay/relay.db` | SQLite database for the relay directory. |
| `/etc/eden-relay/eden-relay.env` | Environment variables loaded by systemd. |
| `/etc/eden-relay/certbot-deploy-hook.sh` | certbot deploy hook that restarts the relay. |
| `/var/log/eden-relay` | Service log directory (optional, when not using journald). |

## 4. Generate a strong fleet root-key passphrase

Each device in the fleet uses the same account root-key passphrase to derive the
account sync key. Generate it once and distribute it securely to every device
that joins the fleet.

On the VPS:

```bash
sudo install -o eden-relay -g eden-relay -m 600 /dev/null /etc/eden-relay/root-key-passphrase
openssl rand -base64 32 | sudo tee /etc/eden-relay/root-key-passphrase > /dev/null
sudo chmod 600 /etc/eden-relay/root-key-passphrase
sudo chown eden-relay:eden-relay /etc/eden-relay/root-key-passphrase
```

Copy the passphrase to clients through an existing secure channel (password
manager, encrypted file share, or in-person transfer). Never expose it in shell
history on shared machines; use `$(cat passphrase.txt)` only with a file that
has `600` permissions.

## 5. Let's Encrypt TLS via certbot

Install certbot and obtain a certificate for `relay.example.com`. Port 80 must
be reachable for the standalone challenge.

```bash
sudo apt update
sudo apt install -y certbot
sudo certbot certonly --standalone -d relay.example.com --agree-tos -n -m admin@example.com
```

The certificate and key will be created at:

```text
/etc/letsencrypt/live/relay.example.com/fullchain.pem
/etc/letsencrypt/live/relay.example.com/privkey.pem
```

Make sure the `eden-relay` user can read them. The simplest approach is to add
`eden-relay` to the `ssl-cert` group and ensure the group can read the
`/etc/letsencrypt/archive` and `/etc/letsencrypt/live` directories:

```bash
sudo usermod -a -G ssl-cert eden-relay
sudo chmod 755 /etc/letsencrypt/live /etc/letsencrypt/archive
sudo chmod 640 /etc/letsencrypt/live/relay.example.com/fullchain.pem
sudo chmod 640 /etc/letsencrypt/live/relay.example.com/privkey.pem
sudo chown root:ssl-cert /etc/letsencrypt/live/relay.example.com/*.pem
```

Log out and back in, or run `newgrp ssl-cert` as root, for the group change to
take effect before starting the service.

## 6. Environment file

Create an environment file for the relay service. The file is loaded by systemd
via `EnvironmentFile`. Keep secrets out of the process command line.

```bash
sudo tee /etc/eden-relay/eden-relay.env <<'EOF'
# eden-memory relay runtime configuration
EDEN_LOG_LEVEL=INFO
EDEN_LOG_FORMAT=json
EOF
sudo chown eden-relay:eden-relay /etc/eden-relay/eden-relay.env
sudo chmod 600 /etc/eden-relay/eden-relay.env
```

## 7. systemd service

Create `/etc/systemd/system/eden-relay.service`:

```ini
[Unit]
Description=eden-memory public relay
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=eden-relay
Group=eden-relay
EnvironmentFile=-/etc/eden-relay/eden-relay.env
WorkingDirectory=/var/lib/eden-relay
ExecStart=/usr/local/bin/eden-memory relay-server \
  --relay-db /var/lib/eden-relay/relay.db \
  --addr 0.0.0.0:443 \
  --tls-cert /etc/letsencrypt/live/relay.example.com/fullchain.pem \
  --tls-key /etc/letsencrypt/live/relay.example.com/privkey.pem \
  --confirm
Restart=always
RestartSec=5

# Hardening
NoNewPrivileges=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/var/lib/eden-relay
ReadOnlyPaths=/etc/eden-relay /etc/letsencrypt

[Install]
WantedBy=multi-user.target
```

To bind to a specific public interface instead of all interfaces, change
`--addr 0.0.0.0:443` to `--addr 203.0.113.10:443` (replace with the VPS public
IP). There is no separate `--listen` flag; binding is controlled entirely by
`--addr`.

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now eden-relay
sudo systemctl status eden-relay
```

## 8. Firewall (ufw)

Allow SSH, certbot's standalone HTTP challenge, and the relay HTTPS port. Deny
all other inbound traffic by default.

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

Verify the rules:

```bash
sudo ufw status verbose
```

If you run a reverse proxy in front of the relay, allow only the proxy port
(typically `80` and `443`) and have the proxy forward to the relay on a
loopback address.

## 9. Health check

The relay exposes `/health` on the bound address. With TLS enabled, use HTTPS:

```bash
curl -fsSL https://relay.example.com/health
```

A healthy relay returns a short JSON status report:

```json
{"status":"ok"}
```

Add a systemd `ExecStartPost` health check if you want the service to fail
fast on startup:

```ini
ExecStartPost=/bin/sh -c 'until curl -fsSL https://relay.example.com/health; do sleep 1; done'
```

## 10. Client registration and sync loop

From a client device, register with the relay and start a foreground sync
loop. The client needs the same fleet root-key passphrase that was generated in
step 4.

```bash
eden-memory --db ~/.eden-memory/default.db \
  relay-register \
  --relay-url https://relay.example.com \
  --account-id your-account \
  --root-key-passphrase "$(cat /path/to/root-key-passphrase)" \
  --confirm

eden-memory --db ~/.eden-memory/default.db \
  sync loop start \
  --relay-url https://relay.example.com \
  --account-id your-account \
  --root-key-passphrase "$(cat /path/to/root-key-passphrase)" \
  --confirm
```

`relay-register` is performed automatically by `sync loop start`, but running it
explicitly is useful to verify connectivity before starting the long-running
loop. The loop runs in the foreground until it receives `SIGINT` or `SIGTERM`;
run it under your own service manager or terminal multiplexer for continuous
sync.

## 11. Pairing additional devices

You can pair a new device through the relay after the first device is
registered.

On a device already in the fleet:

```bash
eden-memory --db ~/.eden-memory/default.db \
  pair create-invitation \
  --relay-url https://relay.example.com \
  --account-id your-account \
  --password "correct-horse-battery-staple" \
  --device-name "Studio Desktop" \
  --root-key-passphrase "$(cat /path/to/root-key-passphrase)" \
  --confirm
```

Share the printed invitation code and the pairing password through separate,
secure channels.

On the new device:

```bash
eden-memory --db ~/.eden-memory/default.db \
  pair accept-invitation --code <code> \
  --start-sync-loop \
  --root-key-passphrase "$(cat /path/to/root-key-passphrase)" \
  --confirm
```

The new device receives the account root key through PAKE, registers itself
with the relay, and (with `--start-sync-loop`) begins syncing immediately.

## 12. Cert renewal hook

eden-memory loads TLS certificates at startup and does not hot-reload them.
certbot must restart the `eden-relay` service after renewing the certificate.

Create `/etc/eden-relay/certbot-deploy-hook.sh`:

```bash
#!/bin/sh
set -e
systemctl restart eden-relay
```

Write the hook and make it executable:

```bash
sudo tee /etc/eden-relay/certbot-deploy-hook.sh <<'EOF'
#!/bin/sh
set -e
systemctl restart eden-relay
EOF
sudo chmod 755 /etc/eden-relay/certbot-deploy-hook.sh
sudo chown root:root /etc/eden-relay/certbot-deploy-hook.sh
```

Tell certbot to use it. You can either re-run certbot with `--deploy-hook` or
edit the renewal config:

```bash
sudo certbot renew --deploy-hook /etc/eden-relay/certbot-deploy-hook.sh --dry-run
```

To make the hook permanent, add it to the certificate's renewal configuration:

```bash
sudo tee -a /etc/letsencrypt/renewal/relay.example.com.conf <<'EOF'
deploy_hook = /etc/eden-relay/certbot-deploy-hook.sh
EOF
```

Then test a dry-run renewal:

```bash
sudo certbot renew --dry-run
```

## 13. Hardening

- **fail2ban**: Install and enable fail2ban to slow brute-force scans on SSH
  and the relay HTTPS port.

  ```bash
  sudo apt install -y fail2ban
  sudo tee /etc/fail2ban/jail.local <<'EOF'
  [sshd]
  enabled = true
  maxretry = 5
  bantime = 3600

  [eden-relay]
  enabled = true
  port = 443
  filter = eden-relay
  logpath = /var/log/eden-relay/access.log
  maxretry = 10
  bantime = 3600
  EOF
  ```

  Create `/etc/fail2ban/filter.d/eden-relay.conf` with a basic filter:

  ```ini
  [Definition]
  failregex = ^<HOST> .* "(POST|GET) /v1/.* HTTP/[0-9.]+" (401|403|429)
              ^<HOST> .* "GET /health HTTP/[0-9.]+" 400
  ignoreregex =
  ```

  The relay currently logs to stderr/journald by default. If you want fail2ban
  to monitor relay requests, route access logs to `/var/log/eden-relay/access.log`
  or point fail2ban at the systemd journal for the `eden-relay.service` unit.

- **Bind to a specific interface**: Use `--addr 203.0.113.10:443` instead of
  `0.0.0.0:443` so the relay is not reachable on internal or backup interfaces.

- **SSH hardening**: Disable password authentication and root login in
  `/etc/ssh/sshd_config`:

  ```text
  PermitRootLogin no
  PasswordAuthentication no
  PubkeyAuthentication yes
  ```

  Then run `sudo systemctl restart ssh`.

- **Automatic updates**: Enable unattended-upgrades to apply security updates
  automatically:

  ```bash
  sudo apt install -y unattended-upgrades
  sudo dpkg-reconfigure -plow unattended-upgrades
  ```

- **Back up the relay database**: The relay database only stores device
  directory data and opaque envelopes; it does not contain memory contents.
  Back it up regularly anyway so account metadata and pending envelopes are not
  lost:

  ```bash
  sudo -u eden-relay sqlite3 /var/lib/eden-relay/relay.db ".backup /var/lib/eden-relay/relay.db.backup"
  ```

## Tailscale-only relay (optional)

If you do not want to expose port 443 to the public internet, run the relay on
a private network such as Tailscale and bind it to the Tailscale interface. For
example:

```bash
eden-memory relay-server \
  --relay-db /var/lib/eden-relay/relay.db \
  --addr 100.64.0.1:8787 \
  --confirm
```

Clients then use `http://100.64.0.1:8787` (plain HTTP is acceptable inside the
private mesh). Do not use plain HTTP over the public internet.

## Expected outcome

After completing this guide:

- `https://relay.example.com/health` returns a JSON `ok` response.
- The `eden-relay` service is running under systemd as the `eden-relay` user.
- Port 443 is reachable from the internet; port 80 is open only for certbot.
- A client device can `relay-register` with the relay and start a sync loop.
- Additional devices can join the fleet via `pair create-invitation` / `pair
  accept-invitation`.
- Certificates renew automatically and restart the relay service via the
  certbot deploy hook.
