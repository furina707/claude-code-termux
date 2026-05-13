#!/data/data/com.termux/files/usr/bin/bash

# Claude Code Wrapper untuk Termux
# Supports: claude, claude --update, claude [args...]

CLAUDE_BINARY="/data/data/com.termux/files/usr/lib/node_modules/@anthropic-ai/claude-code-linux-arm64/claude"
INSTALLER_URL="https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/install.sh"

case "$1" in
  --update|-u|update)
    echo "🔄 Updating Claude Code..."
    echo ""
    curl -fsSL "$INSTALLER_URL" | bash
    ;;
  --help|-h)
    echo "Claude Code - Usage:"
    echo ""
    echo "  claude              Start Claude Code"
    echo "  claude --update     Update Claude Code ke versi terbaru"
    echo "  claude --version    Show version"
    echo "  claude --help       Show this help"
    echo ""
    ;;
  *)
    if [ -z "$1" ]; then
      # No args - run normally
      exec grun "$CLAUDE_BINARY" "${@}"
    elif [ "$1" = "--version" ] || [ "$1" = "-v" ]; then
      exec grun "$CLAUDE_BINARY" "${@}"
    else
      # Pass through other flags to claude
      exec grun "$CLAUDE_BINARY" "${@}"
    fi
    ;;
esac