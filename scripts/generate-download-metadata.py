#!/usr/bin/env python3
"""generate-download-metadata.py

Reads the packaged release archives in a directory and emits a JSON file
with download URLs and metadata suitable for rendering on a docs site.

Example:
    python3 scripts/generate-download-metadata.py \
        --release-tag v2026.0728.1601-eden-releases.1 \
        --repo yakovkhalinsky/eden-releases \
        --packages dist/packages \
        --source-tag v2026.0728.1601 \
        --source-sha abc123 \
        --out dist/download-metadata.json
"""

import argparse
import hashlib
import json
import os
import re
from pathlib import Path


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def platform_from_archive(name: str) -> str | None:
    m = re.search(r"eden-memory-[^-]+-([^-]+-[^.]+)\.tar\.gz$", name)
    if m:
        return m.group(1)
    return None


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate eden-releases download metadata")
    parser.add_argument("--release-tag", required=True)
    parser.add_argument("--repo", required=True, help="owner/repo for GitHub Release URL construction")
    parser.add_argument("--packages", required=True, help="directory containing packaged archives")
    parser.add_argument("--source-tag", required=True)
    parser.add_argument("--source-sha", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    packages_dir = Path(args.packages)
    base_url = f"https://github.com/{args.repo}/releases/download/{args.release_tag}"

    archives = []
    for archive in sorted(packages_dir.glob("eden-memory-*.tar.gz")):
        platform = platform_from_archive(archive.name)
        if not platform:
            continue
        archives.append(
            {
                "platform": platform,
                "name": archive.name,
                "url": f"{base_url}/{archive.name}",
                "size": archive.stat().st_size,
                "sha256": sha256_file(archive),
            }
        )

    metadata = {
        "release_tag": args.release_tag,
        "source": {
            "owner_repo": "yakovkhalinsky/eden-memory",
            "tag": args.source_tag,
            "commit_sha": args.source_sha,
            "release_url": f"https://github.com/yakovkhalinsky/eden-memory/releases/tag/{args.source_tag}",
        },
        "download_base_url": base_url,
        "checksums_url": f"{base_url}/CHECKSUMS.sha256",
        "archives": archives,
        "generated_at": "",
    }

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)
        f.write("\n")

    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
