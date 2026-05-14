#!/bin/bash
# Secure installer - verifies checksums before running

set -euo pipefail

REPO="DamnSit/claude-code-termux"
BASE_URL="https://raw.githubusercontent.com/${REPO}/main"

# Termux uses $PREFIX/tmp, fallback to /tmp
TMPDIR="${PREFIX:-/data/data/com.termux/files/usr}/tmp"
mkdir -p "$TMPDIR"
WORKDIR="$(mktemp -d "${TMPDIR}/claude-secure.XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT

echo "🔐 Verifying installer integrity..."
echo ""

# Force refresh to avoid CDN cache
CACHE_BUST="?t=$(date +%s)"

# Download checksums file
echo "  ▸ Downloading checksums..."
if curl --proto '=https' --tlsv1.2 -fSL "${BASE_URL}/CHECKSUMS.txt${CACHE_BUST}" -o "${WORKDIR}/CHECKSUMS.txt" 2>/dev/null; then
    echo "  ✅ Checksums downloaded"
else
    echo "❌ Failed to download checksums; refusing to run unverified installer."
    exit 1
fi

# Download install script
echo "  ▸ Downloading installer..."
if ! curl --proto '=https' --tlsv1.2 -fSL "${BASE_URL}/install.sh${CACHE_BUST}" -o "${WORKDIR}/install.sh" 2>/dev/null; then
    echo "❌ Failed to download installer."
    echo ""
    echo "   Try again later, or download and verify install.sh manually."
    exit 1
fi
echo "  ✅ Installer downloaded"

# Verify installer checksum
echo "  ▸ Verifying checksums..."
if grep -E '^[a-fA-F0-9]{64}[[:space:]]+install\.sh$' "${WORKDIR}/CHECKSUMS.txt" > "${WORKDIR}/install.sha256"; then
    (cd "$WORKDIR" && sha256sum -c install.sha256 --status)
else
    echo "❌ CHECKSUMS.txt does not contain an install.sh checksum."
    exit 1
fi
echo "  ✅ Checksums verified!"

echo ""
echo "✅ Running installer..."
echo ""

# Execute installer
chmod +x "${WORKDIR}/install.sh"
bash "${WORKDIR}/install.sh" "$@"
