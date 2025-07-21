#!/bin/bash

DISTRO=$(lsb_release -is 2>/dev/null)


# Function to print messages
print_message() {
    echo "================================================="
    echo "$1"
    echo "================================================="
}

# Install Neovim
print_message "Installing Neovim"
if command -v nvim &>/dev/null; then
    echo "Neovim is already installed."
elif [ -f "/etc/arch-release" ]; then
    sudo pacman -S --noconfirm neovim
elif [ -f "/etc/fedora-release" ]; then
    sudo dnf install -y neovim
elif grep -qi "opensuse" /etc/os-release; then
    sudo zypper install -y neovim
else
    {
        am -i nvim
        } || {
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
        sudo rm -rf /opt/nvim
        sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
        export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
    }
fi

# Install unzip if not installed
if ! command -v unzip &>/dev/null; then
    print_message "Installing unzip"
    if [ -f /etc/debian_version ]; then
        sudo apt update
        sudo apt install -y unzip
    elif [ -f "/etc/fedora-release" ]; then
        sudo dnf install -y unzip
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y unzip
    elif grep -qi "opensuse" /etc/os-release; then
        sudo zypper install -y unzip
    elif [ "$(uname)" == "Darwin" ]; then
        brew install unzip
    elif [ -f "/etc/arch-release" ]; then
        sudo pacman -S --noconfirm unzip
    else
        echo "Unsupported OS. Please install unzip manually."
        exit 1
    fi
fi

# Install vim-plug
print_message "Installing vim-plug"
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Clone the configuration repository from GitHub
print_message "Cloning configuration repository from GitHub"
CONFIG_REPO="https://github.com/SykesTheLord/NeoVimConfig.git"
CONFIG_DIR="$HOME/.config/nvim"

if [ -d "$CONFIG_DIR" ]; then
    echo "Backup existing Neovim configuration to $CONFIG_DIR.bak"
    mv "$CONFIG_DIR" "$CONFIG_DIR.bak"
fi

print_message "Installing golang"
if command -v go &>/dev/null; then
    echo "go is already installed."
else
    if [[ "$DISTRO" == "Ubuntu" || "$DISTRO" == "Neon" ]]; then
        sudo apt install -y golang-any

    elif [[ "$DISTRO" == "Debian" ]]; then
        sudo apt install -y golang

    elif [ -f "/etc/arch-release" ]; then
        sudo pacman -S --noconfirm go

    elif [ -f "/etc/fedora-release" ]; then
        sudo dnf install -y go
    elif grep -qi "opensuse" /etc/os-release; then
        sudo zypper install -y go

    else
        echo "Unsupported OS. Please install GO manually." >> toDo.txt
    fi
fi

git clone "$CONFIG_REPO" "$CONFIG_DIR"

if [[ "$DISTRO" == "Ubuntu" || "$DISTRO" == "Neon" ]]; then
    sudo apt install -y lua5.1 luarocks
    sudo apt install -y python3-venv python3-pip
    luarocks config local_by_default true
    sudo apt install -y xclip

elif [[ "$DISTRO" == "Debian" ]]; then
    luarocks config local_by_default true
    sudo apt install -y lua51-devel

elif [ -f "/etc/arch-release" ]; then
    # Arch Linux setup
    sudo pacman -S --noconfirm lua51-devel
    sudo pacman -S --noconfirm luarocks
    luarocks config local_by_default true

elif [ -f "/etc/fedora-release" ]; then
    # Fedora setup
    luarocks config local_by_default true
    sudo dnf install -y lua51-devel
elif grep -qi "opensuse" /etc/os-release; then
    # openSUSE setup
    luarocks config local_by_default true
    sudo zypper install lua51-devel

else
    echo "lua51-devel install failed" >> toDo.txt
fi

# Install Node.js version 18 and npm (for general tooling)
print_message "Installing Node.js version 18 and npm"
if command -v npm &>/dev/null; then
    echo "npm is already installed."
else
    if [ -f /etc/debian_version ]; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt install -y nodejs npm
    elif [ -f "/etc/fedora-release" ]; then
        curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
        sudo dnf install -y nodejs npm
    elif [ -f /etc/redhat-release ]; then
        curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
        sudo yum install -y nodejs
    elif grep -qi "opensuse" /etc/os-release; then
        sudo zypper install -y nodejs npm
    elif [ "$(uname)" == "Darwin" ]; then
        brew install node@18
        brew link --force node@18
    elif [ -f "/etc/arch-release" ]; then
        sudo pacman -S --noconfirm npm
    else
        echo 'Unsupported OS. Please install Node.js version 18 and npm manually. Afterwards add npm to PATH with this command: export PATH="$PATH:$(npm bin -g)"' >> toDo.txt
        echo "Also install treesitter with this command: sudo npm install -g tree-sitter-cli" >> toDo.txt
        exit 1
    fi
fi

# Ensure npm is in PATH
export PATH="$PATH:$(npm bin -g)"

# Verify npm installation
if ! command -v npm &>/dev/null; then
    echo "npm is not installed correctly. Please check the installation and try again."
    exit 1
fi

# Install tree-sitter CLI
print_message "Installing tree-sitter CLI"
sudo npm install -g tree-sitter-cli

# Verify tree-sitter CLI installation
if ! command -v tree-sitter &>/dev/null; then
    echo "tree-sitter CLI is not installed correctly. Please check the installation and try again."
    exit 1
fi

# Install plugins
print_message "Installing plugins"
nvim +PlugInstall +qall &

sleep 50

print_message "Setup complete! You can now start Neovim with 'nvim'."
rm NvimSetup.sh
