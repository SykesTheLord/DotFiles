# DotFiles

Personal dotfiles and setup scripts for Arch Linux (primary), Ubuntu, Debian, Fedora, and openSUSE. Configs are deployed via **direct file copying** — no symlinks, no stow.

## Distro Support

| Distro | Status | Desktop |
|---|---|---|
| Arch Linux | Full | Hyprland or Omarchy |
| Ubuntu | Desktop + Server | i3 |
| Debian / Fedora / openSUSE | Minimal placeholder | — |

---

## Deploying Configs

**Copy repo → home directory:**
```bash
bash installDotfiles.sh [--dry-run]
```

**Sync live edits back → repo:**
```bash
bash updateDotFiles.sh [--dry-run]
```

Both scripts auto-detect the distro and copy only the relevant files. `installDotfiles.sh` backs up any existing file to a `.bak` copy before overwriting. `--dry-run` prints what would happen without making changes.

> `~/.config/hypr/components/monitors.conf` is excluded from sync — it's machine-specific.

---

## Setup Scripts

### `linuxSetup.sh` — Common tools (all distros)

Installs: zsh, Docker, Terraform, direnv, tmux, fzf, ripgrep, Neovim, LSP servers, fonts, oh-my-zsh, TPM, Bicep CLI, Azure PowerShell module, and development directories (`~/Development/Personal`, `~/Development/Work`, etc.).

```bash
bash linuxSetup.sh
```

Detects the distro and runs the appropriate package manager commands. On Arch, also builds and installs `yay` if missing.

---

### `archDesktopInstall.sh` — Arch Hyprland desktop

Installs the full Hyprland desktop stack on top of a base Arch install: Hyprland, Waybar, Alacritty, rofi, swaync, pavucontrol, Bluetooth tools, VMware Workstation, udev rules, hyprpm plugins, and GTK/Qt theming.

```bash
bash archDesktopInstall.sh
```

Run after `linuxSetup.sh`. Deploys dotfiles at the end via `installDotfiles.sh`.

---

### `omarchyPostInstall.sh` — Omarchy layer

Layers personal preferences on top of a fresh [omarchy](https://github.com/basecamp/omarchy) install. Omarchy provides the Hyprland desktop environment; this script adds what it doesn't cover.

```bash
bash omarchyPostInstall.sh [--dry-run] [--restore-home <path>]
```

**What it installs:**
- **Languages & runtimes:** Go, JDK 11/17/21/25, Python pip/pipx, cmake, dotnet SDK 8/9/10
- **Dev tools:** Terraform, direnv, PowerShell, Bicep CLI
- **Apps:** Bitwarden, Claude Code, VMware Workstation, zen-browser (set as default browser)
- **Flatpak:** BudsLink (`io.github.maniacx.BudsLink`)
- **Shell:** zsh + oh-my-zsh + syntax-highlighting + autosuggestions plugins
- **Neovim:** Replaces omarchy-nvim with [SykesTheLord/NeoVimConfig](https://github.com/SykesTheLord/NeoVimConfig)

**What it configures:**
- `~/.config/hypr/hypridle.conf` — brightness dimming (30s), keyboard backlight + DPMS (120s), lock (150s), suspend (600s), using omarchy's `omarchy-system-lock/wake` wrappers
- `~/.config/hypr/windowrules.conf` — user-specific rules (Paradox Launcher, HOI4, Ghidra, JetBrains extended, media app opacity, KDE file pickers, etc.) sourced into Hyprland
- `~/.oh-my-zsh/custom/themes/sykes_omarchy.zsh-theme` — prompt that reads 24-bit colors from the active omarchy theme
- Registers an `omarchy-hook` so zsh colors update automatically on `omarchy-theme-set`

**Restoring a previous home directory:**
```bash
bash omarchyPostInstall.sh --restore-home /path/to/old/home
```
Rsyncs the old home in before deploying new configs. Automatically excludes all paths managed by omarchy (alacritty, waybar, mako, btop, fastfetch, walker, etc.) and by this script, so the fresh setup always takes precedence. Personal data, SSH keys, development directories, and app-specific configs are preserved.

---

### `NvimSetup.sh` — Neovim bootstrap

Installs Neovim and its dependencies, then clones [SykesTheLord/NeoVimConfig](https://github.com/SykesTheLord/NeoVimConfig) and runs its `install.sh`. The Neovim config is maintained in that separate repo (not stored here).

```bash
bash NvimSetup.sh
```

---

### `ubuntuServerInstalli3.sh` — Ubuntu i3 desktop

Sets up an i3 window manager desktop on Ubuntu server (or desktop). Installs i3, polybar, rofi, dunst, picom, and related tools.

```bash
bash ubuntuServerInstalli3.sh
```

---

## Repository Structure

```
DotFiles/
├── arch/                    # Arch Linux — primary, most complete
│   ├── .config/
│   │   ├── hypr/            # Hyprland (modular: monitors, keybinds, env, rules)
│   │   ├── waybar/          # Status bar
│   │   └── alacritty/       # Terminal
│   ├── .oh-my-zsh/custom/themes/
│   │   └── sykes_custom_theme.zsh-theme
│   ├── .scripts/            # Custom executables (tmux-sessionizer, wofi menus, etc.)
│   ├── .themes/             # GTK themes
│   ├── .icons/
│   └── .udev/               # Udev rules
├── omarchy/                 # Omarchy-specific overrides (deployed by omarchyPostInstall.sh)
│   ├── .config/hypr/
│   │   ├── hypridle.conf    # Custom idle/lock timeouts
│   │   └── windowrules.conf # User-specific window rules
│   ├── .oh-my-zsh/custom/themes/
│   │   └── sykes_omarchy.zsh-theme
│   └── .scripts/
│       └── omarchy-zsh-colors-set
├── ubuntu/                  # Ubuntu — desktop i3 + server variants
│   ├── .config/i3/
│   ├── .config/polybar/
│   └── .zshrc.server
├── debian/
├── fedora/
├── opensuse/
├── dotfiles_lib.sh          # Distro detection + file discovery (sourced by install/update)
├── installDotfiles.sh       # Deploy repo → home
├── updateDotFiles.sh        # Sync home → repo
├── linuxSetup.sh            # Common tool installation (all distros)
├── archDesktopInstall.sh    # Hyprland desktop setup (Arch)
├── omarchyPostInstall.sh    # Personal layer on top of omarchy
├── NvimSetup.sh             # Neovim bootstrap
└── ubuntuServerInstalli3.sh # Ubuntu i3 setup
```

---

## Shell & Terminal

- **Shell:** zsh with oh-my-zsh
- **Theme (Arch/standard):** `sykes_custom_theme` — two-line prompt showing time, user@host:path, git branch
- **Theme (Omarchy):** `sykes_omarchy` — same layout, but bracket and accent colors are sourced from the active omarchy color theme automatically
- **Tmux:** Dracula theme via TPM, with git and SSH session status

## Hyprland (Arch)

Config is split into modules under `arch/.config/hypr/components/`:
- `hyprland.conf` — main entry, sources all modules
- Separate files for monitors, keybinds, environment variables, window rules, autostart
- Custom systemd user services for battery monitoring and wallpaper
- Udev rules in `arch/.udev/rules.d/` for hardware integration

## Neovim

Config lives at [SykesTheLord/NeoVimConfig](https://github.com/SykesTheLord/NeoVimConfig) — Lua-based with `vim.pack` (Neovim 0.12+). Run `NvimSetup.sh` to install it.
