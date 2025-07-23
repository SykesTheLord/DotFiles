#!/bin/bash

tries=0
max_tries=20
while [ "$(hyprctl monitors 2>/dev/null | grep -c '^Monitor')" -lt 1 ]; do
    sleep 0.2
    tries=$((tries + 1))
    if [ "$tries" -ge "$max_tries" ]; then
        echo "Timed out waiting for monitors"
        exit 1
    fi
done

monitor_count=$(hyprctl monitors | grep -c '^Monitor')

if [ "$monitor_count" -eq 1 ]; then
    cp ~/.config/hypr/UserScripts/select-keybind-rules/laptop-only-keybinds.conf ~/.config/hypr/components/lid-actions.conf
    echo "Loaded single-monitor config"
elif [ "$monitor_count" -ge 2 ]; then
    cp ~/.config/hypr/UserScripts/select-keybind-rules/external-displays-keybinds.conf ~/.config/hypr/components/lid-actions.conf
    echo "Loaded multi-monitor config"
else
    echo "No active monitors detected!"
fi

