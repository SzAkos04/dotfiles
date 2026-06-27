# ============================================================
# BOOTSTRAP: Homebrew (must be first — everything else depends on it)
# ============================================================
eval "$(/opt/homebrew/bin/brew shellenv)"


# ============================================================
# BOOTSTRAP: Install zinit (plugin manager) if not present
# ============================================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"


# ============================================================
# PLUGINS (loaded via zinit — fast, lazy where possible)
# ============================================================

# Fish-like autosuggestions (grey ghost text as you type)
zinit light zsh-users/zsh-autosuggestions

# Extra completions (kubectl, docker, cargo, npm, pip, etc.)
zinit light zsh-users/zsh-completions

# fzf-tab: replace zsh's default tab menu with fzf fuzzy finder
zinit light Aloxaf/fzf-tab

# History search with up/down arrows (smarter than default)
zinit light zsh-users/zsh-history-substring-search

# Handy aliases: gst, gco, glog, etc.
zinit snippet OMZP::git

# Colored man pages
zinit snippet OMZP::colored-man-pages

zinit light MichaelAquilina/zsh-auto-notify

# Syntax highlighting (must come LAST — needs to wrap all widgets)
zinit light zsh-users/zsh-syntax-highlighting


# zsh-auto-notify config
AUTO_NOTIFY_THRESHOLD=10
AUTO_NOTIFY_TITLE="Terminal"
AUTO_NOTIFY_BODY="[%exit_code] %command (%elapsed)"
AUTO_NOTIFY_EXPIRE_TIME=5000


# ============================================================
# PROMPT — Starship (cross-shell, very fast, feature-rich)
# Install: curl -sS https://starship.rs/install.sh | sh
# Falls back to adam1 if starship isn't installed
# ============================================================
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
else
  autoload -Uz promptinit
  promptinit
  prompt adam1
fi


# ============================================================
# HISTORY
# ============================================================
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history

setopt HIST_IGNORE_ALL_DUPS   # No duplicate entries
setopt HIST_IGNORE_SPACE      # Lines starting with space are not saved
setopt HIST_VERIFY            # Show expanded history before running it
setopt SHARE_HISTORY          # Share history across sessions (implies INC_APPEND)
setopt EXTENDED_HISTORY       # Save timestamp + duration


# ============================================================
# COMPLETION SYSTEM
# ============================================================
autoload -Uz compinit
compinit
zinit cdreplay -q   # replay compdef calls cached during plugin load

# Case-insensitive, partial-word, substring completion
zstyle ':completion:*' matcher-list \
  '' \
  'm:{a-z}={A-Z}' \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=* l:|=*'

# Grouping and descriptions
zstyle ':completion:*' group-name ''
zstyle ':completion:*' format '%F{yellow}── %d ──%f'
zstyle ':completion:*' verbose true

# Menu with colors
zstyle ':completion:*' menu select
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''

# Approximate corrections (up to 2 errors tolerated)
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*:approximate:*' max-errors 2 numeric

# Kill: show processes with colors
zstyle ':completion:*:*:kill:*:processes' \
  list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# fzf-tab: use fzf for tab completion previews
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:*' fzf-preview \
  '[[ -f $realpath ]] && bat --color=always $realpath || ls --color $realpath 2>/dev/null'

# Don't complete uninteresting users
zstyle ':completion:*:*:*:users' ignored-patterns \
  adm amanda apache at avahi avahi-autoipd beaglidx bin cacti canna \
  clamav daemon dbus distcache dnsmasq dovecot fax ftp games gdm \
  gkrellmd gopher hacluster haldaemon halt hsqldb ident junkbust kdm \
  ldap lp mail mailman mailnull man messagebus mldonkey mysql nagios \
  named netdump news nfsnobody nobody nscd ntp nut nx obsrun openvpn \
  operator pcap polkitd postfix postgres privoxy pulse pvm quagga radvd \
  rpc rpcuser rpm rtkit scard shutdown squid sshd statd svn sync tftp \
  usbmux uucp vcsa wwwrun xfs '_*'


# ============================================================
# KEY BINDINGS
# ============================================================
bindkey -e   # Emacs bindings (Ctrl-A, Ctrl-E, Ctrl-R, etc.)

# History substring search — bind to up/down arrows
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P'   history-substring-search-up
bindkey '^N'   history-substring-search-down

# Accept autosuggestion with Ctrl+Space or Right arrow
bindkey '^ '   autosuggest-accept
bindkey '^[[C' autosuggest-accept

# Edit current command in $EDITOR (Ctrl+X Ctrl+E)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Word navigation with Alt+Left / Alt+Right
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word


# ============================================================
# OPTIONS
# ============================================================
setopt AUTO_CD              # Type a dir name to cd into it
setopt AUTO_PUSHD           # cd pushes to stack automatically
setopt PUSHD_IGNORE_DUPS    # No duplicate dirs on stack
setopt PUSHD_SILENT         # Don't print the dir stack
setopt CORRECT              # Suggest corrections for typos
setopt CDABLE_VARS          # cd to a var that holds a path
setopt GLOB_DOTS            # Include dotfiles in globbing
setopt EXTENDED_GLOB        # Extended glob patterns (**, *(.), etc.)
setopt NO_BEEP              # No terminal bell ever
setopt MULTIOS              # Allow multiple redirections
setopt INTERACTIVE_COMMENTS # Allow # comments in interactive shell


# ============================================================
# ENVIRONMENT
# ============================================================
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export LESS='-R --use-color -Dd+r$Du+b'
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

export PATH="$HOME/.cargo/bin:$HOME/Documents/cinit/build:$HOME/.local/bin:$PATH"

# fzf — fuzzy finder defaults
export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border
  --info=inline
  --preview-window=right:50%:wrap
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


# ============================================================
# ALIASES — Core
# ============================================================
alias cat="bat"

if command -v eza &>/dev/null; then
  alias ls="eza -A --icons=always --group-directories-first"
  alias ll="eza -lAaph --icons=always --git --group-directories-first"
  alias lt="eza -lAaph --sort=time --icons=always --group-directories-first"
  alias lS="eza -lAaph --sort=size --icons=always --group-directories-first"
  alias tree="eza --tree -A --icons=always"
else
  alias ls="gls -Apx --group-directories-first --color=auto"
  alias ll="gls -lAaph --group-directories-first --color=auto"
  alias lt="gls -lAaph --sort=time --color=auto"
  alias lS="gls -lAaph --sort=size --color=auto"
fi

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

alias grep="rg"
alias diff="diff --color=auto"
alias ip="ip --color=auto"
alias du="du -h"
alias df="df -h"
alias free="vm_stat"
alias mkdir="mkdir -pv"

alias so="exec zsh"       # Reload shell (clean — replaces process)
alias reload="source ~/.zshrc"  # Reload in-place (keeps current state)
alias zshrc="${EDITOR} ~/.zshrc"

# Safety nets
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"


# ============================================================
# ALIASES — Dev & Tools
# ============================================================
alias vi="nvim"
alias vim="nvim"
alias g="git"
alias d="docker"
alias dc="docker compose"
alias k="kubectl"
alias t="tmux"

alias path='echo $PATH | tr ":" "\n"'
alias serve="python3 -m http.server 8080"
alias duh="du -h --max-depth=1 | sort -h"
alias ports="lsof -iTCP -sTCP:LISTEN -P -n"
alias copy-last='fc -ln -1 | pbcopy 2>/dev/null || fc -ln -1 | xclip -sel clip'


# ============================================================
# FUNCTIONS
# ============================================================

# cd then ls
function cd() {
  builtin cd "$@" && ls
}

# Make a dir and cd into it
function mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract any archive
function extract() {
  case "$1" in
    *.tar.bz2)  tar xjf "$1"         ;;
    *.tar.gz)   tar xzf "$1"         ;;
    *.tar.xz)   tar xJf "$1"         ;;
    *.tar.zst)  tar --zstd -xf "$1"  ;;
    *.bz2)      bunzip2 "$1"         ;;
    *.gz)       gunzip "$1"          ;;
    *.zip)      unzip "$1"           ;;
    *.7z)       7z x "$1"            ;;
    *.rar)      unrar x "$1"         ;;
    *.tar)      tar xf "$1"          ;;
    *)          echo "'$1' cannot be extracted via extract()" ;;
  esac
}

# zoxide-powered fuzzy cd into frecent directories
function fcd() {
  if command -v zoxide &>/dev/null; then
    local dir
    dir=$(zoxide query -l | fzf --preview 'eza --tree --level=2 --color=always {}' --preview-window=right:50%) \
      && cd "$dir"
  fi
}

# Fuzzy-search and open file in editor
function fe() {
  local file
  file=$(fzf --preview 'bat --color=always {}') && ${EDITOR:-nvim} "$file"
}

# Fuzzy kill a process
function fkill() {
  local pid
  pid=$(ps -u $USER -o pid,cmd | tail -n +2 | fzf | awk '{print $1}')
  [ -n "$pid" ] && kill -${1:-9} "$pid"
}

# Quick git log with fzf and preview
function glog() {
  git log --oneline --color | fzf \
    --ansi \
    --preview 'git show --stat --color {1}' \
    --bind 'enter:execute(git show {1} | bat --color=always | less -R)'
}

# Rename files in current dir using vidir (moreutils)
function vidir() {
  if command -v vidir &>/dev/null; then
    command vidir .
  else
    echo "vidir not found — install moreutils: brew install moreutils"
  fi
}


# ============================================================
# AUTOSUGGESTIONS TUNING
# ============================================================
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6c7086'
ZSH_AUTOSUGGEST_USE_ASYNC=true


# ============================================================
# SYNTAX HIGHLIGHTING TUNING
# ============================================================
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[alias]='fg=magenta,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=blue,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=green'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#6c7086,italic'


# ============================================================
# HISTORY SUBSTRING SEARCH TUNING
# ============================================================
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=magenta,fg=white,bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=red,fg=white,bold'
HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS='i'


# ============================================================
# ZOXIDE — smart directory navigation
# ============================================================
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi


# ============================================================
# TMUX — auto-attach or create session named 'main'
# (kept last so everything above is available inside tmux)
# ============================================================
[ -z "$TMUX" ] && exec tmux new-session -A -s main
