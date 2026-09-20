# Deploy od3sa.com — Private Preview

Static site deployment for `od3sa.com` with Caddy basic auth.

## Build

```sh
cd od3sa-com
pnpm install
pnpm build
```

Output: `od3sa-com/dist/` — deploy this directory.

## Caddy Configuration

### Users Fragment

Create a users fragment readable by Caddy **outside of git**:

```sh
# /etc/caddy/od3sa-users (root:caddy 0640 — caddy must read it)
od3sa <bcrypt-hash>
```

Generate the bcrypt hash:
```sh
caddy hash-password
# Enter your site password when prompted
```

Set permissions (0640 so caddy user can read; 0600 root-only broke OD3-82):
```sh
chown root:caddy /etc/caddy/od3sa-users
chmod 0640 /etc/caddy/od3sa-users
```

Username `od3sa` is ops convention. Password stays out of git.

### Site Block

```caddyfile
od3sa.com {
    basic_auth bcrypt "0d3sa pre-launch (internal)" {
        import /etc/caddy/od3sa-users
    }

    root * /srv/od3sa-com/dist
    file_server

    header {
        X-Frame-Options "DENY"
        X-Content-Type-Options "nosniff"
        Content-Security-Policy "default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; script-src 'self' 'unsafe-inline'; frame-ancestors 'none'"
        X-Robots-Tag "noindex, nofollow"
        Referrer-Policy "strict-origin-when-cross-origin"
        Permissions-Policy "geolocation=(), microphone=(), camera=()"
    }

    handle_errors {
        rewrite * /index.html
        file_server
    }
}

www.od3sa.com {
    redir https://od3sa.com{uri} permanent
}
```

### Inline Alternative

If fragment import is unavailable, inline the credentials:

```caddyfile
od3sa.com {
    basic_auth bcrypt "0d3sa pre-launch (internal)" {
        od3sa $2a$14$your-hash-here
    }

    root * /srv/od3sa-com/dist
    file_server

    header {
        X-Frame-Options "DENY"
        X-Content-Type-Options "nosniff"
        Content-Security-Policy "default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; script-src 'self' 'unsafe-inline'; frame-ancestors 'none'"
        X-Robots-Tag "noindex, nofollow"
        Referrer-Policy "strict-origin-when-cross-origin"
        Permissions-Policy "geolocation=(), microphone=(), camera=()"
    }

    handle_errors {
        rewrite * /index.html
        file_server
    }
}

www.od3sa.com {
    redir https://od3sa.com{uri} permanent
}
```

## Bake Check: handle_errors and 401

**Verify handle_errors doesn't turn 401→200.** The `handle_errors` block is for 404 SPA fallback. Confirm that unauthenticated requests still return 401 (not 200 with index.html). Test:

```sh
curl -I https://od3sa.com/
# Should return 401 Unauthorized (not 200 OK)

curl -I -u od3sa:password https://od3sa.com/
# Should return 200 OK
```

If 401 is being swallowed, remove `handle_errors` or scope it to specific status codes.

## Control Plane Gate

The Register CTA links to the staging console signup. For the control-plane to accept open registration:

```sh
# On control-plane service (ONLY behind Caddy basic_auth gate)
CONTROL_PLANE_OPEN_REGISTER=true
```

**Keep this flag `false` until OD3-85 Caddy gate proves.** The site password protects the marketing site; open register on the control-plane should only be enabled once both gates are in place.

## Security Headers

| Header | Value | Purpose |
|--------|-------|---------|
| `X-Frame-Options` | `DENY` | Prevent clickjacking |
| `X-Content-Type-Options` | `nosniff` | Prevent MIME sniffing |
| `Content-Security-Policy` | See above | Restrict resource loading |
| `frame-ancestors` | `'none'` | CSP clickjacking protection |
| `X-Robots-Tag` | `noindex, nofollow` | Prevent indexing |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Control referrer leakage |
| `Permissions-Policy` | `geolocation=(), microphone=(), camera=()` | Disable sensitive APIs |

## HTTPS

Caddy auto-provisions TLS via Let's Encrypt. Ensure:
- DNS A/AAAA records point to server
- Ports 80/443 open
- Email set in global Caddy config for cert notifications

## Dist Path

```
od3sa-com/dist/
```

Copy to your web root (e.g., `/srv/od3sa-com/dist/`).

## Notes

- Site password is NOT the same as user account credentials
- The banner clarifies this distinction for visitors
- Register links to staging console: `console.relay-staging.od3sa.com/signup`
- Install curl points to digit-zero `0d3sa.com` (separate host)
