#!/data/data/com.termux/files/usr/bin/bash
# Simple install - just run this one command
# curl -fsSL https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/install.sh | bash

set -euo pipefail

echo "🔧 Installing Claude Code for Termux..."

# Check ARM64
[[ "$(uname -m)" == "aarch64" ]] || { echo "Only ARM64 supported"; exit 1; }

# Install deps - try multiple package names for glibc-runner
echo "📦 Installing packages..."
pkg update -y -q 2>/dev/null || true
pkg install -y nodejs-lts git wget 2>/dev/null || true

# Try different names for glibc-runner
if ! command -v grun &>/dev/null; then
    echo "🔍 Looking for glibc-runner..."
    pkg install -y grun 2>/dev/null || \
    pkg install -y glibc-runner 2>/dev/null || \
    pkg install -y termux-api 2>/dev/null || true
fi

# Create temp dir in PREFIX (writable)
TEMP_DIR="/data/data/com.termux/files/usr/tmp"
mkdir -p "$TEMP_DIR"
WORK_DIR="$(mktemp -d "${TEMP_DIR}/claude-install.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

# Install Claude Code JS layer
echo "📥 Downloading Claude Code..."
npm install -g @anthropic-ai/claude-code 2>/dev/null || true

# Install native binary directly
echo "📥 Downloading native binary..."
ARM_DIR="/data/data/com.termux/files/usr/lib/node_modules/@anthropic-ai/claude-code-linux-arm64"
mkdir -p "$ARM_DIR"
VERSION=$(npm view @anthropic-ai/claude-code-linux-arm64 version 2>/dev/null || echo "2.1.141")
[[ "$VERSION" =~ ^[0-9]+(\.[0-9]+){2}(-[0-9A-Za-z.-]+)?$ ]] || { echo "Invalid package version: $VERSION"; exit 1; }
echo "   Version: $VERSION"

# Use PREFIX temp dir
TARBALL="${WORK_DIR}/claude.tgz"
EXTRACT_DIR="${WORK_DIR}/extract"
mkdir -p "$EXTRACT_DIR"
echo "   Downloading..."

if curl --proto '=https' --tlsv1.2 -fSL "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64/-/claude-code-linux-arm64-${VERSION}.tgz" -o "$TARBALL"; then
    echo "   Extracting..."
    while IFS= read -r entry; do
        case "$entry" in
            ""|/*|../*|*/../*|*"/.."|*"/../"*) echo "Unsafe tar entry: $entry"; exit 1 ;;
        esac
    done < <(tar -tzf "$TARBALL")
    tar -xzf "$TARBALL" -C "$EXTRACT_DIR"
    [[ -f "$EXTRACT_DIR/package/claude" ]] || { echo "   ❌ Claude binary missing from package"; exit 1; }
    install -m 0755 "$EXTRACT_DIR/package/claude" "$ARM_DIR/claude"
    echo "   ✓ Binary installed"
else
    echo "   ⚠️ Download failed"
fi

# Install npm wrapper (postinstall writes the proper Node wrapper automatically)
# This ensures claude update / claude manager work correctly.
echo "📥 Installing npm wrapper..."
npm install -g --force @xurxuo/claude-code-termux@latest 2>/dev/null || true
echo "   ✓ Wrapper created"

# Test
echo ""
echo "✅ Done!"
claude --version 2>/dev/null || echo "Installed (run claude --version to verify)"

echo ""
echo "       claude --version  (test)"
echo "       claude            (start)"
echo "       claude update     (force update)"
echo "       claude manager    (package manager)"
echo ""
echo "⚠️  Set API key: export ANTHROPIC_API_KEY=sk-ant-..."
