import os
import subprocess

monitors = (
            subprocess.check_output(["hyprctl", "monitors"])
            .decode()
            .strip()
        )

amountOfMonitors = monitors.lower().count("monitor")

if amountOfMonitors > 1:
    os.system('/bin/bash -c "cp $HOME/.config/hypr/UserScripts/select-keybind-rules/external-displays-keybinds.conf $HOME/.config/hypr/components/UserKeybinds.conf"')
    os.system('hyprctl reload')
else:
    os.system('/bin/bash -c "cp $HOME/.config/hypr/UserScripts/select-keybind-rules/laptop-only-keybinds.conf $HOME/.config/hypr/components/UserKeybinds.conf"')
    os.system('hyprctl reload')