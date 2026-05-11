#!/bin/bash
# Sync dotfiles from the home directory back into this repo.
# Usage: bash updateDotFiles.sh [--dry-run]
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
DEST="$SCRIPT_DIR/$DISTRO"
echo "Detected distro: $DISTRO (destination: $DEST)"

MONITORS_CONF=".config/hypr/components/monitors.conf"

sync_dir() {
    local rel="$1"
    local src="$HOME/$rel"
    local dst_parent

    if [[ ! -d "$src" ]]; then
        echo "Warning: source directory not in home, skipping: $src" >&2
        return
    fi

    if [[ "$rel" == .config/* ]]; then
        dst_parent="$DEST/.config"
    else
        dst_parent="$DEST"
    fi

    if $DRY_RUN; then
        echo "[DRY RUN] Would sync dir: $src → $dst_parent/"
    else
        mkdir -p "$dst_parent"
        cp -a "$src" "$dst_parent/"
        echo "Synced dir: $src → $dst_parent/"
    fi
}

sync_file() {
    local rel="$1"
    local src="$HOME/$rel"
    local dst="$DEST/$rel"

    # Skip machine-specific monitor config
    if [[ "$rel" == "$MONITORS_CONF" ]]; then
        echo "Skipping machine-specific: $rel"
        return
    fi

    if [[ ! -f "$src" ]]; then
        echo "Warning: source file not in home, skipping: $src" >&2
        return
    fi

    if $DRY_RUN; then
        echo "[DRY RUN] Would sync file: $src → $dst"
    else
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
        echo "Synced file: $src → $dst"
    fi
}

dirs_tracked=""
files_tracked=""

echo "--- Syncing directories ---"
while IFS= read -r dir; do
    [[ -z "$dir" ]] && continue
    sync_dir "$dir"
    dirs_tracked+="$dir"$'\n'
done < <(get_tracked_dirs "$DEST")

echo "--- Syncing files ---"
while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    sync_file "$file"
    files_tracked+="$file"$'\n'
done < <(get_tracked_files "$DEST")

if ! $DRY_RUN; then
    printf '%s' "$dirs_tracked"  > "$SCRIPT_DIR/directoriesTracked.txt"
    printf '%s' "$files_tracked" > "$SCRIPT_DIR/filesTracked.txt"
    echo "Updated directoriesTracked.txt and filesTracked.txt"
else
    echo "[DRY RUN] Would update directoriesTracked.txt and filesTracked.txt"
fi

echo "Done."
