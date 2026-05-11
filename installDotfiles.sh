#!/bin/bash
# Deploy dotfiles from this repo to the home directory.
# Usage: bash installDotfiles.sh [--dry-run]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=dotfiles_lib.sh
source "$SCRIPT_DIR/dotfiles_lib.sh"

DRY_RUN=false
for arg in "$@"; do
    [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done
$DRY_RUN && echo "[DRY RUN] No files will be written."

DISTRO=$(get_distro_dir) || { echo "Error: unsupported distro" >&2; exit 1; }
SRC="$SCRIPT_DIR/$DISTRO"
echo "Detected distro: $DISTRO (source: $SRC)"

backup_if_exists() {
    local target="$1"
    if [[ -e "$target" ]]; then
        local bak="${target}.bak"
        if $DRY_RUN; then
            echo "[DRY RUN] Would backup: $target → $bak"
        else
            echo "Backing up: $target → $bak"
            mv "$target" "$bak"
        fi
    fi
}

copy_dir() {
    local rel="$1"
    local src="$SRC/$rel"
    local dst_parent

    if [[ ! -d "$src" ]]; then
        echo "Warning: source directory not found, skipping: $src" >&2
        return
    fi

    if [[ "$rel" == .config/* ]]; then
        dst_parent="$HOME/.config"
    else
        dst_parent="$HOME"
    fi

    local dst="$dst_parent/$(basename "$rel")"
    backup_if_exists "$dst"

    if $DRY_RUN; then
        echo "[DRY RUN] Would copy dir: $src → $dst_parent/"
    else
        mkdir -p "$dst_parent"
        cp -a "$src" "$dst_parent/"
        echo "Copied dir: $src → $dst_parent/"
    fi
}

copy_file() {
    local rel="$1"
    local src="$SRC/$rel"
    local dst="$HOME/$rel"

    if [[ ! -f "$src" ]]; then
        echo "Warning: source file not found, skipping: $src" >&2
        return
    fi

    backup_if_exists "$dst"

    if $DRY_RUN; then
        echo "[DRY RUN] Would copy file: $src → $dst"
    else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "Copied file: $src → $dst"
    fi
}

echo "--- Copying directories ---"
while IFS= read -r dir; do
    [[ -z "$dir" ]] && continue
    copy_dir "$dir"
done < <(get_tracked_dirs "$SRC")

echo "--- Copying files ---"
while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    copy_file "$file"
done < <(get_tracked_files "$SRC")

if is_arch && ! $DRY_RUN; then
    echo "--- Arch post-install steps ---"
    if [[ -d "$HOME/.udev/rules" ]]; then
        sudo cp -r "$HOME/.udev/rules/"* /etc/udev/rules.d/.
    fi
    hyprctl reload 2>/dev/null || true
    sudo udevadm control --reload-rules && sudo udevadm trigger
    systemctl enable --user --now omarchy-battery-monitor.timer 2>/dev/null || true
    systemctl enable --user --now wallpaperset.service 2>/dev/null || true
elif is_arch && $DRY_RUN; then
    echo "[DRY RUN] Would run Arch post-install (udev reload, hyprctl, systemd services)"
fi

echo "Done."
