# eden-releases

Public releases, documentation, and agent harness skills for eden-memory.

This repository packages the static binaries produced by
[`yakovkhalinsky/eden-memory`](https://github.com/yakovkhalinsky/eden-memory)
together with resurrected agent-harness skills and publishes them as
GitHub Releases.

## Release workflow

`.github/workflows/release.yml` can be triggered in three ways:

1. **Manual** — `workflow_dispatch` lets you override the source tag.
2. **Scheduled poll** — runs daily at 06:00 UTC and picks the latest green
   `vYYYY.MMDD.HHMM` release from the private source repo.
3. **Repository dispatch** — `eden-memory-released` events can trigger it
   immediately.

The workflow:

1. Lists releases in `yakovkhalinsky/eden-memory`.
2. Selects the newest tag matching `vYYYY.MMDD.HHMM` whose CI checks are green.
3. Downloads the `eden-memory-*` binaries.
4. Bundles the binaries with the agent-harness skills staged under `skills/`.
5. Creates per-platform `.tar.gz` archives and a `CHECKSUMS.sha256` file.
6. Publishes a GitHub Release in this repo (tag: `vYYYY.MMDD.HHMM-eden-releases.N`).
7. Generates `download-metadata.json` for the docs site.

## Required secrets / configuration

- `EDEN_MEMORY_TOKEN` — GitHub token with `repo` read access to
  `yakovkhalinsky/eden-memory`. Falls back to `GITHUB_TOKEN`, which only
  works if the default Actions token has cross-repo access.
- (Optional) `SKILLS_REPO` repository variable — a git URL to clone skills
  from during the workflow. If unset, the workflow packages whatever is
  committed under `skills/`.

## Helper scripts

| Script | Purpose |
|--------|---------|
| `scripts/import-skills.sh` | Copy agent-harness skills from your local Hermes profile tree into `skills/` so they can be committed and bundled. |
| `scripts/fetch-latest-eden-memory.sh` | Standalone script used by the workflow to find the latest green release in the source repo. |
| `scripts/package-release.sh` | Package downloaded binaries + skills into archives and compute checksums. |
| `scripts/generate-download-metadata.py` | Produce `download-metadata.json` with download URLs, sizes, and SHA-256 hashes for the docs site. |

## Importing skills locally

```bash
# Default: imports Adam's agent-harness-rollout skill.
./scripts/import-skills.sh

# Import additional skills.
./scripts/import-skills.sh \
  software-development/agent-harness-rollout \
  software-development/packaged-agentic-teams
```

After importing, review the files, then commit `skills/` and push.

## Verifying a release archive

```bash
tar -xzf eden-memory-2026.0728.1601-linux-amd64.tar.gz
cd eden-memory-2026.0728.1601-linux-amd64
sha256sum -c ../CHECKSUMS.sha256
./eden-memory --help
```

## License

See [LICENSE](./LICENSE).
