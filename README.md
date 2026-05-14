# Claude Code Termux

**Run Claude Code natively on Android — no Linux distro, no proot needed.**

---

## What is this?

Claude Code is an AI coding assistant. This project lets you run it on your Android phone using Termux — no computer needed!

### Requirements

- Android phone with ARM64 processor (most modern phones)
- [Termux app from F-Droid](https://f-droid.org/en/packages/com.termux/)
- [Anthropic API key](https://console.anthropic.com/settings/keys) (free to get)

---

## Quick Install (Recommended)

Copy and paste this in Termux:

```bash
curl -fsSL https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/install.sh | bash
```

That's it! The installer will:
1. Install required packages (nodejs, grun)
2. Download Claude Code
3. Ask for your API key

---

## Alternative: Install via NPM

If the quick install doesn't work, try this:

```bash
pkg update && pkg install nodejs-lts
npm install -g @xurxuo/claude-code-termux
```

---

## Alternative: Use Shell Wrapper (Recommended)

This is a simple shell script that you can read and verify before running:

```bash
# Download and review the script first
curl -fsSL https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/claude-wrapper.sh -o /tmp/claude-wrapper.sh

# Read it - it's just bash, easy to audit!
cat /tmp/claude-wrapper.sh

# If OK, install it
mv /tmp/claude-wrapper.sh $PREFIX/bin/claude
chmod +x $PREFIX/bin/claude
```

Benefits:
- **Transparent** - anyone can read the code
- **Auditable** - no black box binary
- **Safe** - verify before running

---

**⚠️ Avoid: Pre-compiled ELF Binary**

The `claude-termux` binary is a compiled ELF that cannot be easily audited. Use the shell wrapper instead.

---

## Get Your API Key

1. Go to [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)
2. Click "Create Key"
3. Copy the key
4. In Termux, run:
   ```bash
   export ANTHROPIC_API_KEY=sk-ant-your-key-here
   ```

Or add it to your settings:
```bash
nano ~/.claude/settings.json
```

Add:
```json
{
  "apiKey": "sk-ant-your-key-here"
}
```

---

## How to Use

| Command | What it does |
|---------|--------------|
| `claude` | Start Claude Code |
| `claude --version` | Check version |
| `claude update` | Update to latest version |
| `claude install` | Reinstall dependencies |
| `claude uninstall` | Remove Claude Code |
| `claude --dangerously-skip-permissions` | Run without permission prompts (advanced) |

### About --dangerously-skip-permissions

This flag tells Claude Code to **skip all permission prompts** and run any tool/command automatically.

**What it does:**
- Claude can execute any shell command without asking first
- Claude can read/write any file without asking
- No confirmation needed for dangerous operations

**⚠️ Risks (use with caution):**
- Can accidentally delete important files
- Can run harmful commands (like `rm -rf /`)
- No protection against mistakes
- Use only when you understand what you're doing

**When to use:**
- Running automated scripts
- Batch operations you trust
- When you're watching and can stop it if needed

**Example:**
```bash
claude --dangerously-skip-permissions
```

---

## First Time Setup

1. **Get API key** (see above)
2. **Run Claude:**
   ```bash
   claude
   ```
3. **Start coding!** Ask Claude to help you write code, debug, or learn programming.

---

## Update

```bash
claude update
```

Or reinstall:
```bash
npm install -g @xurxuo/claude-code-termux
```

---

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/uninstall.sh | bash
```

Or manually:
```bash
npm uninstall -g @xurxuo/claude-code-termux @anthropic-ai/claude-code @anthropic-ai/claude-code-linux-arm64
rm $PREFIX/bin/claude
```

**Note:** Your settings (`~/.claude/settings.json`) will be kept.

---

## Troubleshooting

### "npm error EBADPLATFORM"
This is normal on Android. The installer will download the binary directly.

### "API key not found"
Make sure you exported your API key:
```bash
export ANTHROPIC_API_KEY=sk-ant-...
```

### "Permission denied"
Make sure the binary is executable:
```bash
chmod +x $PREFIX/bin/claude
```

---

## Security Audit

The shell wrapper is fully transparent. You can read and verify it before running.

### What it does (from source):
- Checks if `grun` and `node` are installed
- Runs `grun` or `node` to execute Claude Code
- Handles `--update`, `--uninstall`, `--version`, `--help` commands

### What it does NOT do:
- Download or execute arbitrary code
- Write to arbitrary filesystem
- Modify your settings
- Run any hidden commands

### How to verify:
```bash
# 1. Download and read the wrapper
curl -fsSL https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/claude-wrapper.sh | less

# 2. Verify it's just bash (no base64 encoded binaries)
curl -fsSL https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/claude-wrapper.sh | head -20
```

---

## Need Help?

- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Open an issue on GitHub

---

*Built for Android. Built for developers.*