# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Astro + Starlight (`docs-site/`). Existing static-site pipeline; no greenfield decision needed.

## Users

Primary: **a developer wiring `eden-memory` into an MCP client** (Claude Code, Cursor, Hermes, or any stdio MCP client).

They land here when they need to install the binary, connect their client, understand recall/search behaviour, or sync memories across devices. They are likely already using an MCP-capable agent and want the authoritative setup steps and reference.

Secondary audiences:

- Developers self-hosting sync, who need `eden-relay` deployment and hardening guides (VPS, Tailscale, systemd).
- Operators verifying releases, who need downloads, checksums, and platform metadata.
- Agent authors building skills on top of the MCP tool surface, who use the skills registry.

## Product Purpose

`0d3sa.com` is the public documentation and release surface for `eden-memory` and `eden-relay` — a local-first memory layer for AI agents and its dedicated sync relay. It makes the binaries learnable, installable, and verifiable outside of the source repositories.

Success means a developer can land on the site, install `eden-memory`, wire their client with `eden-memory setup`, and be remembering and recalling facts across sessions without hunting across READMEs, GitHub releases, or multiple repos.

The Agentic Team Protocol (ATP) and its `eden-team` binary are **intentionally unpublished for now**; their source remains in `agentic_team_protocol/` in this repo but no site content, releases, or docs ship for them.

## Positioning

The site is the **primary, durable source of truth for eden-memory and eden-relay usage**, not a marketing wrapper. It competes with "read the repo README" by ordering the install/setup path first and treating `eden-memory` and `eden-relay` as two components of one coherent system.

Meaningful difference: the docs are generated from the same skill source files the installer writes to `~/.claude/`, so the published site and the installed artifacts stay in sync.

## Operating Context

- The canonical public URL is `https://0d3sa.com` (CNAME present).
- The site is deployed via GitHub Pages from this repo (`eden-releases`).
- Binary releases are published as GitHub Release assets in `yakovkhalinsky/eden-releases`; `binaries/manifest.json` is the source of truth for platform metadata.
- `eden-memory` CI normally auto-cuts releases, updates the manifest, and regenerates `docs-site/src/data/downloads.json`.
- Skill pages are generated from `skills/*/SKILL.md` into `docs-site/src/content/docs/eden-memory/skills/` via `scripts/generate-skills-site.py`.
- A typical user journey: curl-install `eden-memory` → run `eden-memory setup` in a project → restart Claude Code → remember and recall a fact. A secondary journey: install `eden-relay` on a VPS → pair devices → run a sync loop.
- License: MIT (repo root).

## Capabilities and Constraints

Confirmed capabilities:

- Install and setup instructions for `eden-memory` and `eden-relay`.
- Concept docs for the memory model, sync, security, dreaming, and knowledge packets.
- How-to guides for connecting Claude Code, Cursor, Hermes, and generic MCP clients.
- Reference docs for CLI commands, MCP tools, environment variables, fallback slash commands, relay endpoints, and downloads.
- Skills registry with per-client install hints.

Confirmed constraints:

- Content is docs-first; the homepage and navigation must route developers to `eden-memory` quickly.
- Binary download metadata is machine-generated from the release manifest and must not be hand-maintained.
- The site is static and deployed through GitHub Pages.
- The repo is public; no secrets, tokens, or private project memory may be committed.

Explicitly undecided / inferred only:

- Whether and when ATP content returns to the site (source kept in `agentic_team_protocol/`).
- Visual brand direction beyond the existing Obsidian command-center design system.
- Whether non-developer audiences (executives, researchers) need dedicated entry points.

## Brand Commitments

- Name: `0d3sa.com` and `eden-releases`; product names `eden-memory` and `eden-relay`.
- Voice: direct, technical, operational. Favors concrete commands, file paths, and flags over aspirational claims.
- Identity: local-first, no cloud account, self-hosted sync, MIT-licensed binaries.
- Visual world: "Obsidian command center" — dark obsidian ground (#132322), deep-abyss panels (#0e1a19), graphite hairline borders (#424f4f), neon green primary (#3ddc91), signal yellow illustration accents (#ffcd48); Chakra Petch display, Saira body, JetBrains Mono for code. Dark-mode only; see `DESIGN.md`.
- Existing assets: CNAME, README, license, generated docs, and a custom favicon and landing-page CSS override.

## Evidence on Hand

- `/home/yakov/git/eden-releases/README.md` — repo purpose, release flow, regeneration commands.
- `/home/yakov/git/eden-releases/docs-site/package.json` — Astro + Starlight stack and build pipeline.
- `/home/yakov/git/eden-releases/docs-site/src/content/docs/` — docs structure for eden-memory and eden-relay.
- `/home/yakov/git/eden-releases/skills/README.md` and `skills/*/SKILL.md` — skill registry source.
- `/home/yakov/git/eden-releases/CNAME` and `LICENSE` — live domain and license evidence.

Absences future work must not fabricate: customer testimonials, benchmark numbers, pricing, team size claims, security certifications, or a named design system beyond `DESIGN.md`.

## Product Principles

1. **eden-memory first.** The published site serves the developer who is installing and wiring memory into an MCP client; `eden-relay` is reachable from that journey.
2. **Docs are the source of truth.** Keep install commands, CLI/tool reference, and skill pages in sync with the shipped binaries and installed artifacts.
3. **Local-first, no cloud account.** Do not imply a hosted service, sign-up, or external API for core memory/recall.
4. **Show the command.** Favor concrete shell commands and file paths over conceptual explanation.
5. **One coherent system.** `eden-memory` and `eden-relay` are presented as two parts of one memory system, not unrelated products.

## Accessibility & Inclusion

No product-specific accessibility requirement established yet. Follow Starlight's built-in accessibility baseline and WCAG 2.1 AA as a default web standard.