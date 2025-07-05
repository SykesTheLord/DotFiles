import os
import subprocess

power_sources = (
    subprocess.check_output(["ls", "/sys/class/power_supply/"])
    .decode()
    .strip()
    .lower()
)

if "bat" in power_sources.lower():
    os.system(
        '/bin/bash -c "tuned-adm profile laptop-battery-powersave"')
else:
    print("No power sources available")
