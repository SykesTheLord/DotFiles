#!/bin/bash
# Shared distro detection and file discovery for dotfiles scripts.

is_arch()    { [[ -f /etc/arch-release ]]; }
is_fedora()  { [[ -f /etc/fedora-release ]]; }
is_opensuse(){ grep -qi "opensuse" /etc/os-release 2>/dev/null; }
is_debian()  { [[ "$(lsb_release -is 2>/dev/null)" == "Debian" ]]; }
is_ubuntu()  { [[ "$(lsb_release -is 2>/dev/null)" =~ ^(Ubuntu|Neon)$ ]]; }

get_distro_dir() {
    if   is_arch;     then echo "arch"
    elif is_fedora;   then echo "fedora"
    elif is_opensuse; then echo "opensuse"
    elif is_debian;   then echo "debian"
    elif is_ubuntu;   then echo "ubuntu"
    else return 1
    fi
}

# Print tracked directory paths relative to the distro dir (e.g. ".themes", ".config/hypr").
# Args: $1 = distro source dir (e.g. "./arch")
get_tracked_dirs() {
    local src="${1%/}"
    # Top-level dirs, excluding .config itself and .oh-my-zsh
    find "$src" -maxdepth 1 -mindepth 1 -type d \
        ! -name ".config" ! -name ".oh-my-zsh" \
        | sed "s|^${src}/||" | sort
    # Each subdir of .config/ tracked individually
    if [[ -d "$src/.config" ]]; then
        find "$src/.config" -maxdepth 1 -mindepth 1 -type d \
            | sed "s|^${src}/||" | sort
    fi
}

# Print tracked individual file paths relative to the distro dir (e.g. ".zshrc").
# Args: $1 = distro source dir
get_tracked_files() {
    local src="${1%/}"
    # Root-level files only (subdirs are handled as directories above)
    find "$src" -maxdepth 1 -mindepth 1 -type f | sed "s|^${src}/||" | sort
    # Custom oh-my-zsh theme (only non-ignored file in .oh-my-zsh/)
    local theme="$src/.oh-my-zsh/themes/sykes_custom_theme.zsh-theme"
    [[ -f "$theme" ]] && echo ".oh-my-zsh/themes/sykes_custom_theme.zsh-theme"
}
