#!/usr/bin/env sh
# Installer for eden-memory.
# Usage: curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh

set -eu

REPO="yakovkhalinsky/eden-memory"
PREFIX_DEFAULT="${HOME}/.local/bin"

# Detect OS
OS=""
case "$(uname -s)" in
    Linux)     OS="linux" ;;
    Darwin)    OS="darwin" ;;
    *)         echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac

# Detect architecture
ARCH=""
case "$(uname -m)" in
    x86_64)  ARCH="amd64" ;;
    amd64)   ARCH="amd64" ;;
    arm64)   ARCH="arm64" ;;
    aarch64) ARCH="arm64" ;;
    *)       echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

BIN="eden-memory-${OS}-${ARCH}"
URL="https://github.com/${REPO}/releases/latest/download/${BIN}"
CHECKSUM_URL="${URL}.sha256"

# Pick install prefix
if mkdir -p "${PREFIX_DEFAULT}" 2>/dev/null; then
    PREFIX="${PREFIX_DEFAULT}"
else
    PREFIX="/usr/local/bin"
fi

TARGET="${PREFIX}/eden-memory"

# Remove any stale Python wrapper from an old pip/uv install so the new
# static binary can replace it cleanly.
if [ -f "${TARGET}" ]; then
    if head -1 "${TARGET}" 2>/dev/null | grep -q "python"; then
        echo "Removing stale Python wrapper at ${TARGET}..."
        rm -f "${TARGET}"
    fi
fi

# Create temp directory
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "Downloading eden-memory ${OS}/${ARCH}..."
curl -fsSL -o "${TMPDIR}/${BIN}" "${URL}"
curl -fsSL -o "${TMPDIR}/${BIN}.sha256" "${CHECKSUM_URL}"

echo "Verifying checksum..."
cd "${TMPDIR}"
if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c "${BIN}.sha256"
else
    shasum -a 256 -c "${BIN}.sha256"
fi

echo "Installing to ${TARGET}..."
chmod +x "${TMPDIR}/${BIN}"
mkdir -p "${PREFIX}"

# Avoid "Text file busy" when overwriting a running binary by installing via a
# temporary file and an atomic rename.
TMP_BIN="${TARGET}.tmp.$$"
cp "${TMPDIR}/${BIN}" "${TMP_BIN}"
mv -f "${TMP_BIN}" "${TARGET}"

if ! command -v eden-memory >/dev/null 2>&1; then
    echo ""
    echo "eden-memory was installed to ${TARGET}, but it is not on your PATH."
    echo "Add the following to your shell profile:"
    echo "  export PATH=\"${PREFIX}:\$PATH\""
fi

echo ""
echo "eden-memory is installed. Run:"
echo "  eden-memory --db ~/.eden-memory/default.db"
