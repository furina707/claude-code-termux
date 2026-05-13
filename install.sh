#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────
#  Claude Code Termux — install.sh
#  github.com/DamnSit/claude-code-termux
#
#  curl -fsSL https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/install.sh | bash
# ─────────────────────────────────────────────────────────────

set -uo pipefail

# ── colors ────────────────────────────────────────────────────
BLD='\033[1m'
RED='\033[1;31m'
GRN='\033[1;32m'
YLW='\033[1;33m'
CYN='\033[1;36m'
DIM='\033[2m'
NC='\033[0m'

log()  { printf "\n${CYN}▸${NC} %s\n" "$*"; }
ok()   { printf "  ${GRN}✓${NC} %s\n" "$*"; }
warn() { printf "  ${YLW}!${NC} %s\n" "$*"; }
die()  { printf "\n${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }
sep()  { printf "\n${BLD}── %s ──────────────────────────────────────${NC}\n" "$*"; }

# ── constants ─────────────────────────────────────────────────
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
MOD_DIR="${PREFIX}/lib/node_modules"
CC_DIR="${MOD_DIR}/@anthropic-ai/claude-code"
ARM_DIR="${MOD_DIR}/@anthropic-ai/claude-code-linux-arm64"
CLAUDE_BIN="${ARM_DIR}/claude"
WRAPPER="${PREFIX}/bin/claude"
CFG_DIR="${HOME}/.claude"
CFG="${CFG_DIR}/settings.json"

# rc files
BASHRC="${HOME}/.bashrc"
ZSHRC="${HOME}/.zshrc"

# ── header ────────────────────────────────────────────────────
clear
printf "${CYN}${BLD}"
cat << 'EOF'
   ██████╗██╗      █████╗ ██╗   ██╗██████╗ ███████╗
  ██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██╔════╝
  ██║     ██║     ███████║██║   ██║██║  ██║█████╗
  ██║     ██║     ██╔══██║██║   ██║██║  ██║██╔══╝
  ╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝███████╗
   ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝
EOF
printf "${NC}"
printf "\n  ${BLD}Claude Code Termux${NC}  —  Native ARM64 + glibc-runner\n"
printf "  ${DIM}No Ubuntu. No proot-distro. Full native binary.${NC}\n\n"

# ── guard ─────────────────────────────────────────────────────
[[ "$(uname -m)" == "aarch64" ]] || die "Hanya support ARM64 (aarch64)"
[[ -d "$PREFIX" ]]               || die "Termux PREFIX tidak ditemukan"

# ── step 1: update ────────────────────────────────────────────
sep "1/7  Update packages"
log "pkg update & upgrade..."
pkg update -y -q 2>/dev/null || true
pkg upgrade -y -q 2>/dev/null || true
ok "packages up to date"

# ── step 2: deps ──────────────────────────────────────────────
sep "2/7  Dependencies"
log "install nodejs-lts git wget patchelf proot tar..."
pkg install -y -q nodejs-lts git wget patchelf proot tar 2>/dev/null || \
    pkg install -y nodejs-lts git wget patchelf proot tar
ok "deps ok — node $(node -v)  npm $(npm -v)"

# ── step 3: claude code ───────────────────────────────────────
sep "3/7  Install @anthropic-ai/claude-code"
log "npm install (latest)..."
npm install -g @anthropic-ai/claude-code --force \
    2>&1 | grep -vE '^npm (warn|notice)' || true
[[ -d "$CC_DIR" ]] || die "claude-code install gagal"
ok "installed → $CC_DIR"

# ── step 4: linux arm64 binary ────────────────────────────────
sep "4/7  Install native Linux ARM64 binary"
log "npm install @anthropic-ai/claude-code-linux-arm64..."
npm install -g @anthropic-ai/claude-code-linux-arm64 --force \
    2>&1 | grep -vE '^npm (warn|notice)' || true
[[ -f "$CLAUDE_BIN" ]] || die "linux-arm64 binary tidak ditemukan di $CLAUDE_BIN"
chmod +x "$CLAUDE_BIN"
ok "binary → $CLAUDE_BIN"

# ── step 5: patch platform detection ─────────────────────────
sep "5/7  Patch platform detection"

patch_file() {
    local file="$1"
    local label="$2"

    if [[ ! -f "$file" ]]; then
        warn "$label tidak ditemukan, skip"
        return
    fi

    # Cek apakah sudah di-patch
    if grep -q "process.platform === 'android'" "$file" 2>/dev/null; then
        ok "$label sudah di-patch sebelumnya"
        return
    fi

    # Backup
    cp "$file" "${file}.bak"

    # Patch: ganti `process.platform` ke ternary android→linux
    # Pakai temp file (lebih aman dari in-place sed di Termux)
    local tmp="${file}.tmp"

    # Cari baris `const platform = process.platform` dan ganti
    awk '
    /const platform = process\.platform[^=]/ {
        print "const platform ="
        print "  process.platform === '"'"'android'"'"'"
        print "    ? '"'"'linux'"'"'"
        print "    : process.platform"
        next
    }
    { print }
    ' "$file" > "$tmp" && mv "$tmp" "$file"

    # Verify patch masuk
    if grep -q "android" "$file"; then
        ok "patched: $label"
    else
        warn "$label patch mungkin tidak masuk — cek manual"
        cp "${file}.bak" "$file"
    fi
}

patch_file "${CC_DIR}/cli-wrapper.cjs" "cli-wrapper.cjs"
patch_file "${CC_DIR}/install.cjs"     "install.cjs"

# ── step 6: glibc-runner ─────────────────────────────────────
sep "6/7  glibc-runner"

if command -v grun &>/dev/null; then
    ok "glibc-runner sudah terinstall: $(grun --version 2>/dev/null || echo 'ok')"
else
    log "install glibc-repo..."
    pkg install -y -q glibc-repo 2>/dev/null || pkg install -y glibc-repo
    pkg update -y -q 2>/dev/null || true
    log "install glibc-runner..."
    pkg install -y -q glibc-runner 2>/dev/null || pkg install -y glibc-runner
    command -v grun &>/dev/null || die "grun tidak ditemukan setelah install"
    ok "glibc-runner ready"
fi

# verify binary jalan via grun
log "verify native binary..."
VER=$(grun "$CLAUDE_BIN" --version 2>/dev/null | head -1 || true)
if [[ -n "$VER" ]]; then
    ok "binary OK → $VER"
else
    warn "binary test gagal — tapi lanjut (mungkin perlu API key)"
fi

# ── step 7: api key + config ──────────────────────────────────
sep "7/7  API Key & Config"

# Load existing settings if available
EXISTING_KEY=""
EXISTING_URL=""
EXISTING_MODEL=""

if [[ -f "$CFG" ]]; then
    log "Load existing settings..."
    EXISTING_KEY=$(grep -o '"ANTHROPIC_API_KEY"[[:space:]]*:[[:space:]]*"[^"]*"' "$CFG" 2>/dev/null | sed 's/.*"\([^"]*\)"$/\1/' | head -1)
    EXISTING_URL=$(grep -o '"ANTHROPIC_BASE_URL"[[:space:]]*:[[:space:]]*"[^"]*"' "$CFG" 2>/dev/null | sed 's/.*"\([^"]*\)"$/\1/' | head -1)
    EXISTING_MODEL=$(grep -o '"ANTHROPIC_MODEL"[[:space:]]*:[[:space:]]*"[^"]*"' "$CFG" 2>/dev/null | sed 's/.*"\([^"]*\)"$/\1/' | head -1)
    [[ -n "$EXISTING_KEY" ]] && ok "API key ditemukan"
    [[ -n "$EXISTING_URL" ]] && ok "Base URL ditemukan"
    [[ -n "$EXISTING_MODEL" ]] && ok "Model ditemukan"
fi

# ── api key ───────────────────────────────────────────────────
FINAL_KEY="${ANTHROPIC_API_KEY:-}"

if [[ -n "$FINAL_KEY" ]]; then
    printf "\n  ${GRN}Key dari env:${NC} %s...\n" "${FINAL_KEY:0:28}"
    printf "  Pakai ini? [Y/n]: "
    read -r ans
    [[ "${ans}" == "n" || "${ans}" == "N" ]] && FINAL_KEY=""
fi

if [[ -z "$FINAL_KEY" ]]; then
    printf "\n  ${BLD}Anthropic API Key${NC}\n"
    [[ -n "$EXISTING_KEY" ]] && printf "  ${GRN}Sekarang:${NC} %s...%s\n" "${EXISTING_KEY:0:20}" "${EXISTING_KEY: -4}"
    printf "  ${DIM}→ console.anthropic.com/settings/keys${NC}\n\n"
    printf "  Key (Enter = keep existing): "
    read -rs raw; echo
    if   [[ -z "$raw" ]];           then [[ -n "$EXISTING_KEY" ]] && FINAL_KEY="$EXISTING_KEY" || warn "dilewati — set manual nanti"; [[ -n "$EXISTING_KEY" ]] && ok "keep existing key" || true
    elif [[ "$raw" == sk-ant-* ]];  then FINAL_KEY="$raw"; ok "key ok"
    else warn "harus diawali sk-ant-  coba lagi"
    fi
fi

# ── base url (opsional, untuk custom endpoint) ────────────────
printf "\n  ${BLD}Base URL${NC} ${DIM}(kosongkan untuk default Anthropic)${NC}\n"
[[ -n "$EXISTING_URL" ]] && printf "  ${GRN}Sekarang:${NC} %s\n" "$EXISTING_URL"
printf "  ${DIM}contoh: https://opencode.ai/zen${NC}\n\n"
printf "  Base URL (Enter = keep existing): "
read -r BASE_URL
[[ -z "$BASE_URL" && -n "$EXISTING_URL" ]] && BASE_URL="$EXISTING_URL" && ok "keep existing URL"

# ── model ─────────────────────────────────────────────────────
DEFAULT_CHOICE="1"
if [[ -n "$EXISTING_MODEL" ]]; then
    case "$EXISTING_MODEL" in
        claude-sonnet-4-5) DEFAULT_CHOICE="1" ;;
        claude-opus-4-5) DEFAULT_CHOICE="2" ;;
        claude-haiku-4-5) DEFAULT_CHOICE="3" ;;
        claude-sonnet-4-0) DEFAULT_CHOICE="4" ;;
        claude-opus-4-0) DEFAULT_CHOICE="5" ;;
        claude-3-7-sonnet-20250219) DEFAULT_CHOICE="6" ;;
        claude-3-5-haiku-20241022) DEFAULT_CHOICE="7" ;;
    esac
fi

printf "\n  ${BLD}Pilih model${NC}\n"
[[ -n "$EXISTING_MODEL" ]] && printf "  ${GRN}Sekarang:${NC} %s\n\n" "$EXISTING_MODEL"
printf "  ${GRN}1)${NC} claude-sonnet-4-5         ${DIM}← recommended${NC}\n"
printf "  2) claude-opus-4-5           ${DIM}paling pintar${NC}\n"
printf "  3) claude-haiku-4-5          ${DIM}paling cepat${NC}\n"
printf "  4) claude-sonnet-4-0\n"
printf "  5) claude-opus-4-0\n"
printf "  6) claude-3-7-sonnet-20250219\n"
printf "  7) claude-3-5-haiku-20241022\n"
printf "  8) custom\n\n"
printf "  Pilihan [${DEFAULT_CHOICE}]: "
read -r choice
[[ -z "$choice" ]] && choice="$DEFAULT_CHOICE"

case "$choice" in
    1) MODEL="claude-sonnet-4-5" ;;
    2) MODEL="claude-opus-4-5" ;;
    3) MODEL="claude-haiku-4-5" ;;
    4) MODEL="claude-sonnet-4-0" ;;
    5) MODEL="claude-opus-4-0" ;;
    6) MODEL="claude-3-7-sonnet-20250219" ;;
    7) MODEL="claude-3-5-haiku-20241022" ;;
    8) printf "  Nama model: "; read -r MODEL; [[ -z "$MODEL" ]] && MODEL="claude-sonnet-4-5" ;;
    *) warn "invalid, pakai default"; MODEL="claude-sonnet-4-5" ;;
esac
ok "model: $MODEL"

# ── tulis settings.json ───────────────────────────────────────
mkdir -p "$CFG_DIR"

# build env block pure bash
ENV_BLOCK="    \"ANTHROPIC_MODEL\": \"${MODEL}\""
[[ -n "$FINAL_KEY" ]] && ENV_BLOCK="${ENV_BLOCK},\n    \"ANTHROPIC_API_KEY\": \"${FINAL_KEY}\""
[[ -n "$BASE_URL"  ]] && ENV_BLOCK="${ENV_BLOCK},\n    \"ANTHROPIC_BASE_URL\": \"${BASE_URL}\""

printf '{\n  "env": {\n%b\n  },\n  "autoUpdatesChannel": "latest"\n}\n' \
    "$ENV_BLOCK" > "$CFG"

ok "~/.claude/settings.json (preserved existing values)"

# ── wrapper script ────────────────────────────────────────────
MARK="# claude-code-termux"
WRAPPER_PATH="${PREFIX}/bin/claude-wrapper"
CLAUDE_EXEC="${PREFIX}/bin/claude"

# Copy wrapper script
log "install wrapper script..."
if [[ -f "$(dirname "$0")/claude-wrapper.sh" ]]; then
    cp "$(dirname "$0")/claude-wrapper.sh" "$WRAPPER_PATH"
    chmod +x "$WRAPPER_PATH"
    ok "wrapper → $WRAPPER_PATH"
else
    # Fallback: buat wrapper inline
    cat > "$WRAPPER_PATH" << 'WRAPPEREOF'
#!/data/data/com.termux/files/usr/bin/bash
CLAUDE_BINARY="/data/data/com.termux/files/usr/lib/node_modules/@anthropic-ai/claude-code-linux-arm64/claude"
INSTALLER_URL="https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/install.sh"

case "$1" in
  --update|-u|update)
    echo "🔄 Updating Claude Code..."
    curl -fsSL "$INSTALLER_URL" | bash
    ;;
  --help|-h)
    echo "Usage: claude [command]"
    echo "  claude              Start Claude Code"
    echo "  claude --update     Update ke versi terbaru"
    echo "  claude --version    Show version"
    ;;
  *)
    exec grun "$CLAUDE_BINARY" "${@}"
    ;;
esac
WRAPPEREOF
    chmod +x "$WRAPPER_PATH"
    ok "inline wrapper → $WRAPPER_PATH"
fi

# Create executable
ln -sf "$WRAPPER_PATH" "$CLAUDE_EXEC" 2>/dev/null || cp "$WRAPPER_PATH" "$CLAUDE_EXEC"
chmod +x "$CLAUDE_EXEC"
ok "claude executable → $CLAUDE_EXEC"

# Add to PATH in rc files
TMPDIR_LINE="export TMPDIR=\"\${TMPDIR:-${PREFIX}/tmp}\""
PATH_LINE="export PATH=\"\${PATH}:${PREFIX}/bin\""

for rc in "$BASHRC" "$ZSHRC"; do
    [[ -f "$rc" ]] || touch "$rc"
    grep -q "$MARK" "$rc" && sed -i "/$MARK/,/^$/d" "$rc"
    printf '\n%s\n%s\n%s\n' "$MARK" "$TMPDIR_LINE" "$PATH_LINE" >> "$rc"
done

ok "PATH updated → ~/.bashrc & ~/.zshrc"

# apply ke session ini
export TMPDIR="${PREFIX}/tmp"
export PATH="${PATH}:${PREFIX}/bin"

# ── smoke test ────────────────────────────────────────────────
sep "Smoke test"
if grun "$CLAUDE_BIN" --version 2>/dev/null | grep -qE "[0-9]+\.[0-9]+"; then
    ok "$(grun "$CLAUDE_BIN" --version 2>/dev/null | head -1)"
else
    warn "smoke test gagal — coba manual: grun $CLAUDE_BIN --version"
fi

# ── done ──────────────────────────────────────────────────────
printf "\n${GRN}${BLD}"
printf "  ╔══════════════════════════════════════════════╗\n"
printf "  ║   ✅  Claude Code Termux siap digunakan!    ║\n"
printf "  ╚══════════════════════════════════════════════╝\n"
printf "${NC}\n"

[[ -n "$FINAL_KEY" ]] \
    && printf "  ${BLD}Key  :${NC} %s...%s\n" "${FINAL_KEY:0:28}" "${FINAL_KEY: -4}" \
    || printf "  ${YLW}Key  : belum di-set — export ANTHROPIC_API_KEY=...${NC}\n"
[[ -n "$BASE_URL" ]] \
    && printf "  ${BLD}URL  :${NC} %s\n" "$BASE_URL"
printf "  ${BLD}Model:${NC} %s\n\n" "$MODEL"
printf "  ${DIM}source ~/.bashrc${NC}    ← load ke session ini\n"
printf "  ${CYN}claude${NC}              ← jalankan\n"
printf "  ${CYN}claude --update${NC}     ← update ke versi terbaru\n\n"
printf "  ${DIM}Jika ada masalah: bash install.sh lagi, atau cek TROUBLESHOOTING.md${NC}\n\n"
