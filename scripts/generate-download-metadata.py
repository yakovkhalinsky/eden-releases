#!/usr/bin/env python3
"""Generate download metadata for the docs site from binaries/manifest.json.

The manifest uses a per-binary schema:

    {
      "version": "0.3.70",
      "released": "2026-08-05",
      "binaries": {
        "eden-memory": {
          "platforms": {
            "linux-amd64": {
              "os": "linux",
              "arch": "amd64",
              "filename": "eden-memory-linux-amd64",
              "downloadUrl": "...",
              "checksumUrl": "...",
              "sha256": "...",
              "sizeBytes": 0
            }
          }
        }
      }
    }

This script populates sha256 and sizeBytes for every artifact found in the
asset directory. Missing artifacts keep their existing values so placeholder
checksums (e.g. PUBLISHED_AT_RELEASE) survive between releases.
"""

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BINARIES = ROOT / "binaries"
MANIFEST = BINARIES / "manifest.json"
OUTPUT = ROOT / "docs-site" / "src" / "data" / "downloads.json"
REQUIRED_PLATFORM_KEYS = {"os", "arch", "filename", "downloadUrl", "checksumUrl"}
SUPPORTED_BINARIES = {"eden-memory", "eden-relay", "eden-team"}


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def validate_manifest(manifest: dict, assets_dir: Path, verbose: bool = True) -> int:
    """Validate the manifest schema and artifact presence. Returns error count."""
    errors = 0
    binaries = manifest.get("binaries")
    if not isinstance(binaries, dict):
        print("ERROR: manifest is missing top-level 'binaries' object", file=sys.stderr)
        return 1

    for binary_name, binary_meta in binaries.items():
        if binary_name not in SUPPORTED_BINARIES:
            print(f"WARNING: unknown binary '{binary_name}' in manifest")
        platforms = binary_meta.get("platforms")
        if not isinstance(platforms, dict):
            print(f"ERROR: binary '{binary_name}' has no 'platforms' object", file=sys.stderr)
            errors += 1
            continue

        for platform_key, platform in platforms.items():
            missing = REQUIRED_PLATFORM_KEYS - set(platform.keys())
            if missing:
                print(
                    f"ERROR: {binary_name}/{platform_key} missing keys: {', '.join(sorted(missing))}",
                    file=sys.stderr,
                )
                errors += 1
                continue

            filename = platform["filename"]
            fpath = assets_dir / filename
            if not fpath.exists():
                print(
                    f"WARNING: {binary_name}/{platform_key} artifact not found: {fpath}"
                )
            elif verbose:
                print(f"OK: {binary_name}/{platform_key} -> {fpath}")

    return errors


def update_manifest(manifest: dict, assets_dir: Path) -> tuple[int, int]:
    """Populate sha256/sizeBytes for present artifacts. Returns (updated, missing)."""
    updated = 0
    missing = 0
    binaries = manifest.setdefault("binaries", {})

    for binary_name, binary_meta in binaries.items():
        platforms = binary_meta.get("platforms", {})
        for platform_key, platform in platforms.items():
            filename = platform["filename"]
            fpath = assets_dir / filename
            if fpath.exists():
                platform["sha256"] = sha256_file(fpath)
                platform["sizeBytes"] = fpath.stat().st_size
                updated += 1
            else:
                missing += 1

    return updated, missing


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate download metadata")
    parser.add_argument(
        "--tag",
        type=str,
        default=None,
        help="Release tag (e.g. v0.3.70). Strips a leading 'v' for the manifest version and sets released to today (UTC).",
    )
    parser.add_argument(
        "--assets-dir",
        type=Path,
        default=BINARIES,
        help=f"Directory containing the actual binary files to hash/size. Defaults to {BINARIES}.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate file presence and schema without writing any files.",
    )
    args = parser.parse_args()

    if not MANIFEST.exists():
        print(f"No manifest at {MANIFEST}; nothing to generate.", file=sys.stderr)
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        if not args.dry_run:
            OUTPUT.write_text(json.dumps({"binaries": {}}, indent=2) + "\n")
        return 1

    manifest = json.loads(MANIFEST.read_text())

    # Optional version/date bump from tag.
    if args.tag:
        version = args.tag.lstrip("v")
        released = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        manifest["version"] = version
        manifest["released"] = released
        print(f"Using release tag {args.tag} -> version {version}, released {released}")

    print(f"Validating manifest against assets in {args.assets_dir} ...")
    errors = validate_manifest(manifest, args.assets_dir, verbose=True)
    if errors:
        print(f"Validation failed with {errors} error(s).", file=sys.stderr)
        return 1

    updated, missing = update_manifest(manifest, args.assets_dir)
    print(f"Updated {updated} platform(s); {missing} platform(s) retain existing placeholders.")

    if args.dry_run:
        print("Dry-run: no files written.")
        return 0

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(manifest, indent=2) + "\n")
    MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Wrote {MANIFEST} and {OUTPUT}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
