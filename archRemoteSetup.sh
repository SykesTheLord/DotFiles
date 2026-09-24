#!/bin/bash
# archRemoteSetup.sh
# Set up a headless Arch Linux box, running as a QEMU guest, as a remote SSH
# development machine: a dedicated user with SSH key access imported from
# GitHub, qemu-guest-agent, an unattended update timer, then zsh + oh-my-zsh,
# Neovim, tmux/herdr, lazygit/lazydocker, Docker, and toolchains for C/C++,
# C#/.NET, Java, Python and Bash. Reuses the terminal-only arch-wsl/ dotfiles
# (they don't depend on WSL or Windows Terminal), and mirrors archWslSetup.sh
# otherwise.
#
# Stage 1, as root on a fresh box (clone this repo somewhere world-readable,
# e.g. /opt/DotFiles, or re-clone it as the new user for stage 2):
#   bash archRemoteSetup.sh --user <name> [--github-user <name>]
#   Initialises the keyring, locale, sudo, the user account, and imports that
#   GitHub user's public keys into ~/.ssh/authorized_keys. Prompts for
#   whichever of --user/--github-user is omitted. Once a key is installed,
#   disables SSH password and root login (--skip-harden opts out).
#
# Stage 2, as that user:
#   bash archRemoteSetup.sh [--dry-run] [--skip-nvim] [--skip-blackarch] \
#       [--skip-qemu-agent] [--skip-auto-update]
#
#   --dry-run          Print what would happen without changing anything
#   --skip-nvim        Don't install NeoVimConfig or Mason packages
#   --skip-blackarch   Don't add the BlackArch repository (either stage)
#   --skip-qemu-agent  Don't install/enable qemu-guest-agent
#   --skip-auto-update Don't install the Mon/Wed/Sat 03:00 update timer
#
# Both stages enable the multilib repository and add the BlackArch repository
# (keyring pinned by version + SHA-256); both steps are skipped once done.
#
# The update timer (arch-auto-update.service/.timer) runs pacman -Syu, then
# AUR updates via yay as the target user, then paccache -rk2, every Monday,
# Wednesday and Saturday at 03:00. Arch's rolling kernel has no live-patch feed
# (kpatch needs a hand-built patch per kernel build, so it can't auto-cover
# arbitrary updates), so instead of live-patching, the timer detects a pending
# kernel update and reboots into it unattended, but only when nobody is logged
# in and no Claude Code agent is running; otherwise it defers to the next
# Mon/Wed/Sat window.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=dotfiles_lib.sh
source "$DOTFILES_DIR/dotfiles_lib.sh"

DRY_RUN=false
SKIP_NVIM=false
SKIP_BLACKARCH=false
SKIP_HARDEN=false
SKIP_QEMU_AGENT=false
SKIP_AUTO_UPDATE=false
NEW_USER=""
GITHUB_USER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)          DRY_RUN=true; shift ;;
        --skip-nvim)        SKIP_NVIM=true; shift ;;
        --skip-blackarch)   SKIP_BLACKARCH=true; shift ;;
        --skip-harden)      SKIP_HARDEN=true; shift ;;
        --skip-qemu-agent)  SKIP_QEMU_AGENT=true; shift ;;
        --skip-auto-update) SKIP_AUTO_UPDATE=true; shift ;;
        --user)
            [[ -n "${2:-}" ]] || { echo "Error: --user requires a name"; exit 1; }
            NEW_USER="$2"; shift 2 ;;
        --github-user)
            [[ -n "${2:-}" ]] || { echo "Error: --github-user requires a name"; exit 1; }
            GITHUB_USER="$2"; shift 2 ;;
        -h|--help) sed -n '2,/^$/{s/^# \{0,1\}//;p}' "$0"; exit 0 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# ── packages ─────────────────────────────────────────────────────────────────

# Development-focused package set for a headless remote box: shell and
# terminal tools, language toolchains, containers, and network inspection.
# Desktop, media, personal and hardware tools from the Omarchy machine are
# left out (see arch-wsl/'s equivalent list in archWslSetup.sh).
PACMAN_PACKAGES=(
    # base & shell
    base-devel git github-cli openssh curl wget rsync unzip zip
    less man-db man-pages zsh bash-completion
    # editor, multiplexer, git/docker TUIs
    neovim vim tmux lazygit lazydocker
    # CLI tools (pacman-contrib: paccache, to keep the disk image small)
    fzf ripgrep fd bat eza zoxide jq direnv tldr hyperfine btop fastfetch pacman-contrib mise
    # containers & infra
    docker docker-compose docker-buildx terraform
    # C / C++ (clang ships clangd and clang-tidy; gdb backs the cpptools debugger)
    gcc make pkgconf clang llvm libc++ lldb gdb cmake ninja meson bear ccache
    gtest valgrind cppcheck strace ltrace
    # C# / .NET: LTS SDKs 10 and 8 with matching ASP.NET Core runtimes
    # (csharp-ls 0.16.0 targets net8.0)
    dotnet-sdk dotnet-sdk-8.0
    aspnet-runtime aspnet-runtime-8.0
    # Java LTS releases
    jdk17-openjdk jdk21-openjdk jdk25-openjdk maven gradle
    # Python (NeoVimConfig's DAP runs `python -m debugpy.adapter` on the system python)
    python python-pip python-pipx uv ruff python-pytest ipython python-debugpy
    # Bash
    shellcheck shfmt bats
    # prerequisites for Mason's npm-, pip- and luarocks-based packages
    nodejs npm lua51 luarocks tree-sitter-cli
    # Go & Rust
    go rust
    # network debugging & inspection (dig, nc, telnet, whois, nmap, tcpdump)
    bind openbsd-netcat inetutils whois nmap tcpdump
    # QEMU guest integration (clean shutdown/reboot, host-guest freeze/thaw, IP reporting)
    qemu-guest-agent
)

# Not in the official repos
AUR_PACKAGES=(
    herdr-bin   # terminal workspace manager for AI coding agents
    downgrade   # roll a package back to an older version from the Arch Linux Archive
)

# Global .NET tools (~/.dotnet/tools)
DOTNET_TOOLS=(
    dotnet-ef   # Entity Framework Core CLI
    csharpier   # C# formatter, same one conform.nvim runs
)

# jdtls needs Java 21+; matches the desktop's default
JAVA_DEFAULT="java-25-openjdk"

# Mason packages NeoVimConfig uses for C/C++, C#, Java, Python and Bash (LSP, DAP,
# formatters, linters). Installed during setup so the first nvim launch works.
MASON_PACKAGES=(
    clangd clang-format cpptools cpplint cmake-language-server cmakelang cmakelint
    csharp-language-server@0.16.0 netcoredbg csharpier   # csharp-ls pinned like NeoVimConfig's mason.lua
    jdtls java-debug-adapter google-java-format checkstyle
    jedi-language-server black pylint debugpy
    bash-language-server shellcheck beautysh
)

PACMAN_CONF=/etc/pacman.conf
PACMAN_KEYRING_DIR=/usr/share/pacman/keyrings
BLACKARCH_MIRRORLIST=/etc/pacman.d/blackarch-mirrorlist

# BlackArch keyring used to bootstrap the repo; after that pacman keeps the
# blackarch-keyring package updated. BlackArch's strap.sh isn't used because its
# signature check is commented out and checks a stale fingerprint. This tarball's
# .sig verified (2026-09-14) against the BlackArch Master key
# CBA3C7D4798912702DCF568E67D8BDF42AD93F4E from keyserver.ubuntu.com. To bump:
# download the new tarball and .sig, verify them with that key, update both values.
BLACKARCH_KEYRING_VERSION="20251011"
BLACKARCH_KEYRING_SHA256="e4934a37b018dda1df6403147c11c3e8efdc543419f10be485c7836e19f3cfbe"
BLACKARCH_PACKAGES=(blackarch-keyring blackarch-mirrorlist)
# Let those packages take over the bootstrap copies of their files
BLACKARCH_OVERWRITE=(--overwrite "$PACMAN_KEYRING_DIR/blackarch*" --overwrite "$BLACKARCH_MIRRORLIST")

NVIM_CONFIG_REPO="https://github.com/SykesTheLord/NeoVimConfig"
NVIM_CONFIG_DIR="$HOME/Projects/NeoVimConfig"

# Terminal-only configs; they don't depend on WSL or Windows Terminal (the
# hackerman zsh theme is baked-in 24-bit color, so it looks the same over SSH).
REMOTE_DOTFILES_DIR="$DOTFILES_DIR/arch-wsl"

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

# ── pre-flight ───────────────────────────────────────────────────────────────

is_arch || die "This script targets Arch Linux (/etc/arch-release is missing)."
if is_wsl; then
    die "Running under WSL; use archWslSetup.sh instead."
fi

# ── stage 1: root ────────────────────────────────────────────────────────────

# run_root <cmd...>: run as root, via sudo in the user stage
run_root() {
    if [[ $EUID -eq 0 ]]; then
        run "$@"
    else
        run sudo "$@"
    fi
}

enable_multilib() {
    if grep -q '^\[multilib\]' "$PACMAN_CONF"; then
        log "multilib repository already enabled"
        return
    fi
    log "Enabling the multilib repository"
    if grep -q '^#\[multilib\]$' "$PACMAN_CONF"; then
        # Exact header match, so [multilib-testing] stays commented out
        run_root sed -i '/^#\[multilib\]$/,/^#Include/ s/^#//' "$PACMAN_CONF"
    else
        run_root sh -c "printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> '$PACMAN_CONF'"
    fi
}

# Keyring, mirrorlist and pacman.conf entry. The blackarch-keyring and
# blackarch-mirrorlist packages are installed by the stage's pacman -Syu.
configure_blackarch() {
    local keyring="$PACMAN_KEYRING_DIR/blackarch.gpg"
    if [[ -f "$keyring" && -f "$BLACKARCH_MIRRORLIST" ]] && grep -q '^\[blackarch\]' "$PACMAN_CONF"; then
        log "BlackArch repository already configured"
        return
    fi
    log "Adding the BlackArch repository"

    if [[ ! -f "$keyring" ]]; then
        local name="blackarch-keyring-$BLACKARCH_KEYRING_VERSION"
        if $DRY_RUN; then
            echo "  [dry-run] download $name.tar.gz, check its SHA-256, install its keys into $PACMAN_KEYRING_DIR"
        else
            local tmp
            tmp=$(mktemp -d)
            curl -fsSL -o "$tmp/$name.tar.gz" "https://www.blackarch.org/keyring/$name.tar.gz" \
                || { rm -rf "$tmp"; die "Couldn't download the BlackArch keyring ($name.tar.gz)."; }
            if ! sha256sum --quiet -c <<< "$BLACKARCH_KEYRING_SHA256  $tmp/$name.tar.gz"; then
                rm -rf "$tmp"
                die "BlackArch keyring checksum mismatch; refusing to trust it. See BLACKARCH_KEYRING_* in this script."
            fi
            run_root tar xzf "$tmp/$name.tar.gz" --strip-components=1 -C "$PACMAN_KEYRING_DIR" \
                "$name/blackarch.gpg" "$name/blackarch-trusted" "$name/blackarch-revoked"
            rm -rf "$tmp"
        fi
        run_root pacman-key --populate blackarch
    fi

    if [[ ! -f "$BLACKARCH_MIRRORLIST" ]]; then
        run_root curl -fsSL -o "$BLACKARCH_MIRRORLIST" https://blackarch.org/blackarch-mirrorlist
    fi

    if ! grep -q '^\[blackarch\]' "$PACMAN_CONF"; then
        run_root sh -c "printf '\n[blackarch]\nInclude = %s\n' '$BLACKARCH_MIRRORLIST' >> '$PACMAN_CONF'"
    fi
}

# Extra pacman -Syu arguments for the BlackArch packages (empty with --skip-blackarch)
blackarch_install_args() {
    $SKIP_BLACKARCH || printf '%s\n' "${BLACKARCH_OVERWRITE[@]}" "${BLACKARCH_PACKAGES[@]}"
}

# import_github_keys <github-user> <target-user>: fetch the GitHub user's public
# keys and merge them into the target user's authorized_keys, replacing only the
# marked block for that GitHub user so any other keys already in the file (a
# manually-added key, another --github-user's block from an earlier run) are
# left alone. Returns non-zero (without dying) if no keys were found, so
# callers can decide whether to harden ssh.
import_github_keys() {
    local gh_user="$1" target="$2"
    local home authorized_keys keys begin end tmp
    home=$(eval echo "~$target")
    authorized_keys="$home/.ssh/authorized_keys"
    begin="# --- archRemoteSetup.sh: GitHub keys for $gh_user (begin) ---"
    end="# --- archRemoteSetup.sh: GitHub keys for $gh_user (end) ---"

    log "Importing SSH keys for GitHub user '$gh_user' into $target's authorized_keys"
    if $DRY_RUN; then
        echo "  [dry-run] curl https://github.com/$gh_user.keys -> $authorized_keys (replacing only that user's managed block)"
        return 0
    fi

    keys=$(curl -fsSL "https://github.com/$gh_user.keys") \
        || die "Couldn't fetch keys for GitHub user '$gh_user'."
    if [[ -z "$(tr -d '[:space:]' <<< "$keys")" ]]; then
        warn "GitHub user '$gh_user' has no public keys listed; not touching authorized_keys."
        return 1
    fi

    install -d -m 700 -o "$target" -g "$target" "$home/.ssh"
    touch "$authorized_keys"

    tmp=$(mktemp)
    # Drop any existing managed block for this GitHub user; everything else in
    # the file (other keys, other users' blocks) passes through untouched.
    awk -v b="$begin" -v e="$end" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$authorized_keys" > "$tmp"
    { cat "$tmp"; echo "$begin"; printf '%s\n' "$keys"; echo "$end"; } > "$authorized_keys"
    rm -f "$tmp"

    chmod 600 "$authorized_keys"
    chown "$target:$target" "$authorized_keys"
}

# harden_sshd: only called once a working authorized_keys is in place. Disables
# password and root login so the box is only reachable with the imported key.
harden_sshd() {
    local conf=/etc/ssh/sshd_config
    log "Disabling SSH password and root login in $conf"
    if $DRY_RUN; then
        echo "  [dry-run] set PasswordAuthentication no, PermitRootLogin no in $conf; reload sshd"
        return
    fi
    sed -i -E 's/^#?\s*PasswordAuthentication\s+.*/PasswordAuthentication no/' "$conf"
    grep -q '^PasswordAuthentication no' "$conf" || echo 'PasswordAuthentication no' >> "$conf"
    sed -i -E 's/^#?\s*PermitRootLogin\s+.*/PermitRootLogin no/' "$conf"
    grep -q '^PermitRootLogin no' "$conf" || echo 'PermitRootLogin no' >> "$conf"
    systemctl enable --now sshd
    systemctl reload sshd
}

# prompt_var <varname> <prompt-text>: like `read -rp`, but falls back to
# /dev/tty when stdin isn't a terminal (e.g. the script was piped in, or run
# over SSH without a pty), instead of silently reading EOF into an empty var.
prompt_var() {
    local __var="$1" __msg="$2"
    # shellcheck disable=SC2229  # indirect: $__var expands to a variable NAME for read to assign
    if [[ -t 0 ]]; then
        read -rp "$__msg" "$__var"
    elif [[ -r /dev/tty ]]; then
        read -rp "$__msg" "$__var" < /dev/tty
    else
        die "$__msg (no terminal to prompt on; pass it as a flag instead)"
    fi
}

root_stage() {
    [[ -n "$NEW_USER" ]] || prompt_var NEW_USER "Username to create for remote development: "
    [[ "$NEW_USER" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "Invalid username: $NEW_USER"

    [[ -n "$GITHUB_USER" ]] || prompt_var GITHUB_USER "GitHub username to import SSH keys from: "
    [[ -n "$GITHUB_USER" ]] || die "A GitHub username is required to import SSH keys."

    log "Initialising pacman keyring"
    if [[ ! -s /etc/pacman.d/gnupg/pubring.kbx && ! -s /etc/pacman.d/gnupg/pubring.gpg ]]; then
        run pacman-key --init
        run pacman-key --populate archlinux
    else
        log "Keyring already initialised"
    fi

    # curl isn't part of the "base" group, but configure_blackarch() and
    # import_github_keys() both shell out to it, and both run before the main
    # bootstrap install below on a minimal pacstrap image. Install it first.
    command -v curl &>/dev/null || run pacman -Sy --needed --noconfirm curl

    enable_multilib
    $SKIP_BLACKARCH || configure_blackarch

    log "Upgrading system and installing bootstrap packages"
    local repo_args=()
    mapfile -t repo_args < <(blackarch_install_args)
    run pacman -Syu --needed --noconfirm "${repo_args[@]}" base-devel sudo zsh git openssh curl

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
        run passwd -l "$NEW_USER"   # key-only login; import_github_keys sets up access
    fi

    local imported=true
    import_github_keys "$GITHUB_USER" "$NEW_USER" || imported=false

    if $imported && ! $SKIP_HARDEN; then
        harden_sshd
    elif ! $imported; then
        warn "No SSH keys imported; leaving sshd_config untouched. Re-run with a valid --github-user, or add a key manually, before locking out password login."
    else
        warn "--skip-harden set; sshd_config left untouched."
    fi

    if [[ "$DOTFILES_DIR" == /root/* ]]; then
        warn "This repo is under /root, which $NEW_USER can't read. Re-clone it as $NEW_USER for stage 2."
    fi

    echo ""
    echo "✓ Stage 1 complete. Next:"
    echo "  1. Confirm you can SSH in as $NEW_USER with the imported GitHub key"
    echo "  2. As $NEW_USER, run: bash <path-to>/DotFiles/archRemoteSetup.sh"
}

# ── stage 2: user ────────────────────────────────────────────────────────────

install_packages() {
    enable_multilib
    $SKIP_BLACKARCH || configure_blackarch

    log "Installing pacman packages"
    local repo_args=()
    mapfile -t repo_args < <(blackarch_install_args)
    run sudo pacman -Syu --needed --noconfirm "${repo_args[@]}" "${PACMAN_PACKAGES[@]}"
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
    run rsync -rlt --chmod=D755,F644 --backup --suffix=.bak "$REMOTE_DOTFILES_DIR/" "$HOME/"
    run chmod +x "$HOME/.scripts/tmux-sessionizer"
}

install_mise_tools() {
    log "Installing mise tools from ~/.config/mise/config.toml (Claude Code, Codex)"
    run mise install
}

install_nvim_config() {
    log "Installing Neovim config ($NVIM_CONFIG_REPO)"
    if [[ -d "$NVIM_CONFIG_DIR/.git" ]]; then
        run git -C "$NVIM_CONFIG_DIR" pull --ff-only
    else
        # A prior run interrupted mid-clone (e.g. network drop) can leave a
        # non-empty, non-git directory here; `git clone` would refuse it and
        # abort the whole rerun, so clear it out first.
        if [[ -e "$NVIM_CONFIG_DIR" ]]; then
            warn "$NVIM_CONFIG_DIR exists but isn't a git repo (likely an interrupted clone); removing it"
            run rm -rf "$NVIM_CONFIG_DIR"
        fi
        run mkdir -p "$(dirname "$NVIM_CONFIG_DIR")"
        run git clone "$NVIM_CONFIG_REPO" "$NVIM_CONFIG_DIR"
    fi

    # install.sh symlinks the clone to ~/.config/nvim, so the clone has to stay put.
    if [[ "$(readlink -f "$HOME/.config/nvim" 2>/dev/null)" == "$NVIM_CONFIG_DIR" ]]; then
        log "$HOME/.config/nvim already links to the clone; refreshing plugins"
        run nvim --headless +"qall!"
    else
        run bash "$NVIM_CONFIG_DIR/install.sh" --yes --force
    fi
}

configure_java() {
    if ! $DRY_RUN && [[ "$(archlinux-java get 2>/dev/null)" == "$JAVA_DEFAULT" ]]; then
        log "$JAVA_DEFAULT is already the default Java"
        return
    fi
    log "Setting the default Java to $JAVA_DEFAULT"
    run sudo archlinux-java set "$JAVA_DEFAULT"
}

install_dotnet_tools() {
    log "Installing global .NET tools"
    export DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1
    local installed="" tool
    if command -v dotnet &>/dev/null; then
        installed=$(dotnet tool list --global 2>/dev/null | awk 'NR > 2 { print $1 }')
    fi
    for tool in "${DOTNET_TOOLS[@]}"; do
        if grep -qx "$tool" <<< "$installed"; then
            log "$tool already installed"
        else
            run dotnet tool install --global "$tool"
        fi
    done
}

install_mason_packages() {
    local mason="$HOME/.local/share/nvim/mason/packages" pkg
    local missing=()
    for pkg in "${MASON_PACKAGES[@]}"; do
        [[ -d "$mason/${pkg%@*}" ]] || missing+=("$pkg")
    done
    if (( ${#missing[@]} == 0 )); then
        log "Mason packages already installed"
        return
    fi

    log "Installing Mason packages: ${missing[*]}"
    if $DRY_RUN; then
        echo "  [dry-run] nvim --headless: install and wait for ${missing[*]}"
        return
    fi

    # NeoVimConfig starts some installs asynchronously at startup and :MasonInstall
    # doesn't wait for installs already in progress, so start whatever isn't running
    # and wait until none of the wanted packages are still installing.
    local script
    script=$(mktemp --suffix=.lua)
    cat > "$script" << 'EOF'
local registry = require("mason-registry")
local specs = vim.split(vim.env.MASON_WANTED or "", " ", { trimempty = true })
local function get(spec)
    local ok, pkg = pcall(registry.get_package, (spec:gsub("@.*$", "")))
    return ok and pkg or nil
end

local refreshed = false
registry.refresh(function() refreshed = true end)
vim.wait(300000, function() return refreshed end, 200)

for _, spec in ipairs(specs) do
    local pkg = get(spec)
    if pkg and not pkg:is_installed() and not pkg:is_installing() then
        pkg:install({ version = spec:match("@(.+)$") })
    end
end

vim.wait(3600000, function()
    for _, spec in ipairs(specs) do
        local pkg = get(spec)
        if pkg and pkg:is_installing() then return false end
    end
    return true
end, 1000)
EOF
    MASON_WANTED="${missing[*]}" nvim --headless -c "luafile $script" -c "qall" || true
    rm -f "$script"

    local failed=()
    for pkg in "${missing[@]}"; do
        [[ -d "$mason/${pkg%@*}" ]] || failed+=("$pkg")
    done
    if (( ${#failed[@]} > 0 )); then
        warn "Mason packages that didn't install: ${failed[*]} (retry inside nvim with :Mason)"
    fi
}

setup_docker() {
    if [[ "$(ps -p 1 -o comm= 2>/dev/null)" == "systemd" ]]; then
        if systemctl is-enabled --quiet docker.socket 2>/dev/null && systemctl is-active --quiet docker.socket 2>/dev/null; then
            log "docker.socket already enabled"
        else
            log "Enabling docker.socket"
            run sudo systemctl enable --now docker.socket
        fi
    else
        warn "systemd isn't PID 1, so docker won't start on boot."
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

setup_qemu_guest_agent() {
    if systemctl is-enabled --quiet qemu-guest-agent 2>/dev/null && systemctl is-active --quiet qemu-guest-agent 2>/dev/null; then
        log "qemu-guest-agent already enabled"
        return
    fi
    log "Enabling qemu-guest-agent"
    run sudo systemctl enable --now qemu-guest-agent
}

# Unattended pacman + AUR update, run by systemd on a Mon/Wed/Sat 03:00 timer.
# Idempotent: only (re)writes and reloads the units if their content actually
# changed, and only (re)enables the timer if it isn't already enabled+active.
install_auto_updates() {
    local script_path=/usr/local/bin/arch-auto-update.sh
    local service_path=/etc/systemd/system/arch-auto-update.service
    local timer_path=/etc/systemd/system/arch-auto-update.timer
    local tmp_script tmp_service tmp_timer

    tmp_script=$(mktemp)
    cat > "$tmp_script" << 'EOF'
#!/bin/bash
# Written by DotFiles/archRemoteSetup.sh. Runs as root via the
# arch-auto-update.service unit; AUR updates and the Claude Code check run as
# __TARGET_USER__ via runuser.
set -euo pipefail

pacman -Syu --noconfirm
if runuser -l '__TARGET_USER__' -c 'command -v yay' &>/dev/null; then
    runuser -l '__TARGET_USER__' -c 'yay -Syu --noconfirm'
fi
command -v paccache &>/dev/null && paccache -rk2

# Reboot into a newer kernel automatically, but only when it's safe: nobody
# logged in, and no Claude Code agent running (mid-edit or mid-plan) for
# __TARGET_USER__. Arch has no live-patching feed for its rolling kernel
# (kpatch needs a hand-built patch per kernel build), so this is the
# "no restarts needed" story instead: unattended, but deferred while in use.
# A skipped reboot is retried at the next Mon/Wed/Sat window.
running_kernel=$(uname -r)
installed_kernel=$(file -b /boot/vmlinuz-linux 2>/dev/null | grep -oP 'version \K\S+' || true)
if [[ -n "$installed_kernel" && "$installed_kernel" != "$running_kernel" ]]; then
    if [[ -n "$(who)" ]]; then
        logger -t arch-auto-update "Kernel update pending ($running_kernel -> $installed_kernel) but users are logged in; deferring reboot"
    elif runuser -l '__TARGET_USER__' -c 'pgrep -f claude' &>/dev/null; then
        logger -t arch-auto-update "Kernel update pending ($running_kernel -> $installed_kernel) but Claude Code is running; deferring reboot"
    else
        logger -t arch-auto-update "Kernel update pending ($running_kernel -> $installed_kernel); no active users or Claude Code sessions, rebooting"
        systemctl reboot
    fi
fi
exit 0
EOF
    sed -i "s/__TARGET_USER__/$USER/g" "$tmp_script"

    tmp_service=$(mktemp)
    cat > "$tmp_service" << 'EOF'
[Unit]
Description=Arch Linux system update (pacman + AUR)
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/arch-auto-update.sh
EOF

    tmp_timer=$(mktemp)
    cat > "$tmp_timer" << 'EOF'
[Unit]
Description=Run arch-auto-update.service Mon/Wed/Sat at 03:00

[Timer]
OnCalendar=Mon,Wed,Sat 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

    local changed=false
    cmp -s "$tmp_script" "$script_path" 2>/dev/null || changed=true
    cmp -s "$tmp_service" "$service_path" 2>/dev/null || changed=true
    cmp -s "$tmp_timer" "$timer_path" 2>/dev/null || changed=true

    if ! $changed && systemctl is-enabled --quiet arch-auto-update.timer 2>/dev/null \
        && systemctl is-active --quiet arch-auto-update.timer 2>/dev/null; then
        log "Auto-update timer already installed and enabled"
        rm -f "$tmp_script" "$tmp_service" "$tmp_timer"
        return
    fi

    log "Installing the Mon/Wed/Sat 03:00 auto-update timer"
    if $DRY_RUN; then
        echo "  [dry-run] write $script_path, ${service_path##*/}, ${timer_path##*/}; enable timer"
        rm -f "$tmp_script" "$tmp_service" "$tmp_timer"
        return
    fi

    sudo install -m 755 "$tmp_script" "$script_path"
    sudo install -m 644 "$tmp_service" "$service_path"
    sudo install -m 644 "$tmp_timer" "$timer_path"
    rm -f "$tmp_script" "$tmp_service" "$tmp_timer"

    sudo systemctl daemon-reload
    sudo systemctl enable --now arch-auto-update.timer
}

user_stage() {
    [[ -z "$NEW_USER" && -z "$GITHUB_USER" ]] || warn "--user/--github-user are only used when running as root; ignoring them."
    command -v sudo &>/dev/null || die "sudo is missing. Run stage 1 as root first: bash archRemoteSetup.sh --user <name>"
    $DRY_RUN || sudo -v || die "sudo access is required."

    log "Starting Arch remote dev box setup (dry_run=$DRY_RUN)"

    install_packages
    install_yay
    install_aur_packages
    install_oh_my_zsh
    deploy_dotfiles
    install_mise_tools
    install_dotnet_tools
    if ! $SKIP_NVIM; then
        install_nvim_config
    fi
    configure_java
    $SKIP_NVIM || install_mason_packages
    setup_docker
    set_login_shell
    $SKIP_QEMU_AGENT || setup_qemu_guest_agent
    $SKIP_AUTO_UPDATE || install_auto_updates

    echo ""
    echo "✓ Arch remote dev box setup complete$($DRY_RUN && echo " (dry run, nothing changed)" || true)"
    echo ""
    echo "Next steps:"
    echo "  1. Log out and back in (applies the shell and docker group)"
    echo "  2. Run 'gh auth login', then 'nvim' once to finish plugin/LSP installs"
}

if [[ $EUID -eq 0 ]]; then
    root_stage
else
    user_stage
fi
