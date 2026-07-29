# eden-releases

Public releases and documentation for eden-memory.

Live docs: <https://0d3sa.com>

Latest release: <https://github.com/yakovkhalinsky/eden-releases/releases/latest>

## What's here

- `binaries/manifest.json` — platform metadata for the published binaries.
- `docs-site/` — Astro Starlight site that becomes <https://0d3sa.com>.
- `skills/` — agent skills for eden-memory; generated into the site via `scripts/generate-skills-site.py`.
- `.github/workflows/` — CI that deploys the site to GitHub Pages and cuts releases.
- `scripts/` — helpers for metadata and skill-page generation.

## Regenerate skill pages

After editing skills under `skills/`, run:

```bash
python3 scripts/generate-skills-site.py
```

This updates `docs-site/src/content/docs/eden-memory/skills/` from the SKILL.md
source files. Commit the generated pages so Pages builds them.

## Publish a new binary set

This is normally handled automatically by the `eden-memory` CI workflow. On
every green build on `master`, that workflow:

1. Creates a release in `yakovkhalinsky/eden-memory`.
2. Downloads the per-platform binaries.
3. Updates `binaries/manifest.json`.
4. Regenerates `docs-site/src/data/downloads.json`.
5. Commits and pushes the metadata changes to this repo.
6. Creates or updates the GitHub Release here with the binaries and `.sha256` files.

To do it manually (for example, to promote an older release), use the
**eden-memory Public Release (manual fallback)** workflow in this repository
and provide the source tag from `eden-memory`.

Binaries are stored as GitHub Release assets only — they are not committed to git.

## License

MIT — see [LICENSE](./LICENSE).
