#!/usr/bin/env bash
# Apply HDR monitor settings by copying the matching .lua template wholesale
# over config/monitors.lua, then reloading Hyprland.

# Check for battery to confirm if laptop or not
if [ -d /sys/class/power_supply/BAT0 ]; then
    src="monitors.laptop.hdr.lua"
else
    src="monitors.desktop.lua"
    notify-send "HDR Not configured for Desktop use"
fi

cp "$HOME/.config/hypr/UserScripts/monitorselect/$src" \
    "$HOME/.config/hypr/config/monitors.lua"

hyprctl reload
notify-send "HDR script completed"
