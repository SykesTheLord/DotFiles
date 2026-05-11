# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a multi-distro dotfiles repository managing shell configs, window manager configs, and development environments for Arch, Ubuntu, Debian, Fedora, and openSUSE. Configs are deployed via **direct file copying** (not symlinks or GNU stow), managed by Python scripts.

Arch Linux is the primary/most-complete distro. Ubuntu has a server and desktop i3 variant. Debian, Fedora, and openSUSE have minimal placeholder configs.

## Dotfile Management Workflow

**Deploy configs from repo → home directory:**
```bash
bash installDotfiles.sh [--dry-run]
```

**Sync configs from home directory → repo (after editing live):**
```bash
bash updateDotFiles.sh [--dry-run]
```

Both scripts source `dotfiles_lib.sh` for distro detection and file discovery. Discovery excludes oh-my-zsh internals (plugins, lib, templates, tools) and standard oh-my-zsh themes (only `sykes_custom_theme.zsh-theme` is kept). `.config/hypr/components/monitors.conf` is skipped during sync (machine-specific).

`installDotfiles.sh` backs up any existing home directory file/directory to a `.bak` copy before overwriting. `--dry-run` on either script prints what would happen without making changes.

`directoriesTracked.txt` and `filesTracked.txt` are documentation outputs written by `updateDotFiles.sh`; they are not read by `installDotfiles.sh` (which does its own discovery).

## Repository Structure

```
DotFiles/
├── arch/               # Arch Linux (most complete)
│   ├── .config/
│   │   ├── hypr/       # Hyprland WM (modular: monitors, keybinds, env, rules)
│   │   ├── waybar/     # Status bar
│   │   └── alacritty/  # Terminal
│   ├── .scripts/       # Custom executables (tmux-sessionizer, wofi menus, etc.)
│   ├── .themes/        # GTK themes
│   ├── .icons/
│   └── .udev/          # Udev rules
├── ubuntu/             # Ubuntu (desktop i3 + server variants)
│   ├── .config/
│   │   ├── i3/
│   │   └── polybar/
│   └── .zshrc.server   # Server-specific shell config
├── debian/
├── fedora/
├── opensuse/
├── dotfiles_lib.sh     # Distro detection + file discovery (sourced by install/update)
├── installDotfiles.sh  # Deploys repo → home (with --dry-run and .bak backup)
├── updateDotFiles.sh   # Syncs home → repo (with --dry-run)
├── linuxSetup.sh       # Distro-agnostic tool installation
├── archDesktopInstall.sh
├── NvimSetup.sh        # Neovim bootstrap across distros
└── setupGoCryptfsArch.sh
```

## Neovim Configuration

Neovim config is managed from a separate repository: **[SykesTheLord/NeoVimConfig](https://github.com/SykesTheLord/NeoVimConfig)**. It is not stored in this dotfiles repo. `NvimSetup.sh` clones that repo and runs its `install.sh` to deploy the config.

The config is Lua-based with **vim.pack** (Neovim 0.12 built-in). Key facts:
- Leader key: `-`, local leader: `_`
- LSP uses `vim.lsp.config`/`vim.lsp.enable` (requires Neovim 0.12+)
- Format on save via conform.nvim; lint on save via nvim-lint
- DAP debugging for Python, C#, Java, C/C++

## Setup Scripts

- **`linuxSetup.sh`** — Detects distro and installs common tools: Docker, PowerShell, Node.js, Neovim, LSP servers, etc.
- **`archDesktopInstall.sh`** — Installs Hyprland desktop environment, Qt apps, udev rules, VMware
- **`NvimSetup.sh`** — Installs Neovim + dependencies, then clones `SykesTheLord/NeoVimConfig` and runs its `install.sh`
- **`ubuntuServerInstalli3.sh`** — Ubuntu server i3 window manager setup

## Shell & Terminal

- Shell: **zsh** with oh-my-zsh, custom theme `sykes_custom_theme`
- Tmux: Dracula theme, TPM plugins (resurrect + continuum for persistent sessions, battery, CPU)
- Each distro has its own `.zshrc`; Ubuntu has an additional `.zshrc.server`

## Hyprland (Arch)

Config split into modules under `arch/.config/hypr/`:
- `hyprland.conf` — main entry, sources other modules
- Separate files for monitors, keybinds, environment variables, window rules
- Custom systemd user services for battery monitoring and wallpaper
- Udev rules in `arch/.udev/rules.d/` for hardware integration
- OpenRGB config for RGB lighting
