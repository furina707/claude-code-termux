# Troubleshooting

## `command not found: claude`

```bash
source ~/.bashrc
```

Kalau masih gagal, cek PATH:
```bash
export PATH="${PATH}:/data/data/com.termux/files/usr/bin"
```

Atau jalankan langsung:
```bash
/data/data/com.termux/files/usr/bin/claude --version
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

Upgrade bisa overwrite node_modules. Re-run installer:
```bash
curl -fsSL https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/install.sh | bash
```

---

## Update gagal / binary error

Kalau setelah update muncul error kayak:
- `Illegal instruction`
- `Segmentation fault`
- Binary tidak ditemukan

Solusi:
1. Cek versi yang terinstall:
   ```bash
   ls /data/data/com.termux/files/usr/lib/node_modules/@anthropic-ai/
   ```
2. Re-run installer:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/install.sh | bash
   ```
3. Kalau masih gagal, uninstall dulu lalu install ulang:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/uninstall.sh | bash
   curl -fsSL https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/install.sh | bash
   ```

---

## Setelah update, perlu setup ulang?

Tidak perlu. Settings lo tersimpan di `~/.claude/settings.json` —installer tidak akan overwrite API key lo.

Tapi perlu re-run installeragar patch platform terapply ke versi baru.

---

## Lambat / hang saat pertama launch

Normal — glibc-runner perlu init pertama kali. Tunggu ~5 detik.

---

## Update via CLI

Cara termudah update Claude Code:
```bash
claude --update
```

Atau pakai installer langsung:
```bash
curl -fsSL https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/install.sh | bash
```
