# Plan: eden-memory docs-site structure redesign

**Goal ID:** `site-structure-redesign-2026-08-02`  
**Owner role:** Builder  
**Stage:** action (planning)  
**Status:** pending review  
**Date:** 2026-08-02  
**Deadline:** 2026-08-03T00:00:00Z

---

## 1. Goal summary and success criteria

### Goal
Redesign and extend the docs-site at `/home/yakov/git/eden-releases/docs-site` so it contains both detailed reference information and guided tutorial-style content, with special attention to the new relay/multi-device sync functionality.

### Input records
- `goal_record` `e9ed2891-059b-4bb9-a05e-57f93c1f29ea`
- `dispatch_instruction` `259d97ed-a498-453c-8c91-5ac0fecb9e4f`
- `context_summary` `fb7584ab-c696-4787-9998-f1ecd0a44403`
- `hand_off_record` `5c1c57cc-2b85-4e77-ac37-df766c6ff5c3` (Researcher → Builder)

### Success criteria for the redesign
1. Every eden-memory page is labelled by Diátaxis content type (tutorial, how-to, concept, reference) in frontmatter and sidebar.
2. Multi-device sync has a dedicated tutorial, at least one concept page, and expanded reference coverage (env vars, troubleshooting, sidecar files).
3. There is a neutral `/docs/` landing page that routes visitors to eden-memory or agentic-team-protocol paths.
4. Existing public URLs (`/eden-memory/getting-started/`, `/eden-memory/multi-device-sync/`, `/eden-memory/reference/tools/`, `/eden-memory/reference/cli/`, ATP routes) remain reachable or redirect to the new canonical pages.
5. The homepage header and footer "Docs" links point to `/docs/` instead of `/eden-memory/`.
6. The docs-site build command (`npm run build`) still passes and produces the expected routes.
7. No final docs content is written until this plan is approved by yakov or a Dispatcher-assigned Verifier.

---

## 2. Diátaxis content architecture

We adopt the four Diátaxis quadrants for the two product sections and add a top-level `/docs/` hub.

### Top-level information architecture

```text
/
├── /docs/                     NEW — neutral docs landing
├── /eden-memory/              existing product root, repurposed as overview
│   ├── tutorials/
│   ├── how-to/
│   ├── concepts/
│   └── reference/
├── /agentic-team-protocol/    existing product root, repurposed as overview
│   ├── tutorials/
│   ├── concepts/
│   └── reference/
└── (homepage unchanged except Docs link)
```

### Content-type definitions for this site

| Type | Purpose | Voice/depth | Example |
|------|---------|-------------|---------|
| **Tutorial** | First-time, end-to-end experience. Numbered steps, prerequisites, expected output, next steps. | Conversational but precise; 800–1500 words. | "Sync your first two devices" |
| **How-to guide** | Solve a specific problem. Assumes basic familiarity. | Imperative, task-oriented; 500–1000 words. | "Run your own relay server" |
| **Concept** | Explain how the system works. | Explanatory, architecture-focused; 600–1200 words. | "How sync works" |
| **Reference** | Look up complete schemas, flags, env vars, downloads. | Terse, exhaustive tables; 300–1500 words. | "CLI reference" |

### eden-memory section

```text
eden-memory
├── Overview                        (concept + splash landing)
├── Quick start                     (tutorial — install → verify → remember/recall)
├── Tutorials
│   ├── Connect Claude Code
│   ├── Connect Cursor
│   ├── Connect another MCP client
│   ├── Sync two devices with a relay
│   └── Sync two databases on the same machine
├── How-to guides
│   ├── Back up and restore a database
│   ├── Migrate a workspace
│   ├── Prune old memories
│   ├── Run your own relay server
│   └── Approve a peer key rotation
├── Concepts
│   ├── Memory model and embeddings
│   ├── Scopes and identity
│   ├── How sync works
│   ├── Sidecar files
│   └── Security model
└── Reference
    ├── Tools reference
    ├── CLI reference
    ├── Environment variables
    ├── Fallback slash commands
    ├── Skills registry
    ├── Troubleshooting
    └── Downloads and checksums
```

### agentic-team-protocol section

```text
agentic-team-protocol
├── Overview
├── Quick start                     (tutorial — install → ratify charter → run first goal)
├── Tutorials
│   ├── Run your first team goal
│   ├── Ratify a project charter
│   └── Set up a headless supervisor
├── Concepts
│   ├── Lifecycle
│   ├── Roles and agents
│   ├── Charter anatomy
│   └── Record kinds and schema
└── Reference
    ├── Slash commands
    ├── Agent prompts
    └── Default charter
```

---

## 3. Exact new pages

### eden-memory — Tutorials

| Slug | Title | Type | One-line purpose |
|------|-------|------|------------------|
| `eden-memory/tutorials/connect-claude-code` | Connect Claude Code | tutorial | Install, wire MCP, and verify the first memory in Claude Code CLI. |
| `eden-memory/tutorials/connect-cursor` | Connect Cursor | tutorial | Add eden-memory as an MCP server in Cursor and test recall. |
| `eden-memory/tutorials/connect-mcp-client` | Connect another MCP client | tutorial | Generic JSON config and verification for any stdio MCP client. |
| `eden-memory/tutorials/sync-two-devices-relay` | Sync two devices with a relay | tutorial | Full narrative: install binary on both devices, run/locate relay, create invitation, accept, start sync loop, verify. |
| `eden-memory/tutorials/sync-local-databases` | Sync two databases on the same machine | tutorial | Direct one-shot sync between two local databases, optional local pairing. |

### eden-memory — How-to guides

| Slug | Title | Type | One-line purpose |
|------|-------|------|------------------|
| `eden-memory/how-to/backup-restore` | Back up and restore a database | how-to | Use `eden_export_snapshot` / `eden_import_snapshot` and sidecar backup strategy. |
| `eden-memory/how-to/migrate-workspace` | Migrate a workspace | how-to | Remap `org_id`/`workspace_id` with `eden_migrate`. |
| `eden-memory/how-to/prune-memories` | Prune old memories | how-to | Scoped soft/hard deletion with `eden_prune`. |
| `eden-memory/how-to/run-relay-server` | Run your own relay server | how-to | Stand up and secure a self-hosted relay. |
| `eden-memory/how-to/approve-peer-key-change` | Approve a peer key rotation | how-to | Inspect and approve/reject pending Ed25519/X25519 key changes. |

### eden-memory — Concepts

| Slug | Title | Type | One-line purpose |
|------|-------|------|------------------|
| `eden-memory/concepts/memory-model` | Memory model and embeddings | concept | How memories, vectors, SQLite, and search fit together. |
| `eden-memory/concepts/scopes-identity` | Scopes and identity | concept | `agent_id`, `user_id`, `org_id`, `workspace_id` and how scoping affects recall. |
| `eden-memory/concepts/how-sync-works` | How sync works | concept | Delta logs, logical clocks, conflict resolution, double envelope, PAKE pairing, key rotation. |
| `eden-memory/concepts/sidecar-files` | Sidecar files | concept | `<db>.sync-keys.json`, `<db>.root-key.json`, permissions, backup/restore implications. |
| `eden-memory/concepts/security-model` | Security model | concept | Threat model for relay operators, password/entropy requirements, what the relay can and cannot see. |

### eden-memory — Reference

| Slug | Title | Type | One-line purpose |
|------|-------|------|------------------|
| `eden-memory/reference/environment-variables` | Environment variables | reference | Complete table of env vars, defaults, and cascading precedence. |
| `eden-memory/reference/fallback-slash-commands` | Fallback slash commands | reference | `/eden-remember`, `/eden-recall`, `/eden-search`, `/eden-forget`, `/eden-vacuum`, `/eden-health`. |
| `eden-memory/reference/troubleshooting` | Troubleshooting | reference | Symptom → cause → fix matrix (server exits, first recall slow, relay pairing failures, pending key changes, sync loop not registering). |
| `eden-memory/reference/downloads` | Downloads and checksums | reference | Version, release date, platform matrix, checksums, manual install snippet. |

### agentic-team-protocol — Tutorials

| Slug | Title | Type | One-line purpose |
|------|-------|------|------------------|
| `agentic-team-protocol/tutorials/first-team-goal` | Run your first team goal | tutorial | Install ATP, ratify charter, dispatch a trivial goal, observe hand-off. |
| `agentic-team-protocol/tutorials/ratify-charter` | Ratify a project charter | tutorial | Edit charter template, run `/team-charter`, inspect the ratification record. |
| `agentic-team-protocol/tutorials/headless-supervisor` | Set up a headless supervisor | tutorial | Ollama-backed headless ATP supervisor with strict MCP config and JSON output. |

### agentic-team-protocol — Concepts

| Slug | Title | Type | One-line purpose |
|------|-------|------|------------------|
| `agentic-team-protocol/concepts/record-kinds` | Record kinds and schema | concept | `goal_record`, `dispatch_instruction`, `context_summary`, `action_record`, `verdict`, `escalation_record`, `charter_ratification`, `archival_record`. |

### agentic-team-protocol — Reference

| Slug | Title | Type | One-line purpose |
|------|-------|------|------------------|
| `agentic-team-protocol/reference/slash-commands` | Slash commands | reference | `/team`, `/team-charter`, `/team-status`, `/team-escalate`, `/team-continue`, `/team-handoff`. |
| `agentic-team-protocol/reference/agent-prompts` | Agent prompts | reference | What each default agent prompt does and when to spawn it. |
| `agentic-team-protocol/reference/default-charter` | Default charter | reference | Annotated default charter template and ratification checklist. |

---

## 4. Edits to existing pages and navigation

### 4.1 Homepage (`src/pages/index.astro`)

Change three links:
- Header nav: `<a href="/eden-memory/" class="btn btn-primary">Docs</a>` → `<a href="/docs/" class="btn btn-primary">Docs</a>`
- Footer: `<a href="/eden-memory/">Docs</a>` → `<a href="/docs/">Docs</a>`
- Optionally, product card "Read docs →" links can stay pointed at product roots.

### 4.2 eden-memory overview (`src/content/docs/eden-memory/index.mdx`)

- Keep the splash template but shorten the conceptual body and point clearly to the four quadrants.
- Replace the flat "Common tasks" list with quadrant-based quick links:
  - Quick start (`/eden-memory/getting-started/`)
  - Tutorials → sync tutorial (`/eden-memory/tutorials/sync-two-devices-relay/`)
  - Concepts → how sync works (`/eden-memory/concepts/how-sync-works/`)
  - Reference → tools/CLI/env vars

### 4.3 eden-memory getting-started (`src/content/docs/eden-memory/getting-started.md`)

- Convert from mixed reference/tutorial to the canonical **Quick start** tutorial.
- Keep install, verify, connect, and first remember/recall steps.
- Move manual download table, checksums, and platform matrix to `/eden-memory/reference/downloads/`.
- Move detailed client-specific instructions to new tutorials under `/eden-memory/tutorials/`.
- Add frontmatter: `content_type: tutorial`.

### 4.4 eden-memory mcp-clients (`src/content/docs/eden-memory/mcp-clients.md`)

- Repurpose as the neutral client-connection hub (or keep as `/eden-memory/tutorials/connect-mcp-client/`).
- Decision: keep the existing slug but add a prominent card grid linking to the per-client tutorials.
- Add frontmatter: `content_type: tutorial`.

### 4.5 eden-memory multi-device-sync (`src/content/docs/eden-memory/multi-device-sync.md`)

This is the most overloaded page. It becomes a **concept/how-to map** (or is replaced by a redirect).

**Option A (recommended):** Convert the page to a "Multi-device sync overview" concept map that:
- Summarises direct sync vs relay sync.
- Links to the new tutorial (`/eden-memory/tutorials/sync-two-devices-relay/`).
- Links to the concept page (`/eden-memory/concepts/how-sync-works/`).
- Links to how-to guides (`/eden-memory/how-to/run-relay-server/`, `/eden-memory/how-to/approve-peer-key-change/`).
- Links to reference (`/eden-memory/reference/cli/`, `/eden-memory/reference/environment-variables/`, `/eden-memory/reference/troubleshooting/`).

**Option B:** Remove the page and add an Astro redirect from `/eden-memory/multi-device-sync/` to `/eden-memory/concepts/how-sync-works/` (or the tutorial). Option A is safer because it preserves the URL and the existing link text.

Add frontmatter: `content_type: concept`.

### 4.6 eden-memory reference/tools (`src/content/docs/eden-memory/reference/tools.md`)

- Keep as the canonical tools reference.
- Add cross-links to the sync concept page and sync tutorial.
- Add frontmatter: `content_type: reference`.
- Optionally expand sync/pairing tool sections with output examples.

### 4.7 eden-memory reference/cli (`src/content/docs/eden-memory/reference/cli.md`)

- Keep as canonical CLI reference.
- Move env var details to the new `/eden-memory/reference/environment-variables/` page; keep a one-line "see also" link.
- Add frontmatter: `content_type: reference`.

### 4.8 Skill pages (`src/content/docs/eden-memory/skills/*.md`)

- Keep as reference/installable artifacts.
- Reduce duplicated install narrative by linking to the new tutorials instead of repeating full steps.
- Add `content_type: reference` frontmatter.

### 4.9 agentic-team-protocol overview (`src/content/docs/agentic-team-protocol/index.mdx`)

- Keep the overview but add quadrant quick links.

### 4.10 agentic-team-protocol getting-started (`src/content/docs/agentic-team-protocol/getting-started.md`)

- Convert to the ATP **Quick start** tutorial.
- Move headless-supervisor content to `/agentic-team-protocol/tutorials/headless-supervisor/`.
- Keep manual install and charter ratification.

### 4.11 agentic-team-protocol lifecycle / agents / charter-anatomy

- Add frontmatter: `content_type: concept`.
- Add "See also" links to the new tutorials.

### 4.12 New `/docs/` landing page

Create `src/pages/docs.astro` (custom Astro page) OR `src/content/docs/index.mdx` (Starlight page). Recommendation: custom Astro page matching the homepage visual style, with two product cards and direct links to the most common starting points.

If Starlight requires a `src/content/docs/index.mdx` for the docs root, create both:
- `src/pages/docs.astro` for the styled landing.
- A minimal `src/content/docs/index.mdx` with `redirect` frontmatter or a canonical link to `/docs/`.

**Decision needed:** Whether to use a custom Astro page or a Starlight page for `/docs/`. Custom Astro page keeps visual consistency with the homepage.

### 4.13 `astro.config.mjs` sidebar changes

Current sidebar groups by product with nested topic labels. New sidebar groups by Diátaxis content type under each product.

New eden-memory sidebar:

```javascript
{
  label: 'eden-memory',
  items: [
    { label: 'Overview', slug: 'eden-memory' },
    { label: 'Quick start', slug: 'eden-memory/getting-started' },
    {
      label: 'Tutorials',
      items: [
        { label: 'Connect Claude Code', slug: 'eden-memory/tutorials/connect-claude-code' },
        { label: 'Connect Cursor', slug: 'eden-memory/tutorials/connect-cursor' },
        { label: 'Connect another MCP client', slug: 'eden-memory/tutorials/connect-mcp-client' },
        { label: 'Sync two devices with a relay', slug: 'eden-memory/tutorials/sync-two-devices-relay' },
        { label: 'Sync two databases locally', slug: 'eden-memory/tutorials/sync-local-databases' },
      ],
    },
    {
      label: 'How-to guides',
      items: [
        { label: 'Back up and restore', slug: 'eden-memory/how-to/backup-restore' },
        { label: 'Migrate a workspace', slug: 'eden-memory/how-to/migrate-workspace' },
        { label: 'Prune old memories', slug: 'eden-memory/how-to/prune-memories' },
        { label: 'Run your own relay server', slug: 'eden-memory/how-to/run-relay-server' },
        { label: 'Approve a peer key rotation', slug: 'eden-memory/how-to/approve-peer-key-change' },
      ],
    },
    {
      label: 'Concepts',
      items: [
        { label: 'Memory model and embeddings', slug: 'eden-memory/concepts/memory-model' },
        { label: 'Scopes and identity', slug: 'eden-memory/concepts/scopes-identity' },
        { label: 'How sync works', slug: 'eden-memory/concepts/how-sync-works' },
        { label: 'Sidecar files', slug: 'eden-memory/concepts/sidecar-files' },
        { label: 'Security model', slug: 'eden-memory/concepts/security-model' },
      ],
    },
    {
      label: 'Reference',
      items: [
        { label: 'Tools reference', slug: 'eden-memory/reference/tools' },
        { label: 'CLI reference', slug: 'eden-memory/reference/cli' },
        { label: 'Environment variables', slug: 'eden-memory/reference/environment-variables' },
        { label: 'Fallback slash commands', slug: 'eden-memory/reference/fallback-slash-commands' },
        { label: 'Troubleshooting', slug: 'eden-memory/reference/troubleshooting' },
        { label: 'Skills registry', slug: 'eden-memory/skills' },
        { label: 'Downloads and checksums', slug: 'eden-memory/reference/downloads' },
      ],
    },
  ],
}
```

New agentic-team-protocol sidebar:

```javascript
{
  label: 'agentic-team-protocol',
  items: [
    { label: 'Overview', slug: 'agentic-team-protocol' },
    { label: 'Quick start', slug: 'agentic-team-protocol/getting-started' },
    {
      label: 'Tutorials',
      items: [
        { label: 'Run your first team goal', slug: 'agentic-team-protocol/tutorials/first-team-goal' },
        { label: 'Ratify a project charter', slug: 'agentic-team-protocol/tutorials/ratify-charter' },
        { label: 'Set up a headless supervisor', slug: 'agentic-team-protocol/tutorials/headless-supervisor' },
      ],
    },
    {
      label: 'Concepts',
      items: [
        { label: 'Lifecycle', slug: 'agentic-team-protocol/lifecycle' },
        { label: 'Roles and agents', slug: 'agentic-team-protocol/agents' },
        { label: 'Charter anatomy', slug: 'agentic-team-protocol/charter-anatomy' },
        { label: 'Record kinds and schema', slug: 'agentic-team-protocol/concepts/record-kinds' },
      ],
    },
    {
      label: 'Reference',
      items: [
        { label: 'Slash commands', slug: 'agentic-team-protocol/reference/slash-commands' },
        { label: 'Agent prompts', slug: 'agentic-team-protocol/reference/agent-prompts' },
        { label: 'Default charter', slug: 'agentic-team-protocol/reference/default-charter' },
      ],
    },
  ],
}
```

---

## 5. URL preservation / redirect strategy

### 5.1 URLs that must stay reachable

| Current URL | Strategy | New canonical target |
|-------------|----------|--------------------|
| `/eden-memory/getting-started/` | Keep slug, rewrite content to Quick start tutorial | same |
| `/eden-memory/multi-device-sync/` | Keep slug, rewrite as concept map (Option A) | same |
| `/eden-memory/reference/tools/` | Keep slug, add cross-links | same |
| `/eden-memory/reference/cli/` | Keep slug, trim env var detail | same |
| `/eden-memory/skills/*/` | Keep all skill slugs | same |
| `/agentic-team-protocol/` | Keep slug | same |
| `/agentic-team-protocol/getting-started/` | Keep slug, rewrite to Quick start tutorial | same |
| `/agentic-team-protocol/lifecycle/` | Keep slug | same |
| `/agentic-team-protocol/agents/` | Keep slug | same |
| `/agentic-team-protocol/charter-anatomy/` | Keep slug | same |

### 5.2 Internal links that must be updated

- `src/pages/index.astro`: Docs link → `/docs/`
- `src/content/docs/eden-memory/index.mdx`: Common tasks links → quadrant links.
- `src/content/docs/eden-memory/getting-started.md`: Manual downloads link → `/eden-memory/reference/downloads/`; client setup links → new tutorials.
- `src/content/docs/eden-memory/mcp-clients.md`: Links to skill pages → also link to new tutorials.
- `src/content/docs/eden-memory/reference/tools.md`: "See the multi-device sync guide" link → point to `/eden-memory/multi-device-sync/` (kept as map).
- `src/content/docs/eden-memory/reference/cli.md`: Env var detail → link to `/eden-memory/reference/environment-variables/`.
- `src/content/docs/eden-memory/skills/*.md`: Reduce duplicated install steps; link to `/eden-memory/getting-started/` or per-client tutorials.

### 5.3 Redirect rules (Astro static build)

Add to `astro.config.mjs` `defineConfig` root:

```javascript
export default defineConfig({
  site: 'https://0d3sa.com',
  base: '/',
  redirects: {
    // No page moves yet in Phase 1–2; add here if any slugs are renamed.
  },
  integrations: [
    starlight({ ... })
  ],
});
```

If Option B is chosen for `/eden-memory/multi-device-sync/`, add:

```javascript
redirects: {
  '/eden-memory/multi-device-sync/': '/eden-memory/concepts/how-sync-works/',
}
```

Recommendation: use Option A (keep slug as map) to avoid a redirect and preserve search-engine juice.

---

## 6. Relay / multi-device sync content mapping

The new structure distributes the overloaded `multi-device-sync.md` content across dedicated pages.

| Topic | Current location | New canonical page(s) | Type |
|-------|------------------|----------------------|------|
| Sync modes overview (direct vs relay) | `/eden-memory/multi-device-sync/` | `/eden-memory/multi-device-sync/` (map) + `/eden-memory/concepts/how-sync-works/` | concept |
| Step-by-step relay sync | `/eden-memory/multi-device-sync/` | `/eden-memory/tutorials/sync-two-devices-relay/` | tutorial |
| Direct local sync | `/eden-memory/multi-device-sync/` | `/eden-memory/tutorials/sync-local-databases/` | tutorial |
| Relay server setup | `/eden-memory/multi-device-sync/` | `/eden-memory/how-to/run-relay-server/` | how-to |
| Pairing (direct + relay PAKE) | `/eden-memory/multi-device-sync/` | `/eden-memory/tutorials/sync-two-devices-relay/` + `/eden-memory/concepts/how-sync-works/` | tutorial + concept |
| Sync loop start/once/status/stop | `/eden-memory/multi-device-sync/` | `/eden-memory/reference/cli/` + `/eden-memory/tutorials/sync-two-devices-relay/` | reference + tutorial |
| Device names | `/eden-memory/multi-device-sync/` | `/eden-memory/reference/cli/` | reference |
| Pending key changes | `/eden-memory/multi-device-sync/` | `/eden-memory/how-to/approve-peer-key-change/` + `/eden-memory/reference/cli/` | how-to + reference |
| Sidecar files | `/eden-memory/multi-device-sync/` | `/eden-memory/concepts/sidecar-files/` | concept |
| Security notes (relay threat model) | `/eden-memory/multi-device-sync/` | `/eden-memory/concepts/security-model/` | concept |
| Disabling sync (`--sync-disabled`) | `/eden-memory/multi-device-sync/` + `/eden-memory/reference/cli/` | `/eden-memory/reference/environment-variables/` + `/eden-memory/reference/cli/` | reference |
| Env vars for sync | `/eden-memory/reference/cli/` | `/eden-memory/reference/environment-variables/` | reference |
| Troubleshooting sync | `/eden-memory/multi-device-sync/` | `/eden-memory/reference/troubleshooting/` | reference |
| Tool schemas for sync/pairing/relay | `/eden-memory/reference/tools/` | `/eden-memory/reference/tools/` (expanded) | reference |

The `/eden-memory/multi-device-sync/` page becomes a **concept map** that:
1. Summarises the two sync modes in one table.
2. Provides a "Start here" link to `/eden-memory/tutorials/sync-two-devices-relay/`.
3. Links to each dedicated page above under clear headings.

---

## 7. Phased rollout plan

### Phase 1 — Navigation and landing (1 Builder cycle) — IN PROGRESS

**Status:** In progress (approved by user/Verifier consensus on 2026-08-02).

1. Create `/docs/` landing page (`src/pages/docs.astro`).
2. Update homepage `Docs` links in `src/pages/index.astro`.
3. Update `astro.config.mjs` with new Diátaxis sidebars.
4. Add `content_type` frontmatter to all existing pages.
5. Rewrite `/eden-memory/multi-device-sync/` as a concept map.
6. Verify build and all existing internal links.

**Deliverable:** Navigable new structure with old URLs preserved.

### Phase 2 — eden-memory tutorials (1 Builder cycle)

1. Create `/eden-memory/tutorials/connect-claude-code.md` (move content from skill page + getting-started).
2. Create `/eden-memory/tutorials/connect-cursor.md`.
3. Create `/eden-memory/tutorials/connect-mcp-client.md`.
4. Create `/eden-memory/tutorials/sync-two-devices-relay.md`.
5. Create `/eden-memory/tutorials/sync-local-databases.md`.
6. Trim `/eden-memory/getting-started.md` to the canonical Quick start tutorial and link to new tutorials.
7. Trim skill pages to reference-only and link to tutorials.

**Deliverable:** All eden-memory first-experience paths are tutorial-shaped.

### Phase 3 — eden-memory concepts and reference (1–2 Builder cycles)

1. Create concept pages:
   - `/eden-memory/concepts/memory-model.md`
   - `/eden-memory/concepts/scopes-identity.md`
   - `/eden-memory/concepts/how-sync-works.md`
   - `/eden-memory/concepts/sidecar-files.md`
   - `/eden-memory/concepts/security-model.md`
2. Create how-to pages:
   - `/eden-memory/how-to/backup-restore.md`
   - `/eden-memory/how-to/migrate-workspace.md`
   - `/eden-memory/how-to/prune-memories.md`
   - `/eden-memory/how-to/run-relay-server.md`
   - `/eden-memory/how-to/approve-peer-key-change.md`
3. Create reference pages:
   - `/eden-memory/reference/environment-variables.md`
   - `/eden-memory/reference/fallback-slash-commands.md`
   - `/eden-memory/reference/troubleshooting.md`
   - `/eden-memory/reference/downloads.md`
4. Update `/eden-memory/reference/tools.md` and `/eden-memory/reference/cli.md` with cross-links.

**Deliverable:** Complete eden-memory Diátaxis coverage.

### Phase 4 — ATP tutorials and reference polish (1 Builder cycle)

1. Create `/agentic-team-protocol/tutorials/first-team-goal.md`.
2. Create `/agentic-team-protocol/tutorials/ratify-charter.md`.
3. Create `/agentic-team-protocol/tutorials/headless-supervisor.md` (move from getting-started).
4. Create `/agentic-team-protocol/concepts/record-kinds.md`.
5. Create `/agentic-team-protocol/reference/slash-commands.md`, `/agentic-team-protocol/reference/agent-prompts.md`, `/agentic-team-protocol/reference/default-charter.md`.
6. Trim `/agentic-team-protocol/getting-started.md` to Quick start tutorial.

**Deliverable:** ATP has tutorial + concept + reference structure.

### Phase 5 — Verification and redirects (Verifier cycle)

1. Run `npm run build`.
2. Validate all routes from the old URL list return the expected content.
3. Validate all new routes are present in the generated `dist/`.
4. Run `astro preview` and spot-check the sidebar on desktop and mobile.
5. Add any missing redirects to `astro.config.mjs`.

---

## 8. Build command and verification checklist

### Build command

```bash
cd /home/yakov/git/eden-releases/docs-site
npm run build
```

This runs:
1. `node ../scripts/sync-atp-to-docs.js`
2. `python3 ../scripts/generate-skills-site.py`
3. `astro build`

### Verification checklist

- [ ] `npm run build` exits 0.
- [ ] `dist/` contains `index.html` for `/`, `/docs/`, `/eden-memory/`, `/agentic-team-protocol/`.
- [ ] `dist/eden-memory/getting-started/index.html` exists.
- [ ] `dist/eden-memory/multi-device-sync/index.html` exists and contains only the map + links.
- [ ] `dist/eden-memory/reference/tools/index.html` and `dist/eden-memory/reference/cli/index.html` exist.
- [ ] All new tutorial routes are present in `dist/`.
- [ ] The homepage header and footer "Docs" links point to `/docs/`.
- [ ] The sidebar renders the Diátaxis groups for both products.
- [ ] No broken internal links reported by `astro build`.
- [ ] `astro preview` shows the new `/docs/` landing page.

---

## 9. Decisions record (approved by user/Verifier consensus on 2026-08-02)

1. **Approach to `/docs/` landing page:** **A** — Custom Astro page (`src/pages/docs.astro`) matching homepage style.

2. **Fate of `/eden-memory/multi-device-sync/`:** **A** — Keep slug, rewrite as a concept map linking to new pages (preserves URL and external links).

3. **Client-specific install content duplication:** Skill pages will be shortened to reference-only and link to tutorials, but this is deferred to Phase 2. For Phase 1, only add `content_type: reference` frontmatter to skill pages.

4. **ATP scope in this redesign:** Phase 4 (ATP tutorials and reference polish) is included in this goal.

5. **Downloads/reference page source:** `/eden-memory/reference/downloads/` will read from `src/data/downloads.json` and be implemented as `.mdx` in Phase 3.

6. **Content-type frontmatter field name:** **A** — `content_type: tutorial|how-to|concept|reference`.

7. **Redirect hosting:** Astro built-in static `redirects` are sufficient; no redirects are needed in Phase 1 because all existing slugs are preserved.

---

## 10. Plan file path

`/home/yakov/git/eden-releases/docs-site/plan/site-structure-redesign-2026-08-02.md`

This plan is ready for Verifier review and user approval before any content or code changes are made.
