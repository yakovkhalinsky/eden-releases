# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Astro + Starlight (`docs-site/`). Existing static-site pipeline; no greenfield decision needed.

## Users

Primary: **a developer using the Agentic Team Protocol (ATP)** in Claude Code CLI.

They land here when they need to install the protocol, wire `eden-memory`, understand role-based agent teams, or opt a project in. They are likely already using Claude Code and want the authoritative setup steps and reference.

Secondary audiences (inferred from repo structure):

- Developers choosing an MCP memory server for a non-ATP client, who need `eden-memory` docs, install hints, and client-specific skills.
- Operators setting up headless ATP supervisors or multi-device sync, who need `eden-team` and `eden-relay` reference.
- Project owners ratifying a team charter or reviewing default guardrails.

## Product Purpose

`0d3sa.com` is the public documentation and release surface for the Agentic Team Protocol and its companion binaries (`eden-memory`, `eden-relay`, `eden-team`). It makes the protocol learnable, installable, and verifiable outside of the source repositories.

Success means a developer can land on the site, install ATP, wire `eden-memory`, and be running a chartered team in Claude Code without hunting across READMEs, GitHub releases, or multiple repos.

## Positioning

The site is the **primary, durable source of truth for ATP usage**, not a marketing wrapper. It competes with "read the repo README" by ordering the protocol first and treating `eden-memory`/`eden-relay`/`eden-team` as parts of one coherent system rather than independent products.

Meaningful difference: the docs are generated from the same skill/charter/command source files the installer writes to `~/.claude/`, so the published site and the installed artifacts stay in sync.

## Operating Context

- The canonical public URL is `https://0d3sa.com` (CNAME present).
- The site is deployed via GitHub Pages from this repo (`eden-releases`).
- Binary releases are published as GitHub Release assets in `yakovkhalinsky/eden-releases`; `binaries/manifest.json` is the source of truth for platform metadata.
- `eden-memory` CI normally auto-cuts releases, updates the manifest, and regenerates `docs-site/src/data/downloads.json`.
- Skill pages are generated from `skills/*/SKILL.md` into `docs-site/src/content/docs/eden-memory/skills/` via `scripts/generate-skills-site.py`.
- ATP charter and concepts are synced from `agentic-team-protocol/` into `docs-site/src/content/docs/agentic-team-protocol/` via `scripts/sync-atp-to-docs.js`.
- A typical user journey: curl-install ATP → run `eden-memory setup claude` → restart Claude Code → ratify charter with `/team-charter` → dispatch a goal with `/team`.
- License: MIT (repo root).

## Capabilities and Constraints

Confirmed capabilities:

- Install and setup instructions for ATP, `eden-memory`, `eden-relay`, and `eden-team`.
- Concept docs for ATP lifecycle, charter anatomy, record kinds, and default global charter.
- How-to guides for connecting Claude Code, Cursor, Hermes, and generic MCP clients.
- Reference docs for CLI tools, MCP tools, environment variables, fallback slash commands, and downloads.
- Skills registry with per-client install hints.
- Auto-generated skill pages and ATP docs to keep published content in sync with install artifacts.

Confirmed constraints:

- Content is docs-first; the homepage and navigation must route developers to ATP quickly.
- Binary download metadata is machine-generated from the release manifest and must not be hand-maintained.
- The site is static and deployed through GitHub Pages.
- The repo is public; no secrets, tokens, or private project memory may be committed.

Explicitly undecided / inferred only:

- Whether the homepage should lead with ATP or with the broader eden-memory product family (user answer: ATP should be primary; eden-memory/eden-relay/eden-team are secondary).
- Visual brand direction beyond what the current Starlight theme provides.
- Whether non-developer audiences (executives, researchers) need dedicated entry points.

## Brand Commitments

- Name: `0d3sa.com` and `eden-releases`; product names `eden-memory`, `eden-relay`, `eden-team`, `Agentic Team Protocol`.
- Voice: direct, technical, protocol-oriented. Favors concrete commands, file paths, and stage lifecycles over aspirational claims.
- Identity: local-first, no cloud account, open protocol, MIT-licensed companion binaries.
- Visual world: "Local-first product" — light off-white ground (#fafafa), white panels (#ffffff), green primary (#16a34a), Manrope display/body, JetBrains Mono for code. Light-mode only; no dark-mode toggle.
- Existing assets: CNAME, README, license, generated docs, and a custom favicon and landing-page CSS override.

## Evidence on Hand

- `/home/yakov/git/eden-releases/README.md` — repo purpose, release flow, regeneration commands.
- `/home/yakov/git/eden-releases/agentic-team-protocol/README.md` and `CHARTER.md` — ATP install steps and default global charter.
- `/home/yakov/git/eden-releases/docs-site/package.json` — Astro + Starlight stack and build pipeline.
- `/home/yakov/git/eden-releases/docs-site/src/content/docs/` — existing docs structure for eden-memory and ATP.
- `/home/yakov/git/eden-releases/skills/README.md` and `skills/*/SKILL.md` — skill registry source.
- `/home/yakov/git/eden-releases/CNAME` and `LICENSE` — live domain and license evidence.

Absences future work must not fabricate: customer testimonials, benchmark numbers, pricing, team size claims, security certifications, or a named design system beyond Starlight defaults.

## Product Principles

1. **ATP first.** The published site serves the developer who is installing and running the protocol; companion components are reachable from that journey, not competing with it.
2. **Docs are the source of truth.** Keep install commands, charter text, and skill reference in sync with the artifacts the installer writes to `~/.claude/`.
3. **Local-first, no cloud account.** Do not imply a hosted service, sign-up, or external API for core memory/recall.
4. **Show the command.** Favor concrete shell commands and file paths over conceptual explanation.
5. **One coherent system.** `eden-memory`, `eden-relay`, and `eden-team` are presented as parts of the ATP toolkit, not unrelated products.

## Accessibility & Inclusion

No product-specific accessibility requirement established yet. Follow Starlight's built-in accessibility baseline and WCAG 2.1 AA as a default web standard.
