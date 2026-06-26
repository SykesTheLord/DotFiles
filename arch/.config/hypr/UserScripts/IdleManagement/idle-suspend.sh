#!/bin/bash

# Skip suspend if on AC power
for psu in /sys/class/power_supply/*/; do
    type=$(cat "$psu/type" 2>/dev/null)
    online=$(cat "$psu/online" 2>/dev/null)
    if [ "$type" = "Mains" ] && [ "$online" = "1" ]; then
        echo "AC power connected, skipping suspend"
        exit 0
    fi
done

# Skip suspend if docked (multiple monitors active)
monitor_count=$(hyprctl monitors -j | jq length)
if [ "$monitor_count" -gt 1 ]; then
    echo "Docked, skipping suspend"
    exit 0
fi

systemctl suspend
