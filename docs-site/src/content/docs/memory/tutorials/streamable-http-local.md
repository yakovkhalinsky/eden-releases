---
title: Run a local HTTP MCP server
description: Start memory as a self-hosted Streamable HTTP MCP server and verify it with curl.
content_type: tutorial
---

# Run a local HTTP MCP server

This tutorial starts memory as a self-hosted Streamable HTTP server on loopback, sets up bearer-token authentication, and verifies the setup with curl.

:::note[Self-hosted only]
This guide covers running a local HTTP MCP server on your own machine. This is **not** a managed, hosted, or multi-tenant service — you run and operate the server yourself.
:::

## Prerequisites

- A Linux or macOS machine with shell access.
- The `od3sa-memory` binary installed (run `od3sa-memory version` to verify).
- An MCP client that supports the Streamable HTTP transport.

## 1. Install or update the binary

Run the installer to get the latest release:

```bash
curl -fsSL https://0d3sa.com/memory/install.sh | sh
```

If you already have the binary, check for updates:

```bash
od3sa-memory update --check
od3sa-memory update
```

## 2. Generate an API key

The HTTP server requires bearer-token authentication. Generate a key and save it to a file with restricted permissions:

```bash
openssl rand -base64 32 > ~/.memory/mcp-api-key.txt
chmod 600 ~/.memory/mcp-api-key.txt
```

Alternatively, export the key as an environment variable:

```bash
export MEMORY_MCP_API_KEY="$(openssl rand -base64 32)"
```

The file-based method (`--api-key-file`) is preferred because it avoids exposing the key in process listings.

## 3. Start the HTTP server

Start the server on loopback using the key file:

```bash
od3sa-memory --db ~/.memory/default.db mcp --http 127.0.0.1:8788 \
  --api-key-file ~/.memory/mcp-api-key.txt
```

Or with the environment variable:

```bash
export MEMORY_MCP_API_KEY="$(cat ~/.memory/mcp-api-key.txt)"
od3sa-memory --db ~/.memory/default.db mcp --http 127.0.0.1:8788
```

The server logs that it is listening on `127.0.0.1:8788`. Keep this terminal open.

:::caution[Binding to all interfaces]
Passing `:8788` or `0.0.0.0:8788` exposes the server to your network. Only do this behind a firewall, VPN, or TLS terminator. For local development and testing, always bind to `127.0.0.1:8788`.
:::

## 4. Verify the server card (no auth)

The server exposes a discovery endpoint at `/.well-known/mcp/server-card.json`. This endpoint does not require authentication:

```bash
curl http://127.0.0.1:8788/.well-known/mcp/server-card.json
```

You should see a JSON response with the server's capabilities, protocol version, and available tools.

## 5. Test the MCP endpoint (with auth)

The MCP protocol endpoint is `POST /`. It requires the bearer token in the `Authorization` header.

Send an `initialize` request:

```bash
curl -X POST http://127.0.0.1:8788/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(cat ~/.memory/mcp-api-key.txt)" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": { "name": "curl-test", "version": "1.0.0" }
    }
  }'
```

A successful response includes the server's protocol version, capabilities, and server info.

## 6. Call a tool

After initialization, call `memory_health` to verify the server can access the database:

```bash
curl -X POST http://127.0.0.1:8788/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(cat ~/.memory/mcp-api-key.txt)" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "memory_health",
      "arguments": {}
    }
  }'
```

The response includes the health status and database path.

## Expected output

- `GET /.well-known/mcp/server-card.json` returns the server card without authentication.
- `POST /` with a valid bearer token returns MCP responses.
- `POST /` without a token or with an invalid token returns `401 Unauthorized`.

## Connect an MCP client

Configure your Streamable HTTP MCP client to connect to:

| Field | Value |
|-------|-------|
| URL | `http://127.0.0.1:8788/` |
| Authorization | `Bearer <your-api-key>` |

The server card URL (`http://127.0.0.1:8788/.well-known/mcp/server-card.json`) can be used for auto-discovery if your client supports it.

## Run as a background service

For long-running use, run the server under a process manager or in a tmux session:

```bash
tmux new-session -d -s memory-http \
  "od3sa-memory --db ~/.memory/default.db mcp --http 127.0.0.1:8788 \
    --api-key-file ~/.memory/mcp-api-key.txt"
```

Attach with `tmux attach -t memory-http` to view logs.

## Troubleshooting

- **401 Unauthorized** — check that the bearer token matches the key in the file or environment variable.
- **Connection refused** — verify the server is running and bound to the correct address.
- **Address already in use** — another process is using port 8788. Choose a different port or stop the conflicting process.
- **Permission denied reading key file** — ensure the key file has `0600` or `0400` permissions and is owned by your user.

## See also

- [Quick start](/memory/getting-started/)
- [Connect another MCP client](/memory/tutorials/connect-mcp-client/)
- [CLI reference](/memory/reference/cli/)
- [Environment variables](/memory/reference/environment-variables/)
