#!/bin/bash
monitor_count=$(hyprctl monitors -j | jq length)
if [ "$monitor_count" -gt 1 ]; then
    # Docked — displays already off from dpms listener, don't suspend
    echo "Docked, skipping suspend"
else
    systemctl suspend
fi
