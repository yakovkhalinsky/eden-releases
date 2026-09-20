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

### Auth Fragment (0600)

Create a Caddyfile fragment with 0600 permissions **outside of git**:

```sh
# /etc/caddy/od3sa-users (0600, root:root)
basic_auth {
  realm "0d3sa pre-launch (internal)"
  preview <bcrypt-hash>
}
```

Generate the bcrypt hash:
```sh
caddy hash-password
# Enter your site password when prompted
```

Set permissions:
```sh
chmod 0600 /etc/caddy/od3sa-users
chown root:root /etc/caddy/od3sa-users
```

### Site Block

```caddyfile
od3sa.com {
    import /etc/caddy/od3sa-users

    root * /srv/od3sa-com/dist
    file_server

    header {
        X-Frame-Options "DENY"
        X-Content-Type-Options "nosniff"
        Content-Security-Policy "default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; script-src 'self' 'unsafe-inline'; frame-ancestors 'none'"
        X-Robots-Tag "noindex, nofollow"
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

If fragment import is unavailable, inline the auth block:

```caddyfile
od3sa.com {
    basic_auth {
        realm "0d3sa pre-launch (internal)"
        preview $2a$14$your-hash-here
    }

    root * /srv/od3sa-com/dist
    file_server

    header {
        X-Frame-Options "DENY"
        X-Content-Type-Options "nosniff"
        Content-Security-Policy "default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; script-src 'self' 'unsafe-inline'; frame-ancestors 'none'"
        X-Robots-Tag "noindex, nofollow"
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

## Control Plane Gate

The Register CTA links to the staging console signup. For the control-plane to accept open registration:

```sh
# On control-plane service (ONLY behind Caddy basic_auth gate)
CONTROL_PLANE_OPEN_REGISTER=true
```

**Keep this flag `false` until OD3-85 Caddy gate is up.** The site password protects the marketing site; open register on the control-plane should only be enabled once both gates are in place.

## Security Headers

| Header | Value | Purpose |
|--------|-------|---------|
| `X-Frame-Options` | `DENY` | Prevent clickjacking |
| `X-Content-Type-Options` | `nosniff` | Prevent MIME sniffing |
| `Content-Security-Policy` | See above | Restrict resource loading |
| `frame-ancestors` | `'none'` | CSP clickjacking protection |
| `X-Robots-Tag` | `noindex, nofollow` | Prevent indexing |

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
