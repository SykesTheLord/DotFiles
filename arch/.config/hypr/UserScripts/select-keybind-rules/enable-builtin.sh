#!/bin/bash
# Re-enable the laptop's built-in display (eDP-1) by sed-flipping the single
# eDP-1 line in config/monitors.lua, then reloading Hyprland.

sed -i -e 's|hl.monitor({ output = "eDP-1", disabled = true })|hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.333333, vrr = 1 })|g' ~/.config/hypr/config/monitors.lua
hyprctl reload
