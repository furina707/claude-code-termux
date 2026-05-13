# Build Rust Wrapper untuk Android ARM64

## Cara Build

### Method 1: Build di Termux langsung

```bash
# Install Rust
pkg install rust

# Clone repo
cd ~/claude-code-termux/rust-wrapper

# Build dengan musl target untuk static binary
cargo build --release --target aarch64-linux-musl

# Output ada di target/aarch64-linux-musl/release/claude-termux
```

### Method 2: Cross-compile dari PC

**Install cross-compile toolchain:**
```bash
# macOS
rustup target add aarch64-unknown-linux-gnu

# Linux
rustup target add aarch64-unknown-linux-gnu
# + install gcc-aarch64-linux-gnu

# Windows (WSL)
rustup target add aarch64-unknown-linux-gnu
```

**Build:**
```bash
cd rust-wrapper
cargo build --release --target aarch64-unknown-linux-gnu
```

### Method 3: Build static binary (recommend untuk Termux)

```bash
# Di Termux
pkg install rust binutils

# Build static
RUSTFLAGS="-C target-feature=+crt-static" cargo build --release

# Atau pakai musl
cargo build --release --target aarch64-unknown-linux-musl
```

## Output

Binary akan ada di:
- `target/release/claude-termux` (jika di Termux)
- `target/aarch64-unknown-linux-gnu/release/claude-termux` (cross-compile)

## Install ke Termux

```bash
# Copy binary ke PATH
cp target/aarch64-unknown-linux-gnu/release/claude-termux \
   /data/data/com.termux/files/usr/bin/claude

# Make executable
chmod +x /data/data/com.termux/files/usr/bin/claude

# Test
claude --help
```

## Build Notes

- Minimum Rust version: 1.70+
- Dependencies sudah pakai `anyhow` untuk error handling yang baik
- `crossterm` untuk cross-platform terminal operations
- `clap` untuk CLI argument parsing

## Troubleshooting

### "linker `aarch64-linux-gnu-gcc` not found"
```bash
# Ubuntu/Debian
sudo apt install gcc-aarch64-linux-gnu

# macOS
# Hanya bisa cross-compile via Docker atau Linux VM
```

### Static build gagal
```bash
# Install musl target
rustup target add aarch64-unknown-linux-musl

# Build
cargo build --release --target aarch64-unknown-linux-musl
```