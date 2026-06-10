#!/usr/bin/env bash
# deploy.sh — install dotfiles, backing up any originals first
# Usage: ./deploy.sh [--dry-run]

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# ── Mapping: repo path → target path ────────────────────────────
declare -A FILES=(
  [".zshrc"]="$HOME/.zshrc"
  [".tmux.conf"]="$HOME/.tmux.conf"
  [".config/nvim/init.lua"]="$HOME/.config/nvim/init.lua"
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

echo ""
echo "done."
if [[ -d "$BACKUP_DIR" ]]; then
  echo "originals backed up to: $BACKUP_DIR"
fi
echo ""

# ── Post-install hints ───────────────────────────────────────────
if ! $DRY_RUN; then
  echo "next steps:"
  echo "  source ~/.zshrc"
  echo "  nvim  (runs :Lazy sync on first open)"
  echo ""
  echo "optional:"
  echo "  sudo apt install clangd bat ripgrep fzf"
  echo "  pip install pwntools python-lsp-server --break-system-packages"
fi
