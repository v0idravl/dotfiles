# ── Core behavior ──────────────────────────────────────────────
setopt autocd
setopt interactivecomments
setopt nonomatch
setopt notify
setopt promptsubst

WORDCHARS='_-'
PROMPT_EOL_MARK=""

# ── History ────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify
setopt hist_find_no_dups
setopt share_history
alias history="history 0"

# ── Completion ─────────────────────────────────────────────────
autoload -Uz compinit
compinit -d ~/.cache/zcompdump
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' rehash true
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ── Kali-style two-line prompt (adapted for Debian) ────────────
autoload -Uz colors && colors

configure_prompt() {
    PROMPT=$'%F{#8a9a7b}┌──%F{#7aa89f}(%B%F{#957fb8}v0idravl%b%F{#7aa89f})%F{#8a9a7b}-%F{#7fb4ca}[%B%F{#e6c384}%(6~.%-1~/…/%4~.%5~)%b%F{#7fb4ca}]\n%F{#8a9a7b}└─%B%F{#c34043}▶%b%F{reset} '
}
configure_prompt

# Newline before each prompt (after the first)
precmd() {
    if [ -z "$_NEW_LINE_BEFORE_PROMPT" ]; then
        _NEW_LINE_BEFORE_PROMPT=1
    else
        print ""
    fi
}

# ── Colors for ls, grep, etc. ──────────────────────────────────
eval "$(dircolors -b)"
export LS_COLORS="$LS_COLORS:ow=30;44:"

# ── eza: colorful ls, always show hidden files ─────────────────
alias ls='eza --color=always --icons --group-directories-first --all'
alias ll='eza --color=always --icons --group-directories-first --all --long --header'
alias lt='eza --color=always --icons --group-directories-first --all --tree --level=2'
alias la='eza --color=always --icons --all'

# ── Navigation ─────────────────────────────────────────────────
setopt auto_pushd
setopt pushd_ignore_dups
alias ..='cd ..'
alias ...='cd ../..'
alias bd='popd'
alias v=nvim
alias vim=nvim
alias t=tmux
alias bat='batcat'          # Debian ships bat as batcat
alias cat='batcat --paging=never'

# ── Safe defaults ──────────────────────────────────────────────
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'

# ── Keybindings ────────────────────────────────────────────────
bindkey -e
bindkey '^R' history-incremental-search-backward
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ── Plugins (installed via apt) ────────────────────────────────
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'

# ── fzf ────────────────────────────────────────────────────────
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && \
    source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && \
    source /usr/share/doc/fzf/examples/completion.zsh
export PATH="$HOME/.local/bin:$PATH"

# DAGAR ops CLI
export PATH="$PATH:/home/harry/Documents/dagar/bin"

if [ -z "$TMUX" ]; then
    tmux attach -t default 2>/dev/null || tmux new-session -s default
fi
