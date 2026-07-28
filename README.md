# eden-releases

Public releases and documentation for [eden-memory](https://github.com/yakovkhalinsky/eden-memory).

Live docs: <https://0d3sa.com>

## What's here

- `binaries/` — built `eden-memory` binaries per platform, plus checksums.
- `docs-site/` — Astro Starlight site that becomes <https://0d3sa.com>.
- `.github/workflows/` — CI that deploys the site to GitHub Pages and cuts GitHub Releases from the binaries directory.
- `scripts/` — helpers for packaging, metadata generation, and releases.

## Add a new binary

1. Drop the built binary into `binaries/` as `eden-memory-<os>-<arch>`.
2. Generate a checksum:
   ```bash
   cd binaries
   sha256sum eden-memory-<os>-<arch> > eden-memory-<os>-<arch>.sha256
   ```
3. Update `binaries/manifest.json`.
4. Run `./scripts/generate-download-metadata.py` to refresh `docs-site/src/data/downloads.json`.
5. Commit, tag `vYYYY.MMDD.HHMM`, and push. The release workflow will create a GitHub Release.

## License

MIT — see [LICENSE](./LICENSE).
