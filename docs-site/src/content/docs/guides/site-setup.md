---
title: Site setup
description: How this public release docs site is built and deployed, and how to reuse the pattern for a private-source project.
---

This site is a public-facing release portal for a private-source project.
The source code for `eden-memory` and related projects is not in this repository; only binaries, documentation, manifests, and release metadata live here.
The result is published at <https://0d3sa.com> from a GitHub Pages deployment.

You can copy the same shape for any private-source project you want to distribute publicly.

## What lives where

| Repository path | Purpose |
|-----------------|---------|
| `binaries/manifest.json` | Platform metadata for the latest release assets. |
| `docs-site/` | Astro + Starlight site that becomes the public docs site. |
| `.github/workflows/` | CI for building docs and attaching release binaries. |
| `scripts/` | Helpers that generate metadata and package releases. |
| `public/eden-memory/install.sh` | One-line installer served from the custom domain. |

The actual binaries are not committed to git.
They are attached to a GitHub Release as release assets and downloaded by URL.

## Repository setup

1. Create a public GitHub repository for releases and docs only.
   This repo should not contain your private source code.
2. Add a docs site under `docs-site/`.
   This site uses [Astro](https://astro.build/) and [Starlight](https://starlight.astro.build/).
3. Add release metadata under `binaries/manifest.json` that lists each supported platform, filename, and checksum file.
4. Keep release tooling in `scripts/` and `.github/workflows/`.
5. Publish binaries to GitHub Releases, not to git.

### Example manifest

```json
{
  "version": "0.3.17",
  "released": "2026-07-28",
  "platforms": {
    "linux-amd64": {
      "filename": "eden-memory-linux-amd64",
      "checksum": "eden-memory-linux-amd64.sha256"
    }
  }
}
```

The docs site reads this manifest to generate the download table on the install page.

## Custom domain

This site uses a custom apex domain, `0d3sa.com`, served from GitHub Pages.

1. Buy the domain through any registrar.
2. In your DNS provider, create an `A` record pointing the apex to the GitHub Pages IPs:

   ```text
   185.199.108.153
   185.199.109.153
   185.199.110.153
   185.199.111.153
   ```

3. In your repository, go to **Settings > Pages** and enter the custom domain.
4. Add `docs-site/public/CNAME` with the domain on its own line:

   ```text
   0d3sa.com
   ```

   Starlight copies `public/CNAME` into the build output so the file survives deployment.
5. GitHub Pages will create an HTTPS certificate once the DNS record is detected.

## GitHub Pages deployment

The `.github/workflows/pages.yml` workflow builds and deploys the docs site on every push to `main` or `master`.

The workflow:

1. Checks out the repository.
2. Installs pnpm using `pnpm/action-setup@v4`.
3. Sets up Node.js from `docs-site/.nvmrc`.
4. Installs dependencies with `pnpm install --frozen-lockfile`.
5. Builds the site with `pnpm build` inside `docs-site/`.
6. Uploads `docs-site/dist` as a GitHub Pages artifact.
7. Deploys the artifact to GitHub Pages.

Repository settings that must be enabled:

- **Settings > Pages > Source**: GitHub Actions.
- Workflow permissions must include `contents: read`, `pages: write`, and `id-token: write`.

## Binaries as release assets

This project does not commit compiled binaries to git.
Instead, the release workflow attaches them to a GitHub Release.

When a version tag like `v*` is pushed, `.github/workflows/release.yml` attaches every file in the `binaries/` directory to the matching release.

To publish a new binary set:

1. Build or fetch the binaries for every target platform.
2. Generate SHA-256 checksum files:

   ```bash
   for f in eden-memory-*; do sha256sum "$f" > "$f.sha256"; done
   ```

3. Place the binaries and `.sha256` files in `binaries/`.
4. Update `binaries/manifest.json` if filenames or platforms changed.
5. Run the metadata generator:

   ```bash
   ./scripts/generate-download-metadata.py --assets-dir ./binaries
   ```

6. Commit and push the manifest and generated `docs-site/src/data/downloads.json`.
7. Create a GitHub Release with the matching `v*` tag.
   The workflow will attach the files in `binaries/` automatically.

Users download from the release asset URL, for example:

```text
https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-linux-arm64
```

The install script at `public/eden-memory/install.sh` resolves `latest/download` to the most recent release and picks the correct platform.

## Multi-product structure

The site has two product sections, `eden-memory` and `agentic-team-protocol`.
When you add another product, create a parallel directory under `docs-site/src/content/docs/<product>/`:

```text
src/content/docs/
├── index.mdx                 # splash landing page
├── another-product/
│   ├── index.mdx             # product overview
│   └── guides/
│       └── install.md        # product install page
└── eden-memory/
    ├── index.mdx
    ├── guides/
    │   ├── install.md
    │   ├── getting-started.md
    │   └── mcp-clients.md
    └── reference/
        └── tools.md
```

Then add the product to the sidebar in `docs-site/astro.config.mjs`:

```js
sidebar: [
  {
    label: 'eden-memory',
    items: [
      { label: 'Overview', slug: 'eden-memory' },
      {
        label: 'Guides',
        items: [
          { label: 'Install', slug: 'eden-memory/guides/install' },
        ],
      },
    ],
  },
  {
    label: 'another-product',
    items: [
      { label: 'Overview', slug: 'another-product' },
      {
        label: 'Guides',
        items: [
          { label: 'Install', slug: 'another-product/guides/install' },
        ],
      },
    ],
  },
],
```

Each product can have its own install script, manifest entry, and release assets.
If products share a release repo, keep one `binaries/manifest.json` with a top-level `products` key or use one manifest file per product.

## Keeping the site in sync

| Trigger | What to do |
|---------|------------|
| New release | Update `binaries/manifest.json`, regenerate metadata, push. |
| New product | Add directory, add sidebar entry, add release assets. |
| Domain change | Update DNS, GitHub Pages settings, and `public/CNAME`. |
| Content edit | Edit a docs page and push; Pages rebuilds automatically. |

## Reference

- [Astro docs](https://docs.astro.build/)
- [Starlight docs](https://starlight.astro.build/)
- [GitHub Pages custom domain docs](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)
- [GitHub Releases docs](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)
