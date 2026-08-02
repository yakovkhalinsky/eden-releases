# Plan: Rebrand site buttons to dark-green + black with white text

## Goal
Update the 0d3sa docs-site so buttons and accent elements use a dark-green-and-black palette, button text is always white, and the background color changes on hover.

## Scope
- Homepage (`src/pages/index.astro`)
- Docs landing page (`src/pages/docs.astro`)
- Starlight docs theme override (`src/styles/starlight-custom.css`)

## Design decisions
1. Replace the blue accent (`#7c8cff`) with a dark green palette:
   - `--accent`: `#2d6a4f` (dark green)
   - `--accent-600`: `#40916c` (lighter green for hover)
2. Keep backgrounds black/dark (`--bg: #0b0d10`, `--bg-card: #151922`, etc.).
3. Button text is always white (`#ffffff` / `var(--text)`).
4. Background changes on hover:
   - Primary buttons: dark green → lighter green.
   - Copy buttons: transparent/dark card background → dark green background.
   - Ghost/secondary buttons: transparent → dark green background.
5. Update related accents (pill dot, links, current-sidebar indicator) to green tones for consistency.

## Files to change
- `docs-site/src/pages/index.astro`
  - `:root` color tokens
  - `.btn-primary`, `.copy-btn`, `.pill .dot`, `.client-link:hover`, `.product-card:hover`, `.step-num` color
- `docs-site/src/pages/docs.astro`
  - `:root` color tokens
  - `.btn-primary`, `.quadrant-link:hover`, `.product-tag` background/color
- `docs-site/src/styles/starlight-custom.css`
  - `--sl-color-text-accent` and `--sl-color-bg-accent`
  - `.hero .sl-flex a[role="button"]` primary and secondary styles
  - `#starlight__search button` text color and hover

## Verification
- `cd docs-site && npm run build` exits 0.
- All 47 pages generate.
- Buttons render white text on dark green (hover) and black backgrounds.
- No broken internal links.
