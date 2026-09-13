#!/bin/bash
# archWslSetup.sh
# Set up Arch Linux on WSL with the terminal tooling from the main Omarchy
# machine (zsh + oh-my-zsh, Neovim, tmux/herdr, lazygit/lazydocker, btop, mise,
# languages), themed with Omarchy's "hackerman" palette.
#
# Stage 1, as root on a fresh image (clone this repo somewhere world-readable,
# e.g. /opt/DotFiles, or re-clone it as the new user for stage 2):
#   bash archWslSetup.sh --user <name>
#   Initialises the keyring, locale, sudo, the user account and /etc/wsl.conf
#   (systemd + default user). Then from Windows: wsl --terminate <distro>
#
# Stage 2, as that user:
#   bash archWslSetup.sh [--dry-run] [--skip-nvim] [--skip-terminal]
#
#   --dry-run        Print what would happen without changing anything
#   --skip-nvim      Don't install SykesTheLord/NeoVimConfig
#   --skip-terminal  Don't add the Hackerman scheme to Windows Terminal

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=dotfiles_lib.sh
source "$DOTFILES_DIR/dotfiles_lib.sh"

DRY_RUN=false
SKIP_NVIM=false
SKIP_TERMINAL=false
NEW_USER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)       DRY_RUN=true; shift ;;
        --skip-nvim)     SKIP_NVIM=true; shift ;;
        --skip-terminal) SKIP_TERMINAL=true; shift ;;
        --user)
            [[ -n "${2:-}" ]] || { echo "Error: --user requires a name"; exit 1; }
            NEW_USER="$2"; shift 2 ;;
        -h|--help) sed -n '2,/^$/{s/^# \{0,1\}//;p}' "$0"; exit 0 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# ── packages ─────────────────────────────────────────────────────────────────

# CLI/TUI subset of what's installed on the Omarchy desktop; GUI apps, drivers,
# Hyprland and hardware tools are left out.
PACMAN_PACKAGES=(
    # base & shell
    base-devel git github-cli git-filter-repo openssh curl wget rsync unzip zip
    less man-db man-pages zsh bash-completion
    # editors & multiplexers
    neovim vim tmux
    # CLI / TUI tools
    fzf ripgrep fd bat eza zoxide jq gum direnv tldr dua-cli hyperfine btop
    fastfetch lazygit lazydocker plocate inotify-tools xmlstarlet qrencode
    expac pacman-contrib usage mise
    # containers & infra
    docker docker-compose docker-buildx terraform
    # languages & build tooling
    go rust clang llvm libc++ cmake ninja valgrind
    lua51 luarocks tree-sitter-cli
    python python-pip python-pipx
    ruby libyaml postgresql-libs mariadb-libs
    jdk11-openjdk jdk17-openjdk jdk21-openjdk jdk25-openjdk maven
    dotnet-sdk dotnet-sdk-8.0 dotnet-sdk-9.0
    # network / security
    nmap tcpdump bind whois openbsd-netcat socat inetutils
    # misc
    imagemagick yt-dlp bitwarden-cli
    # WSLg clipboard, used by Neovim's "unnamedplus"
    wl-clipboard
)

# Omarchy ships herdr/cliamp from its own repo; these are the AUR equivalents.
AUR_PACKAGES=(
    herdr-bin
    cliamp
    downgrade
    wslu        # wslview: open URLs/files with Windows defaults
)

# Must match arch-wsl/.oh-my-zsh/custom/themes/sykes_hackerman.zsh-theme and
# arch-wsl/.config/btop/themes/hackerman.theme. black/brightBlack are brighter
# than hackerman's own so zsh-autosuggestions stay readable.
HACKERMAN_WT_SCHEME='{
  "name": "Hackerman",
  "background": "#0B0C16",
  "foreground": "#ddf7ff",
  "cursorColor": "#ddf7ff",
  "selectionBackground": "#1f253a",
  "black": "#151828",
  "red": "#50f872",
  "green": "#4fe88f",
  "yellow": "#50f7d4",
  "blue": "#829dd4",
  "purple": "#86a7df",
  "cyan": "#7cf8f7",
  "white": "#ddf7ff",
  "brightBlack": "#6a6e95",
  "brightRed": "#85ff9d",
  "brightGreen": "#9cf7c2",
  "brightYellow": "#a4ffec",
  "brightBlue": "#c4d2ed",
  "brightPurple": "#cddbf4",
  "brightCyan": "#d1fffe",
  "brightWhite": "#ddf7ff"
}'

NVIM_CONFIG_REPO="https://github.com/SykesTheLord/NeoVimConfig"
NVIM_CONFIG_DIR="$HOME/Projects/NeoVimConfig"

# ── helpers ──────────────────────────────────────────────────────────────────

log()  { printf '\033[1;32m▶\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; exit 1; }
run() {
    if $DRY_RUN; then
        echo "  [dry-run] $*"
    else
        "$@"
    fi
}
run_sh() {
    if $DRY_RUN; then
        echo "  [dry-run] bash -c \"$*\""
    else
        bash -c "$*"
    fi
}

# ini_set <file> <section> <key> <value>: set a key in an INI file, adding the
# section if missing and leaving everything else untouched.
ini_set() {
    local file="$1" section="$2" key="$3" value="$4"
    if $DRY_RUN; then
        echo "  [dry-run] set [$section] $key = $value in $file"
        return
    fi
    touch "$file"
    awk -v s="[$section]" -v k="$key" -v v="$value" '
        function emit() { if (insec && !done) { print k " = " v; done = 1 } }
        /^\[.*\][[:space:]]*$/ { emit(); insec = ($1 == s); if (insec) seen = 1; print; next }
        insec && $0 ~ "^[[:space:]]*" k "[[:space:]]*=" { if (!done) { print k " = " v; done = 1 }; next }
        { print }
        END { emit(); if (!seen) { if (NR > 0) print ""; print s; print k " = " v } }
    ' "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
}

# ── pre-flight ───────────────────────────────────────────────────────────────

if ! is_wsl; then
    $DRY_RUN || die "Not running under WSL (no 'microsoft' in /proc/sys/kernel/osrelease)."
    warn "Not running under WSL; continuing because this is a dry run."
fi
is_arch || die "This script targets Arch Linux (/etc/arch-release is missing)."

# ── stage 1: root ────────────────────────────────────────────────────────────

root_stage() {
    [[ -n "$NEW_USER" ]] || die "Running as root: pass --user <name> to create your account, then re-run as that user."
    [[ "$NEW_USER" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "Invalid username: $NEW_USER"

    log "Initialising pacman keyring"
    if [[ ! -s /etc/pacman.d/gnupg/pubring.kbx && ! -s /etc/pacman.d/gnupg/pubring.gpg ]]; then
        run pacman-key --init
        run pacman-key --populate archlinux
    else
        log "Keyring already initialised"
    fi

    # Container-derived rootfs images can skip man pages via NoExtract; MANPAGER relies on them.
    if grep -qE '^NoExtract.*usr/share/man' /etc/pacman.conf; then
        log "Re-enabling man pages in /etc/pacman.conf"
        run sed -i -E 's|^(NoExtract.*usr/share/man.*)$|#\1|' /etc/pacman.conf
    fi

    log "Upgrading system and installing bootstrap packages"
    run pacman -Syu --needed --noconfirm base-devel sudo zsh git

    log "Configuring locale (en_US.UTF-8)"
    if ! locale -a 2>/dev/null | grep -qix 'en_US\.utf8'; then
        run sed -i 's/^#\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
        run locale-gen
    fi
    [[ -f /etc/locale.conf ]] || run_sh 'echo "LANG=en_US.UTF-8" > /etc/locale.conf'

    log "Allowing the wheel group to use sudo"
    run_sh "echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel && chmod 440 /etc/sudoers.d/10-wheel"

    if id "$NEW_USER" &>/dev/null; then
        log "User $NEW_USER already exists; ensuring wheel membership"
        run usermod -aG wheel "$NEW_USER"
    else
        log "Creating user $NEW_USER"
        run useradd -m -G wheel -s /usr/bin/zsh "$NEW_USER"
        run passwd "$NEW_USER"
    fi

    log "Writing /etc/wsl.conf (systemd + default user)"
    ini_set /etc/wsl.conf boot systemd true
    ini_set /etc/wsl.conf user default "$NEW_USER"

    if [[ "$DOTFILES_DIR" == /root/* ]]; then
        warn "This repo is under /root, which $NEW_USER can't read. Re-clone it as $NEW_USER for stage 2."
    fi

    echo ""
    echo "✓ Stage 1 complete. Next:"
    echo "  1. In PowerShell: wsl --terminate ${WSL_DISTRO_NAME:-<distro>}"
    echo "  2. Reopen the distro (it now logs in as $NEW_USER with systemd running)"
    echo "  3. Run: bash <path-to>/DotFiles/archWslSetup.sh"
}

# ── stage 2: user ────────────────────────────────────────────────────────────

install_packages() {
    log "Installing pacman packages"
    run sudo pacman -Syu --needed --noconfirm "${PACMAN_PACKAGES[@]}"
}

install_yay() {
    if command -v yay &>/dev/null; then
        log "yay already installed"
        return
    fi
    log "Installing yay (AUR helper)"
    if $DRY_RUN; then
        echo "  [dry-run] build yay-bin from https://aur.archlinux.org/yay-bin.git"
        return
    fi
    local tmp
    tmp=$(mktemp -d)
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
}

install_aur_packages() {
    log "Installing AUR packages"
    run yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
}

install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log "oh-my-zsh already installed"
    else
        log "Installing oh-my-zsh"
        run_sh 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    fi

    local custom="$HOME/.oh-my-zsh/custom"
    for plugin in zsh-syntax-highlighting zsh-autosuggestions; do
        if [[ ! -d "$custom/plugins/$plugin" ]]; then
            log "Installing $plugin"
            run git clone --depth 1 "https://github.com/zsh-users/$plugin" "$custom/plugins/$plugin"
        fi
    done
}

deploy_dotfiles() {
    log "Deploying arch-wsl/ configs (changed files are kept as .bak)"
    run rsync -a --no-group --backup --suffix=.bak "$DOTFILES_DIR/arch-wsl/" "$HOME/"
    run chmod +x "$HOME/.scripts/tmux-sessionizer"
}

install_mise_tools() {
    log "Installing mise tools from ~/.config/mise/config.toml"
    run mise install node
    # npm-backed tools need node on PATH while installing
    run mise exec node -- mise install
}

install_nvim_config() {
    log "Installing Neovim config ($NVIM_CONFIG_REPO)"
    if [[ -d "$NVIM_CONFIG_DIR/.git" ]]; then
        run git -C "$NVIM_CONFIG_DIR" pull --ff-only
    else
        run mkdir -p "$(dirname "$NVIM_CONFIG_DIR")"
        run git clone "$NVIM_CONFIG_REPO" "$NVIM_CONFIG_DIR"
    fi

    # install.sh symlinks the clone to ~/.config/nvim, so the clone has to stay put.
    if [[ "$(readlink -f "$HOME/.config/nvim" 2>/dev/null)" == "$NVIM_CONFIG_DIR" ]]; then
        log "~/.config/nvim already links to the clone; refreshing plugins"
        run nvim --headless +"qall!"
    else
        run bash "$NVIM_CONFIG_DIR/install.sh" --yes --force
    fi
}

# Omarchy's hackerman.nvim (built on aether.nvim), installed as a native package
# under the data dir so neither the NeoVimConfig clone nor its lockfile changes.
install_nvim_theme() {
    log "Installing hackerman.nvim"
    local site="$HOME/.local/share/nvim/site"
    local repo dir
    for repo in bjarneo/aether.nvim bjarneo/hackerman.nvim; do
        dir="$site/pack/hackerman/start/${repo#*/}"
        if [[ -d "$dir/.git" ]]; then
            run git -C "$dir" pull --ff-only
        else
            run git clone --depth 1 "https://github.com/$repo" "$dir"
        fi
    done

    run mkdir -p "$site/after/plugin"
    if $DRY_RUN; then
        echo "  [dry-run] write $site/after/plugin/hackerman.lua"
        return
    fi
    cat > "$site/after/plugin/hackerman.lua" << 'EOF'
-- Written by DotFiles/archWslSetup.sh: Omarchy's hackerman theme on WSL.
-- after/plugin runs once NeoVimConfig's init (which sets nordic) is done, so this wins.
if vim.g.colors_name == "hackerman" or not pcall(vim.cmd.colorscheme, "hackerman") then
    return
end

-- NeoVimConfig pins lualine to "nord"; follow the colorscheme instead.
local ok, lualine = pcall(require, "lualine")
if ok and lualine.get_config then
    local cfg = lualine.get_config()
    cfg.options.theme = "auto"
    lualine.setup(cfg)
end
EOF
}

setup_docker() {
    if [[ "$(ps -p 1 -o comm= 2>/dev/null)" == "systemd" ]]; then
        log "Enabling docker.socket"
        run sudo systemctl enable --now docker.socket
    else
        warn "systemd isn't PID 1, so docker won't start on boot. Set [boot] systemd=true in /etc/wsl.conf (stage 1 does this)."
    fi

    if ! id -nG "$USER" | grep -qw docker; then
        log "Adding $USER to the docker group"
        run sudo usermod -aG docker "$USER"
    fi
}

set_login_shell() {
    if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "/usr/bin/zsh" ]]; then
        log "Setting zsh as the login shell"
        run sudo chsh -s /usr/bin/zsh "$USER"
    fi
}

print_terminal_manual_steps() {
    echo "  Add this to \"schemes\" in Windows Terminal's settings.json and set"
    echo "  \"colorScheme\": \"Hackerman\" on the ${WSL_DISTRO_NAME:-Arch} profile:"
    echo "$HACKERMAN_WT_SCHEME"
}

configure_windows_terminal() {
    if ! command -v cmd.exe &>/dev/null; then
        warn "Windows interop isn't available; skipping Windows Terminal."
        print_terminal_manual_steps
        return
    fi

    local localappdata
    localappdata=$(wslpath "$(cmd.exe /c 'echo %LOCALAPPDATA%' 2>/dev/null | tr -d '\r')")

    local settings="" candidate
    for candidate in \
        "$localappdata/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json" \
        "$localappdata/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json" \
        "$localappdata/Microsoft/Windows Terminal/settings.json"; do
        if [[ -f "$candidate" ]]; then
            settings="$candidate"
            break
        fi
    done

    if [[ -z "$settings" ]]; then
        warn "Windows Terminal settings.json not found."
        print_terminal_manual_steps
        return
    fi
    if ! jq empty "$settings" 2>/dev/null; then
        warn "$settings contains comments or isn't plain JSON; not editing it automatically."
        print_terminal_manual_steps
        return
    fi

    local font=""
    if compgen -G "/mnt/c/Windows/Fonts/JetBrainsMonoNerdFont*" >/dev/null \
        || compgen -G "$localappdata/Microsoft/Windows/Fonts/JetBrainsMonoNerdFont*" >/dev/null; then
        font="JetBrainsMono Nerd Font"
    else
        warn "JetBrainsMono Nerd Font isn't installed on Windows; icons in eza/nvim/prompt will be missing."
        warn "Get it from https://www.nerdfonts.com/font-downloads and set it as the profile font."
    fi

    local distro="${WSL_DISTRO_NAME:-archlinux}"
    log "Adding the Hackerman scheme to Windows Terminal (profile: $distro)"
    if $DRY_RUN; then
        echo "  [dry-run] update $settings (scheme, colorScheme, font, unbind alt+enter)"
        return
    fi

    local backup tmp
    backup="$settings.bak.$(date +%s)"
    tmp=$(mktemp)
    cp "$settings" "$backup"

    # alt+enter toggles fullscreen by default, which swallows tmux/herdr's split binding.
    jq --argjson scheme "$HACKERMAN_WT_SCHEME" --arg distro "$distro" --arg font "$font" '
        def themed: if .name == $distro then
                .colorScheme = "Hackerman"
                | if $font != "" then .font.face = $font else . end
            else . end;
        .schemes = ([.schemes[]? | select(.name != "Hackerman")] + [$scheme])
        | if (.profiles | type) == "object" then .profiles.list |= map(themed)
          else .profiles |= map(themed) end
        | .actions = ([.actions[]? | select(.keys != "alt+enter")] + [{"command": "unbound", "keys": "alt+enter"}])
    ' "$backup" > "$tmp"
    cat "$tmp" > "$settings"
    rm -f "$tmp"

    if ! jq -e --arg distro "$distro" '[(.profiles.list? // .profiles)[] | select(.name == $distro)] | length > 0' "$settings" >/dev/null; then
        warn "No Windows Terminal profile named '$distro'; the scheme was added but not applied to a profile."
    fi
    log "Windows Terminal updated (backup: $backup)"
}

user_stage() {
    [[ -z "$NEW_USER" ]] || warn "--user is only used when running as root; ignoring it."
    command -v sudo &>/dev/null || die "sudo is missing. Run stage 1 as root first: bash archWslSetup.sh --user <name>"
    $DRY_RUN || sudo -v || die "sudo access is required."

    log "Starting Arch WSL setup (dry_run=$DRY_RUN)"

    install_packages
    install_yay
    install_aur_packages
    install_oh_my_zsh
    deploy_dotfiles
    install_mise_tools
    if ! $SKIP_NVIM; then
        install_nvim_config
        install_nvim_theme
    fi
    setup_docker
    set_login_shell
    $SKIP_TERMINAL || configure_windows_terminal

    echo ""
    echo "✓ Arch WSL setup complete$($DRY_RUN && echo " (dry run, nothing changed)" || true)"
    echo ""
    echo "Next steps:"
    echo "  1. In PowerShell: wsl --terminate ${WSL_DISTRO_NAME:-<distro>}  (applies the shell and docker group)"
    echo "  2. Reopen the distro. zsh starts with the sykes_hackerman prompt"
    echo "  3. Run 'gh auth login', then 'nvim' once to finish plugin/LSP installs"
}

if [[ $EUID -eq 0 ]]; then
    root_stage
else
    user_stage
fi
