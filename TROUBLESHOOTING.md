# Troubleshooting

## `command not found: claude`

```bash
source ~/.bashrc
```

Kalau masih gagal:
```bash
alias claude="grun /data/data/com.termux/files/usr/lib/node_modules/@anthropic-ai/claude-code-linux-arm64/claude"
```

---

## `grun: command not found`

```bash
pkg install glibc-repo -y
pkg update
pkg install glibc-runner -y
```

---

## `claude --version` keluar error / crash

Verify binary langsung:
```bash
grun /data/data/com.termux/files/usr/lib/node_modules/@anthropic-ai/claude-code-linux-arm64/claude --version
```

Kalau masih crash, re-run installer:
```bash
curl -fsSL https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/install.sh | bash
```

---

## API key error / unauthorized

Cek `~/.claude/settings.json`:
```bash
cat ~/.claude/settings.json
```

Edit kalau perlu:
```bash
nano ~/.claude/settings.json
```

---

## Platform detection error

Patch mungkin tidak masuk. Re-run installer otomatis patch ulang. Atau manual:

```bash
nano /data/data/com.termux/files/usr/lib/node_modules/@anthropic-ai/claude-code/cli-wrapper.cjs
```

Cari: `const platform = process.platform`

Ganti dengan:
```js
const platform =
  process.platform === 'android'
    ? 'linux'
    : process.platform
```

Lakukan hal yang sama di `install.cjs`.

---

## Setelah `pkg upgrade`, claude rusak

Upgrade bisa overwrite node_modules. Re-run installer.

---

## Lambat / hang saat pertama launch

Normal — glibc-runner perlu init pertama kali. Tunggu ~5 detik.
