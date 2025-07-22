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

yay -S --noconfirm hyprland-git
yay -S --noconfirm hyprlock-git
yay -S --noconfirm hyprpaper-git
yay -S --noconfirm hypridle-git
yay -S --noconfirm fastfetch
yay -S --noconfirm wofi
yay -S --noconfirm waybar
yay -S --noconfirm brightnessctl
pacman -S --noconfirm uwsm
# Enable services
sudo systemctl enable swaync
yay -S --noconfirm xdg-desktop-portal-hyprland-git

yay -S --noconfirm QGtk3Style
yay -S --noconfirm themix-full-git
yay -S --noconfirm eww
yay -S --noconfirm webcord
yay -S --noconfirm hyprsysteminfo
yay -S --noconfirm hyprcursor
yay -S --noconfirm wlogout
yay -S --noconfirm vmware-keymaps
yay -S --noconfirm vmware-workstation
sudo systemctl start vmware-networks-configuration.service
sudo cp -rv ~/.DotFiles/arch/.udev/rules/* /etc/udev/rules.d/.
sudo ln -s ~/.scripts/opt /opt/scripts
