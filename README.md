# dotfiles

Personal workstation config — zsh, tmux, neovim. Tuned for offensive security / lab work on Debian.

## What's here

| File | Purpose |
|---|---|
| `.zshrc` | zsh config — history, completions, fzf, aliases |
| `.tmux.conf` | tmux config — C-a prefix, vi keys, lab-friendly status bar |
| `.config/nvim/init.lua` | neovim 0.12+ — lazy.nvim, kanagawa, telescope, treesitter, pylsp |
| `.local/bin/lab-session` | spin up a standard lab tmux layout (enum/shell/listener/notes) |
| `docs/nvim_cheat.txt` | neovim keybind reference for this config |
| `docs/tmux_cheat.txt` | tmux keybind reference for this config |

## Deploy

```bash
git clone git@github.com:v0idravl/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./deploy.sh
```

Backs up any existing files to `~/.dotfiles-backup/<timestamp>/` before symlinking.
Preview changes first with `./deploy.sh --dry-run`.

## Requirements

- zsh, tmux, neovim 0.12+, git
- fzf (for ctrl-r/ctrl-t history and file search)
- xclip (for tmux clipboard yank)
- tree-sitter CLI + a C compiler (parser builds for nvim-treesitter `main`; deploy.sh installs the CLI to `~/.local/bin`)
- JetBrainsMono Nerd Font (prompt/tmux glyphs; deploy.sh installs to `~/.local/share/fonts`)

**Optional (activates LSP features):**
```bash
sudo apt install clangd bat ripgrep
pip install pwntools python-lsp-server --break-system-packages
```

## Neovim plugins (auto-installed by lazy.nvim on first launch)

- **kanagawa** — colorscheme (dragon variant)
- **telescope** — fuzzy find files, grep, buffers
- **nvim-treesitter** — syntax highlighting for python, c, asm, markdown, bash
- **mason** — LSP server manager (`:Mason`)
- **nvim-cmp** — completion (manual trigger: `<C-Space>`)
- **which-key** — keybinding popup on `<leader>` pause

## Key bindings quick ref

See `docs/nvim_cheat.txt` and `docs/tmux_cheat.txt` for full references.

**tmux prefix:** `C-a`  
**nvim leader:** `<Space>`

| tmux | action |
|---|---|
| `prefix \|` | vertical split |
| `prefix -` | horizontal split |
| `Alt+arrow` | switch pane (no prefix) |
| `prefix S` | sync panes |
| `y` (copy mode) | yank to clipboard |

| nvim | action |
|---|---|
| `<leader>ff` | find files |
| `<leader>fg` | live grep |
| `K` | LSP hover |
| `gd` | go to definition |
| `<C-Space>` | trigger completion |
