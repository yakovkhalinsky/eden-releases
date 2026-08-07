# Refocus docs-site on Agentic Team Protocol — implementation plan

Goal ID: `refocus-docs-site-on-atp-2026-08-05`
Branch: `feat/refocus-docs-atp-2026-08-05`

## Objective

Position the Agentic Team Protocol (ATP) as the installable product in the 0d3sa docs site, and reframe eden-memory, eden-relay, and eden-team as the components that make it work.

## Current problems

1. `src/pages/index.astro` leads with "Local-first memory for AI agents" and sends the primary CTA to `/eden-memory/getting-started/`.
2. `src/pages/docs.astro` presents eden-memory and agentic-team-protocol as two equal products.
3. `src/content/docs/agentic-team-protocol/index.mdx` is a plain text page without a splash hero.
4. `astro.config.mjs` lists eden-memory first with a full Diátaxis tree; agentic-team-protocol is second and smaller.
5. `src/content/docs/eden-memory/index.mdx` frames eden-memory as the "flagship binary of the eden-memory monorepo".
6. Detailed relay and headless-supervisor content is mixed into eden-memory and ATP sections.

## Proposed changes

### A. Marketing landing page (`src/pages/index.astro`)

- Headline: "Installable agent teams for Claude Code" (or similar).
- Primary CTA: `/agentic-team-protocol/getting-started/`
- Secondary CTA: deep-dive into components (`/docs/`)
- Install card shows both ATP and eden-memory install commands, framed as "Step 1 / Step 2".
- Product cards: ATP first/primary, eden-memory as "memory & sync component", eden-relay/eden-team grouped as infrastructure components.
- Three-binary section retitled "What ships in the release".
- Decision card short answer: "Install ATP. It brings eden-memory with it."

### B. Docs landing page (`src/pages/docs.astro`)

- ATP as hero/default path with full Diátaxis entry points.
- "Components" section below with cards for eden-memory, eden-relay, eden-team linking to their deep docs.
- Remove the two-equal-products framing.

### C. ATP overview (`src/content/docs/agentic-team-protocol/index.mdx`)

- Convert to Starlight `template: splash` with `hero` block matching eden-memory visual weight.
- Primary action: `/agentic-team-protocol/getting-started/`
- Secondary action: `/agentic-team-protocol/lifecycle/` or `/agentic-team-protocol/agents/`

### D. Sidebar (`astro.config.mjs`)

Top-level order:

1. **agentic-team-protocol** — keep existing items, make it first.
2. **Components** — new group containing:
   - **eden-memory** (Overview, Quick start, Tutorials, How-to, Concepts, Reference)
   - **eden-relay** (Overview, How-to guides)
   - **eden-team** (Overview, Tutorials)

Moves and redirects:
- `/eden-memory/how-to/run-relay-server/` → `/eden-relay/how-to/run-relay-server/` (redirect added)
- `/eden-memory/how-to/deploy-public-vps/` → `/eden-relay/how-to/deploy-public-vps/` (redirect added)
- `/agentic-team-protocol/tutorials/headless-supervisor/` → `/eden-team/tutorials/headless-supervisor/` (redirect added)

### E. eden-memory overview (`src/content/docs/eden-memory/index.mdx`)

- Frame eden-memory as the durable memory/sync component of ATP.
- Remove "flagship binary of the eden-memory monorepo" framing.
- Keep the component description; move the monorepo/three-binary detail to a reference/concept page if needed (retained in `reference/downloads` and kept minimal).

### F. New component sections

- `src/content/docs/eden-relay/index.mdx` — overview splash or concept page.
- `src/content/docs/eden-relay/how-to/run-relay-server.md` — moved from eden-memory.
- `src/content/docs/eden-relay/how-to/deploy-public-vps.md` — moved from eden-memory.
- `src/content/docs/eden-team/index.mdx` — overview splash or concept page.
- `src/content/docs/eden-team/tutorials/headless-supervisor.md` — moved from ATP tutorials.

### G. Link updates

- Update `multi-device-sync.md` to point to new eden-relay how-to paths.
- Update any internal links inside moved pages to reflect new locations where necessary.
- Keep external/public URLs stable via redirects.

## Build verification

- `cd /home/yakov/git/eden-releases/docs-site && pnpm install && pnpm run build`
- Check `dist/` contains:
  - `/agentic-team-protocol/index.html`
  - `/eden-memory/index.html`
  - `/eden-relay/index.html`
  - `/eden-team/index.html`
- Check redirects for moved slugs resolve.
- No broken internal links.

## Implementation status

- [x] Created plan file.
- [x] Branched `feat/refocus-docs-atp-2026-08-05` from `origin/main`.
- [x] Rewrote `src/pages/index.astro` to lead with ATP.
- [x] Rewrote `src/pages/docs.astro` with ATP hero + Components section.
- [x] Converted `src/content/docs/agentic-team-protocol/index.mdx` to splash hero.
- [x] Restructured `astro.config.mjs` with ATP first and Components group.
- [x] Rewrote `src/content/docs/eden-memory/index.mdx` as ATP component.
- [x] Created `eden-relay/` and `eden-team/` sections; moved run-relay-server, deploy-public-vps, and headless-supervisor pages.
- [x] Updated all stale internal links to the new component paths.
- [x] Added redirects for moved slugs.
- [x] Built successfully with `pnpm run build`; 50 pages generated, no errors.
- [x] Verified key paths exist in `dist/`.

## Records to write

1. `action_record` with goal ID, stage `action`, owner `builder`, input record IDs from context summary and hand-off record, plus list of changed files, build result, branch, commit SHA.
2. `hand_off_record` to `verifier` with success criteria and the action record ID as input.
