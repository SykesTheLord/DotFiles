#!/bin/bash
# linuxRemoteSetup.sh
# Set up a headless Linux box, running as a QEMU guest, as a remote SSH
# development machine: a dedicated user with SSH key access imported from
# GitHub, qemu-guest-agent, an unattended update timer, then zsh + oh-my-zsh,
# Neovim, tmux/herdr, Docker, and toolchains for C/C++, C#/.NET, Java, Python
# and Bash. Supports Arch, Debian, Ubuntu, Fedora, CentOS/RHEL/Rocky/AlmaLinux
# and openSUSE (detected via dotfiles_lib.sh). Reuses the terminal-only
# arch-wsl/ dotfiles (they don't depend on WSL, Windows Terminal, or Arch).
#
# A few things have no real equivalent outside Arch and stay Arch-only:
# BlackArch, and the AUR-only tools yay installs (herdr, downgrade — not in
# the default repos of the other distros, and no safe generic install method
# for either). Everywhere else gets a log line noting they're skipped, not a
# fake stand-in. lazygit and lazydocker aren't packaged on the other distros
# either, but both publish prebuilt Linux binaries on their GitHub releases
# (the same mechanism their own install docs use), so install_lazygit_lazydocker
# fetches those directly instead of skipping them.
#
# Stage 1, as root on a fresh box (clone this repo somewhere world-readable,
# e.g. /opt/DotFiles, or re-clone it as the new user for stage 2):
#   bash linuxRemoteSetup.sh --user <name> [--github-user <name>] [--skip-github]
#   Initialises the package manager, locale, sudo and the user account.
#   Prompts for --user if omitted. Unless --github-user is already given (or
#   --skip-github opts out), it then always asks whether to enroll a GitHub
#   account's public keys into ~/.ssh/authorized_keys, and if so, which one.
#   Once a key is installed, disables SSH password and root login
#   (--skip-harden opts out); if you decline enrollment, the account is left
#   with a locked password and no key, so set one (`passwd <user>`) or add a
#   key by hand before disconnecting.
#
# Stage 2, as that user (also asks the same GitHub-enrollment question as
# stage 1, so an already-configured, non-root user can self-service add or
# refresh their own keys; defaults to no, and never touches sshd_config):
#   bash linuxRemoteSetup.sh [--dry-run] [--skip-nvim] [--skip-blackarch] \
#       [--skip-qemu-agent] [--skip-auto-update] [--github-user <name>] [--skip-github]
#
#   --dry-run          Print what would happen without changing anything
#   --skip-nvim        Don't install NeoVimConfig or Mason packages
#   --skip-blackarch   Don't add the BlackArch repository (Arch only)
#   --skip-qemu-agent  Don't install/enable qemu-guest-agent
#   --skip-auto-update Don't install the Mon/Wed/Sat 03:00 update timer
#   --skip-github      Don't ask about GitHub key enrollment (either stage)
#
# The update timer (linux-auto-update.service/.timer) upgrades all packages
# via the distro's own package manager (plus AUR via yay on Arch), then every
# Monday, Wednesday and Saturday at 03:00. There's no live-patch feed for any
# of these distros' kernels that covers arbitrary updates, so instead of
# live-patching, the timer detects a pending kernel update and reboots into it
# unattended, but only when nobody is logged in and no Claude Code agent is
# running; otherwise it defers to the next Mon/Wed/Sat window.
#
# Package names are a best-effort mapping from the Arch original to Debian/
# Ubuntu, Fedora/CentOS and openSUSE naming conventions. A handful of the less
# common dev tools (eza, fastfetch, very recent JDK/.NET SDK releases, etc.)
# may not exist in every release's repos; installs are resilient to individual
# unknown packages (the run continues; check the install_packages log for
# anything skipped) rather than aborting the whole setup.

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
SKIP_GITHUB=false
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
        --skip-github)      SKIP_GITHUB=true; shift ;;
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

# ── distro / package manager detection ──────────────────────────────────────

if is_arch; then
    PKG_MANAGER=pacman
elif is_fedora || is_centos; then
    PKG_MANAGER=dnf
elif is_opensuse; then
    PKG_MANAGER=zypper
elif is_debian || is_ubuntu; then
    PKG_MANAGER=apt
else
    echo "Error: unsupported distro (checked Arch, Fedora, CentOS/RHEL family, openSUSE, Debian, Ubuntu)." >&2
    exit 1
fi

if is_arch && is_wsl; then
    echo "Error: running Arch under WSL; use archWslSetup.sh instead." >&2
    exit 1
fi

# Debian/Ubuntu use the "sudo" group and ship the ssh daemon's unit as
# ssh.service; everyone else uses "wheel" and sshd.service.
case "$PKG_MANAGER" in
    apt) SUDO_GROUP=sudo; SSHD_UNIT=ssh ;;
    *)   SUDO_GROUP=wheel; SSHD_UNIT=sshd ;;
esac

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

# Not in the official repos. Arch-only: no AUR equivalent exists elsewhere.
AUR_PACKAGES=(
    herdr-bin   # terminal workspace manager for AI coding agents
    downgrade   # roll a package back to an older version from the Arch Linux Archive
)

# Debian/Ubuntu. herdr and a pacman-contrib-style cache cleaner have no
# packaged equivalent here, so they're left out rather than guessed at (see
# the AUR_PACKAGES comment above). lazygit/lazydocker aren't packaged either,
# but install_lazygit_lazydocker fetches them from GitHub releases instead.
# fd/bat ship under
# fdfind/batcat on Debian/Ubuntu; deploy_dotfiles symlinks fd/bat to them.
APT_PACKAGES=(
    build-essential git gh openssh-server curl wget rsync unzip zip
    less man-db manpages zsh bash-completion
    neovim vim tmux
    fzf ripgrep fd-find bat eza zoxide jq direnv tldr hyperfine btop fastfetch mise
    docker.io docker-compose-v2 docker-buildx-plugin terraform
    gcc g++ pkg-config clang llvm libc++-dev lldb gdb cmake ninja-build meson bear ccache
    libgtest-dev valgrind cppcheck strace
    dotnet-sdk-8.0 dotnet-sdk-10.0 aspnetcore-runtime-8.0 aspnetcore-runtime-10.0
    openjdk-17-jdk openjdk-21-jdk openjdk-25-jdk maven gradle
    python3 python3-pip pipx python3-pytest ipython3 python3-debugpy
    shellcheck shfmt bats
    nodejs npm lua5.1 liblua5.1-0-dev luarocks
    golang-go rustc cargo
    bind9-dnsutils netcat-openbsd telnet whois nmap tcpdump
    qemu-guest-agent
)

# Fedora / CentOS-RHEL family. "@development-tools" is a dnf group reference,
# valid directly in `dnf install`. Docker needs its own repo here first (see
# setup_docker_repo) since neither ships docker-ce in the base repos.
DNF_PACKAGES=(
    @development-tools git gh openssh-server curl wget rsync unzip zip
    less man-db man-pages zsh bash-completion
    neovim vim tmux
    fzf ripgrep fd-find bat eza zoxide jq direnv tldr hyperfine btop fastfetch mise
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin terraform
    gcc gcc-c++ pkgconf-pkg-config clang llvm libcxx-devel lldb gdb cmake ninja-build meson bear ccache
    gtest-devel valgrind cppcheck strace ltrace
    dotnet-sdk-8.0 dotnet-sdk-10.0 aspnetcore-runtime-8.0 aspnetcore-runtime-10.0
    java-17-openjdk-devel java-21-openjdk-devel java-25-openjdk-devel maven gradle
    python3 python3-pip pipx python3-pytest python3-ipython python3-debugpy
    ShellCheck shfmt bats
    nodejs npm lua lua-devel luarocks
    golang rust cargo
    bind-utils nmap-ncat telnet whois nmap tcpdump
    qemu-guest-agent glibc-langpack-en
)

# openSUSE. "devel_basis" is a zypper pattern, installed separately (patterns
# can't mix with regular packages in one `zypper install`). Both the
# versioned (nodejsNN/npmNN) and plain nodejs/npm names are listed since the
# convention varies by openSUSE version; whichever doesn't exist is skipped.
ZYPPER_PACKAGES=(
    git gh openssh curl wget rsync unzip zip
    less man man-pages zsh bash-completion
    neovim vim tmux
    fzf ripgrep fd bat eza zoxide jq direnv tldr hyperfine btop fastfetch mise
    docker docker-compose docker-buildx terraform
    gcc gcc-c++ pkg-config clang llvm libc++-devel lldb gdb cmake ninja meson bear ccache
    gtest valgrind cppcheck strace ltrace
    dotnet-sdk-8.0 dotnet-sdk-10.0 aspnetcore-runtime-8.0 aspnetcore-runtime-10.0
    java-17-openjdk-devel java-21-openjdk-devel java-25-openjdk-devel maven gradle
    python3 python3-pip python3-pipx python3-pytest python3-iPython python3-debugpy
    ShellCheck shfmt bats
    nodejs20 npm20 nodejs npm lua51 lua51-devel luarocks
    go rust cargo
    bind-utils netcat-openbsd inetutils telnet whois nmap tcpdump
    qemu-guest-agent
)

# Global .NET tools (~/.dotnet/tools)
DOTNET_TOOLS=(
    dotnet-ef   # Entity Framework Core CLI
    csharpier   # C# formatter, same one conform.nvim runs
)

# jdtls needs Java 21+; matches the desktop's default. Used verbatim by Arch's
# archlinux-java; the generic configure_java path below searches for a JDK
# directory matching this version number.
JAVA_DEFAULT="java-25-openjdk"
JAVA_DEFAULT_VERSION="25"

# Mason packages NeoVimConfig uses for C/C++, C#, Java, Python and Bash (LSP, DAP,
# formatters, linters). Installed during setup so the first nvim launch works.
# Distro-agnostic: Mason fetches these from its own registry (npm/pip/go/cargo),
# so this list doesn't change per distro, only the prerequisites above do.
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

# Terminal-only configs; they don't depend on WSL, Windows Terminal or Arch (the
# hackerman zsh theme is baked-in 24-bit color, so it looks the same over SSH
# regardless of distro).
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

# run_root <cmd...>: run as root, via sudo in the user stage
run_root() {
    if [[ $EUID -eq 0 ]]; then
        run "$@"
    else
        run sudo "$@"
    fi
}

# pkg_install <pkgs...>: install packages as root (via sudo if not already
# root), tolerating individual unknown-package names rather than aborting the
# whole transaction — the package lists above are a best-effort cross-distro
# mapping and not every tool exists in every release's repos.
pkg_install() {
    case "$PKG_MANAGER" in
        pacman) run_root pacman -S --needed --noconfirm "$@" ;;
        apt)    run_root apt-get install -y --ignore-missing "$@" ;;
        dnf)    run_root dnf install -y --setopt=strict=0 --skip-broken "$@" ;;
        zypper) run_root zypper --non-interactive install --no-recommends --ignore-unknown "$@" ;;
    esac
}

# ── Arch-only: BlackArch / multilib ──────────────────────────────────────────

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
    is_arch && ! $SKIP_BLACKARCH && printf '%s\n' "${BLACKARCH_OVERWRITE[@]}" "${BLACKARCH_PACKAGES[@]}"
    return 0
}

# ── Fedora/CentOS-only: Docker CE repo ───────────────────────────────────────

# Neither Fedora nor the CentOS/RHEL family ships docker-ce in its base repos
# (both promote podman instead), so it needs Docker's own repo added first.
setup_docker_repo() {
    [[ "$PKG_MANAGER" == dnf ]] || return 0
    if [[ -f /etc/yum.repos.d/docker-ce.repo ]]; then
        log "Docker CE repository already configured"
        return
    fi
    log "Adding the Docker CE repository"
    local repo_url="https://download.docker.com/linux/centos/docker-ce.repo"
    is_fedora && repo_url="https://download.docker.com/linux/fedora/docker-ce.repo"
    run_root dnf -y install dnf-plugins-core
    run_root dnf config-manager --add-repo "$repo_url"
}

# ── SSH key enrollment (shared by both stages) ──────────────────────────────

# import_github_keys <github-user> <target-user>: fetch the GitHub user's public
# keys and merge them into the target user's authorized_keys, replacing only the
# marked block for that GitHub user so any other keys already in the file (a
# manually-added key, another --github-user's block from an earlier run) are
# left alone. Returns non-zero (without dying) if no keys were found, so
# callers can decide whether to harden ssh. Works both as root (stage 1,
# target is a different, newly-created user) and as the target user themselves
# (stage 2, self-service enrollment into their own already-owned homedir).
import_github_keys() {
    local gh_user="$1" target="$2"
    local home authorized_keys keys begin end tmp
    home=$(eval echo "~$target")
    authorized_keys="$home/.ssh/authorized_keys"
    begin="# --- linuxRemoteSetup.sh: GitHub keys for $gh_user (begin) ---"
    end="# --- linuxRemoteSetup.sh: GitHub keys for $gh_user (end) ---"

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

    if [[ $EUID -eq 0 ]]; then
        install -d -m 700 -o "$target" -g "$target" "$home/.ssh"
    else
        install -d -m 700 "$home/.ssh"   # already ours; no chown needed (or permitted)
    fi
    touch "$authorized_keys"

    tmp=$(mktemp)
    # Drop any existing managed block for this GitHub user; everything else in
    # the file (other keys, other users' blocks) passes through untouched.
    awk -v b="$begin" -v e="$end" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$authorized_keys" > "$tmp"
    { cat "$tmp"; echo "$begin"; printf '%s\n' "$keys"; echo "$end"; } > "$authorized_keys"
    rm -f "$tmp"

    chmod 600 "$authorized_keys"
    [[ $EUID -eq 0 ]] && chown "$target:$target" "$authorized_keys"
    return 0
}

# harden_sshd: only called once a working authorized_keys is in place. Disables
# password and root login so the box is only reachable with the imported key.
harden_sshd() {
    local conf=/etc/ssh/sshd_config
    log "Disabling SSH password and root login in $conf"
    if $DRY_RUN; then
        echo "  [dry-run] set PasswordAuthentication no, PermitRootLogin no in $conf; reload $SSHD_UNIT"
        return
    fi
    sed -i -E 's/^#?\s*PasswordAuthentication\s+.*/PasswordAuthentication no/' "$conf"
    grep -q '^PasswordAuthentication no' "$conf" || echo 'PasswordAuthentication no' >> "$conf"
    sed -i -E 's/^#?\s*PermitRootLogin\s+.*/PermitRootLogin no/' "$conf"
    grep -q '^PermitRootLogin no' "$conf" || echo 'PermitRootLogin no' >> "$conf"
    systemctl enable --now "$SSHD_UNIT"
    systemctl reload "$SSHD_UNIT"
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

# confirm <prompt-text> [default(y|n)]: yes/no prompt with the same /dev/tty
# fallback as prompt_var, except a fully non-interactive shell takes the
# default instead of dying (there's always a sensible default here, unlike a
# username). Returns 0 for yes, 1 for no.
confirm() {
    local msg="$1" default="${2:-y}" reply=""
    [[ "$default" == y ]] && msg="$msg [Y/n] " || msg="$msg [y/N] "
    if [[ -t 0 ]]; then
        read -rp "$msg" reply
    elif [[ -r /dev/tty ]]; then
        read -rp "$msg" reply < /dev/tty
    fi
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy] ]]
}

# decide_github_user <target-user> <confirm-default y|n>: sets GITHUB_USER
# (unless --skip-github or --github-user already decided it) by always asking
# whether to enroll a GitHub account's keys for <target-user>, and if so,
# which one. Runs in both stages: stage 1 asks for the account it's about to
# create, stage 2 lets an already-configured, non-root user enroll (or
# refresh) their own keys the same way.
decide_github_user() {
    local target="$1" default="$2"
    if $SKIP_GITHUB; then
        [[ -z "$GITHUB_USER" ]] || warn "--skip-github set; ignoring --github-user."
        GITHUB_USER=""
    elif [[ -z "$GITHUB_USER" ]] && confirm "Enroll SSH keys from a GitHub account for $target?" "$default"; then
        prompt_var GITHUB_USER "GitHub username to import SSH keys from: "
    fi
}

# ── locale ───────────────────────────────────────────────────────────────────

configure_locale() {
    log "Configuring locale (en_US.UTF-8)"
    case "$PKG_MANAGER" in
        dnf)
            pkg_install glibc-langpack-en
            if [[ -f /etc/locale.conf ]]; then
                grep -q '^LANG=en_US.UTF-8' /etc/locale.conf 2>/dev/null \
                    || run_sh "echo 'LANG=en_US.UTF-8' >> /etc/locale.conf"
            else
                run_sh 'echo "LANG=en_US.UTF-8" > /etc/locale.conf'
            fi
            ;;
        apt)
            if ! locale -a 2>/dev/null | grep -qix 'en_US\.utf8'; then
                run sed -i 's/^# *\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
                run locale-gen
            fi
            run_root update-locale LANG=en_US.UTF-8
            ;;
        pacman|zypper)
            if ! locale -a 2>/dev/null | grep -qix 'en_US\.utf8'; then
                run sed -i 's/^#\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
                run locale-gen
            fi
            [[ -f /etc/locale.conf ]] || run_sh 'echo "LANG=en_US.UTF-8" > /etc/locale.conf'
            ;;
    esac
}

# ── stage 1: root ────────────────────────────────────────────────────────────

root_stage() {
    [[ -n "$NEW_USER" ]] || prompt_var NEW_USER "Username to create for remote development: "
    [[ "$NEW_USER" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "Invalid username: $NEW_USER"

    decide_github_user "$NEW_USER" y

    if is_arch; then
        log "Initialising pacman keyring"
        if [[ ! -s /etc/pacman.d/gnupg/pubring.kbx && ! -s /etc/pacman.d/gnupg/pubring.gpg ]]; then
            run pacman-key --init
            run pacman-key --populate archlinux
        else
            log "Keyring already initialised"
        fi

        # curl isn't part of the "base" group, but configure_blackarch() and
        # import_github_keys() both shell out to it, and both run before the
        # main bootstrap install below on a minimal pacstrap image.
        command -v curl &>/dev/null || run pacman -Sy --needed --noconfirm curl

        enable_multilib
        $SKIP_BLACKARCH || configure_blackarch

        log "Upgrading system and installing bootstrap packages"
        local repo_args=()
        mapfile -t repo_args < <(blackarch_install_args)
        run pacman -Syu --needed --noconfirm "${repo_args[@]}" base-devel sudo zsh git openssh curl
    else
        command -v curl &>/dev/null || pkg_install curl

        log "Upgrading system and installing bootstrap packages"
        case "$PKG_MANAGER" in
            apt)
                run apt-get update -y
                run apt-get install -y --ignore-missing sudo zsh git openssh-server curl
                ;;
            dnf)
                run dnf install -y --setopt=strict=0 --skip-broken sudo zsh git openssh-server curl
                ;;
            zypper)
                run zypper --non-interactive install -t pattern devel_basis
                run zypper --non-interactive install --no-recommends --ignore-unknown sudo zsh git openssh curl
                ;;
        esac
    fi

    configure_locale

    log "Allowing the $SUDO_GROUP group to use sudo"
    run_sh "echo '%$SUDO_GROUP ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-$SUDO_GROUP && chmod 440 /etc/sudoers.d/10-$SUDO_GROUP"

    local zsh_path
    zsh_path=$(command -v zsh || echo /usr/bin/zsh)

    if id "$NEW_USER" &>/dev/null; then
        log "User $NEW_USER already exists; ensuring $SUDO_GROUP membership"
        run usermod -aG "$SUDO_GROUP" "$NEW_USER"
    else
        log "Creating user $NEW_USER"
        run useradd -m -G "$SUDO_GROUP" -s "$zsh_path" "$NEW_USER"
        run passwd -l "$NEW_USER"   # locked until a key is imported or a password is set below
    fi

    local imported=false
    if [[ -n "$GITHUB_USER" ]]; then
        import_github_keys "$GITHUB_USER" "$NEW_USER" && imported=true
    fi

    if $imported && ! $SKIP_HARDEN; then
        harden_sshd
    elif $imported; then
        warn "--skip-harden set; sshd_config left untouched."
    elif [[ -n "$GITHUB_USER" ]]; then
        warn "No SSH keys imported; leaving sshd_config untouched. Re-run with a valid --github-user, or add a key manually, before locking out password login."
    else
        warn "No GitHub account enrolled; $NEW_USER has a locked password and no SSH key. Run 'passwd $NEW_USER' or add a key to that user's ~/.ssh/authorized_keys before disconnecting."
    fi

    if [[ "$DOTFILES_DIR" == /root/* ]]; then
        warn "This repo is under /root, which $NEW_USER can't read. Re-clone it as $NEW_USER for stage 2."
    fi

    echo ""
    echo "✓ Stage 1 complete. Next:"
    echo "  1. Confirm you can SSH in as $NEW_USER with the imported GitHub key"
    echo "  2. As $NEW_USER, run: bash <path-to>/DotFiles/linuxRemoteSetup.sh"
}

# ── stage 2: user ────────────────────────────────────────────────────────────

install_packages() {
    if is_arch; then
        enable_multilib
        $SKIP_BLACKARCH || configure_blackarch
        log "Installing pacman packages"
        local repo_args=()
        mapfile -t repo_args < <(blackarch_install_args)
        run sudo pacman -Syu --needed --noconfirm "${repo_args[@]}" "${PACMAN_PACKAGES[@]}"
        return
    fi

    setup_docker_repo
    log "Installing packages (herdr has no equivalent here; skipped)"
    case "$PKG_MANAGER" in
        apt)
            run sudo apt-get update -y
            run sudo apt-get full-upgrade -y
            run sudo apt-get install -y --ignore-missing "${APT_PACKAGES[@]}"
            ;;
        dnf)
            run sudo dnf upgrade -y
            run sudo dnf install -y --setopt=strict=0 --skip-broken "${DNF_PACKAGES[@]}"
            ;;
        zypper)
            run sudo zypper --non-interactive install -t pattern devel_basis
            run sudo zypper --non-interactive refresh
            run sudo zypper --non-interactive update
            run sudo zypper --non-interactive install --no-recommends --ignore-unknown "${ZYPPER_PACKAGES[@]}"
            ;;
    esac
}

# Debian/Ubuntu package fd/bat under fdfind/batcat to avoid name clashes with
# unrelated existing commands; symlink the plain names so configs that expect
# `fd`/`bat` (fzf previews, eza, etc.) work the same as on every other distro.
symlink_renamed_tools() {
    [[ "$PKG_MANAGER" == apt ]] || return 0
    run mkdir -p "$HOME/.local/bin"
    if command -v fdfind &>/dev/null && [[ ! -e "$HOME/.local/bin/fd" ]]; then
        run ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi
    if command -v batcat &>/dev/null && [[ ! -e "$HOME/.local/bin/bat" ]]; then
        run ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"
    fi
}

# tree-sitter-cli isn't natively packaged on most non-Arch distros; npm (just
# installed above) gets the same binary everywhere.
install_tree_sitter_cli() {
    is_arch && return 0
    if command -v tree-sitter &>/dev/null; then
        log "tree-sitter-cli already installed"
        return
    fi
    log "Installing tree-sitter-cli via npm"
    run sudo npm install -g tree-sitter-cli
}

# uv and ruff aren't reliably packaged outside Arch; pipx (in the package
# lists above) gets both the same way on every other distro.
install_uv_ruff() {
    is_arch && return 0
    if ! command -v pipx &>/dev/null; then
        warn "pipx not found; skipping uv/ruff install"
        return
    fi
    local tool
    for tool in uv ruff; do
        if command -v "$tool" &>/dev/null; then
            log "$tool already installed"
        else
            log "Installing $tool via pipx"
            run pipx install "$tool"
        fi
    done
}

# install_github_release_binary <owner/repo> <binary-name>: installs a single
# prebuilt Linux binary from a project's latest GitHub release. Used for
# lazygit/lazydocker, which publish release tarballs named
# "<binary>_<version>_Linux_<arch>.tar.gz" (goreleaser's standard layout, and
# the exact mechanism both projects' own install docs use) but aren't
# packaged in any of the non-Arch distros' default repos. Resilient by
# design: any failure (no network, API rate limit, unexpected asset layout)
# warns and returns rather than aborting the rest of setup.
install_github_release_binary() {
    local repo="$1" bin="$2"
    if command -v "$bin" &>/dev/null; then
        log "$bin already installed"
        return
    fi

    local arch
    case "$(uname -m)" in
        x86_64)        arch=x86_64 ;;
        aarch64|arm64) arch=arm64 ;;
        *)
            warn "Unsupported architecture for $bin ($(uname -m)); skipping"
            return
            ;;
    esac

    log "Installing $bin from the latest $repo release"
    if $DRY_RUN; then
        echo "  [dry-run] fetch the latest $repo release tarball for Linux/$arch and install $bin to /usr/local/bin"
        return
    fi

    local version url tmp
    version=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
        | grep -Po '"tag_name":\s*"v\K[^"]+' | head -n1) || true
    if [[ -z "$version" ]]; then
        warn "Couldn't determine the latest $repo release (network or API rate limit?); skipping $bin"
        return
    fi
    url="https://github.com/$repo/releases/download/v$version/${bin}_${version}_Linux_${arch}.tar.gz"

    tmp=$(mktemp -d)
    if ! curl -fsSL -o "$tmp/$bin.tar.gz" "$url"; then
        warn "Couldn't download $bin $version from $url; skipping"
        rm -rf "$tmp"
        return
    fi
    if ! tar xzf "$tmp/$bin.tar.gz" -C "$tmp" "$bin" 2>/dev/null; then
        warn "Unexpected archive layout for $bin $version; skipping"
        rm -rf "$tmp"
        return
    fi
    sudo install -m 755 "$tmp/$bin" /usr/local/bin/"$bin"
    rm -rf "$tmp"
}

# Arch already gets both natively via PACMAN_PACKAGES.
install_lazygit_lazydocker() {
    is_arch && return 0
    install_github_release_binary jesseduffield/lazygit lazygit
    install_github_release_binary jesseduffield/lazydocker lazydocker
}

install_yay() {
    if ! is_arch; then
        log "Skipping yay/AUR (herdr, downgrade): no AUR equivalent on this distro"
        return
    fi
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
    is_arch || return 0
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

# Arch keeps archlinux-java (it already manages /usr/lib/jvm/default). Every
# other distro has no such tool, so this finds the newest installed JDK under
# /usr/lib/jvm or /usr/lib64/jvm (openSUSE uses the lib64 path) and points
# /usr/lib/jvm/default at it directly — the path .zshrc's JAVA_HOME expects,
# kept the same across distros on purpose — plus the native alternatives
# mechanism so `java` on PATH matches too.
configure_java() {
    if is_arch; then
        if ! $DRY_RUN && [[ "$(archlinux-java get 2>/dev/null)" == "$JAVA_DEFAULT" ]]; then
            log "$JAVA_DEFAULT is already the default Java"
            return
        fi
        log "Setting the default Java to $JAVA_DEFAULT"
        run sudo archlinux-java set "$JAVA_DEFAULT"
        return
    fi

    if $DRY_RUN; then
        echo "  [dry-run] locate the newest installed JDK under /usr/lib(64)/jvm and point /usr/lib/jvm/default + the java alternative at it"
        return
    fi

    local jdk_dir
    jdk_dir=$(find /usr/lib/jvm /usr/lib64/jvm -maxdepth 1 -iname "*${JAVA_DEFAULT_VERSION}*openjdk*" -type d 2>/dev/null | sort -V | tail -1)
    [[ -n "$jdk_dir" ]] || jdk_dir=$(find /usr/lib/jvm /usr/lib64/jvm -maxdepth 1 -iname '*openjdk*' -type d 2>/dev/null | sort -V | tail -1)
    if [[ -z "$jdk_dir" ]]; then
        warn "Couldn't find an installed JDK under /usr/lib(64)/jvm; JAVA_HOME (hardcoded to /usr/lib/jvm/default in .zshrc) will be wrong."
        return
    fi

    if [[ "$(readlink -f /usr/lib/jvm/default 2>/dev/null)" == "$(readlink -f "$jdk_dir")" ]]; then
        log "/usr/lib/jvm/default already points at $jdk_dir"
        return
    fi

    log "Setting the default Java to $jdk_dir"
    sudo mkdir -p /usr/lib/jvm
    sudo ln -sfn "$jdk_dir" /usr/lib/jvm/default
    if command -v update-alternatives &>/dev/null; then
        sudo update-alternatives --set java "$jdk_dir/bin/java" 2>/dev/null || true
    elif command -v alternatives &>/dev/null; then
        sudo alternatives --set java "$jdk_dir/bin/java" 2>/dev/null || true
    fi
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
    local zsh_path
    zsh_path=$(command -v zsh || echo /usr/bin/zsh)
    if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]]; then
        log "Setting zsh as the login shell"
        run sudo chsh -s "$zsh_path" "$USER"
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

# Unattended package update, run by systemd on a Mon/Wed/Sat 03:00 timer.
# Idempotent: only (re)writes and reloads the units if their content actually
# changed, and only (re)enables the timer if it isn't already enabled+active.
# The generated script detects its own package manager at runtime (rather than
# baking in $PKG_MANAGER) so it stays correct even if copied to another box.
install_auto_updates() {
    local script_path=/usr/local/bin/linux-auto-update.sh
    local service_path=/etc/systemd/system/linux-auto-update.service
    local timer_path=/etc/systemd/system/linux-auto-update.timer
    local tmp_script tmp_service tmp_timer

    tmp_script=$(mktemp)
    cat > "$tmp_script" << 'EOF'
#!/bin/bash
# Written by DotFiles/linuxRemoteSetup.sh. Must run as root (the
# linux-auto-update.service unit pins User=root); AUR updates (Arch only) and
# the Claude Code check run as __TARGET_USER__ via runuser.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "linux-auto-update.sh must run as root (it's meant to run via" \
         "linux-auto-update.service, e.g. 'sudo systemctl start linux-auto-update.service')" >&2
    exit 1
fi

if command -v pacman &>/dev/null; then
    pacman -Syu --noconfirm
    if runuser -l '__TARGET_USER__' -c 'command -v yay' &>/dev/null; then
        runuser -l '__TARGET_USER__' -c 'yay -Syu --noconfirm'
    fi
    command -v paccache &>/dev/null && paccache -rk2
elif command -v apt-get &>/dev/null; then
    apt-get update -y
    apt-get full-upgrade -y
    apt-get autoremove -y
    apt-get autoclean -y
elif command -v dnf &>/dev/null; then
    dnf upgrade -y
    dnf autoremove -y
    dnf clean packages
elif command -v zypper &>/dev/null; then
    zypper --non-interactive refresh
    zypper --non-interactive update
    zypper clean --all
fi

# Reboot into a newer kernel automatically, but only when it's safe: nobody
# logged in, and no Claude Code agent running (mid-edit or mid-plan) for
# __TARGET_USER__. None of these distros have a live-patch feed covering
# arbitrary kernel updates, so this is the "no restarts needed" story instead:
# unattended, but deferred while in use. A skipped reboot is retried at the
# next Mon/Wed/Sat window.
kernel_image=""
for candidate in /boot/vmlinuz-linux /boot/vmlinuz; do
    [[ -e "$candidate" ]] && kernel_image="$candidate" && break
done
if [[ -z "$kernel_image" ]]; then
    kernel_image=$(ls -1v /boot/vmlinuz-* 2>/dev/null | tail -1)
fi
running_kernel=$(uname -r)
installed_kernel=""
[[ -n "$kernel_image" ]] && installed_kernel=$(file -b "$kernel_image" 2>/dev/null | grep -oP 'version \K\S+' || true)
if [[ -n "$installed_kernel" && "$installed_kernel" != "$running_kernel" ]]; then
    if [[ -n "$(who)" ]]; then
        logger -t linux-auto-update "Kernel update pending ($running_kernel -> $installed_kernel) but users are logged in; deferring reboot"
    elif runuser -l '__TARGET_USER__' -c 'pgrep -f claude' &>/dev/null; then
        logger -t linux-auto-update "Kernel update pending ($running_kernel -> $installed_kernel) but Claude Code is running; deferring reboot"
    else
        logger -t linux-auto-update "Kernel update pending ($running_kernel -> $installed_kernel); no active users or Claude Code sessions, rebooting"
        systemctl reboot
    fi
fi
exit 0
EOF
    sed -i "s/__TARGET_USER__/$USER/g" "$tmp_script"

    tmp_service=$(mktemp)
    cat > "$tmp_service" << 'EOF'
[Unit]
Description=Linux system update (package manager + AUR on Arch)
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/linux-auto-update.sh
EOF

    tmp_timer=$(mktemp)
    cat > "$tmp_timer" << 'EOF'
[Unit]
Description=Run linux-auto-update.service Mon/Wed/Sat at 03:00

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

    if ! $changed && systemctl is-enabled --quiet linux-auto-update.timer 2>/dev/null \
        && systemctl is-active --quiet linux-auto-update.timer 2>/dev/null; then
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
    sudo systemctl enable --now linux-auto-update.timer
}

user_stage() {
    [[ -z "$NEW_USER" ]] || warn "--user is only used when running as root; ignoring it."
    command -v sudo &>/dev/null || die "sudo is missing. Run stage 1 as root first: bash linuxRemoteSetup.sh --user <name>"
    $DRY_RUN || sudo -v || die "sudo access is required."

    log "Starting Linux remote dev box setup ($PKG_MANAGER, dry_run=$DRY_RUN)"

    # Unlike stage 1 (a brand-new account with no other access yet), $USER is
    # already logged in here, so enrollment is opt-in (default no) and never
    # touches sshd_config — it's just self-service key add/refresh.
    decide_github_user "$USER" n
    if [[ -n "$GITHUB_USER" ]]; then
        import_github_keys "$GITHUB_USER" "$USER" \
            || warn "No SSH keys imported for GitHub user '$GITHUB_USER'."
    fi

    install_packages
    symlink_renamed_tools
    install_tree_sitter_cli
    install_uv_ruff
    install_lazygit_lazydocker
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
    echo "✓ Linux remote dev box setup complete$($DRY_RUN && echo " (dry run, nothing changed)" || true)"
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
