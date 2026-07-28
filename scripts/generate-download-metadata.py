#!/usr/bin/env python3
"""Generate download metadata for the docs site from binaries/manifest.json."""

import json
import os
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BINARIES = ROOT / "binaries"
OUTPUT = ROOT / "docs-site" / "src" / "data" / "downloads.json"
RELEASE_BASE = "https://github.com/yakovkhalinsky/eden-releases/releases/latest/download"

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

def main():
    manifest_path = BINARIES / "manifest.json"
    if not manifest_path.exists():
        print(f"No manifest at {manifest_path}; nothing to generate.")
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_text(json.dumps({"platforms": {}}, indent=2))
        return

    manifest = json.loads(manifest_path.read_text())
    platforms = {}
    for key, meta in manifest.get("platforms", {}).items():
        filename = meta["filename"]
        fpath = BINARIES / filename
        if not fpath.exists():
            print(f"Warning: {filename} listed in manifest but not found in binaries/")
            continue
        checksum = sha256_file(fpath)
        platforms[key] = {
            "os": meta.get("os", key.split("-", 1)[0]),
            "arch": meta.get("arch", key.split("-", 1)[1]),
            "filename": filename,
            "downloadUrl": f"{RELEASE_BASE}/{filename}",
            "checksumUrl": f"{RELEASE_BASE}/{filename}.sha256",
            "sha256": checksum,
            "sizeBytes": fpath.stat().st_size,
        }

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps({
        "version": manifest.get("version", ""),
        "released": manifest.get("released", ""),
        "platforms": platforms,
    }, indent=2) + "\n")
    print(f"Wrote {OUTPUT} with {len(platforms)} platform(s).")

if __name__ == "__main__":
    main()
