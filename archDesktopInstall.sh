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

paru -S --noconfirm --skipreview hyprland-git
paru -S --noconfirm --skipreview hyprlock-git
paru -S --noconfirm --skipreview hyprpaper-git
paru -S --noconfirm --skipreview hypridle-git
paru -S --noconfirm --skipreview fastfetch
paru -S --noconfirm --skipreview wofi
paru -S --noconfirm --skipreview waybar
paru -S --noconfirm --skipreview brightnessctl
pacman -S --noconfirm uwsm
# Enable services
sudo systemctl enable swaync
paru -S --noconfirm --skipreview xdg-desktop-portal-hyprland-git

paru -S --noconfirm --skipreview QGtk3Style
paru -S --noconfirm --skipreview themix-full-git
paru -S --noconfirm --skipreview eww
paru -S --noconfirm --skipreview webcord
paru -S --noconfirm --skipreview hyprsysteminfo
paru -S --noconfirm --skipreview hyprcursor
paru -S --noconfirm --skipreview wlogout
paru -S --noconfirm --skipreview vmware-keymaps
paru -S --noconfirm --skipreview vmware-workstation
sudo systemctl start vmware-networks-configuration.service
sudo cp -rv ~/.DotFiles/arch/.udev/rules/* /etc/udev/rules.d/.
sudo ln -s ~/.scripts/opt /opt/scripts

echo "SkipReview" | sudo tee -a /etc/paru.conf
