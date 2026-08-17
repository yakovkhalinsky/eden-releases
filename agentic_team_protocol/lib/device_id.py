"""device_id.py — stable, privacy-safe device identifier helper.

Derives a deterministic device_id from the hostname using a short SHA-256 hash.
Useful for populating EDEN_DEVICE_ID in ATP metrics (runbooks/atp-metrics-collection.md).

The identifier is:
- deterministic for the same hostname,
- stable across restarts,
- free of personal identifiers (no username, MAC, serial, IP).

Output format: <project-slug>-<sha256(hostname)[0:16]>
"""

import hashlib
import os
import platform


def derive_device_id(project_slug: str | None = None, hostname: str | None = None) -> str:
    """Return a stable device_id derived from the hostname.

    Args:
        project_slug: Prefix for the identifier. Defaults to the
            EDEN_DEVICE_ID_PROJECT_SLUG environment variable or "eden".
        hostname: Hostname to hash. Defaults to platform.node() or "unknown".

    Returns:
        A string like "eden-a1b2c3d4e5f67890".
    """
    if project_slug is None:
        project_slug = os.environ.get("EDEN_DEVICE_ID_PROJECT_SLUG", "eden")
    if hostname is None:
        hostname = platform.node() or "unknown"
    digest = hashlib.sha256(hostname.encode("utf-8")).hexdigest()[:16]
    return f"{project_slug}-{digest}"


def main(argv: list[str] | None = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(
        description="Print a stable, privacy-safe device identifier derived from the hostname."
    )
    parser.add_argument(
        "--hostname",
        help="Override the hostname used to derive the identifier.",
    )
    parser.add_argument(
        "--project-slug",
        default=os.environ.get("EDEN_DEVICE_ID_PROJECT_SLUG", "eden"),
        help="Project slug prefix (default: eden, or EDEN_DEVICE_ID_PROJECT_SLUG).",
    )
    args = parser.parse_args(argv)
    print(derive_device_id(project_slug=args.project_slug, hostname=args.hostname))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
