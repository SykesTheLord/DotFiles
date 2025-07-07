#!/bin/bash
# /usr/local/bin/power-switch.sh

MODE="$1"

# If "auto", detect the current power status
if [ "$MODE" = "auto" ]; then
    if grep -q 1 /sys/class/power_supply/AC/online 2>/dev/null; then
        MODE="on"
    else
        MODE="off"
    fi
fi

if [ "$MODE" = "on" ]; then
    tuned-adm profile balanced
elif [ "$MODE" = "off" ]; then
    tuned-adm profile laptop-battery-powersave
else
    echo "Unknown mode: $MODE"
    exit 1
fi

