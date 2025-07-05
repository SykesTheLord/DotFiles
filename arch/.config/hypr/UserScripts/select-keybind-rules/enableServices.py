import os
import subprocess

user = os.getlogin()

for service in os.listdir("/home/"+user+"/.config/systemd/user"):
    subprocess.check_output(["systemctl", "enable", "--user", service])