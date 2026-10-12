#!/bin/sh
# QUERVEX 1.0.0 installer for Linux, macOS and WSL (no root rights needed).
#
# Downloads the standalone executable of release v1.0.0 (or uses it if it sits next to this
# script), checks its SHA-256 fingerprint, copies it to ~/.local/bin/quervex and offers to add that
# folder to PATH. Without a standalone executable for your machine, falls back to npm (Node.js >= 22).
#
# One-line install:
#   curl -fsSL https://github.com/fthcodexa-be/quervex-cli/releases/download/v1.0.0/install.sh | sh
#
#   --mode=auto|exe|npm   auto (default): standalone executable, otherwise npm
#   --install-dir=DIR     target folder (default: ~/.local/bin)
#   --no-path             never modify shell startup files
#   --yes                 answer yes to every question
set -eu

VERSION="1.0.0"
BASE_URL="${QUERVEX_DOWNLOAD_BASE:-https://github.com/fthcodexa-be/quervex-cli/releases/download/v1.0.0}"
MODE=auto
INSTALL_DIR="$HOME/.local/bin"
NO_PATH=0
YES=0
TMP_FILE=""

for arg in "$@"; do
  case "$arg" in
    --mode=*) MODE="${arg#--mode=}" ;;
    --install-dir=*) INSTALL_DIR="${arg#--install-dir=}" ;;
    --no-path) NO_PATH=1 ;;
    --yes|-y) YES=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

say() { printf '  \033[36m>\033[0m %s\n' "$1"; }
ok()  { printf '  \033[32m+\033[0m %s\n' "$1"; }
die() { printf '  \033[31mx\033[0m %s\n' "$1" >&2; exit 1; }
cleanup() { [ -n "$TMP_FILE" ] && rm -f "$TMP_FILE"; return 0; }
trap cleanup EXIT INT TERM

node_major() {
  command -v node >/dev/null 2>&1 || { echo 0; return; }
  v=$(node --version 2>/dev/null | sed -n 's/^v\([0-9]*\).*/\1/p')
  echo "${v:-0}"
}

ask() {
  [ "$YES" -eq 1 ] && return 0
  [ -r /dev/tty ] || return 1
  printf '  ? %s [y/N] ' "$1"
  read -r answer < /dev/tty || return 1
  case "$answer" in y|Y|yes|o|O|oui) return 0 ;; *) return 1 ;; esac
}

# SHA-256 of the release executables, written by the build: a download is never run unchecked.
expected_sha256() {
  case "$1" in
    quervex-setup-linux-x64) echo "49a6e51063c435cb89b0088accffe1da627426a0e4eab9696a180a62045dc257" ;;
    quervex-setup-linux-arm64) echo "140abd6275aea12246f59c4abe2757ece70f2928d1ae9cd5c4ed5ddbff44cb6b" ;;
    quervex-setup-macos-x64) echo "" ;;
    quervex-setup-macos-arm64) echo "" ;;
    *) echo "" ;;
  esac
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1
  else die "sha256sum or shasum is required to check the download."
  fi
}

# HTTPS only from GitHub; a mirror set in QUERVEX_DOWNLOAD_BASE may use another protocol
# (the SHA-256 fingerprint is checked in every case).
download() {
  if command -v curl >/dev/null 2>&1; then
    if [ -n "${QUERVEX_DOWNLOAD_BASE:-}" ]; then curl -fsSL -o "$2" "$1"; else curl -fsSL --proto '=https' --tlsv1.2 -o "$2" "$1"; fi
  elif command -v wget >/dev/null 2>&1; then
    if [ -n "${QUERVEX_DOWNLOAD_BASE:-}" ]; then wget -q -O "$2" "$1"; else wget -q --https-only -O "$2" "$1"; fi
  else die "curl or wget is required to download QUERVEX."
  fi
}

printf '\n  \033[35mQUERVEX %s - installer\033[0m\n\n' "$VERSION"

case "$(uname -s)" in
  Linux) OS=linux ;;
  Darwin) OS=macos ;;
  *) die "Unsupported system: $(uname -s). On Windows, use install.ps1 (PowerShell)." ;;
esac
case "$(uname -m)" in
  x86_64|amd64) ARCH=x64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *) ARCH=$(uname -m) ;;
esac

ASSET="quervex-setup-$OS-$ARCH"
EXPECTED=$(expected_sha256 "$ASSET")
# Directory of this script; when piped (curl | sh) $0 is the shell, so nothing is found next to it.
HERE=$(cd "$(dirname "$0")" 2>/dev/null && pwd || echo "")

if [ "$MODE" = auto ]; then
  if [ -n "$EXPECTED" ]; then MODE=exe
  elif [ "$(node_major)" -ge 22 ]; then
    say "No standalone executable for $OS-$ARCH in this release: installing with npm."
    MODE=npm
  else die "No standalone executable for $OS-$ARCH and Node.js >= 22 was not found. Install Node.js (https://nodejs.org) and run this script again."
  fi
fi

if [ "$MODE" = exe ]; then
  [ -n "$EXPECTED" ] || die "No standalone executable for $OS-$ARCH in this release."
  if [ -n "$HERE" ] && [ -f "$HERE/$ASSET" ]; then
    SOURCE="$HERE/$ASSET"
    say "Using $SOURCE"
  else
    TMP_FILE=$(mktemp "${TMPDIR:-/tmp}/quervex.XXXXXX")
    SOURCE="$TMP_FILE"
    say "Downloading $BASE_URL/$ASSET"
    download "$BASE_URL/$ASSET" "$SOURCE" || die "Download failed: $BASE_URL/$ASSET"
  fi
  ACTUAL=$(sha256_of "$SOURCE")
  [ "$ACTUAL" = "$EXPECTED" ] || die "SHA-256 mismatch for $ASSET (expected $EXPECTED, got $ACTUAL): file rejected."
  ok "SHA-256 fingerprint verified"

  say "Installing to $INSTALL_DIR"
  mkdir -p "$INSTALL_DIR"
  # Copy then rename: replaces a running quervex safely.
  cp "$SOURCE" "$INSTALL_DIR/quervex.new"
  chmod 755 "$INSTALL_DIR/quervex.new"
  mv -f "$INSTALL_DIR/quervex.new" "$INSTALL_DIR/quervex"
  if [ "$OS" = macos ]; then xattr -d com.apple.quarantine "$INSTALL_DIR/quervex" 2>/dev/null || true; fi
  ok "Copied to $INSTALL_DIR/quervex"

  case ":$PATH:" in
    *":$INSTALL_DIR:"*) ok "$INSTALL_DIR is already in PATH" ;;
    *)
      if [ "$NO_PATH" -eq 0 ]; then
        case "$(basename "${SHELL:-sh}")" in
          zsh) RC="$HOME/.zshrc" ;;
          bash) RC="$HOME/.bashrc" ;;
          *) RC="$HOME/.profile" ;;
        esac
        if [ -f "$RC" ] && grep -q '# Added by the QUERVEX installer' "$RC"; then
          ok "PATH already set in $RC"
        elif ask "Add $INSTALL_DIR to PATH in $RC?"; then
          printf '\n# Added by the QUERVEX installer\nexport PATH="%s:$PATH"\n' "$INSTALL_DIR" >> "$RC"
          ok "PATH updated in $RC"
        else
          say "Add this line to your shell profile: export PATH=\"$INSTALL_DIR:\$PATH\""
        fi
      fi
      ;;
  esac
  CHECK=$("$INSTALL_DIR/quervex" --version)
else
  [ "$(node_major)" -ge 22 ] || die "Node.js >= 22 is required for the npm install."
  say "npm install -g quervex@$VERSION"
  npm install -g "quervex@$VERSION" || die "npm install failed (try with sudo, or configure an npm prefix in your home folder)."
  CHECK=$(quervex --version)
fi

[ "$CHECK" = "$VERSION" ] || die "The installed program does not start correctly (got: $CHECK)."
printf '\n'
ok "QUERVEX $CHECK installed."
printf '  Open a NEW terminal and type: \033[36mquervex\033[0m\n\n'
