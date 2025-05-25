#!/bin/bash

# Determine the distribution
DISTRO=$(lsb_release -is 2>/dev/null)

print_message() {
    echo "================================================="
    echo "$1"
    echo "================================================="
}


INSTALL_DESKTOPENV= false
read -p "Should this be installed for desktop environment? [y/N] " de_choice
case "$de_choice" in
    [Yy]* ) INSTALL_DESKTOPENV=true ;;
    * ) INSTALL_DESKTOPENV=false ;;
esac


if [[ "$INSTALL_DESKTOPENV" == true && -f "/etc/arch-release" ]]; then

    #
    # --- PROMPT FOR SWAYWM INSTALLATION (once) ---
    #
    INSTALL_SWAY=false

    # If sway already on PATH, we’ll install QtGreet unconditionally later
    if command -v sway &> /dev/null; then
        INSTALL_SWAY=true
    else
        # Ask user if they want SwayWM
        read -p "SwayWM is not installed. Would you like to install SwayWM? [y/N] " sway_choice
        case "$sway_choice" in
            [Yy]* ) INSTALL_SWAY=true ;;
            * ) INSTALL_SWAY=false ;;
        esac
    fi

    if [ "$INSTALL_SWAY" = true ]; then
        echo "→ Will ensure SwayWM is present, then install QtGreet."
    else
        echo "→ Skipping SwayWM and QtGreet installation."
    fi
fi

if [[ "$DISTRO" == "Ubuntu" || "$DISTRO" == "Neon" ]]; then
    # Ubuntu setup
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
    if [ "$INSTALL_SWAY" = true ]; then
        # 1) Ensure SwayWM
        if ! command -v sway &> /dev/null; then
            echo "Installing SwayWM on Ubuntu…"
            sudo apt-get update
            sudo apt-get install -y sway \
                || { echo "ERROR: could not install sway" >&2; exit 1; }
        else
            echo "SwayWM already installed."
        fi

        # 2) Ensure QtGreet
        if ! command -v qtgreet &> /dev/null; then
            echo "QtGreet not found, building from source (including dependencies)…"

            # 1) Install build tools & Qt6/Wayland dev libraries
            sudo apt-get update
            sudo apt-get install -y \
                git build-essential meson ninja-build pkg-config \
                qt6-base-dev qt6-base-private-dev qt6-declarative-dev \
                qt6-wayland-dev qt6-wayland-dev-tools \
                libwayland-dev libx11-dev libxcb1-dev libxkbcommon-dev \
                libpam0g-dev \
                || { echo "ERROR: could not install build deps" >&2; exit 1; }

            # 2) Clone & build each DFL framework + WayQt
            DEPS=(
                "https://gitlab.com/desktop-frameworks/wayqt.git"
                "https://gitlab.com/desktop-frameworks/applications.git"
                "https://gitlab.com/desktop-frameworks/ipc.git"
                "https://gitlab.com/desktop-frameworks/utils.git"
                "https://gitlab.com/desktop-frameworks/login1.git"
            )
            for repo in "${DEPS[@]}"; do
                name=$(basename -s .git "$repo")
                echo "→ Building dependency: $name"
                [ -d "/tmp/$name" ] || git clone "$repo" "/tmp/$name"
                cd "/tmp/$name"
                meson setup build --prefix=/usr --buildtype=release \
                    || { echo "ERROR: meson setup failed for $name" >&2; exit 1; }
                ninja -C build && sudo ninja -C build install \
                    || { echo "ERROR: building/installing $name failed" >&2; exit 1; }
            done

            # 3) Clone & build QtGreet
            echo "→ Building QtGreet"
            [ -d /tmp/QtGreet ] || git clone https://gitlab.com/marcusbritanicus/QtGreet.git /tmp/QtGreet
            cd /tmp/QtGreet
            meson setup build --prefix=/usr --buildtype=release -Dbuild_greetwl=false \
                || { echo "ERROR: meson setup failed for QtGreet" >&2; exit 1; }
            ninja -C build && sudo ninja -C build install \
                || { echo "ERROR: building/installing QtGreet failed" >&2; exit 1; }
            cd ~
            echo "→ QtGreet built & installed from source."
        else
            echo "QtGreet already installed."
        fi
    fi

elif [[ "$DISTRO" == "Debian" ]]; then
    # Debian setup
    print_message "Setting up for Debian"
    sudo apt update && sudo apt upgrade -y
    sudo apt-get install -y wget
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    source /etc/os-release
    wget -q https://packages.microsoft.com/config/debian/$VERSION_ID/packages-microsoft-prod.deb
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
    curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash - && sudo apt-get install -y nodejs && sudo npm install -g npm@latest
    if [ "$INSTALL_SWAY" = true ]; then
        # 1) Ensure SwayWM
        if ! command -v sway &> /dev/null; then
            echo "Installing SwayWM on Ubuntu…"
            sudo apt-get update
            sudo apt-get install -y sway \
                || { echo "ERROR: could not install sway" >&2; exit 1; }
        else
            echo "SwayWM already installed."
        fi

        # 2) Ensure QtGreet
        if ! command -v qtgreet &> /dev/null; then
            echo "QtGreet not found, building from source (including dependencies)…"

            # 1) Install build tools & dev libs
            sudo apt-get update
            sudo apt-get install -y \
                git build-essential meson ninja-build pkg-config \
                qtbase5-dev qtdeclarative5-dev libqt5waylandclient5-dev \
                libwayland-dev libx11-dev libxcb-composite0-dev libxkbcommon-dev \
                libelogind-dev libpam0g-dev \
                || { echo "ERROR: could not install build deps" >&2; exit 1; }

            # 2) Clone & build each DFL framework + WayQt
            DEPS=(
                "https://gitlab.com/desktop-frameworks/wayqt.git"
                "https://gitlab.com/desktop-frameworks/applications.git"
                "https://gitlab.com/desktop-frameworks/ipc.git"
                "https://gitlab.com/desktop-frameworks/utils.git"
                "https://gitlab.com/desktop-frameworks/login1.git"
            )
            for repo in "${DEPS[@]}"; do
                name=$(basename -s .git "$repo")
                echo "→ Building dependency: $name"
                [ -d "/tmp/$name" ] || git clone "$repo" "/tmp/$name"
                cd "/tmp/$name"
                meson setup build --prefix=/usr --buildtype=release \
                    || { echo "ERROR: meson setup failed for $name" >&2; exit 1; }
                ninja -C build && sudo ninja -C build install \
                    || { echo "ERROR: building/installing $name failed" >&2; exit 1; }
            done

            # 3) Clone & build QtGreet
            echo "→ Building QtGreet"
            [ -d /tmp/QtGreet ] || git clone https://gitlab.com/marcusbritanicus/QtGreet.git /tmp/QtGreet
            cd /tmp/QtGreet
            meson setup build --prefix=/usr --buildtype=release -Dbuild_greetwl=false \
                || { echo "ERROR: meson setup failed for QtGreet" >&2; exit 1; }
            ninja -C build && sudo ninja -C build install \
                || { echo "ERROR: building/installing QtGreet failed" >&2; exit 1; }
            cd ~
            echo "→ QtGreet built & installed from source."
        else
            echo "QtGreet already installed."
        fi
    fi

elif [ -f "/etc/arch-release" ]; then
    # Arch Linux setup
    print_message "Setting up for Arch"
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm git
    if ! command -v yay &> /dev/null; then
        sudo chown -R $USER:$USER /opt
        cd /opt
        git clone https://aur.archlinux.org/yay-bin.git
        cd yay-bin
        sudo pacman -S base-devel
        makepkg -si
        cd ~/
    fi

    sudo pacman -S --noconfirm zsh docker docker-compose
    sudo systemctl enable docker.service
    sudo pacman -S --noconfirm dotnet-runtime-8.0 dotnet-sdk-8.0
    sleep 10
    sudo dotnet tool install --global PowerShell
    yay -S --noconfirm powershell-git
    sudo pacman -S --noconfirm ripgrep
    sudo pacman -S --noconfirm direnv
    sudo pacman -S --noconfirm tmux
    sudo pacman -S --noconfirm fzf


    if lspci | grep -qi nvidia; then
        print_message "NVIDIA GPU detected. Installing drivers..."

        # Synchronize package databases and install the NVIDIA DKMS driver
        sudo pacman -Syu --noconfirm nvidia-dkms

        print_message "nvidia-dkms installation complete."
    fi

    if [ "$INSTALL_DESKTOPENV" = true ]; then
        if ! command -v hyprland &> /dev/null; then
            print_message "Installing Hyprland"
            # Install required programs
            wget https://raw.githubusercontent.com/SykesTheLord/AutoLinuxSetup/refs/heads/main/archDesktopInstall.sh
            bash archDesktopInstall.sh
        fi
    fi



elif [ -f "/etc/fedora-release" ]; then
    # Fedora setup
    print_message "Setting up for Fedora"
    sudo dnf install -y wget curl ca-certificates dnf-plugins-core python3-pip git
    sudo dnf update -y
    sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
    sudo rpm -Uvh https://packages.microsoft.com/config/fedora/$(rpm -E %fedora)/packages-microsoft-prod.rpm
    sudo dnf install -y dotnet-sdk-8.0 dotnet-runtime-8.0 aspnetcore-runtime-8.0
    sudo dnf install -y clang clang-tools-extra
    sudo dnf module install -y nodejs:18/common
    sudo dnf install -y npm18
    sudo dnf install -y zsh
    sudo dotnet tool install --global PowerShell
    sudo dnf install -y ripgrep
    sudo dnf install -y direnv
    sudo dnf install -y tmux
    sudo dnf install -y fzf
    sudo dnf copr enable pgdev/ghostty
    sudo dnf install -y ghostty
    if [ "$INSTALL_SWAY" = true ]; then
        if ! command -v sway &> /dev/null; then
            echo "Installing SwayWM on Fedora…"
            sudo dnf install -y sway \
                || { echo "ERROR: dnf could not install sway" >&2; exit 1; }
        else
            echo "SwayWM already installed."
        fi

        if ! command -v qtgreet &> /dev/null; then
            echo "QtGreet not found, building from source (including dependencies)…"

            # 1) Install build tools & dev libs
            sudo dnf install -y \
                git @development-tools meson ninja-build pkgconf-pkg-config \
                qt5-qtbase-devel qt5-qtdeclarative-devel qt5-qtwayland-devel \
                wayland-devel libX11-devel xcb-util-devel libxkbcommon-devel \
                elogind-devel pam-devel \
                || { echo "ERROR: could not install build deps" >&2; exit 1; }

            # 2) Clone & build DFL frameworks + WayQt
            DEPS=(
                "https://gitlab.com/desktop-frameworks/wayqt.git"
                "https://gitlab.com/desktop-frameworks/applications.git"
                "https://gitlab.com/desktop-frameworks/ipc.git"
                "https://gitlab.com/desktop-frameworks/utils.git"
                "https://gitlab.com/desktop-frameworks/login1.git"
            )
            for repo in "${DEPS[@]}"; do
                name=$(basename -s .git "$repo")
                echo "→ Building dependency: $name"
                [ -d "/tmp/$name" ] || git clone "$repo" "/tmp/$name"
                cd "/tmp/$name"
                meson setup build --prefix=/usr --buildtype=release \
                    || { echo "ERROR: meson setup failed for $name" >&2; exit 1; }
                ninja -C build && sudo ninja -C build install \
                    || { echo "ERROR: building/installing $name failed" >&2; exit 1; }
            done

            # 3) Clone & build QtGreet
            echo "→ Building QtGreet"
            [ -d /tmp/QtGreet ] || git clone https://gitlab.com/marcusbritanicus/QtGreet.git /tmp/QtGreet
            cd /tmp/QtGreet
            meson setup build --prefix=/usr --buildtype=release -Dbuild_greetwl=false \
                || { echo "ERROR: meson setup failed for QtGreet" >&2; exit 1; }
            ninja -C build && sudo ninja -C build install \
                || { echo "ERROR: building/installing QtGreet failed" >&2; exit 1; }
            cd ~
            echo "→ QtGreet built & installed from source."
        else
            echo "QtGreet already installed."
        fi
    fi
    if lspci | grep -qi nvidia; then
        print_message "NVIDIA GPU detected. Installing drivers..."

        # Update system and install the akmod-nvidia driver from RPM Fusion
        sudo dnf update -y
        sudo dnf install -y akmod-nvidia
        sudo dnf install xorg-x11-drv-nvidia-cuda

        print_message "akmod-nvidia installation complete. Wait a few minutes for the kernel module to build."
    fi

elif grep -qi "opensuse" /etc/os-release; then
    # openSUSE setup
    print_message "Setting up for openSUSE"
    sudo zypper refresh
    sudo zypper dup -y
    sudo zypper --non-interactive patch
    sudo zypper install -y wget curl ca-certificates
    sudo zypper install -y docker docker-compose
    sudo systemctl enable docker && sudo systemctl start docker
    if grep -qi "opensuse leap 15.6" /etc/os-release; then
        wget -O libopenssl1_0_0-1.0.2u-lp156.133.5.x86_64.rpm https://download.opensuse.org/repositories/home:/MaxxedSUSE:/Compiler-Tools-15.6/15.6/x86_64/libopenssl1_0_0-1.0.2u-lp156.133.5.x86_64.rpm
        sudo rpm -i libopenssl1_0_0-1.0.2u-lp156.133.5.x86_64.rpm
        rm -f libopenssl1_0_0-1.0.2u-lp156.133.5.x86_64.rpm
    else
        wget -O libopenssl1_0_0-1.0.2u-security.146.64.x86_64.rpm https://download.opensuse.org/repositories/home:/ohollmann:/branches:/security:/tls/openSUSE_Tumbleweed/x86_64/libopenssl1_0_0-1.0.2u-security.146.64.x86_64.rpm
        sudo rpm -i libopenssl1_0_0-1.0.2u-security.146.64.x86_64.rpm
        rm -f libopenssl1_0_0-1.0.2u-security.146.64.x86_64.rpm
    fi
    sudo zypper refresh
    sudo zypper install -y libicu
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo wget -O /etc/zypp/repos.d/microsoft-prod.repo https://packages.microsoft.com/config/opensuse/15/prod.repo
    sudo zypper refresh
    sudo zypper install -y clang
    sudo zypper install -y nodejs npm
    sudo zypper install -y zsh
    sudo zypper install -y dotnet-sdk-8.0
    sudo zypper install -y aspnetcore-runtime-8.0
    sudo dotnet tool install --global powershell
    sudo zypper install -y ripgrep
    sudo zypper install -y direnv
    sudo zypper install -y libgthread-2_0-0
    sudo zypper install -y tmux
    sudo zypper install -y fzf
    sudo zypper install -y ghostty

    if [ "$INSTALL_SWAY" = true ]; then
        if ! command -v sway &> /dev/null; then
            echo "Installing SwayWM on openSUSE…"
            sudo zypper install -y sway \
                || { echo "ERROR: zypper could not install sway" >&2; exit 1; }
        else
            echo "SwayWM already installed."
        fi

        if ! command -v qtgreet &> /dev/null; then
            echo "QtGreet not found, building from source (including dependencies)…"

            # 1) Install build tools & dev libs
            sudo zypper install -y \
                git patterns-devel_basis-devel_C_C++ meson ninja pkg-config \
                libqt5-qtbase-devel libqt5-qtdeclarative-devel libqt5-qtwayland-devel \
                wayland-devel libX11-devel libxcb-devel libxkbcommon-devel \
                libelogind-devel libpam-devel \
                || { echo "ERROR: could not install build deps" >&2; exit 1; }

            # 2) Clone & build DFL frameworks + WayQt
            DEPS=(
                "https://gitlab.com/desktop-frameworks/wayqt.git"
                "https://gitlab.com/desktop-frameworks/applications.git"
                "https://gitlab.com/desktop-frameworks/ipc.git"
                "https://gitlab.com/desktop-frameworks/utils.git"
                "https://gitlab.com/desktop-frameworks/login1.git"
            )
            for repo in "${DEPS[@]}"; do
                name=$(basename -s .git "$repo")
                echo "→ Building dependency: $name"
                [ -d "/tmp/$name" ] || git clone "$repo" "/tmp/$name"
                cd "/tmp/$name"
                meson setup build --prefix=/usr --buildtype=release \
                    || { echo "ERROR: meson setup failed for $name" >&2; exit 1; }
                ninja -C build && sudo ninja -C build install \
                    || { echo "ERROR: building/installing $name failed" >&2; exit 1; }
            done

            # 3) Clone & build QtGreet
            echo "→ Building QtGreet"
            [ -d /tmp/QtGreet ] || git clone https://gitlab.com/marcusbritanicus/QtGreet.git /tmp/QtGreet
            cd /tmp/QtGreet
            meson setup build --prefix=/usr --buildtype=release -Dbuild_greetwl=false \
                || { echo "ERROR: meson setup failed for QtGreet" >&2; exit 1; }
            ninja -C build && sudo ninja -C build install \
                || { echo "ERROR: building/installing QtGreet failed" >&2; exit 1; }
            cd ~
            echo "→ QtGreet built & installed from source."
        else
            echo "QtGreet already installed."
        fi
    fi


else
    echo "No supported Distro for install found"
    exit 1
fi

# Docker group setup
if ! getent group docker > /dev/null; then
    echo "Group 'docker' does not exist. Creating it now..."
    sudo groupadd docker
    echo "Group 'docker' created successfully."
else
    echo "Group 'docker' already exists."
fi
sudo usermod -aG docker $USER

# Terraform installation
if [ -f "/etc/arch-release" ]; then
    sudo pacman -S --noconfirm terraform
elif [[ "$DISTRO" == "Ubuntu" || "$DISTRO" == "Debian" || "$DISTRO" == "Neon" ]]; then
    wget -O go0.24.0.linux-amd64.tar.gz https://go.dev/dl/go1.24.0.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go0.24.0.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update
    sudo apt-get install -y terraform
elif [ -f "/etc/fedora-release" ]; then
    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
    sudo dnf install -y terraform
else
    echo "Download Terrafrom manually from Hashicorp.com" >> toDo.txt
fi

mkdir UserApps

if [[ $(grep -i Microsoft /proc/version) ]]; then
    wget https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip
    unzip win32yank-x64.zip -d ~/UserApps/win32yank
    chmod +x ~/UserApps/win32yank/win32yank.exe
    if [[ "$DISTRO" == "Ubuntu" || "$DISTRO" == "Debian" ]]; then
        # Download the installer script
        wget -q https://raw.githubusercontent.com/ivan-hc/AM/main/AM-INSTALLER -O AM-INSTALLER

        chmod a+x AM-INSTALLER
        # Execute the modified script
        ./AM-INSTALLER
    fi
else
    # Download the installer script
    wget -q https://raw.githubusercontent.com/ivan-hc/AM/main/AM-INSTALLER -O AM-INSTALLER
    chmod a+x AM-INSTALLER

    # Execute the modified script
    ./AM-INSTALLER
    am -i zen-browser
    if [[ "$DISTRO" == "Ubuntu" || "$DISTRO" == "Debian" || "$DISTRO" == "Neon" ]]; then
        am -i ghostty
    fi
    # Open Jetbrains for toolbox link
    firefox https://www.jetbrains.com/toolbox-app/download/download-thanks.html?platform=linux
fi


git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
echo "Open tmux and run Ctrl+b+I to install plugins." >> toDo.txt

# Fetch the latest Bicep CLI binary
curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
chmod +x ./bicep
sudo mv ./bicep /usr/local/bin/bicep

# Install and setup Neovim using the local NvimSetup.sh
wget https://raw.githubusercontent.com/SykesTheLord/NeoVimConfig/refs/heads/main/NvimSetup.sh

bash NvimSetup.sh

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

mkdir ~/Development
mkdir ~/Development/Personal
mkdir ~/Development/School
mkdir ~/Development/Work

git clone https://github.com/SykesTheLord/DotFiles.git
cd DotFiles
python3 installDotfiles.py
cd

echo "Create and setup ssh keys for github." >> toDo.txt
echo "Now run 'sudo chsh $USER' if on Fedora, otherwise run 'chsh -s \$(which zsh)'." >> toDo.txt
echo "Run 'sudo apt install -y plasma-workspace-wayland' if in Kubuntu." >> toDo.txt

print_message "Now run 'sudo chsh $USER' if on Fedora, otherwise run 'chsh -s \$(which zsh)'."


