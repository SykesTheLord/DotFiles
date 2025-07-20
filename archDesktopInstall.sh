#!/bin/bash
sudo pacman -S --noconfirm swaync
sudo pacman -S --noconfirm wireplumber
sudo pacman -S --noconfirm pipewire
sudo pacman -S --noconfirm qt6-wayland
sudo pacman -S --noconfirm qt5-wayland
sudo pacman -S --noconfirm kitty
sudo pacman -S --noconfirm wl-clipboard
sudo pacman -S --noconfirm gnome-keyring
sudo pacman -S --noconfirm libsecret
sudo pacman -S --noconfirm slurp
sudo pacman -S --noconfirm grim
sudo pacman -S --noconfirm imagemagick
sudo pacman -S --noconfirm swappy
sudo pacman -S --noconfirm spotify-launcher
sudo pacman -S --noconfirm pavucontrol
sudo pacman -S --noconfirm rofi
sudo pacman -S --noconfirm blueman
sudo pacman -S --noconfirm qt6ct
sudo pacman -S --noconfirm bitwarden
sudo pacman -S --noconfirm network-manager-applet
sudo pacman -S --noconfirm nwg-look
sudo pacman -S --noconfirm font-config
sudo pacman -S --noconfirm rustc
sudo pacman -S --noconfirm cargo
sudo pacman -S --noconfirm ghostty
sudo pacman -S --noconfirm tuned

paru -S --noconfirm hyprland-git
paru -S --noconfirm hyprlock-git
paru -S --noconfirm hyprpaper-git
paru -S --noconfirm hypridle-git
paru -S --noconfirm fastfetch
paru -S --noconfirm wofi
paru -S --noconfirm waybar
paru -S --noconfirm brightnessctl
pacman -S --noconfirm uwsm
# Enable services
sudo systemctl enable swaync
paru -S --noconfirm xdg-desktop-portal-hyprland-git

paru -S --noconfirm QGtk3Style
paru -S --noconfirm themix-full-git
paru -S --noconfirm eww
paru -S --noconfirm webcord
paru -S --noconfirm hyprsysteminfo
paru -S --noconfirm hyprcursor
paru -S --noconfirm wlogout
paru -S --noconfirm vmware-keymaps
paru -S --noconfirm vmware-workstation
sudo systemctl start vmware-networks-configuration.service
sudo cp -rv ~/.DotFiles/arch/.udev/rules/* /etc/udev/rules.d/.
sudo ln -s ~/.scripts/opt /opt/scripts

