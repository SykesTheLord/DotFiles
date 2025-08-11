#!/usr/bin/env bash
# Start one bar per connected monitor
killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 0.2; done

if command -v xrandr >/dev/null; then
    for m in $(xrandr --query | awk '/ connected/{print $1}'); do
        MONITOR="$m" polybar -q main -r &
    done
else
    polybar -q main -r &
fi

