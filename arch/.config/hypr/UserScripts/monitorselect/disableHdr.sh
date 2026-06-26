#!/usr/bin/env bash
# Restore non-HDR monitor settings by copying the matching .lua template
# wholesale over config/monitors.lua, then reloading Hyprland.

# Check for battery to confirm if laptop or not
if [ -d /sys/class/power_supply/BAT0 ]; then
    src="monitors.laptop.lua"
else
    src="monitors.desktop.lua"
fi

cp "$HOME/.config/hypr/UserScripts/monitorselect/$src" \
    "$HOME/.config/hypr/config/monitors.lua"

hyprctl reload
notify-send "HDR Disable script completed"
