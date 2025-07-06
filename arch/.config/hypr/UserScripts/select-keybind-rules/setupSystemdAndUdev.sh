#!/bin/bash

mkdir -p ~/.config/systemd/user
cp ~/.config/hypr/UserScripts/select-keybind-rules/hypr-keybind-config-switcher.service ~/.config/systemd/user/hypr-keybind-config-switcher.service
udevadm control --reload-rules
systemctl --user daemon-reload
bash switch-keybinds.sh
