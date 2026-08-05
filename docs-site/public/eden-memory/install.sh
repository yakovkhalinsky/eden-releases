#!/usr/bin/env sh
# Installer for the eden-memory monorepo binaries.
# Usage:
#   curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
#   curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh -s eden-relay
#   EDEN_INSTALL_BIN=eden-team curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
#
# Defaults to installing eden-memory. Valid binaries: eden-memory, eden-relay, eden-team.

set -eu

REPO="yakovkhalinsky/eden-releases"
PREFIX_DEFAULT="${HOME}/.local/bin"

# Select binary to install
BIN_NAME="${1:-${EDEN_INSTALL_BIN:-eden-memory}}"
case "${BIN_NAME}" in
    eden-memory|eden-relay|eden-team) ;;
    *) echo "Unsupported binary: ${BIN_NAME}"; echo "Usage: $0 [eden-memory|eden-relay|eden-team]"; exit 1 ;;
esac

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

BIN="${BIN_NAME}-${OS}-${ARCH}"
URL="https://github.com/${REPO}/releases/latest/download/${BIN}"
CHECKSUM_URL="${URL}.sha256"

# Pick install prefix
if mkdir -p "${PREFIX_DEFAULT}" 2>/dev/null; then
    PREFIX="${PREFIX_DEFAULT}"
else
    PREFIX="/usr/local/bin"
fi

TARGET="${PREFIX}/${BIN_NAME}"

# Capture previous version if the target already exists.
PREVIOUS_VERSION="none"
if [ -x "${TARGET}" ]; then
    PREVIOUS_VERSION=$("${TARGET}" version 2>/dev/null || echo "unknown")
fi

# Remove any stale Python wrapper from an old pip/uv install so the new
# static binary can replace it cleanly. Only the eden-memory binary had a
# Python wrapper historically.
if [ "${BIN_NAME}" = "eden-memory" ] && [ -f "${TARGET}" ]; then
    if head -1 "${TARGET}" 2>/dev/null | grep -q "python"; then
        echo "Removing stale Python wrapper at ${TARGET}..."
        rm -f "${TARGET}"
    fi
fi

# Create temp directory
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "Downloading ${BIN_NAME} ${OS}/${ARCH}..."

# Use a progress bar if curl supports it; otherwise stay silent.
CURL_PROGRESS="--progress-bar"
if ! curl --progress-bar --help >/dev/null 2>&1; then
  CURL_PROGRESS="--no-progress-meter"
fi

curl -fsSL ${CURL_PROGRESS} -o "${TMPDIR}/${BIN}" "${URL}"
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

if ! command -v "${BIN_NAME}" >/dev/null 2>&1; then
    echo ""
    echo "${BIN_NAME} was installed to ${TARGET}, but it is not on your PATH."
    echo "Add the following to your shell profile:"
    echo "  export PATH=\"${PREFIX}:\$PATH\""
fi

# Show before/after versions.
UPDATED_VERSION=$("${TARGET}" version 2>/dev/null || echo "unknown")
echo ""
echo "${BIN_NAME} updated: ${PREVIOUS_VERSION} → ${UPDATED_VERSION}"
echo ""
echo "Run:"
case "${BIN_NAME}" in
    eden-memory)
        echo "  eden-memory --db ~/.eden-memory/default.db"
        ;;
    eden-relay)
        echo "  eden-relay --db /var/lib/eden-relay/relay.db --addr :8787"
        ;;
    eden-team)
        echo "  eden-team --help"
        ;;
esac

# ANSI color helpers via printf, gated by TTY and NO_COLOR for portability.
NO_COLOR="${NO_COLOR:-}"
if [ -t 1 ] && [ -z "${NO_COLOR}" ]; then
    ESC="$(printf '\033')"
    GREEN="${ESC}[32m"
    CYAN="${ESC}[36m"
    YELLOW="${ESC}[33m"
    DIM="${ESC}[90m"
    RESET="${ESC}[0m"
else
    GREEN=""
    CYAN=""
    YELLOW=""
    DIM=""
    RESET=""
fi

cat <<EOF

${GREEN}Your memory garden is ready:${RESET}

    ${CYAN}${BIN_NAME}${RESET}
    +-- ${YELLOW}${TARGET}${RESET}
    +-- ${YELLOW}~/.eden-memory/default.db${RESET}
    +-- ${YELLOW}~/.cache/eden-memory/${RESET}
    +-- ${DIM}~/.claude.json   (after setup claude)${RESET}

${GREEN}Quick start:${RESET}
EOF

case "${BIN_NAME}" in
    eden-memory)
        cat <<EOF
  ${CYAN}eden-memory --db ~/.eden-memory/default.db${RESET}
  ${CYAN}eden-memory health${RESET}
  ${CYAN}eden-memory remember --agent-id eve --user-id yakov --content "hello world"${RESET}
  ${CYAN}eden-memory tree${RESET}
EOF
        ;;
    eden-relay)
        cat <<EOF
  ${CYAN}eden-relay --db /var/lib/eden-relay/relay.db --addr :8787${RESET}
  ${CYAN}curl http://localhost:8787/health${RESET}
EOF
        ;;
    eden-team)
        cat <<EOF
  ${CYAN}eden-team --help${RESET}
  ${CYAN}eden-team start --goal "Create /tmp/atp-hello.txt containing exactly 'hello from ATP'"${RESET}
EOF
        ;;
esac
