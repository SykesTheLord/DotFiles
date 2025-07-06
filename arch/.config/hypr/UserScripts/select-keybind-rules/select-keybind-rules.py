import os
import subprocess
from time import sleep

monitors = subprocess.check_output(["xdpyinfo"]).decode().strip()

if "number of screens:    1" not in monitors:
    os.system(
        '/bin/bash -c "cp $HOME/.config/hypr/UserScripts/select-keybind-rules/external-displays-keybinds.conf $HOME/.config/hypr/components/UserKeybinds.conf"'
    )
    os.system("hyprctl reload")
else:
    os.system(
        '/bin/bash -c "cp $HOME/.config/hypr/UserScripts/select-keybind-rules/laptop-only-keybinds.conf $HOME/.config/hypr/components/UserKeybinds.conf"'
    )
    os.system("hyprctl reload")
