# od3sa.com — Ledger Light Static Site

Marketing site for od3sa (letter-o) with register-first flow.

## Design

**Ledger Light** — warm paper/ink/clay palette, anti-clone to the digit-zero 0d3sa.com docs.

### Tokens

| Token | Value |
|-------|-------|
| `--paper` | `#F3EEE6` |
| `--paper-2` | `#E8E1D6` |
| `--ink` | `#1A1814` |
| `--ink-mute` | `#5C574E` |
| `--line` | `#D4CBBE` |
| `--clay` | `#C45C3A` |
| `--clay-deep` | `#9A3F28` |
| `--fog` | `#F7F5F1` |

### Typography

- **Display (H1 only):** Fraunces
- **UI:** Figtree / Source Sans 3
- **Mono (install only):** IBM Plex Mono

### Shape

- `--r-sm`: 6px
- `--r-md`: 10px
- `--r-lg`: 14px
- Max width: 1080px

## Development

```sh
pnpm install
pnpm dev
```

## Build

```sh
pnpm build
```

Output: `dist/`

## Page Structure

1. **Banner** — Private preview notice
2. **Nav** — Wordmark, Docs, Install, Register (filled)
3. **Hero** — Story left, Register card right
4. **Trust chips** — Private preview, staging console, free forever, etc.
5. **Free forever** — Local memory + self-hosted relay
6. **Coding agents / MCP** — Claude Code, Cursor, any MCP client
7. **Sync** — Optional encrypted multi-device sync
8. **Why Register** — 3 beats: Org, Devices, Optional relay (staging labelled)
9. **Pricing honesty** — Free forever local + self-host
10. **FAQ** — 4 items
11. **Install** — Steps with digit-zero curl (`0d3sa.com`)
12. **Honesty** — Local CLIs don't require Register
13. **Footer** — Copyright, Docs, support email

## Register

Register CTA links to staging console: `https://console.relay-staging.od3sa.com/signup`

## Constraints

- Install curl must use digit-zero: `https://0d3sa.com/memory/install.sh`
- No secrets in git
- `noindex, nofollow` until public launch

## Deploy

See [DEPLOY.md](./DEPLOY.md) for Caddy configuration with basic auth.

**Control-plane gate:** Ops must set `CONTROL_PLANE_OPEN_REGISTER=true` on control-plane **only behind Caddy**. Keep flag `false` until OD3-85 gate is up.

## Related

- [OD3-88](https://linear.app/od3sa/issue/OD3-88) — This implementation
- [OD3-84](https://linear.app/od3sa/issue/OD3-84) — Parent issue
- [OD3-85](https://linear.app/od3sa/issue/OD3-85) — Roy deploy task
- [OD3-86](https://linear.app/od3sa/issue/OD3-86) — Open signup (unblocks Register CTA)
