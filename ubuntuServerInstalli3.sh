#!/bin/bash
set -e

print_message() {
    echo "================================================="
    echo "$1"
    echo "================================================="
}

# 1. Update and upgrade the system
print_message "Setting up for Ubuntu or Ubuntu variant"
sudo apt update && sudo apt upgrade -y
sudo apt-get install -y wget apt-transport-https software-properties-common
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
source /etc/os-release
wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell
sudo apt update && sudo apt upgrade -y
sudo apt-get install -y clangd-19
sudo apt-get install -y dotnet-sdk-8.0
sudo apt install -y default-jre openjdk-8-jre openjdk-19-jre npm
sudo apt install -y ripgrep
sudo apt install -y direnv
sudo apt install -y tmux
sudo apt install -y fzf
sudo apt install -y zsh
wget https://github.com/fastfetch-cli/fastfetch/releases/download/2.42.0/fastfetch-linux-amd64.deb
sudo apt install -y ./fastfetch-linux-amd64.deb
curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash - && sudo apt-get install -y nodejs && sudo npm install -g npm@latest

# Docker group setup
if ! getent group docker > /dev/null; then
    echo "Group 'docker' does not exist. Creating it now..."
    sudo groupadd docker
    echo "Group 'docker' created successfully."
else
    echo "Group 'docker' already exists."
fi
sudo usermod -aG docker jacob

wget -O go0.24.0.linux-amd64.tar.gz https://go.dev/dl/go1.24.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go0.24.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install -y terraform

wget -q "https://raw.githubusercontent.com/ivan-hc/AM/main/INSTALL" -O INSTALL-AM.sh && chmod a+x INSTALL-AM.sh
sudo ./INSTALL-AM.sh

am -i zen-browser
am -i obsidian

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
echo "Open tmux and run Ctrl+b+I to install plugins." >> toDo.txt

# Fetch the latest Bicep CLI binary
curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
chmod +x ./bicep
sudo mv ./bicep /usr/local/bin/bicep


bash ~/.DotFiles/NvimSetup.sh

# Install Terraform autocomplete
if command -v terraform &>/dev/null; then
    terraform -install-autocomplete
else
    echo "Run the following command: terraform -install-autocomplete" >> toDo.txt
fi

# Install Azure Shell module
pwsh -Command "Install-Module -Name Az -Repository PSGallery -Force"

# Install Oh-My-Zsh
wget -O installZsh.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
sh installZsh.sh --unattended --keep-zshrc --skip-chsh
sleep 30
rm -f installZsh.sh

# Install Oh-My-Zsh plugins
zsh -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
zsh -c "git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone --depth 1 --filter=blob:none https://github.com/ryanoasis/nerd-fonts.git ~/nerd-fonts
chmod +x ~/nerd-fonts/install.sh
cd
sudo ./nerd-fonts/install.sh -q -S

cd ~

mkdir ~/Development
mkdir ~/Development/Personal
mkdir ~/Development/School
mkdir ~/Development/Work
mkdir ~/Development/.history


if [ "$INSTALL_DESKTOPENV" = true ]; then
    sudo timedatectl set-local-rtc 1
fi

cd ~/.DotFiles
python3 installDotfiles.py
cd


# 2. Install X11 server and i3 window manager (and related X utilities)
sudo apt install -y xorg xinit x11-xserver-utils dbus-x11
sudo apt install -y i3 i3status i3lock  # i3 window manager and core components

# 3. Install additional tools from dotfiles (window manager workflow utilities)
sudo apt install -y polybar rofi dunst picom feh  # feh for setting wallpaper, if used in config
sudo apt install -y kitty alacritty                # terminal emulators (as in dotfiles)
sudo apt install -y tmux neofetch                 # terminal multiplexer and system info
sudo apt install -y fonts-firacode fonts-jetbrains-mono  # common fonts (replace with Nerd Font if needed)

# Copy dotfiles zsh config if repository is available (optional)
# (You can clone your DotFiles repo and use stow or manual copy for .zshrc, .zimrc, etc.)

# 6. Install basic KDE applications and their optional dependencies
sudo apt install -y dolphin ark okular
sudo apt install -y okular-extra-backends          # Okular support for additional file formats (e.g., EPub, etc.)
sudo apt install -y p7zip-full unrar               # Ark support for 7z and RAR archives:contentReference[oaicite:2]{index=2}
sudo apt install -y kio-extras ffmpegthumbs        # Dolphin: network filesystems, video thumbnails, etc.

# 7. Install Pywal for dynamic theming (if used in Hyprland config)
sudo apt install -y python3-pip python3-xcbgen
sudo pip3 install -U pywal  # Install/upgrade pywal for wallpaper-based theming

# 8. Enable i3 launch on RDP (xrdp) sessions
sudo apt install -y xrdp
# Configure XRDP to start i3 for our user
# echo "#!/bin/sh\nexec i3" > "${HOME}/.xsession"  # Use .xsession to start i3 on login:contentReference[oaicite:3]{index=3}
# chmod +x "${HOME}/.xsession"
# Alternatively, for system-wide RDP default, uncomment:
sudo sed -i 's#^test -x /etc/X11/Xsession && exec /etc/X11/Xsession#exec i3#' /etc/xrdp/startwm.sh

# Restart xrdp service to apply changes
sudo systemctl restart xrdp

cd ~/.DotFiles
python3 installDotfiles.py
cd



