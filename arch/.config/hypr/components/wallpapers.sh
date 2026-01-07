#!/usr/bin/env bash
WALLPAPER_DIR="$HOME/.config/hypr/components/backgrounds/"
# Get all current wallpaper basenames into an associative array for quick lookup
declare -A CURRENT_WALLS
while IFS= read -r line; do
    CURRENT_WALLS["$(basename "$line")"]=1
done < <(hyprctl hyprpaper listloaded)

# Get all monitors as an array
mapfile -t MONITORS < <(hyprctl monitors -j | jq -r '.[] | .name')
sleep 5

# Build the hyprctl command with monitor-wallpaper pairs
for monitor in "${MONITORS[@]}"; do
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f ! -name "$(basename "$CURRENT_WALL")" | shuf -n 1)
    hyprctl hyprpaper wallpaper $monitor, $WALLPAPER, cover
done

