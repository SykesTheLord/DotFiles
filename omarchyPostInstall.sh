#!/bin/bash
# omarchyPostInstall.sh
# Post-install customizations layered on top of a fresh omarchy install.
# Run as your normal user (sudo is invoked internally where needed).
#
# Usage: bash omarchyPostInstall.sh [--dry-run]

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        *) echo "Unknown argument: $arg"; exit 1 ;;
    esac
done

# ── helpers ──────────────────────────────────────────────────────────────────

log()  { echo "▶ $*"; }
run()  {
    if $DRY_RUN; then
        echo "  [dry-run] $*"
    else
        "$@"
    fi
}
run_sh() {
    if $DRY_RUN; then
        echo "  [dry-run] bash -c \"$*\""
    else
        bash -c "$*"
    fi
}

# ── pre-flight ────────────────────────────────────────────────────────────────

if [[ ! -d "$HOME/.local/share/omarchy" ]]; then
    echo "Error: omarchy is not installed (expected ~/.local/share/omarchy)."
    echo "Install omarchy first, then re-run this script."
    exit 1
fi

log "Starting omarchy post-install (dry_run=$DRY_RUN)"

# ── 1. yay ────────────────────────────────────────────────────────────────────

install_yay() {
    if command -v yay &>/dev/null; then
        log "yay already installed"
        return
    fi
    log "Installing yay (AUR helper)"
    run sudo pacman -S --needed --noconfirm base-devel git
    TMP=$(mktemp -d)
    run git clone https://aur.archlinux.org/yay.git "$TMP/yay"
    run_sh "cd '$TMP/yay' && makepkg -si --noconfirm"
    rm -rf "$TMP"
}

install_yay

# ── 2. languages & runtimes ───────────────────────────────────────────────────

log "Installing languages and runtimes"

run sudo pacman -S --needed --noconfirm \
    go \
    jdk11-openjdk \
    jdk17-openjdk \
    jdk21-openjdk \
    jdk25-openjdk \
    python-pip \
    python-pipx \
    cmake

# dotnet SDKs (omarchy ships dotnet-runtime-9.0; add SDKs for 8, 9, 10)
run yay -S --needed --noconfirm \
    dotnet-sdk-8.0 \
    dotnet-sdk-9.0 \
    dotnet-sdk-10.0

# ── 3. dev tools ──────────────────────────────────────────────────────────────

log "Installing dev tools"

run sudo pacman -S --needed --noconfirm terraform direnv

# PowerShell: try dotnet global tool first, then AUR fallback
log "Installing PowerShell"
if ! command -v pwsh &>/dev/null; then
    if dotnet tool install --global PowerShell 2>/dev/null; then
        log "PowerShell installed via dotnet tool"
    else
        log "dotnet tool install failed, falling back to AUR"
        run yay -S --needed --noconfirm powershell-bin
    fi
else
    log "PowerShell already installed"
fi

# Bicep CLI
log "Installing Bicep CLI"
if ! command -v bicep &>/dev/null; then
    BICEP_TMP=$(mktemp)
    run curl -Lo "$BICEP_TMP" \
        "https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64"
    run sudo install -o root -g root -m 0755 "$BICEP_TMP" /usr/local/bin/bicep
    rm -f "$BICEP_TMP"
else
    log "Bicep already installed"
fi

# ── 4. additional apps ────────────────────────────────────────────────────────

log "Installing additional apps"

run yay -S --needed --noconfirm \
    bitwarden \
    claude-code \
    vmware-keymaps \
    vmware-workstation

# zen-browser (try AUR first)
log "Installing zen-browser"
if ! command -v zen-browser &>/dev/null && ! yay -Q zen-browser-bin &>/dev/null 2>&1; then
    run yay -S --needed --noconfirm zen-browser-bin
else
    log "zen-browser already installed"
fi

# VMware services
log "Enabling VMware services"
run sudo systemctl enable --now vmware-networks.service
run sudo systemctl enable --now vmware-usbarbitrator.service

# ── 5. flatpak BudsLink ───────────────────────────────────────────────────────

log "Installing BudsLink (flatpak)"
if ! flatpak list 2>/dev/null | grep -q "io.github.maniacx.BudsLink"; then
    run flatpak install -y flathub io.github.maniacx.BudsLink
else
    log "BudsLink already installed"
fi

# ── 6. browser defaults ───────────────────────────────────────────────────────

log "Setting zen-browser as default browser"
run xdg-settings set default-web-browser zen-browser.desktop
for mime in x-scheme-handler/http x-scheme-handler/https text/html text/xml; do
    run xdg-mime default zen-browser.desktop "$mime"
done

# ── 7. zsh + oh-my-zsh ───────────────────────────────────────────────────────

log "Installing zsh"
run sudo pacman -S --needed --noconfirm zsh

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log "Installing oh-my-zsh"
    run_sh 'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
else
    log "oh-my-zsh already installed"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    log "Installing zsh-syntax-highlighting"
    run git clone https://github.com/zsh-users/zsh-syntax-highlighting \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    log "Installing zsh-autosuggestions"
    run git clone https://github.com/zsh-users/zsh-autosuggestions \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# ── 8. deploy omarchy/ config files ──────────────────────────────────────────

log "Deploying omarchy config files to home directory"
run rsync -av --no-group "$DOTFILES_DIR/omarchy/" "$HOME/"
run chmod +x "$HOME/.scripts/omarchy-zsh-colors-set"

# ── 9. .zshrc ────────────────────────────────────────────────────────────────

log "Installing .zshrc"
if [[ -f "$HOME/.zshrc" && ! -f "$HOME/.zshrc.pre-omarchy" ]]; then
    run cp "$HOME/.zshrc" "$HOME/.zshrc.pre-omarchy"
fi
run cp "$DOTFILES_DIR/arch/.zshrc" "$HOME/.zshrc"

# Patch theme name to the omarchy-aware variant
run sed -i 's/ZSH_THEME=.*/ZSH_THEME="sykes_omarchy"/' "$HOME/.zshrc"

# Ensure ~/.local/bin is in PATH (omarchy binaries live there)
if ! grep -q '\.local/bin' "$HOME/.zshrc"; then
    run_sh 'echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.zshrc"'
fi

log "Setting zsh as default login shell"
run sudo chsh -s "$(which zsh)" "$USER"

# ── 10. wire window rules into hyprland ───────────────────────────────────────

log "Wiring window rules into ~/.config/hypr/hyprland.conf"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [[ -f "$HYPR_CONF" ]]; then
    if ! grep -q 'windowrules\.conf' "$HYPR_CONF"; then
        run_sh 'echo "source = ~/.config/hypr/windowrules.conf" >> "$HOME/.config/hypr/hyprland.conf"'
    else
        log "windowrules.conf already sourced in hyprland.conf"
    fi
else
    log "Warning: $HYPR_CONF not found; hyprland may not be configured yet"
fi

# ── 11. zsh theme color generator + omarchy hook ─────────────────────────────

log "Generating initial zsh theme colors"
if [[ -f "$HOME/.config/omarchy/current/theme/colors.toml" ]]; then
    run "$HOME/.scripts/omarchy-zsh-colors-set"
else
    log "No active omarchy theme yet; colors will be generated on first theme-set"
fi

log "Registering omarchy theme-set hook for zsh theme"
HOOK_DIR="$HOME/.config/omarchy/hooks/theme-set.d"
run mkdir -p "$HOOK_DIR"

HOOK_FILE="$HOOK_DIR/zsh-theme"
if [[ ! -f "$HOOK_FILE" ]] || $DRY_RUN; then
    if $DRY_RUN; then
        echo "  [dry-run] write $HOOK_FILE"
    else
        cat > "$HOOK_FILE" << 'EOF'
#!/bin/bash
"$HOME/.scripts/omarchy-zsh-colors-set"
EOF
        chmod 755 "$HOOK_FILE"
    fi
else
    log "theme-set hook already installed"
fi

# ── 12. neovim config ────────────────────────────────────────────────────────

log "Replacing neovim config with SykesTheLord/NeoVimConfig"
if [[ -d "$HOME/.config/nvim" ]]; then
    BACKUP="$HOME/.config/nvim.bak.$(date +%s)"
    log "Backing up existing nvim config to $BACKUP"
    run mv "$HOME/.config/nvim" "$BACKUP"
fi

NVIM_TMP=$(mktemp -d)
run git clone https://github.com/SykesTheLord/NeoVimConfig "$NVIM_TMP/NeoVimConfig"
run bash "$NVIM_TMP/NeoVimConfig/install.sh"
run rm -rf "$NVIM_TMP"

# ── done ─────────────────────────────────────────────────────────────────────

echo ""
echo "✓ omarchy post-install complete$(${DRY_RUN} && echo " (dry-run — no changes made)" || true)"
echo ""
echo "Next steps:"
echo "  1. Log out and back in (or reboot) for the shell change to take effect"
echo "  2. Open a new terminal — it should launch zsh with the sykes_omarchy theme"
echo "  3. Run 'omarchy-theme-set <name>' to apply a theme and sync zsh colors"
