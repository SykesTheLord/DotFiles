#!/bin/bash

DISTRO=$(lsb_release -is 2>/dev/null)

print_message() {
    echo "================================================="
    echo "$1"
    echo "================================================="
}

if [[ "$DISTRO" == "Ubuntu" || "$DISTRO" == "Debian" || "$DISTRO" == "Neon" ]]; then
    # Ubuntu setup
    print_message "Updating for Debian based"
    sudo apt update && sudo apt upgrade -y
    sudo am -u

elif [ -f "/etc/arch-release" ]; then
    # Arch Linux setup
    print_message "Updating for Arch"
    sudo pacman -Syu --noconfirm

elif [ -f "/etc/fedora-release" ]; then
    # Fedora setup
    print_message "Updating for Fedora"
    sudo dnf update -y

elif grep -qi "opensuse" /etc/os-release; then
    # openSUSE setup
    print_message "Setting up for openSUSE"
    sudo zypper refresh
    sudo zypper dup -y
    sudo zypper --non-interactive patch


else
    echo "No supported Distro for install found"
    exit 1
fi

if [[ $(grep -i Microsoft /proc/version) || "$DISTRO" == "Ubuntu" || "$DISTRO" == "Debian" || "$DISTRO" == "Neon" ]]; then
    bash ~/.config/updateNeovimConf.sh
    print_message "Completed updates"
else
    bash ~/.config/updateNeovimConf.sh
    am -u
    sudo flatpak update
    print_message "Completed updates"
fi

