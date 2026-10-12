#!/bin/sh
# QUERVEX uninstaller for macOS / Linux.
#   --install-dir=DIR   folder used at install time (default: ~/.local/bin)
#   --purge             also delete ~/.quervex (history, profiles, .env)
set -eu

INSTALL_DIR="$HOME/.local/bin"
PURGE=0
for arg in "$@"; do
  case "$arg" in
    --install-dir=*) INSTALL_DIR="${arg#--install-dir=}" ;;
    --purge) PURGE=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

ok() { printf '  \033[32m+\033[0m %s\n' "$1"; }

printf '\n  \033[35mQUERVEX - uninstaller\033[0m\n\n'

if [ -f "$INSTALL_DIR/quervex" ]; then
  rm -f "$INSTALL_DIR/quervex"
  ok "Removed $INSTALL_DIR/quervex"
fi

for RC in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
  if [ -f "$RC" ] && grep -q '# Added by the QUERVEX installer' "$RC"; then
    # Removes the comment line and the export line that follows it.
    sed -i.quervex-bak '/# Added by the QUERVEX installer/{N;d;}' "$RC" && rm -f "$RC.quervex-bak"
    ok "PATH entry removed from $RC"
  fi
done

if command -v npm >/dev/null 2>&1 && npm ls -g --depth=0 quervex 2>/dev/null | grep -q 'quervex@'; then
  npm uninstall -g quervex >/dev/null && ok "npm package removed"
fi

if [ "$PURGE" -eq 1 ] && [ -d "$HOME/.quervex" ]; then
  rm -rf "$HOME/.quervex"
  ok "Removed $HOME/.quervex"
fi

printf '\n'
ok "QUERVEX uninstalled."
printf '\n'
