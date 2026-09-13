# ~/.zshrc for Arch Linux on WSL (deployed by archWslSetup.sh / installDotfiles.sh)

export ZSH="$HOME/.oh-my-zsh"

# Hackerman colors are baked into the theme (~/.oh-my-zsh/custom/themes)
ZSH_THEME="sykes_hackerman"

plugins=(git zsh-syntax-highlighting zsh-autosuggestions docker kubectl dotnet terraform)

source $ZSH/oh-my-zsh.sh

# ── Environment ──────────────────────────────────────────────────────────────

export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export BAT_THEME=ansi
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# wslu opens URLs (gh, az login, ...) in the Windows default browser
command -v wslview &>/dev/null && export BROWSER=wslview

# Development toolchains
export DOTNET_ROOT=/usr/share/dotnet
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
export JAVA_HOME=/usr/lib/jvm/default     # switch with: sudo archlinux-java set java-<n>-openjdk
export CMAKE_GENERATOR=Ninja
export CMAKE_EXPORT_COMPILE_COMMANDS=ON   # compile_commands.json for clangd

typeset -U path
path=("$HOME/.local/bin" $path "$HOME/.dotnet/tools" "$HOME/go/bin" "$HOME/.scripts")

# ── Tool integrations ────────────────────────────────────────────────────────

command -v mise &>/dev/null && eval "$(mise activate zsh)"
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
command -v fzf &>/dev/null && source <(fzf --zsh)
command -v uv &>/dev/null && eval "$(uv generate-shell-completion zsh)"

autoload -U +X bashcompinit && bashcompinit
command -v terraform &>/dev/null && complete -o nospace -C /usr/bin/terraform terraform

# ── Aliases ──────────────────────────────────────────────────────────────────

# File system (from Omarchy's bash defaults)
if command -v eza &>/dev/null; then
    alias ls='eza -lh --group-directories-first --icons=auto'
    alias lsa='ls -a'
    alias lt='eza --tree --level=2 --long --icons --git'
    alias lta='lt -a'
fi

alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias eff='$EDITOR "$(ff)"'

# cd falls back to zoxide's frecency search when the path isn't a directory
if command -v zoxide &>/dev/null; then
    zd() {
        if (( $# == 0 )); then
            builtin cd ~ || return
        elif [[ -d $1 ]]; then
            builtin cd "$1" || return
        else
            if ! z "$@"; then
                echo "Error: Directory not found"
                return 1
            fi
            printf "\U000F17A9 "
            pwd
        fi
    }
    alias cd="zd"
fi

open() { ( wslview "$@" >/dev/null 2>&1 & ) }

# Tools
alias vim="nvim"
n() { if [ "$#" -eq 0 ]; then command nvim . ; else command nvim "$@"; fi; }
alias d='docker'
alias t='tmux attach || tmux new -s Work'
alias tk="tmux kill-server"
alias h='herdr'
alias cx='printf "\033[2J\033[3J\033[H" && claude --permission-mode auto'
alias cy='codex --approve-for-me'
alias mup='MISE_MINIMUM_RELEASE_AGE=0 mise up'
alias updateAll='yay -Syu --noconfirm && mise up'
alias compile-cpp='clang++ -std=c++23 -stdlib=libc++'
alias mermaidUp='docker run -d --platform linux/amd64 --publish 8000:8080 --name mermaid-live ghcr.io/mermaid-js/mermaid-live-editor'
alias mermaidDown='docker stop mermaid-live && docker rm mermaid-live'

# ── Startup ──────────────────────────────────────────────────────────────────

if [[ $- == *i* ]] && command -v fastfetch &>/dev/null; then
    fastfetch
fi
