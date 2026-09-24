# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a multi-distro dotfiles repository managing shell configs, window manager configs, and development environments for Arch, Ubuntu, Debian, Fedora, and openSUSE. Configs are deployed via **direct file copying** (not symlinks or GNU stow), managed by bash scripts.

Arch Linux is the primary/most-complete distro. `arch-wsl/` holds the terminal-only configs for Arch under WSL; `dotfiles_lib.sh` selects it instead of `arch/` when running under WSL. Ubuntu has a server and desktop i3 variant. Debian, Fedora, and openSUSE have minimal placeholder configs.

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
├── arch-wsl/           # Arch on WSL (terminal configs + hackerman colors)
├── omarchy/            # Omarchy overrides + sykes_omarchy zsh theme
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
- **`archWslSetup.sh`** — Arch on WSL in two stages (root: keyring/locale/user/`wsl.conf`; user: packages, yay + AUR, oh-my-zsh, `arch-wsl/` deploy, mise, .NET global tools, NeoVimConfig, default JDK, Mason packages, docker, Windows Terminal scheme). Dev toolchains for C/C++, C#/.NET, Java, Python and Bash are grouped in `PACMAN_PACKAGES`. Keep the WSL package lists to tools that make sense for development under WSL, with no GUI, media, personal or hardware tools. fastfetch, vim, downgrade, Go, Rust, nmap, tcpdump and whois are included on purpose. Both stages enable multilib and add BlackArch (`enable_multilib`, `configure_blackarch`; both idempotent, `--skip-blackarch` opts out). The BlackArch keyring is pinned by `BLACKARCH_KEYRING_VERSION` and `BLACKARCH_KEYRING_SHA256`. Only bump them after verifying the new tarball's `.sig` against the BlackArch Master key `CBA3C7D4798912702DCF568E67D8BDF42AD93F4E`. Don't switch to `strap.sh`: its verification is disabled. `MASON_PACKAGES` mirrors NeoVimConfig's `mason.lua` for those languages and is installed by a headless nvim Lua waiter, because NeoVimConfig's bootstrap and `:MasonInstall` don't wait for async installs already in progress. The WSL path must not depend on Omarchy tooling (no `omarchy/` files, Omarchy repo packages, or `omarchy-*` commands). Hackerman colors are hardcoded in `arch-wsl/.oh-my-zsh/custom/themes/sykes_hackerman.zsh-theme`, `arch-wsl/.config/btop/themes/hackerman.theme`, and `HACKERMAN_WT_SCHEME` in the script; keep them in sync. It reaches Neovim through `hackerman.nvim` + `aether.nvim` packages in `~/.local/share/nvim/site`, because the NeoVimConfig repo has no Omarchy theme support.
- **`archRemoteSetup.sh`** — Arch as a headless remote SSH dev box running as a QEMU guest, in two stages (root: keyring/locale/user, then GitHub key enrollment, then disables SSH password/root login once a key is confirmed installed — `--skip-harden` opts out; user: packages, yay + AUR, oh-my-zsh, dotfiles deploy, mise, .NET global tools, NeoVimConfig, default JDK, Mason packages, docker, `qemu-guest-agent`, unattended-update timer). Prompts for `--user` if not passed. `decide_github_user` runs in *both* stages (unless `--github-user` is already given): `confirm()` (a yes/no `prompt_var`-style helper, falling back to `/dev/tty`, and to its given default rather than dying when no terminal is available at all) asks whether to enroll a GitHub account before `prompt_var` asks which one; `--skip-github` opts out of asking (either stage). Stage 1 passes `confirm` a default of yes (the new account has no other access yet) and, once a key is imported, proceeds to `harden_sshd`. Stage 2 passes a default of no and calls `import_github_keys` directly for `$USER` with no sshd changes — since that stage only runs once you're already logged in as that user, it's self-service key add/refresh, not initial access provisioning. `import_github_keys` itself is EUID-aware (root chowns to the target user for stage 1; stage 2 skips that since non-root can't chown and doesn't need to) and fetches `https://github.com/<user>.keys`, merging it into `authorized_keys` by replacing only that GitHub user's own marked block (`# --- archRemoteSetup.sh: GitHub keys for <user> (begin/end) ---`), so reruns and multiple enrolled accounts don't clobber other keys already in the file. Declining enrollment in stage 1 leaves the account with a locked password and no key (warned at the end, with the `passwd <user>` / manual-key fallback) rather than silently locking them out with no explanation. Reuses `arch-wsl/`'s terminal-only dotfiles as-is (`REMOTE_DOTFILES_DIR`) since they don't depend on WSL or Windows Terminal — the hackerman zsh theme is baked-in 24-bit color. Otherwise mirrors `archWslSetup.sh`'s package lists, BlackArch/multilib handling, and Mason install waiter, minus WSL/Windows-only pieces (`wsl.conf`, Windows Terminal scheme, `wslu`, `wl-clipboard`, `hackerman.nvim`). Root-stage and user-stage steps are check-then-act throughout (multilib/BlackArch/curl/user-exists/package-`--needed`/Mason-dir/docker-socket/qemu-agent-enabled checks, and `install_auto_updates` diffing generated files against what's deployed) so reruns only do what's actually missing. `install_auto_updates` (`--skip-auto-update` opts out) writes `/usr/local/bin/arch-auto-update.sh` plus a `arch-auto-update.service`/`.timer` pair (`OnCalendar=Mon,Wed,Sat 03:00:00`, `Persistent=true`) that runs `pacman -Syu`, then `yay -Syu` as the target user via `runuser -l`, then `paccache -rk2`. Arch's rolling kernel has no live-patch feed (`kpatch` needs a hand-built patch per kernel build, so it can't cover arbitrary updates), so instead the script compares `/boot/vmlinuz-linux`'s embedded version (via `file -b`) against `uname -r` and, if they differ, reboots unattended — but only when `who` is empty and `pgrep -f claude` finds nothing for the target user; otherwise it logs a deferral (`logger -t arch-auto-update`) and retries at the next window. `setup_qemu_guest_agent` (`--skip-qemu-agent` opts out) installs and enables the `qemu-guest-agent` package/service for clean shutdown, freeze/thaw and IP reporting from the QEMU host.
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
