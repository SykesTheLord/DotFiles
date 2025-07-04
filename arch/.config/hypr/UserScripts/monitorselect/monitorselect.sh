#!/usr/bin/env bash

# Check for battery to confirm if laptop or not
if [ -d /sys/class/power_supply/BAT0 ]; then
    src="monitors.laptop.conf"
else
    src="monitors.desktop.conf"
fi

cp "$HOME/.config/hypr/UserScripts/monitorselect/$src" \
    "$HOME/.config/hypr/components/monitors.conf"

hyprctl reload
