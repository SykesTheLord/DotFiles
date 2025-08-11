#!/usr/bin/env bash
# Icons follow your Waybar: on=󰂯, off/disabled=󰂲, connected=󰂱 {n}
state="$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/ {print $2}')"
if [[ "$state" != "yes" ]]; then
    echo "󰂲"
    exit 0
fi
count=$(bluetoothctl info | grep -c "Device")
# Alternative (more robust): bluetoothctl devices Connected | wc -l
count=$(bluetoothctl devices Connected | wc -l)
if (( count > 0 )); then
    echo "󰂱 $count"
else
    echo "󰂯"
fi

