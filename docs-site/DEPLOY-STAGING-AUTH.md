# Pre-launch Staging Deploy — od3sa.com

> **For:** Roy (Ops) / Zero Cool (Sec review)  
> **Issue:** [OD3-82](https://linear.app/od3sa/issue/OD3-82)

This document covers deploying the static marketing site behind HTTP basic auth using Caddy.

---

## Build

```bash
cd docs-site
pnpm install
pnpm build
```

Output: `dist/` directory with static assets.

---

## Caddy Setup

### File server with basic auth

Serve the static `dist/` directory via Caddy `file_server` with HTTP basic auth protecting all routes (including assets).

### TLS

Use Caddy's automatic HTTPS with Let's Encrypt for:
- `od3sa.com` (apex)
- `www.od3sa.com`

**Canonical recommendation:** Use apex `od3sa.com` as canonical; redirect `www` → apex.

### Example Caddyfile

```caddyfile
od3sa.com {
    # Basic auth — password from environment or 0600 users file
    # DO NOT commit actual password hashes to git
    basic_auth * {
        realm "0d3sa pre-launch (internal)"
        {$SITE_USER} {$SITE_PASSWORD_HASH}
    }

    # Security headers (Zero Cool requirements)
    header {
        Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data:; frame-ancestors 'none'"
        X-Frame-Options "DENY"
        X-Content-Type-Options "nosniff"
        Referrer-Policy "strict-origin-when-cross-origin"
        Permissions-Policy "geolocation=(), microphone=(), camera=()"
    }

    root * /srv/od3sa/dist
    file_server

    # Custom 401 page with helper text
    handle_errors {
        @401 expression {http.error.status_code} == 401
        handle @401 {
            respond "0d3sa pre-launch (internal) — invite password required. Press Cancel to exit." 401
        }
    }
}

www.od3sa.com {
    redir https://od3sa.com{uri} permanent
}
```

---

## Authentication

### Password storage (NEVER in git or chat)

**Option A — Environment variables:**
```bash
export SITE_USER="preview"
export SITE_PASSWORD_HASH="$(caddy hash-password --plaintext 'YOUR_PASSWORD_HERE')"
```

**Option B — 0600 users file (preferred):**

Create a Caddy users fragment file with restricted permissions:
```bash
# Generate bcrypt hash
HASH=$(caddy hash-password --plaintext 'YOUR_PASSWORD_HERE')

# Create users file with proper Caddyfile syntax
cat > /etc/caddy/od3sa-users <<EOF
basic_auth {
    realm "0d3sa pre-launch (internal)"
    preview $HASH
}
EOF

chmod 0600 /etc/caddy/od3sa-users
chown caddy:caddy /etc/caddy/od3sa-users
```

Then import in the site block:
```caddyfile
od3sa.com {
    import /etc/caddy/od3sa-users
    # ... rest of config
}
```

### Realm (Jen/ZC)

The `realm` directive sets the browser auth dialog title:
```
0d3sa pre-launch (internal)
```

---

## Security Checklist (Zero Cool)

- [ ] **No passwords in repo/chat** — Caddy basicauth from env or 0600 htpasswd file only
- [ ] **TLS via Let's Encrypt** — apex + www covered
- [ ] **Canonical + redirect** — apex `od3sa.com` canonical, www redirects
- [ ] **Security headers:**
  - `Content-Security-Policy` — tight for static site (`default-src 'self'`, etc.)
  - `X-Frame-Options: DENY` / `frame-ancestors 'none'`
  - `X-Content-Type-Options: nosniff`
  - `Referrer-Policy: strict-origin-when-cross-origin`
- [ ] **Static only** — no admin/debug/API endpoints on this vhost
- [ ] **Basic auth covers all routes** — including `/images/`, `/memory/`, all assets
- [ ] **401 body** — helper text for Cancel action

---

## Validation

After deploy, verify:

1. `curl -I https://od3sa.com` returns 401 Unauthorized
2. `curl -u preview:PASSWORD https://od3sa.com` returns 200 with HTML
3. `curl -I https://www.od3sa.com` returns 301 redirect to apex
4. Security headers present on authenticated responses
5. All asset paths (images, CSS, JS) require auth

---

## Out of Scope

- Custom login UI (use Caddy basic auth only)
- Public SEO / removing password (requires Yakov green light)
- Staging console / cloud account features (not on this vhost)
