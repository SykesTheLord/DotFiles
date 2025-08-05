#!/bin/bash
sudo pacman -S --noconfirm swaync
sudo pacman -S --noconfirm pipewire
sudo pacman -S --noconfirm qt6-wayland
sudo pacman -S --noconfirm qt5-wayland
sudo pacman -S --noconfirm wl-clipboard
sudo pacman -S --noconfirm gnome-keyring
sudo pacman -S --noconfirm libsecret
sudo pacman -S --noconfirm imagemagick
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
sudo pacman -S --noconfirm alacritty
sudo pacman -S --noconfirm tlp

battery_found=false
for bat in /sys/class/power_supply/BAT*; do
    if [ -f "$bat/type" ] && grep -q "Battery" "$bat/type"; then
        battery_found=true
        break
    fi
done
if [ "$battery_found" = true ]; then
    yay -S --noconfirm tlp-rdw slimbookbattery
fi

kernel_release=$(uname -r)
symlink_path="/boot/vmlinuz-$kernel_release"

if [[ -L "$symlink_path" ]]; then
    target=$(readlink "$symlink_path")
    variant=$(basename "$target" | sed 's/vmlinuz-//')
else
    if [[ "$kernel_release" =~ -([a-z]+)$ ]]; then
        variant="linux-${BASH_REMATCH[1]}"
    else
        variant="linux"
    fi
fi

headerInstall="$variant-headers"

yay -s --noconfirm $headerInstall

yay -S --noconfirm hyprland
yay -S --noconfirm hyprlock
yay -S --noconfirm hyprpaper
yay -S --noconfirm hypridle
yay -S --noconfirm fastfetch
yay -S --noconfirm wofi
yay -S --noconfirm waybar
yay -S --noconfirm brightnessctl
pacman -S --noconfirm uwsm
# Enable services
sudo systemctl enable swaync
yay -S --noconfirm xdg-desktop-portal-hyprland
yay -S --noconfirm hyprpicker
yay -S --noconfirm hyprshot
yay -S --noconfirm QGtk3Style
yay -S --noconfirm themix-full-git
yay -S --noconfirm eww
yay -S wl-clip-persist
yay -S --noconfirm webcord
yay -S --noconfirm hyprsysteminfo
yay -S --noconfirm hyprcursor
yay -S --noconfirm wlogout
yay -S --noconfirm lazydocker
yay -S --noconfirm vmware-keymaps
yay -S --noconfirm vmware-workstation
sudo systemctl start vmware-networks-configuration.service
sudo cp -rv ~/.DotFiles/arch/.udev/rules/* /etc/udev/rules.d/.
sudo ln -s ~/.scripts/opt /opt/scripts
echo "HibernateDelaySec=1800" | sudo tee -a /etc/systemd/sleep.conf
