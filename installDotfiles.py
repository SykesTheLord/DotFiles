import os
import library as lib

directory_path = ""

if lib.is_arch_linux():
    print("Updating Arch files")
    directory_path = "./arch/"

elif lib.is_fedora():
    print("Updating Fedora files")
    directory_path = "./fedora/"

elif lib.is_opensuse():
    print("Updating openSuse files")
    directory_path = "./opensuse/"

elif lib.is_debian():
    print("Updating Debian files")
    directory_path = "./debian/"

elif lib.is_ubuntu_or_neon():
    print("Updating Ubuntu based files")
    directory_path = "./ubuntu/"

else:
    print("No supported distro in use.")

if directory_path != "":
    files_tmp, directories_tmp = lib.list_files_recursive(directory_path)
    directories = []
    files = []
    for directory in directories_tmp:
        directories.append(directory.replace(directory_path, ""))
    for file in files_tmp:
        files.append(file.replace(directory_path, ""))
    for directory in directories:
        if directory.startswith(".config"):
            command = "cp -a -v " + directory_path + directory + " " + "~/" + ".config/"
        else:
            command = "cp -a -v " + directory_path + directory + " " + "~/"
        os.system('/bin/bash -c "' + command + '"')
    for file in files:
        command = "cp -v " + directory_path + file + " " + "~/" + file
        os.system('/bin/bash -c "' + command + '"')


if lib.is_arch_linux():
    os.system('/bin/bash -c "sudo cp -r ~/.udev/rules/* /etc/udev/rules.d/."')
    os.system("hyprctl reload")
    os.system("sudo udevadm control --reload-rules && sudo udevadm trigger")
    os.system("systemctl enable --user --now omarchy-battery-monitor.timer")
    os.system("systemctl enable --user --now wallpaperset.service")
