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
KALI=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --kali)    KALI=true ;;
    *) echo "unknown arg: $arg (use --dry-run and/or --kali)"; exit 1 ;;
  esac
done

# ── Mapping: repo path → target path ────────────────────────────
declare -A FILES=(
  [".zshrc"]="$HOME/.zshrc"
  [".tmux.conf"]="$HOME/.tmux.conf"
  [".config/nvim/init.lua"]="$HOME/.config/nvim/init.lua"
  [".config/alacritty/alacritty.toml"]="$HOME/.config/alacritty/alacritty.toml"
  [".config/sway/config"]="$HOME/.config/sway/config"
  [".config/gtk-3.0/settings.ini"]="$HOME/.config/gtk-3.0/settings.ini"
  [".local/bin/lab-session"]="$HOME/.local/bin/lab-session"
)

# Kali "evil twin": swap the three themed configs for the kali/ copies.
# Targets stay the same ($HOME/...); only the repo source path changes.
# (alacritty is host-side over SSH, so it stays the host copy.)
if $KALI; then
  unset 'FILES[.zshrc]' 'FILES[.tmux.conf]' 'FILES[.config/nvim/init.lua]'
  # sway + GTK theme are host-only (the Kali box is headless)
  unset 'FILES[.config/sway/config]'
  unset 'FILES[.config/gtk-3.0/settings.ini]'
  FILES["kali/.zshrc"]="$HOME/.zshrc"
  FILES["kali/.tmux.conf"]="$HOME/.tmux.conf"
  FILES["kali/.config/nvim/init.lua"]="$HOME/.config/nvim/init.lua"
fi

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
$KALI    && echo "(kali evil-twin set)"
$DRY_RUN && echo "(dry run — no changes will be made)"
echo ""

for repo_path in "${!FILES[@]}"; do
  link "$repo_path" "${FILES[$repo_path]}"
done

# lab-session needs execute bit
if ! $DRY_RUN; then
  chmod +x "$HOME/.local/bin/lab-session"
fi

# ── GTK dark theme (host desktop only; the kali box is headless) ──
# settings.ini (symlinked above) themes GTK3 apps. GTK4/libadwaita apps and
# the cursor are dconf-backed, so apply those via gsettings here. Theme
# providers: gnome-themes-extra (Adwaita-dark), breeze-icon-theme (icons).
if ! $DRY_RUN && ! $KALI; then
  log "installing GTK dark-theme assets..."
  sudo apt-get install -y gnome-themes-extra breeze-icon-theme
  if command -v gsettings &>/dev/null; then
    log "applying GTK theme via gsettings (GTK4/libadwaita + cursor)..."
    gsettings set org.gnome.desktop.interface gtk-theme    'Adwaita-dark' || true
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'  || true
    gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'      || true
    gsettings set org.gnome.desktop.interface icon-theme   'breeze-dark'  || true
  fi
fi

# ── Wayland login: greetd on VT1 (host desktop only) ──────────────
# tuigreet (in greetd) launches sway. greetd is pinned to vt = 1, so
# getty@tty1 MUST be masked or the two fight over the console — the
# symptom is a garbled greeter that bounces you back to a text login.
# Text consoles stay available on Ctrl+Alt+F2–F6 (logind autovt).
# greetd is only enabled here, never started/restarted: it takes effect
# on next reboot so this never kills the session running deploy.sh.
if ! $DRY_RUN && ! $KALI; then
  log "installing sway desktop + greetd login stack..."
  sudo apt-get install -y \
    greetd tuigreet sway swaylock swayidle waybar fuzzel mako-notifier \
    network-manager-gnome lxqt-policykit brightnessctl grim slurp \
    wl-clipboard wireplumber

  log "installing greetd config to /etc/greetd/config.toml..."
  sudo install -Dm644 "$DOTFILES/etc/greetd/config.toml" /etc/greetd/config.toml

  log "masking getty@tty1 (greetd owns VT1)..."
  sudo systemctl mask getty@tty1.service

  log "enabling greetd (takes effect on next reboot)..."
  sudo systemctl enable greetd.service
fi

# ── System packages ──────────────────────────────────────────────
if ! $DRY_RUN; then
  log "installing apt packages..."
  sudo apt-get install -y alacritty clangd bat ripgrep fzf unzip

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

  if $KALI; then
    log "kali set: skipping Nerd Font install (glyphs render on the SSH client)"
  elif fc-list | grep -qi "JetBrainsMono Nerd Font"; then
    log "JetBrainsMono Nerd Font already installed, skipping"
  else
    log "installing JetBrainsMono Nerd Font (prompt/status glyphs)..."
    FONT_DIR="$HOME/.local/share/fonts"
    FONT_TMP="$(mktemp -d)"
    mkdir -p "$FONT_DIR"
    curl -fsSL -o "$FONT_TMP/JetBrainsMono.zip" \
      "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    unzip -oq "$FONT_TMP/JetBrainsMono.zip" -d "$FONT_DIR" "*.ttf"
    rm -rf "$FONT_TMP"
    fc-cache -f "$FONT_DIR"
    log "nerd font installed to $FONT_DIR"
  fi

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
