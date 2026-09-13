---
title: CLI, env vars, and endpoints
description: Reference for the relay binary — flags, environment variables, REST endpoints, and authentication.
content_type: reference
---

# relay reference

`relay` is a single-purpose HTTP relay for memory sync. It has no memory or MCP subcommands: it serves one REST API, stores its device directory in SQLite, and forwards opaque envelopes between paired devices.

Run it with `--db` pointing at a persistent SQLite path:

```bash
relay --db /var/lib/relay/relay.db --addr 127.0.0.1:8787
```

## CLI flags

| Flag | Default | Description |
|------|---------|-------------|
| `--db` | `$MEMORY_RELAY_DB` | SQLite database path for the relay device directory. **Required.** |
| `--addr` | `$MEMORY_RELAY_ADDR` or `127.0.0.1:8787` | Listen address. Non-loopback addresses require `--allow-remote-bind`. |
| `--tls-cert` | `$MEMORY_TLS_CERT` | TLS certificate path. Enables HTTPS when both cert and key are set. |
| `--tls-key` | `$MEMORY_TLS_KEY` | TLS private key path. Required when `--tls-cert` is set. |
| `--allow-remote-bind` | `$MEMORY_RELAY_ALLOW_REMOTE_BIND` or `false` | Allow binding to a non-loopback address. |
| `--log-format` | `$MEMORY_LOG_FORMAT` or `text` | Log format: `text` or `json`. |
| `--log-level` | `$MEMORY_LOG_LEVEL` or `INFO` | Log level: `DEBUG`, `INFO`, `WARN`, `ERROR`. |
| `--version` | — | Print the version and exit. |

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MEMORY_RELAY_ADDR` | `127.0.0.1:8787` | Listen address, used when `--addr` is not passed. |
| `MEMORY_RELAY_DB` | — | Relay database path, used when `--db` is not passed. |
| `MEMORY_TLS_CERT` / `MEMORY_TLS_KEY` | — | TLS certificate and key paths. Both must be set to enable HTTPS. |
| `MEMORY_RELAY_ALLOW_REMOTE_BIND` | `false` | Set to `1`/`true` to allow non-loopback binding. |
| `MEMORY_LOG_FORMAT` | `text` | Log format: `text` or `json`. |
| `MEMORY_LOG_LEVEL` | `INFO` | Log level: `DEBUG`, `INFO`, `WARN`, `ERROR`. |

## Binding and TLS

- **Loopback by default.** The relay refuses to bind a non-loopback address (or a hostname) unless `--allow-remote-bind` is set. This prevents an accidental public expose.
- **Plain HTTP warning.** Without `--tls-cert`/`--tls-key` the relay serves plain HTTP and logs a warning at startup. Put it behind a TLS-terminating reverse proxy, or give it a certificate directly, when devices sync over the internet.
- Certificates are loaded at startup only; restart the process after renewing them (see the [VPS deploy guide](/relay/how-to/deploy-public-vps/#12-cert-renewal-hook)).

## REST endpoints

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| `GET` | `/health` | none | Health check; returns `{"status":"ok"}`. |
| `POST` | `/v1/register` | none* | Register a device (account ID, device ID, Ed25519/X25519 public keys, auth secret). |
| `POST` | `/v1/push` | device | Push an encrypted envelope to a peer. |
| `POST` | `/v1/pull` | device | Pull pending envelopes. |
| `POST` | `/v1/ack` | device | Acknowledge processed envelopes so they are deleted. |
| `POST` | `/v1/cleanup` | device | Remove expired envelopes for the account. |
| `GET`/`POST` | `/v1/peers` | device | List the other devices registered under the same account. |
| `POST` | `/v1/pake/start` | none | Begin a PAKE pairing exchange. |
| `POST` | `/v1/pake/lookup` | none | Look up a pending PAKE session. |
| `POST` | `/v1/pake/respond` | none | Respond to a PAKE invitation. |
| `POST` | `/v1/pake/confirm` | none | Complete a PAKE pairing. |

\* `/v1/register` is unauthenticated by design: it stores the public keys and a per-device auth secret that the client generates. Everything after registration requires a derived bearer token.

## Authentication

- The relay is **PAKE-only for pairing**: pairing passwords are used inside the PAKE exchange and never stored or sent as bearer credentials.
- Every authenticated endpoint requires three headers:
  - `X-Memory-Account-ID` — the fleet account ID,
  - `X-Memory-Device-ID` — the registered device ID,
  - `Authorization: Bearer <token>` — a token derived from the per-device secret issued at registration.
- Tokens are derived, not stored: the relay keeps the per-device secret and recomputes `DeriveAuthTokenFromSecret(secret, accountID, deviceID)` for comparison. There is no legacy static-password mode.

## What the relay stores

The relay database contains only device directory data (account IDs, device IDs, public keys, per-device secrets) and pending encrypted envelopes. It never contains memory content, metadata, or embeddings. See [Security model](/memory/concepts/security-model/) for the threat model.

## See also

- [relay overview](/relay/)
- [Run your own relay server](/relay/how-to/run-relay-server/)
- [Deploy on a public VPS](/relay/how-to/deploy-public-vps/)
- [How sync works](/memory/concepts/how-sync-works/)