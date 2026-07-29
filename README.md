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

1. Build or fetch binaries for all target platforms and generate SHA-256 checksums:
   ```bash
   for f in eden-memory-*; do sha256sum "$f" > "$f.sha256"; done
   ```
2. Update `binaries/manifest.json` if filenames or platforms changed.
3. Run `./scripts/generate-download-metadata.py --assets-dir </path/to/binaries>`.
4. Commit and push the manifest + metadata changes.
5. Create a GitHub Release and attach the binary files and their `.sha256` files.

Binaries are stored as GitHub Release assets only — they are not committed to git.

## License

MIT — see [LICENSE](./LICENSE).
