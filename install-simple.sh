#!/data/data/com.termux/files/usr/bin/bash
# Simple install - just run this one command
# curl -fsSL https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/install.sh | bash

set -euo pipefail

echo "🔧 Installing Claude Code for Termux..."

# Check ARM64
[[ "$(uname -m)" == "aarch64" ]] || { echo "Only ARM64 supported"; exit 1; }

# Install deps
echo "📦 Installing packages..."
pkg update -y -q 2>/dev/null || true
pkg install -y nodejs-lts grun git wget 2>/dev/null || pkg install -y nodejs-lts grun

# Install Claude Code JS layer
echo "📥 Downloading Claude Code..."
npm install -g @anthropic-ai/claude-code 2>/dev/null || true

# Install native binary directly
echo "📥 Downloading native binary..."
ARM_DIR="/data/data/com.termux/files/usr/lib/node_modules/@anthropic-ai/claude-code-linux-arm64"
mkdir -p "$ARM_DIR"
VERSION=$(npm view @anthropic-ai/claude-code-linux-arm64 version 2>/dev/null || echo "2.1.141")
curl -fsSL "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64/-/claude-code-linux-arm64-${VERSION}.tgz" -o /tmp/claude.tgz
tar -xzf /tmp/claude.tgz -C "$ARM_DIR"
mv "$ARM_DIR/package/claude" "$ARM_DIR/claude" 2>/dev/null || true
rm -rf "$ARM_DIR/package" /tmp/claude.tgz

# CRITICAL: Create wrapper that uses grun + native binary
echo "🔧 Creating wrapper..."
cat > /data/data/com.termux/files/usr/bin/claude << 'WRAPPER'
#!/bin/bash
exec grun /data/data/com.termux/files/usr/lib/node_modules/@anthropic-ai/claude-code-linux-arm64/claude "$@"
WRAPPER
chmod +x /data/data/com.termux/files/usr/bin/claude

# Backup npm wrapper to prevent overwrite
if [[ -f "/data/data/com.termux/files/usr/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe" ]]; then
    mv /data/data/com.termux/files/usr/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe /data/data/com.termux/files/usr/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe.bak 2>/dev/null || true
fi

# Test
echo ""
echo "✅ Done! Testing..."
grun /data/data/com.termux/files/usr/lib/node_modules/@anthropic-ai/claude-code-linux-arm64/claude --version 2>/dev/null || echo "Binary installed, run 'claude' to start"

echo ""
echo "Usage: claude --version  (test)"
echo "       claude             (start)"
echo ""
echo "⚠️  Set API key: export ANTHROPIC_API_KEY=sk-ant-..."