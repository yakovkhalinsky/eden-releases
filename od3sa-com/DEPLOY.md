# Deploy od3sa.com — Private Preview

Static site deployment for `od3sa.com` with Caddy basic auth.

## Build

```sh
cd od3sa-com
pnpm install
pnpm build
```

Output: `dist/` directory with static files.

## Caddy Configuration

### Option B: External users file (recommended)

1. Create password hash:
   ```sh
   caddy hash-password
   # Enter your site password when prompted
   ```

2. Create users file with 0600 permissions **outside** of git:
   ```sh
   # /etc/caddy/od3sa-users (0600, root:root)
   preview:$2a$14$...hashed-password...
   ```

3. Caddyfile:
   ```caddyfile
   od3sa.com {
       import /etc/caddy/od3sa-users as users

       basicauth * {
           import users
       }

       root * /srv/od3sa-com/dist
       file_server

       header {
           X-Frame-Options "DENY"
           X-Content-Type-Options "nosniff"
           Content-Security-Policy "default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; script-src 'self' 'unsafe-inline'"
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

   Alternative inline users block if import not supported:
   ```caddyfile
   od3sa.com {
       basicauth * {
           # hash generated via `caddy hash-password`
           preview $2a$14$your-hash-here
       }

       root * /srv/od3sa-com/dist
       file_server

       header {
           X-Frame-Options "DENY"
           X-Content-Type-Options "nosniff"
           Content-Security-Policy "default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; script-src 'self' 'unsafe-inline'"
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

### Users file format

```
# /etc/caddy/od3sa-users
# Format: username:bcrypt-hash
# Generate hash: caddy hash-password
preview:$2a$14$...
```

Permissions:
```sh
chmod 0600 /etc/caddy/od3sa-users
chown root:root /etc/caddy/od3sa-users
```

## Basic Auth Realm

The realm shown to users is:
```
0d3sa pre-launch (internal)
```

To set a custom realm in Caddy v2.7+:
```caddyfile
basicauth * {
    realm "0d3sa pre-launch (internal)"
    preview $2a$14$...
}
```

## Dist Path

Deploy the contents of:
```
od3sa-com/dist/
```

To your web root (e.g., `/srv/od3sa-com/dist/`).

## Security Headers

The Caddyfile includes:
- `X-Frame-Options: DENY` — prevent clickjacking
- `X-Content-Type-Options: nosniff` — prevent MIME sniffing
- `Content-Security-Policy` — restrict resource loading
- `X-Robots-Tag: noindex, nofollow` — prevent indexing (also set in HTML meta)

## HTTPS

Caddy auto-provisions TLS via Let's Encrypt. Ensure:
- DNS A/AAAA records point to server
- Ports 80/443 open
- Email set in global Caddy config for cert notifications

## Notes

- Site password is NOT the same as user account credentials
- The banner clarifies this distinction for visitors
- Register CTA is disabled until OD3-86 lands
- Install curl points to digit-zero `0d3sa.com` (separate host)
