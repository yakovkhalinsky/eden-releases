# eden-releases

Public releases and documentation for [eden-memory](https://github.com/yakovkhalinsky/eden-memory).

Live docs: <https://0d3sa.com>

Latest release: <https://github.com/yakovkhalinsky/eden-releases/releases/latest>

## What's here

- `binaries/manifest.json` — platform metadata for the published binaries.
- `docs-site/` — Astro Starlight site that becomes <https://0d3sa.com>.
- `.github/workflows/` — CI that deploys the site to GitHub Pages and attaches any files in `binaries/` to GitHub Releases.
- `scripts/` — helpers for metadata generation and releases.

## Publish a new binary set

1. Fetch the built binaries for all platforms from the private `eden-memory` release (or build them locally).
2. Generate/refresh SHA-256 checksums:
   ```bash
   for f in eden-memory-*; do sha256sum "$f" > "$f.sha256"; done
   ```
3. Update `binaries/manifest.json` with any new platforms or filenames.
4. Run `./scripts/generate-download-metadata.py --assets-dir </path/to/binaries>`.
5. Commit and push the manifest + metadata changes.
6. Create a GitHub Release and attach the binary files and their `.sha256` files.

## Cutting a release

```bash
git tag -a vYYYY.MMDD.HHMM -m "eden-memory release vYYYY.MMDD.HHMM"
git push origin vYYYY.MMDD.HHMM
```

Then upload the platform binaries to the drafted release. The `release.yml` workflow will attach any files already in `binaries/`; actual binary files are kept as release assets only, not committed to git.

## License

MIT — see [LICENSE](./LICENSE).
