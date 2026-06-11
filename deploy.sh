#!/usr/bin/env bash
# deploy.sh — install dotfiles, backing up any originals first
# Usage: ./deploy.sh [--dry-run]

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "run as your user, not root — sudo is used internally where needed"
  exit 1
fi

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# ── Mapping: repo path → target path ────────────────────────────
declare -A FILES=(
  [".zshrc"]="$HOME/.zshrc"
  [".tmux.conf"]="$HOME/.tmux.conf"
  [".config/nvim/init.lua"]="$HOME/.config/nvim/init.lua"
  [".config/alacritty/alacritty.toml"]="$HOME/.config/alacritty/alacritty.toml"
  [".local/bin/lab-session"]="$HOME/.local/bin/lab-session"
)

# ── Helpers ──────────────────────────────────────────────────────
log()    { echo "  $*"; }
backup() {
  local target="$1"
  local rel="${target#$HOME/}"
  local dest="$BACKUP_DIR/$rel"
  mkdir -p "$(dirname "$dest")"
  cp -a "$target" "$dest"
  log "backed up: ~/$rel → $BACKUP_DIR/$rel"
}
link() {
  local src="$DOTFILES/$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  if $DRY_RUN; then
    log "[dry-run] would link: $dst → $src"
    return
  fi
  # back up real files (not existing symlinks pointing here already)
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    backup "$dst"
    rm -f "$dst"
  elif [[ -L "$dst" ]]; then
    rm -f "$dst"
  fi
  ln -s "$src" "$dst"
  log "linked: $dst"
}

# ── Main ─────────────────────────────────────────────────────────
echo ""
echo "dotfiles deploy — $(date)"
$DRY_RUN && echo "(dry run — no changes will be made)"
echo ""

for repo_path in "${!FILES[@]}"; do
  link "$repo_path" "${FILES[$repo_path]}"
done

# lab-session needs execute bit
if ! $DRY_RUN; then
  chmod +x "$HOME/.local/bin/lab-session"
fi

# ── System packages ──────────────────────────────────────────────
if ! $DRY_RUN; then
  log "installing apt packages..."
  sudo apt-get install -y alacritty clangd bat ripgrep fzf

  if command -v update-alternatives &>/dev/null; then
    sudo update-alternatives --set x-terminal-emulator /usr/bin/alacritty 2>/dev/null \
      && log "set alacritty as default x-terminal-emulator" \
      || log "note: update-alternatives failed (alacritty not in alternatives db)"
  fi

  log "installing neovim (latest stable)..."
  NVIM_TMP="$(mktemp -d)"
  curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" \
    | tar -xz -C "$NVIM_TMP"
  sudo rm -rf /opt/nvim-linux-x86_64
  sudo mv "$NVIM_TMP/nvim-linux-x86_64" /opt/
  sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
  rm -rf "$NVIM_TMP"
  log "neovim installed: $(/usr/local/bin/nvim --version | head -1)"

  log "installing tree-sitter cli (required by nvim-treesitter main branch)..."
  mkdir -p "$HOME/.local/bin"
  curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz" \
    | gunzip > "$HOME/.local/bin/tree-sitter"
  chmod +x "$HOME/.local/bin/tree-sitter"
  log "tree-sitter installed: $("$HOME/.local/bin/tree-sitter" --version)"
fi

# ── Python packages ───────────────────────────────────────────────
if ! $DRY_RUN; then
  log "installing python packages..."
  if [[ $EUID -eq 0 ]]; then
    pip3 install --break-system-packages python-lsp-server pwntools
  else
    pip3 install --break-system-packages --user python-lsp-server pwntools
  fi
fi

echo ""
echo "done."
if [[ -d "$BACKUP_DIR" ]]; then
  echo "originals backed up to: $BACKUP_DIR"
fi
echo ""
echo "next steps:"
echo "  source ~/.zshrc"
echo "  nvim  (runs :Lazy sync on first open)"
