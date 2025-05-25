#!/bin/bash
sudo pacman -S --noconfirm swaync wireplumber pipewire qt6-wayland qt5-wayland kitty wl-clipboard gnome-keyring libsecret slurp grim imagemagick swappy  spotify-launcher pavucontrol rofi blueman qt6ct bitwarden network-manager-applet nwg-look font-config rustc cargo ghostty linux-headers
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
yay -S --noconfirm discord_arch_electron
yay -S --noconfirm hyprsysteminfo
yay -S --noconfirm hyprcursor
yay -S --noconfirm wlogout
yay -S --noconfirm vmware-keymaps
yay -S --noconfirm vmware-workstation
